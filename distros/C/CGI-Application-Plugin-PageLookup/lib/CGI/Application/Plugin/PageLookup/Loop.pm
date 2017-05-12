package CGI::Application::Plugin::PageLookup::Loop;

use warnings;
use strict;

=head1 NAME

CGI::Application::Plugin::PageLookup::Loop - Manage list structures in a website

=head1 VERSION

Version 1.8

=cut

our $VERSION = '1.8';
our $AUTOLOAD;

=head1 DESCRIPTION

This module manages the instantiation of list style template parameters across a website;
for example TMPL_LOOP in L<HTML::Template>, though one must use L<HTML::Template::Pluggable> for it to
work. For example a menu is typically implemented in HTML as <ul>....</ul>. Using this module
the menu can be instantiated from the database and the same data used to instantiate a human-readable
sitemap page. On the other hand the staff page will have list data that is only required on that page.
This module depends on L<CGI::Application::Plugin::PageLookup>.

=head1 SYNOPSIS

In the template you might define a menu as follows (with some CSS and javascript to make it look nice):

    <ul>
    <TMPL_LOOP NAME="loop.menu">
	<li>
		<a href="<TMPL_VAR NAME="lang">/<TMPL_VAR NAME="this.href1">"><TMPL_VAR NAME="this.atitle1"></a>
		<TMPL_IF NAME="submenu1">
		<ul>
		<TMPL_LOOP NAME="submenu1">
			<li>
				<a href="<TMPL_VAR NAME="lang">/<TMPL_VAR NAME="href2">"><TMPL_VAR NAME="atitle2"></a>
				<TMPL_IF NAME="submenu2">
				<ul>
				<TMPL_LOOP NAME="submenu2">
				<li>
					<a href="<TMPL_VAR NAME="lang">/<TMPL_VAR NAME="href3">"><TMPL_VAR NAME="atitle3"></a>
				</li>
				</TMPL_LOOP>
				</ul>
				</TMPL_IF>
			</li>
		</TMPL_LOOP>
		</ul>	
		</TMPL_IF>
	</li>
    </TMPL_LOOP>
    </ul>

and the intention is that this should be the same on all English pages, the same on all Vietnamese pages etc etc.
The use of "this." below the top levels is dictated by L<HTML::Template::Plugin::Dot> which also optionally allows
renaming of this implicit variable. You must register the "loop" parameter as a CGI::Application::Plugin::PageLookup::Loop object as follows:

    use CGI::Application;
    use CGI::Application::Plugin::PageLookup qw(:all);
    use CGI::Application::Plugin::PageLookup::Loop;
    use HTML::Template::Pluggable;
    use HTML::Template::Plugin::Dot;

    sub cgiapp_init {
        my $self = shift;

        # pagelookup depends CGI::Application::DBH;
        $self->dbh_config(......); # whatever arguments are appropriate

        $self->html_tmpl_class('HTML::Template::Pluggable');

        $self->pagelookup_config(

                # load smart dot-notation objects
                objects =>
                {
                        # Register the 'values' parameter
                        loop => 'CGI::Application::Plugin::PageLookup::Loop',
		},

		# Processing of the 'lang' parameter inside a loop requires global_vars = 1 inside the template infrastructure
		template_params => {global_vars => 1}

	);
    }


    ...

The astute reader will notice that the above will only work if you set the 'global_vars' to true. After that all that remains is to populate
the cgiapp_loops table with the appropriate values. To fill the above menu you might run the following SQL:

	INSERT INTO cgiapp_loops (lang, loopName, lineage, rank, param, value) VALUES ('en', 'menu', '', 0, 'href1', '')
	INSERT INTO cgiapp_loops (lang, loopName, lineage, rank, param, value) VALUES ('en', 'menu', '', 0, 'atitle1', 'Home page')
	INSERT INTO cgiapp_loops (lang, loopName, lineage, rank, param, value) VALUES ('en', 'menu', '', 1, 'href1', 'aboutus')
	INSERT INTO cgiapp_loops (lang, loopName, lineage, rank, param, value) VALUES ('en', 'menu', '', 1, 'atitle1', 'About us')
	INSERT INTO cgiapp_loops (lang, loopName, lineage, rank, param, value) VALUES ('en', 'menu', '', 2, 'href1', 'products')
	INSERT INTO cgiapp_loops (lang, loopName, lineage, rank, param, value) VALUES ('en', 'menu', '', 2, 'atitle1', 'Our products')
	INSERT INTO cgiapp_loops (lang, loopName, lineage, rank, param, value) VALUES ('en', 'menu', '', 3, 'href1', 'contactus')
	INSERT INTO cgiapp_loops (lang, loopName, lineage, rank, param, value) VALUES ('en', 'menu', '', 3, 'atitle1', 'Contact us')
	INSERT INTO cgiapp_loops (lang, loopName, lineage, rank, param, value) VALUES ('en', 'menu', '', 4, 'href1', 'sitemap')
	INSERT INTO cgiapp_loops (lang, loopName, lineage, rank, param, value) VALUES ('en', 'menu', '', 4, 'atitle1', 'Sitemap')

