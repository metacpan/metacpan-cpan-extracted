package CGI::Application::Plugin::PageLookup;

use warnings;
use strict;
use CGI::Application::Plugin::Forward;
use Carp;
use base qw(Exporter);
use vars qw($VERSION @EXPORT_OK %EXPORT_TAGS);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT_OK = qw(
    pagelookup_config
    pagelookup_get_config
    pagelookup_set_charset
    pagelookup_prefix
    pagelookup_sql
    pagelookup
    pagelookup_notfound
    pagelookup_set_expiry
    pagelookup_default_lang
    pagelookup_404
    pagelookup_msg_param
    pagelookup_rm
    xml_sitemap_rm
    xml_sitemap_sql
    xml_sitemap_base_url
);
%EXPORT_TAGS  = (all => \@EXPORT_OK);

=head1 NAME

CGI::Application::Plugin::PageLookup - Database driven model framework for CGI::Application

=head1 VERSION

Version 1.8

=cut

our $VERSION = '1.8';

=head1 DESCRIPTION

A model component for CGI::Application built around a table that has one row for each
page and that provides support for multiple languages and the 'dot' notation in templates.

=head1 SYNOPSIS

    package MyCGIApp base qw(CGI::Application);
    use CGI::Application::Plugin::PageLookup qw(:all);

    # Anything but the simplest usage depends on "dot" notation.
    use HTML::Template::Pluggable; 
    use HTML::Template::Plugin::Dot;

    sub cgiapp_init {
        my $self = shift;

        # pagelookup depends CGI::Application::DBH;
        $self->dbh_config(......); # whatever arguments are appropriate
	
        $self->html_tmpl_class('HTML::Template::Pluggable');

        $self->pagelookup_config(

		# prefix defaults to 'cgiapp_'.
		prefix => 'mycgiapp_',

		# load smart dot-notation objects
		objects => 
		{
			# Support for TMPL_LOOP
			loop => 'CGI::Application::Plugin::PageLookup::Loop',

			# Decoupling external and internal representations of URLs
			href => 'CGI::Application::Plugin::PageLookup::Href',

			# Page specific and site wide parameters
			value => 'CGI::Application::Plugin::PageLookup::Value',

			# We have defined a MyCGIApp::method method 
			method => 'create_custom_object',

			# We can also handle CODE refs
			callback => sub {
				my $self = shift;
				my $page_id = shift;
				my $template = shift;
				........  
			}

		},

		# remove certain fields before sending the parameters to the template.
		remove =>
		[
			'custom_col1',
			'priority'
		],

		xml_sitemap_base_url => 'http://www.mytestsite.org'

	);

    }

    sub create_custom_object {
	my $self = shift;
	my $page_id = shift;
	my $template = shift;
	my $name = shift;
	return ........... # smart object that can be used for dot notation
    }

    sub setup {
        my $self = shift;

        $self->run_modes({
		'pagelookup'  => 'pagelookup_rm',
		'xml_sitemap' => 'xml_sitemap',
		'extra_stuff' => 'extra_stuff'
	});
	............
    }

    sub extra_stuff {
	my $self = shift;

	# do page lookup
        my $template_obj = $self->pagelookup($page_id,
					handle_notfound=>0, # force function to return undef if page not found
					objects=> ....); #  but override config for this run mode alone.

	return $self->notfound($page_id) unless $template_obj;

	# More custom stuff
	$template_obj->param( .....);

        return $template_obj->output;
 
    }

=head1 DATABASE

Something like the following schema is assumed. In general each column on these tables 
corresponds to a template parameter that needs to be on every page on the website and each row in the join
corresponds to a page on the website. The exact types are not required and can be changed
but these are the recommended values. The lang and internalId columns combined should be as unique as the pageId 
column. They are used to link the different language versions of the same page and also the page with 
nearby pages in the same language. The lang column is used to join the two pages. The lang and collation fields expect
to find some template structure like this:
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="<TMPL_VAR NAME="lang">-<TMPL_VAR NAME="collation">">
...
</html> 
The priority, lastmod and changefreq columns are used in XML sitemaps as defined by http://www.sitemaps.org/protocol.php.
The changefreq field is also used in setting the expiry header. Since these fields are not expected to be in general usage,
by default they are deleted just before being sent to the template. The lineage and rank columns are used by menu/sitemap 
functionality and together should be unique.

