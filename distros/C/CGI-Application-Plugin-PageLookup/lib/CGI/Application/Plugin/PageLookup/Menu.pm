package CGI::Application::Plugin::PageLookup::Menu;

use warnings;
use strict;
use Carp;

=head1 NAME

CGI::Application::Plugin::PageLookup::Menu - Support for consistent menus across a multilingual website

=head1 VERSION

Version 1.8

=cut

our $VERSION = '1.8';

=head1 DESCRIPTION

The L<CGI::Application::Plugin::PageLookup::Loop> module can be used to create a database driven menu 
and similarly data driven site map page. However the Loop module can only translate into other languages
if the URLs are kept the same apart from a language identifier. This means that the website
would have  search engine friendly in only one language. The L<CGI::Application::Plugin::PageLookup::Href> module
could be used to create a static menu and site map that is automatically translated into various languages
with search engine friendly URLs. However they cannot be combined as you cannot pass through first the Loop and then the Href.
What this module offers is a specialised variant of the Loop smart object that does combine these features.
This module depends on L<CGI::Application::Plugin::PageLookup>.

=head1 SYNOPSIS

In the template you might define a menu as follows (with some CSS and javascript to make it look nice):

    <ul>
    <TMPL_LOOP NAME="menu.structure('title')">
	<li>
		<a href="<TMPL_VAR NAME="this.pageid">"><TMPL_VAR NAME="this.title"></a>
		<TMPL_IF NAME="this.structure('title')">
		<ul>
		<TMPL_LOOP NAME="this.structure('title')">
			<li>
				<a href="/<TMPL_VAR NAME="this.pageid">"><TMPL_VAR NAME="this.title"></a>
				<TMPL_IF NAME="this.structure('title')">
				<ul>
				<TMPL_LOOP NAME="this.structure('title')">
				<li>
					<a href="/<TMPL_VAR NAME="this.pageid">"><TMPL_VAR NAME="this.title"></a>
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
You must register the "menu" parameter as a CGI::Application::Plugin::PageLookup::Menu object as follows:

    use CGI::Application;
    use CGI::Application::Plugin::PageLookup qw(:all);
    use CGI::Application::Plugin::PageLookup::Menu;
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
                        menu => 'CGI::Application::Plugin::PageLookup::Menu',
		},

	);
    }

=head1 NOTES

=over

=item

This module requires no extra table but it does depend on the 'lineage' and 'rank' columns in the
cgiapp_strcuture table. These columns work the same way as they do in the cgiapp_loops table.
That is the items are ordered according to the rank column and the lineage column is a comma separated
list indicating the ranks of the parent menu items.

=item 

The module can be used to get data either for menus or human readable sitemaps.

=item 

One value that will always be returned is the 'pageId' column which can be translated into a URL as dictated
by the website policy. However due to capitalisation issues, you must either call it 'pageid' in the template 
or specify 'case_sensitive => 1' somewhere in the template infrastructure.

=item

Use of this module for creating menus and sitemaps rather than the Loop module also means you may
not need to set 'globalvars => 1' in the template infrastructure.

=item

You can specify additional columns from the cgiapp_pages table to be included the parameters. These could include 
a title, may be some javascript etc. These columns are not specified in the core database spec.

=item

In the synopsis all parameters below the headline structure call were shown as being "this dot something". In accordance
with L<HTML::Template::Plugin::Dot> this can be changed by using ":" notation. This has not actually been tested yet.
Nor have we tried testing varying the arguments at different levels of the menu structure. 

=back

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

=head2 structure

This function is specified in the template where additional columns are specified. 
If no arguments are specified only the 'pageId' column is returned for each menu item.
Additional arguments should be specified either as a single comma separated string (deprecated)
or as multiple arguments.

=cut

sub structure {
	my $self = shift;
	my @params = @_;
	my $template = "$self->{name}.structure('";
	if (scalar(@params) == 1) {
		# legacy case
		$template .= "$params[0]')";
		@params = split /,/, $params[0];
	}
	else {
		$template .= join "','", @params;
		$template .= "')";
	}
	return $self->__structure(\@params, "", [$template]);
}