Now suppose that you need to describe the products in more detail. Then you might add the following rows:

	INSERT INTO cgiapp_loops (lang, loopName, lineage, rank, param, value) VALUES ('en', 'submenu1', '2', 0, 'href2', 'wodgets')
	INSERT INTO cgiapp_loops (lang, loopName, lineage, rank, param, value) VALUES ('en', 'submenu1', '2', 0, 'atitle2', 'Finest wodgets')
	INSERT INTO cgiapp_loops (lang, loopName, lineage, rank, param, value) VALUES ('en', 'submenu1', '2', 1, 'href2', 'bladgers')
	INSERT INTO cgiapp_loops (lang, loopName, lineage, rank, param, value) VALUES ('en', 'submenu1', '2', 1, 'atitle2', 'Delectable bladgers')
	INSERT INTO cgiapp_loops (lang, loopName, lineage, rank, param, value) VALUES ('en', 'submenu1', '2', 2, 'href2', 'spodges')
	INSERT INTO cgiapp_loops (lang, loopName, lineage, rank, param, value) VALUES ('en', 'submenu1', '2', 2, 'atitle2', 'Exquisite spodges')
	
Now suppose that the bladger market is hot, and we need to further subdivide our menu. Then you might add the following rows:

	INSERT INTO cgiapp_loops (lang, loopName, lineage, rank, param, value) VALUES ('en', 'submenu2', '2,1', 0, 'href3', 'bladgers/runcible')
	INSERT INTO cgiapp_loops (lang, loopName, lineage, rank, param, value) VALUES ('en', 'submenu2', '2,1', 0, 'atitle3', 'Runcible bladgers')
	INSERT INTO cgiapp_loops (lang, loopName, lineage, rank, param, value) VALUES ('en', 'submenu2', '2,1', 1, 'href3', 'bladgers/collapsible')
	INSERT INTO cgiapp_loops (lang, loopName, lineage, rank, param, value) VALUES ('en', 'submenu2', '2,1', 1, 'atitle3', 'Collapsible bladgers')
	INSERT INTO cgiapp_loops (lang, loopName, lineage, rank, param, value) VALUES ('en', 'submenu2', '2,1', 2, 'href3', 'bladgers/goldplated')
	INSERT INTO cgiapp_loops (lang, loopName, lineage, rank, param, value) VALUES ('en', 'submenu2', '2,1', 2, 'atitle3', 'Gold plated bladgers')


=head1 DATABASE

This module depends on only one extra table: cgiapp_loops. The lang and internalId columns join against
the cgiapp_table. However the internalId column can null, making the parameter available to all pages
in the same language. The key is formed by all of the columns except for the value.

=over 

=item Table: cgiapp_loops

 Field        Type                                                                Null Key  Default Extra
 ------------ ------------------------------------------------------------------- ---- ---- ------- -----
 lang         varchar(2)                                                          NO   UNI  NULL          
 internalId   unsigned numeric(10,0)                                              YES  UNI  NULL          
 loopName     varchar(20)							  NO   UNI  NULL          
 lineage      varchar(255)							  NO   UNI                
 rank	      unsigned numeric(2,0)						  NO   UNI  0             
 param        varchar(20)                                                         NO   UNI  NULL          
 value        text								  NO        NULL          

=back

The loopName is the parameter name of the TMPL_LOOP structure. The rank indicates which iteration of the loop
this row is instantiating. The lineage is a comma separated list of ranks so that we know what part of a nested
loop structure this row instantiates. For a top-level parameter this will always be the empty string.

=head1 FUNCTIONS

=head2 new

A constructor following the requirements set out in L<CGI::Application::Plugin::PageLookup>.

=cut

sub new {
	my $class = shift;
	my $self = {};
	$self->{cgiapp} = shift;
	$self->{page_id} = shift;
	$self->{template} = shift;
	$self->{name} = shift;
	my %args = @_;
	$self->{config} = \%args;

	bless $self, $class;
	return $self;
}

=head2 can

We need to autoload methods so that the template writer can use loops without needing to know
where the loops will be used. Thus 'can' must return a true value in all cases to avoid breaking
L<HTML::Template::Plugin::Dot>. Also 'can' is supposed to either return undef or a CODE ref. This seems the cleanest
way of meeting all requirements.

=cut