=over

=item Table: cgiapp_structure

 Field        Type                                                                Null Key  Default Extra 
 ------------ ------------------------------------------------------------------- ---- ---- ------- -----
 internalId   unsigned numeric(10,0)                                              NO   PRI  NULL          
 template     varchar(20)                                                         NO        NULL          
 lastmod      date                                                                NO        NULL          
 changefreq   enum('always','hourly','daily','weekly','monthly','yearly','never') NO        NULL          
 priority     decimal(3,3)                                                        YES       NULL          
 lineage      varchar(255)                                                        NO   UNI  NULL    	 
 rank	      unsigned numeric(10,0)                                              NO   UNI  NULL    	 

=item Table: cgiapp_pages

 Field        Type                                                                Null Key  Default Extra 
 ------------ ------------------------------------------------------------------- ---- ---- ------- -----
 pageId       varchar(255)                                                        NO   UNI  NULL          
 lang         varchar(2)       	                                                  NO   PRI  NULL          
 internalId   unsigned numeric(10,0)                                              NO   PRI  NULL          

 + any custom columns that the web application might require.

=item Table: cgiapp_lang

 Field        Type                                                                Null Key  Default Extra 
 ------------ ------------------------------------------------------------------- ---- ---- ------- -----
 lang         varchar(2)                                                          NO   PRI  NULL          
 collation    varchar(2)                                                          NO        NULL          

 + any custom columns that the web application might require.

=back

=head1 EXPORT

These functions can be optionally imported into the CGI::Application or related namespace.

    pagelookup_config
    pagelookup_get_config
    pagelookup_set_charset
    pagelookup_prefix
    pagelookup_sql
    pagelookup
    pagelookup_notfound
    pagelookup_set_expiry
    pagelookup_default_lang
    pagelookup_404
    pagelookup_msg_param
    pagelookup_rm
    xml_sitemap_rm
    xml_sitemap_sql
    xml_sitemap_base_url

Use the tag :all to export all of them.

=head1 FUNCTIONS

=head2 pagelookup_config

This function defines the default behaviour of the plugin, though this can be overridden for specific runmodes.
The possible arguments are as follows:

=over

=item prefix

This sets the prefix used in the database schema. It defaults to 'cgiapp_'.

=item  handle_notfound

If set (which it is by default), the pagelookup function will return 
the results of calling pagelookup_notfound when a pagelookup fails. If not set
the runmode must handle page lookup failures itself which it will identify 
because the pagelookup function will return undef.

=item expiry

If set (which it is by default), the pagelookup function will set the appropriate
expiry header based upon the changefreq column.

=item remove

This points to an array ref of fields that are not expected to be required by the template. 
It defaults to template, pageId and internalId, changefreq.

=item objects

This points to a hash ref. Each key is a parameter name (upto the dot). The value
is something that defines a smart object as described in L<HTML::Template::Plugin::Dot>.
The point about a smart object is that usually it defines an AUTOLOAD function so if the template
has <TMPL_VAR NAME="object.getcarter"> and the pagelookup_config has mapped object to some
object $MySmartObject then the method $MySmartObject->getcarter() will be called. Alternatively
there may be no AUTOLOAD function but the smart object may have methods that take additional arguments.
This way the template can be much more decoupled from the structure of the database.

There are three ways a smart object can be defined. Firstly if the value is a CODE ref,
then the ref is passed 1.) the reference to the CGI::Application object; 2.) the page id; 3.) the template,
4.) the parameter name 5.) any argument overrides. Otherwise if the CGI::Application has the value as a method, then the method is called with 
the same arguments as above. Finally the value is assumed to be the name of a module and the new constructor
of the supposed module is called with the same arguments. A typical smart object might be coded as follows:

	package MySmartObject;

	sub new {
		my $class = shift;
		my $self = .....
		......
		return bless $self, $class;
	}

	# If you do not have this, then HTML::Template::Plugin::Dot will not know that you can!
	# [Note really can is supposed to return a subroutine ref, but this works in this context.]
	sub can { return 1; }

	# This is the function that actually produces the value to be inserted into the template.
	sub AUTOLOAD {
		my $self = shift;
		my $method = $AUTOLOAD;
		if ($method =~ s/^MySmartObject\:\:(.+)$/) {
			$method = $1;	# Now we have what is in the template.
		}
		else {
			....
		}
		.....
		return $value;
	}

