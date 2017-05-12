package AxKit::App::TABOO::Provider::NewsList;
use strict;
use warnings;
use Carp;

# This is the "NewsList" Provider, that is, it constructs objects that 
# eventually gives back XML containing listed stories.
# It just implements the AxKit Provider API, and therefore contains 
# no method that anybody should use for anything, so the POD deals with 
# what you should expect from this module. 


our $VERSION = '0.4';

=head1 NAME

AxKit::App::TABOO::Provider::NewsList - Provider for listing news stories in TABOO

=head1 SYNOPSIS

In the Apache config:

  <Location /news/>
  	PerlHandler AxKit
        AxContentProvider AxKit::App::TABOO::Provider::NewsList
    	PerlSetVar TABOOListDefaultRecords 20
    	PerlSetVar TABOOListMaxRecords 200
  </Location>


Please note that this should go B<before> the configuration of the
L<AxKit::App::TABOO::Provider::NewsList> Provider if you are using
both.


=head1 DESCRIPTION 

This is a Provider, it implements the AxKit Provider API, and
therefore contains no method that anybody should use for anything. For
that reason, this documentation deals with what you should expect to
be returned for different URIs.

It will return lists of news stories, so it makes use of Plural
Stories objects. Stories are returned sorted by timestamp, most recent
story first.

This Provider will return either the story except the content field
(which is unsuitable for longer lists of comments), or just title, submitter names and so on, depending on the URI.

In accordance with the TABOO philosophy, it interacts with Data
objects, that are Perl objects responsible for retrieving data from a
data storage, make up sensible data structures, return XML markup,
etc. In contrast with the News provider, this provider mainly
interacts with Plural objects to make lists of stories. Also, it
doesn't deal with comments.

=head1 CONFIGURATION DIRECTIVES

=over

=item TABOOListDefaultRecords

The maximum number of stories TABOO will retrieve from the data store
if the user gives no other instructions in the URI (see below). It is
recommended that you set this to some reasonable value.

=item TABOOListMaxRecords

The maximum number of stories TABOO will retrieve from the data store
in any case. If the user requests more than this number, a 403
Forbidden error will be returned. It is highly recommended that you
set this to a value you think your server can handle.

=back

=cut



use Data::Dumper;
use XML::LibXML;

use vars qw/@ISA/;
@ISA = ('Apache::AxKit::Provider');

use Apache;
use Apache::Log;
use Apache::AxKit::Exception;
use Apache::AxKit::Provider;

use AxKit;
use AxKit::App::TABOO;
use AxKit::App::TABOO::Data::Plurals::Stories;
use AxKit::App::TABOO::Data::Category;


sub init {
  my $self = shift;

  my $r = $self->apache_request();
  
  AxKit::Debug(10, "[NewsList] Request object: " . $r->as_string);
  AxKit::Debug(8, "[NewsList] Provider using URI " . $r->uri);
  
  $self->{number} = $r->dir_config('TABOOListDefaultRecords');
  $self->{maxrecords} = $r->dir_config('TABOOListMaxRecords');

  $self->{uri} = $r->uri;
  $self->{session} = AxKit::App::TABOO::session($r);

  my @uri = split('/', $r->uri);
  
  foreach my $part (@uri) {

    if ($part =~ m/^[0-9]+$/) {
      $self->{number} = $part;
      next;
    }
    if ($part eq 'list') {
      $self->{list} = 1;
      next;
    }
    if ($part eq 'editor') {
      $self->{editor} = 1;
      next;
    }
    if ($part eq 'unpriv') {
      $self->{unpriv} = 1;
      next;
    }

    if ($part ne 'news') {
      $self->{sectionid} = $part;
    }

  }
  AxKit::Debug(9, "[NewsList] Data parsed in init: " . Dumper($self));

  return $self;
}

sub process {
  my $self = shift;
  if ($self->{uri} =~ m|/news/.*/$|) {
    # URIs should never end with / unless it is just /news/
    throw Apache::AxKit::Exception::Retval(
					   return_code => 404,
					   -text => "URIs should not end with /");  
  }
  if ((AxKit::App::TABOO::authlevel($self->{session}) < 4) && ($self->{editor})) {
    throw Apache::AxKit::Exception::Retval(
					   return_code => 401,
					   -text => "You're not allowed to see editor-only stories without being authenticated as one.");
  }
  if (($self->{unpriv}) && ($self->{editor})) {
    throw Apache::AxKit::Exception::Retval(
					   return_code => 404,
					   -text => "Editor and Unpriviliged are mutually exclusive.");
  }
  if ($self->{number} > $self->{maxrecords}) {
    throw Apache::AxKit::Exception::Retval(
					   return_code => 403,
					   -text => "The server limit for number of records is " . $self->{maxrecords});
    }
  
  if ($self->{sectionid}) {
    # Iff a resource doesn't exist, it means that the section doesn't
    # exist, so we just check the list of sections
    $self->{section} = AxKit::App::TABOO::Data::Category->new();  
    unless ($self->{section}->load(what => '*', 
				   limit => {type => 'stsec',
					     catname => $self->{sectionid}})) {
      throw Apache::AxKit::Exception::Retval(
					     return_code => 404,
					     -text => "Not found by NewsList Provider.");
    }
  }
  # No exceptions thrown means that we go ahead here:
  $self->{exists} = 1;
  return 1;
}