sub can {
	my $self = shift;
	my $loopname = shift;
	return sub {
	  my $self = shift;

          # $dlineage are the "breadcrumbs" required to navigate our way through the database
	  # and corresponds to the 'lineage' column on the cgiapp_loops table.
	  my $dlineage = shift;
	  $dlineage = "" unless defined $dlineage;

	  # $tlineage are the "breadcrumbs" required to navigate our way through the HTML::Template structure.
	  # It corresponds to the ARRAY ref used in $template->query(loop=> [....]) only that the
	  # post "dot" string of the final array member (aka $loopname) is missing.
	  my $tlineage = shift;
	  $tlineage = [$self->{name}] unless defined $tlineage;

          my $prefix = $self->{cgiapp}->pagelookup_prefix(%{$self->{config}});
          my $page_id = $self->{page_id};
          my $dbh = $self->{cgiapp}->dbh;

	  # This is what we actually want to return
	  my @loop;

	  # These are temporary variables that will help us get there
	  my $current_row = undef;
	  my $current_rank = undef;
	  $self->{work_to_be_done} = [] unless exists $self->{work_to_be_done};

	  # First one pass over the loop
          my @sql = (
                "SELECT l.rank, l.param, l.value FROM ${prefix}loops l, ${prefix}pages p WHERE l.internalId = p.internalId AND l.loopName = '$loopname' AND l.lang = p.lang AND p.pageId = '$page_id' and l.lineage = '$dlineage' order by l.rank asc",
                "SELECT l.rank, l.param, l.value FROM ${prefix}loops l, ${prefix}pages p WHERE l.internalId IS NULL AND l.loopName = '$loopname' AND l.lang = p.lang AND p.pageId = '$page_id' and l.lineage = '$dlineage' order by l.rank asc");
          foreach my $s (@sql) {
                my $sth = $dbh->prepare($s) || croak $dbh->errstr;
                $sth->execute || croak $dbh->errstr;
                while(my $hash_ref = $sth->fetchrow_hashref) {

			my $next_rank = $hash_ref->{rank};
			my $param = $hash_ref->{param};
			my $value = $hash_ref->{value};

			# rank transitions
			if (!defined $current_rank) {
				$current_rank = $next_rank;
				$current_row = {};
			}
			elsif ($current_rank < $next_rank) {

				# Now we need to add in any loop variables
				$self->__populate_lower_loops($dlineage, $tlineage, $current_row, $current_rank, $loopname);

				# We are finally ready to get this structure out of the door
				push @loop, $current_row;
				$current_row = {};
				$current_rank = $next_rank;
			}

			$current_row->{$param} = $value;

		}
                croak $sth->errstr if $sth->err;
                $sth->finish;
		if ($current_row) {
			$self->__populate_lower_loops($dlineage, $tlineage, $current_row, $current_rank, $loopname);
			push @loop, $current_row if %$current_row;
		}
		last if @loop;
          }

	  # Now go back over the remaining work
	  while(@{$self->{work_to_be_done}}) {
		my $work = shift @{$self->{work_to_be_done}};
		&$work();
	  }

          return \@loop;

	};
}

=head2 AUTOLOAD 

We need to autoload methods so that the template writer can use loops without needing to know
where the variables  will be used.

=cut

sub AUTOLOAD {
	my $self = shift;
	my @method = split /::/, $AUTOLOAD;
	my $param = pop @method;
	my $c = $self->can($param);
	return &$c($self, @_) if $c;
	return undef;
}

=head2 __populate_lower_loops

A private function that does what is says.

=cut 

sub __populate_lower_loops {
	my $self = shift;
	my $dlineage = shift;
	my $tlineage = shift;
	my $current_row = shift;
	my $current_rank = shift;
	my $loopname = shift;
	my $comma = ',';
        my $new_dlineage = join $comma , (split /,/, $dlineage), $current_rank;
        my @new_tlineage = @$tlineage;
        my $thead = pop @new_tlineage;
        push @new_tlineage, "$thead.$loopname";
        my @new_vars = $self->{template}->query(loop=>\@new_tlineage);
        foreach my $var (@new_vars) {

        	# exclude anything that is not a loop
                next if $self->{template}->query(name=>[@new_tlineage, $var]) eq 'VAR';

                # extract new loop name (following mechanics in HTML::Template::Plugin::Dot)
                my ($one, $the_rest) = split /\./, $var, 2;
                my $loopmap_name = 'this';
                $loopmap_name = $1 if $the_rest =~ s/\s*:\s*([_a-z]\w*)\s*$//;

                # Okay we have set up the structure but let's finish the current SQL
                # before populating this one
                my $new_loop = [];
                $current_row->{$the_rest} = $new_loop;
                my $new_tlineage = [@new_tlineage, $one];
                push @{$self->{work_to_be_done}}, sub {
                	push @$new_loop,  @{$self->$the_rest($new_dlineage, $new_tlineage)};
                };
        }
	return;
}


=head2 DESTROY

We have to define DESTROY, because an autoloaded version would be bad.

=cut

sub DESTROY {
}

=head1 AUTHOR

Nicholas Bamber, C<< <nicholas at periapt.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-cgi-application-plugin-pagelookup at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Application-Plugin-PageLookup>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head2 AUTOLOAD

AUTOLOAD is quite a fraught subject. There is probably no perfect solution. See http://www.perlmonks.org/?node_id=342804 for a sample of the issues.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CGI::Application::Plugin::PageLookup::Loop


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


=head1 COPYRIGHT & LICENSE

Copyright 2009 Nicholas Bamber.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of CGI::Application::Plugin::PageLookup::Loop