Note that the smart object does not have access to HASH ref because the data is changing at the point
it would be used and so is non-deterministic.

=item charset

This is a string defining the character encoding. This defaults to 'utf-8'.

=item template_params

This is a hashref containing additional parameters that are to be passed to the load_templ function.

=item default_lang

This is a two letter code and defaults to 'en'. It is used when creating a notfound page when a language
cannot otherwise be guessed.

=item status_404

This is the internal id corresponding to the not found page.

=item msg_param

This is the parameter used to store error messages.

=item xml_sitemap_base_url

This is the url for the whole site. It is mandatory to set this if you want XML sitemaps (which you should).

=back

=cut

sub pagelookup_config {
   my $self = shift;
   my %args = @_;

   croak "Calling pagelookup_config after the pagelookup has already been configured" if defined $self->{__cgi_application_plugin_pagelookup};

   $args{prefix} = "cgiapp_" unless exists $args{prefix};
   $args{handle_notfound} = 1 unless exists $args{handle_notfound};
   $args{expiry} = 1 unless exists $args{expiry};
   $args{remove} = ['template', 'pageId', 'internalId', 'changefreq'] unless exists $args{remove};
   $args{objects} = {} unless exists $args{objects};
   $args{template_params} = {} unless exists $args{template_params};
   $args{default_lang} = 'en' unless exists $args{default_lang};
   $args{status_404} = '404' unless exists $args{status_404};
   $args{msg_param} = 'pagelookup_message' unless exists $args{msg_param};
   $args{charset} = 'utf-8' unless exists $args{charset};

   $self->{__cgi_application_plugin_pagelookup} = \%args;

   $self->pagelookup_set_charset();
   return;
}

=head2 pagelookup_get_config 

Returns config including any overrides passed in as arguments.

=cut

sub pagelookup_get_config {
   my $self = shift;
   my %args = (%{$self->{__cgi_application_plugin_pagelookup}}, @_);
   return %args;
}

=head2 pagelookup_set_charset

This function sets the character set based upon the config.

=cut

sub pagelookup_set_charset {
   my $self = shift;
   my %args = $self->pagelookup_get_config(@_);
   $self->header_props(-encoding=>$args{charset},-charset=>$args{charset});
   return;
}

=head2 pagelookup_prefix

This function returns the prefix that is used on the database for all the tables.
The prefix can of course be overridden.

=cut

sub pagelookup_prefix {
   my $self = shift;
   my %args = $self->pagelookup_get_config(@_);
   return $args{prefix};
}

=head2 pagelookup_sql 

This function returns the SQL that is used to lookup a specific page.
It takes a single argument which is usually expected to be a pageId.
This may also be taken in the form of a HASH ref having two fields: internalId and lang.

=cut

sub pagelookup_sql {
   my $self = shift;
   my $page_id = shift;
   my $prefix = $self->pagelookup_prefix(@_);
   if (ref($page_id) eq "HASH") {
	croak "internalId expected" unless exists $page_id->{internalId};
	croak "lang expected" unless exists $page_id->{lang};
 	return "SELECT s.template, s.changefreq, p.*, l.* FROM ${prefix}pages p, ${prefix}lang l, ${prefix}structure s WHERE p.lang = l.lang AND p.lang = '$page_id->{lang}' AND p.internalId = s.internalId AND p.internalId = $page_id->{internalId}";
   }
   return "SELECT s.template, s.changefreq, p.*, l.* FROM ${prefix}pages p, ${prefix}lang l, ${prefix}structure s WHERE p.lang = l.lang AND p.pageId = '$page_id' AND p.internalId = s.internalId";
}

=head2 pagelookup 

This is the function that does the heavy lifting. It takes a page id and optionally some
arguments overriding the default config. Then the sequence of events is as follows:
1.) Lookup up the various parameters from the database.
2.) If this fails then exit either handling or just returning undef according to instructions.
3.) Load the template object.
4.) Set the expiry header unless instructed not to.
5.) Load the smart objects that are mentioned in the template.
6.) Remove unwanted parameters.
7.) Put the parameters into the template object.
8.) Return the now partially or completely filled template object.

The page id may also be taken in the form of a HASH ref having two fields: internalId and lang.

=cut