sub exists {
  my $self = shift;
  if (defined($self->{exists})) {
    return 1;
  } else {
    return 0;
  }
  # Thanks, Kip! :-)
}


sub key {
  my $self = shift;
  return $self->{uri} . "/" . AxKit::App::TABOO::loggedin($self->{session});
}


sub mtime {
  my $self=shift;
  return time();
}


sub get_fh {
  throw Apache::AxKit::Exception::IO(
	      -text => "No fh for NewsList Provider");
}

sub get_strref {
  my $self = shift;
  my $what = 'storyname,sectionid,primcat,editorok,title,submitterid,timestamp';
  unless ($self->{list}) {
    $what .= ',minicontent,seccat,freesubject,image,username,linktext,lasttimestamp';
  }
  my %limit;
  my $authlevel = AxKit::App::TABOO::authlevel($self->{session});
  if (($authlevel < 4) || ($self->{unpriv})) {
    $limit{'editorok'} = 1;
  } elsif ($self->{editor}) {
    $limit{'editorok'} = 0;
  }
  if ($self->{sectionid}) {
    $limit{'sectionid'} = $self->{sectionid};
  }
  AxKit::Debug(9, "[NewsList] Limit records to: " . Dumper(%limit));

  $self->{stories} = AxKit::App::TABOO::Data::Plurals::Stories->new();
  $self->{stories}->load(what => $what, 
			 limit => \%limit, 
			 orderby => 'timestamp DESC', 
			 entries => $self->{number});
  $self->{stories}->addcatinfo;
  $self->{stories}->adduserinfo;
  my $doc = XML::LibXML::Document->new();
  my $rootel = $doc->createElement('taboo');
  $rootel->setAttribute('type', ($self->{list}) ? 'list':'stories');
  $rootel->setAttribute('origin', 'NewsList');
  if ($authlevel >= 5) {
    $rootel->setAttribute('can-edit', '1');
  }
  $doc->setDocumentElement($rootel);
  $self->{stories}->write_xml($doc, $rootel);
  if ($self->{section}) {
    $self->{section}->write_xml($doc, $rootel);
  }
  $self->{out} = $doc;
  AxKit::Debug(10, Dumper($self->{out}->toString(1)));

  return \$self->{out}->toString(1);
}

sub get_styles {
  my $self = shift;
  
  my @styles = (
		{ type => "text/xsl",
		  href => "/transforms/news/xhtml/newslist-provider.xsl" },
	       );
		
  return \@styles;
}


=head1 URI USAGE

Like the News Provider, the URI in this Provider consists of several
parts that is parsed and used directly to construct the objects that
contain the data we wish to send to the user.

The URIs currently begin with C</news/>. This should be made
customizable in the future, but currently needs to be hardcoded in the
httpd.conf and is hardcoded in the Provider itself.

In this provider, C</news/> will return all the news stories, only
limited in number by the TABOOListMaxRecords directive.


Optionally, one may then append a C<sectionid>, to get the stories in
that section.

By default, any user will see the stories they are authorized to see,
so a higher privileged user will see both stories that are approved by
an editor and stories that have yet to be approved. That user may then
append C</editor>, to see only the stories that has not yet been
approved, I<or> C</unpriv> to see what unprivileged users see.

The default is to return all information except the
C<content>-field. With this information, one can build a page to
display several stories, but with links to the whole story.

In all cases, if you rather want a simple list of titles, timestamp
and submitter information, you may append C</list> to the URI.

At the end of the URI, you may also append an integer representing how
many stories you want. This number defaults to the
TABOOListDefaultRecords value, but may be both smaller and larger than
that, however not larger than TABOOListMaxRecords.

To take some complete examples:

  /news/features/editor/list/5

This would, if the user is logged in and authorized as an editor
return a simple list of up to 5 stories from the features section that
needs to be approved. The list is suitable to get an overview.

  /news/features/30

will return up to 30 stories from the features section, where the
C<title>, C<minicontent>, etc is included. Normal users will often
want to view this and then select what they want to read more about.


=head1 TODO

Since every resource comes with a C<lasttimestamp>, it should be
relatively simple to implement C<mtime> better than it is now, but the
question is if all code updates C<lasttimestamp> reliably enough...

The C<get_styles> method is implemented, but just to "make it work
right now". It needs to take many conditions into account, such as the
mime type requested by the user. It is even possible it should be
going into a parent class.


=head1 BUGS/QUIRKS

It is non-trivial is to configure both the News and NewsList providers
to work and at the same time having the submit.xsp in the same
directory. There is a somewhat ad hoc example in L<AxKit::App::TABOO>
now.


=head1 SEE ALSO

L<AxKit::App::TABOO::Data::Provider::News>,
L<AxKit::App::TABOO::Data::Plurals::Stories>


=head1 FORMALITIES

See L<AxKit::App::TABOO>.

=cut



1;