sub __structure {
	my $self = shift;
	my @params = @{shift || []};

        # $dlineage are the "breadcrumbs" required to navigate our way through the database
	# and corresponds to the 'lineage' column on the cgiapp_structure table.
	my $dlineage = shift;
	croak "database lineage missing" unless defined $dlineage;

	# $tlineage are the "breadcrumbs" required to navigate our way through the HTML::Template structure.
	# It corresponds to the ARRAY ref used in $template->query(loop=> [....]).
	my $tlineage = shift;
	croak "template lineage missing" unless defined $tlineage;

        my $prefix = $self->{cgiapp}->pagelookup_prefix(%{$self->{config}});
        my $page_id = $self->{page_id};
        my $dbh = $self->{cgiapp}->dbh;

	# This is what we actually want to return
	my @loop;

	$self->{work_to_be_done} = [] unless exists $self->{work_to_be_done};

	# generate SQL: get menu structure but optionally pull extra columns from cgiapp_pages
	my @params_sql;
	foreach my $p (@params) {
		push @params_sql, ", p2.$p";
	}
	my $param_sql = join "", @params_sql;
        my $sql = "SELECT s.rank, p2.pageId $param_sql FROM ${prefix}structure s, ${prefix}pages p2, ${prefix}pages p1 WHERE p1.lang = p2.lang AND s.internalId = p2.internalId AND p1.pageId = '$page_id' AND s.lineage = '$dlineage' AND s.priority IS NOT NULL ORDER BY s.rank ASC";

	# First one pass over the loop
        my $sth = $dbh->prepare($sql) || croak $dbh->errstr;
        $sth->execute || croak $dbh->errstr;
        while(my $hash_ref = $sth->fetchrow_hashref) {

		my $current_rank = delete $hash_ref->{rank};

		# Now we need to add in any loop variables
		$self->__populate_lower_loops($dlineage, $tlineage, $hash_ref, $current_rank, \@params);

		# We are finally ready to get this structure out of the door
		push @loop, $hash_ref;

	}
        croak $sth->errstr if $sth->err;
        $sth->finish;

	# Now go back over the remaining work
	while(@{$self->{work_to_be_done}}) {
		my $work = shift @{$self->{work_to_be_done}};
		&$work();
	}

        return \@loop;
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
	my $param = shift;
	my $comma = ',';
        my $new_dlineage = join $comma , (split /,/, $dlineage), $current_rank;
        my @new_tlineage = @$tlineage;
        my @new_vars = $self->{template}->query(loop=>\@new_tlineage);
        foreach my $var (@new_vars) {

        	# exclude anything that is not a loop
                next if $self->{template}->query(name=>[@new_tlineage, $var]) eq 'VAR';

                # extract new loop name (following mechanics in HTML::Template::Plugin::Dot)
                my ($one, $the_rest) = split /\./, $var, 2;
                my $loopmap_name = 'this';
                $loopmap_name = $1 if $the_rest =~ s/\s*:\s*([_a-z]\w*)\s*$//;
		croak "can only handle structure: $the_rest" unless $the_rest =~ /^structure/;

                # Okay we have set up the structure but let's finish the current SQL
                # before populating this one
                my $new_loop = [];
                $current_row->{structure} = $new_loop;
                my $new_tlineage = [@new_tlineage, $var];
                push @{$self->{work_to_be_done}}, sub {
                	push @$new_loop,  @{$self->__structure($param, $new_dlineage, $new_tlineage)};
                };
        }
	return;
}

=head2 slice

This function is a variant of the C<< structure >> function, which allows one to specify a part of the menu.
The first argument is the database lineage which is a string consisting of comma separated numbers. The other arguments 
are as described under C<< structure >>. The slice function can only be used in the topmost TMPL_LOOP of a template.

=cut

sub slice {
        my $self = shift;
        my $dlineage = shift;
        my $template = "$self->{name}.slice('$dlineage','";
	my @params = @_;
        if (scalar(@params) == 1) {
                # legacy case
                $template .= "$params[0]')";
                @params = split /,/, $params[0];
        }
        else {
                $template .= join "','", @params;
                $template .= "')";
        }
        return $self->__structure(\@params, $dlineage, [$template]);
}

=head1 AUTHOR

Nicholas Bamber, C<< <nicholas at periapt.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-cgi-application-plugin-pagelookup at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Application-Plugin-PageLookup>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CGI::Application::Plugin::PageLookup::Menu


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

1; # End of CGI::Application::Plugin::PageLookup::Menu