sub pagelookup {
   my $self = shift;
   my $page_id = shift;
   my @inargs = @_;
   my %args = $self->pagelookup_get_config(@inargs);
   my $dbh = $self->dbh();
   my $sth = $dbh->prepare($self->pagelookup_sql($page_id, @inargs)) || croak $dbh->errstr;
   $sth->execute || croak $dbh->errstr;
   my $hash_ref = $sth->fetchrow_hashref;

   # check if page was found
   unless ($hash_ref) {
	croak $dbh->errstr if $dbh->err;
        $sth->finish;

	if ($args{handle_notfound}) {
		return $self->pagelookup_notfound($page_id, @inargs);
	}

	return undef;
   }

   $page_id = $hash_ref->{pageId} if ref($page_id) eq "HASH";

   # Load the template
   my $template = $self->load_tmpl($hash_ref->{template}, %{$args{template_params}});

   # Get a list of smart objects mentioned in the template
   my %smart_objects_actually_used = ();
   foreach my $o ($template->query()) {
	if ($o =~ /^([a-zA-Z_]\w+)\./) {
		$smart_objects_actually_used{$1} = 1;
	}
   }

   # Set the expiry headers
   $self->pagelookup_set_expiry($hash_ref, @inargs) if $args{expiry};

   # create the smart objects
   foreach my $okey (keys %{$args{objects}}) {
	next unless $smart_objects_actually_used{$okey};
	my $ovalue = $args{objects}->{$okey};
	my $object = undef;

	if (ref($ovalue) eq "CODE") {
		$object = &$ovalue($self, $page_id, $template, $okey, @inargs);
	}
	elsif ($self->can($ovalue)) {
		$object = $self->$ovalue($page_id, $template, $okey, @inargs);
	}
	else {
		use UNIVERSAL::require;
		$object = eval {
			$ovalue->require;
			return $ovalue->new($self, $page_id, $template, $okey, @inargs);
		};
		croak "Could not create smart object: $okey: $@" if $@;
	}

        $hash_ref->{$okey} = $object if $object;

   }

   # remove unwanted parameters
   foreach my $remove (@{$args{remove}}) {
	delete $hash_ref->{$remove};
   }

   # we cannot think of anything else to stop us from inserting the parameters into the template
   $template->param(%$hash_ref);
   return $template;
}

=head2 pagelookup_rm 

This function is a generic run mode. It takes a page id and tries to do everything else.
Of course most of the work is done by pagelookup.

=cut 

sub pagelookup_rm {
   my $self = shift;
   my $page_id = $self->param('pageid') || return $self->forward($self->start_mode());
   my $template = $self->pagelookup($page_id);
   croak "no template returned: $page_id" unless $template;
   return $template->output;
}

=head2 xml_sitemap_rm

This method is intended to be installed as a sitemap. Since the format is fixed, it is self-contained and does not load
templates from files. Note if a page as a null priority then it is not put in the sitemap.
For this function to work it is necessary to set the base BASE_URL parameter.

=cut

sub xml_sitemap_rm {
   my $self = shift;
   my $dbh = $self->dbh();
   my $base_url = $self->xml_sitemap_base_url();
   my $sql = $self->xml_sitemap_sql();
   my $sth = $dbh->prepare($sql) || croak $dbh->errstr;
   $sth->execute or  croak $dbh->errstr;
   my $hash_ref = $sth->fetchall_arrayref({});
   my $template =<<"EOS"
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
<TMPL_LOOP NAME="urls">
   <url>
      <loc>$base_url<TMPL_VAR NAME="pageId"></loc>
      <lastmod><TMPL_VAR NAME="lastmod"></lastmod>
      <changefreq><TMPL_VAR NAME="changefreq"></changefreq>
      <priority><TMPL_VAR NAME="priority"></priority>
   </url>
</TMPL_LOOP>
</urlset>
EOS
;
   my $t = $self->load_tmpl(\$template);
   $t->param(urls=>$hash_ref);
   $self->header_add( -type => 'text/xml', -charset=>'utf-8' );
   return $t->output;
}

=head2 pagelookup_notfound

This function takes a page id which has failed a page lookup and tries to find the best fitting
404 page. First of all it attempts to find the correct by language by assuming that if the first three 
characters of the page id consists of two characters followed by a '/'. If this matches then the first
two characters are taken to be the language. If that fails then the language is taken to be $self->pagelookup_default_lang.
Then the relevant 404 page is looked up by language and internal id. The internalId is taken to be $self->pagelookup_404 . 
Of course it is assumed that this page lookup cannot fail. The header  404 status is added
to the header and the original page id is inserted into the $self->pagelookup_msg_param parameter.
If this logic does not match your URL structure you can omit exporting this function or turn notfound handling off
and implement your own logic.

=cut

sub pagelookup_notfound {
   my $self = shift;
   my $page_id = shift;
   my @inargs = @_;
   my %args = $self->pagelookup_get_config(@inargs);

   # Best guess at language
   my $lang = $self->pagelookup_default_lang(@inargs);
   if ($page_id =~ /^(\w\w)\//) {
	$lang = $1;
   }

   my $template = $self->pagelookup({lang=>$lang, internalId => $self->pagelookup_404}, handle_notfound=>0) || croak "failed to construct 'not found' page";
   $template->param( $self->pagelookup_msg_param(@inargs) => $page_id);
   $self->header_add( -status => 404 );
   return $template;

}

=head2 pagelookup_set_expiry

This function sets the expiry header based upon the hash_ref.

=cut

sub pagelookup_set_expiry {
   my $self = shift;
   my $hash_ref = shift;
   my $changefreq = $hash_ref->{changefreq} or return;
   my %mapping = (always=>'-1d', hourly=>'+1h', daily=>'+1d', weekly=>'+7d', monthly=>'+1M', yearly=>'+1y', never=>'+3y');
   $self->header_add(-expires=>$mapping{$changefreq});
   return;
}

=head2 pagelookup_default_lang 

This returns the default language code.

=cut

sub pagelookup_default_lang {
   my $self = shift;
   my %args = $self->pagelookup_get_config(@_);
   return $args{default_lang};
}

=head2 pagelookup_404

This returns the core id used by 404 pages.

=cut

sub pagelookup_404 {
   my $self = shift;
   my %args = $self->pagelookup_get_config(@_);
   return $args{status_404};
}

=head2 pagelookup_msg_param

This returns the parameter that pagelookup uses for inserting error messages.

=cut

sub pagelookup_msg_param {
   my $self = shift;
   my %args = $self->pagelookup_get_config(@_);
   return $args{msg_param};
}

=head2 xml_sitemap_sql

This returns the SQL used to get the XML sitemap data.

=cut

sub xml_sitemap_sql {
   my $self = shift;
   my $prefix = $self->pagelookup_prefix(@_);
   return "SELECT pageId, lastmod, changefreq, priority FROM ${prefix}pages p, ${prefix}structure s WHERE priority IS NOT NULL AND p.internalId = s.internalId ORDER BY priority DESC";
}

=head2 xml_sitemap_base_url

This returns the base url used in XML sitemaps.

=cut

sub xml_sitemap_base_url {
   my $self = shift;
   my %args = $self->pagelookup_get_config(@_);
   return $args{xml_sitemap_base_url} || croak "no xml sitemp base url set";
}


=head1 AUTHOR

Nicholas Bamber, C<< <nicholas at periapt.co.uk> >>

=head1 BUGS

Currently errors are not trapped early enough and hence error messages are less informative than they might be.

Also we are working on validating the code against more L<DBI> drivers. Currently mysql and SQLite are known to work.
It is known to be incompatible with postgres, which should be fixed in the next release. This may entail schema changes.
It is also known to be in incompatible with L<DBD::DBM>, apparently on account of a join across three tables.
The SQL is not ANSI standard and that is one possible change. Another approach may be to make the schema configurable.

Please report any bugs or feature requests to C<bug-cgi-application-plugin-pagelookup at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Application-Plugin-PageLookup>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CGI::Application::Plugin::PageLookup


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-Application-Plugin-PageLookup>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CGI-Application-Plugin-PageLookup>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CGI-Application-Plugin-PageLookup>

=item * Search CPAN

L<http://search.cpan.org/dist/CGI-Application-Plugin-PageLookup/>

=back


=head1 ACKNOWLEDGEMENTS

Thanks to JavaFan for suggesting the use of L<Test::Database>. Thanks to  Philippe Bruhat
for help with getting Test::Database to work more smoothly.

=head1 COPYRIGHT & LICENSE

Copyright 2009 Nicholas Bamber.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of CGI::Application::Plugin::PageLookup
