package CGI::Application::Plugin::PageLookup::Href;

use warnings;
use strict;
use Carp;

=head1 NAME

CGI::Application::Plugin::PageLookup::Href - Manage internal URLs

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

In the template you might define a number of links as follows:

    <p>This page in other languages:</p>
    <ul>
		<li><a href="<TMPL_VAR NAME="href.translate('en')">">English</a></li>
		<li><a href="<TMPL_VAR NAME="href.translate('de')">">German</a></li>
		<li><a href="<TMPL_VAR NAME="href.translate('fr')">">French</a></li>
    </ul>

    <p>Some other pages that may be of interest</p>
    <ul>
		<li><a href="<TMPL_VAR NAME="href.refer(1)">">My first page</a></li>
		<li><a href="<TMPL_VAR NAME="href.refer(2)">">My second and more exciting page</a></li>
		<li><a href="<TMPL_VAR NAME="href.refer(3)">">My last will and testament</a></li>
    </ul>

You must register the "href" parameter as a CGI::Application::Plugin::PageLookup::Href object as follows:

    use CGI::Application;
    use CGI::Application::Plugin::PageLookup qw(:all);
    use CGI::Application::Plugin::PageLookup::Href;
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
                        # Register the 'href' parameter
                        href => 'CGI::Application::Plugin::PageLookup::Href',
		},


	);
    }


    ...

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

=head2 translate

This function takes the existing page id and translates it into another specified language. This way every
page can link to its cognate page in another languages.

=cut

sub translate {
	my $self = shift;
	my $language = shift;
        my $prefix = $self->{cgiapp}->pagelookup_prefix(%{$self->{config}});
        my $page_id = $self->{page_id};
        my $dbh = $self->{cgiapp}->dbh;

	# First one pass over the loop
        my $sql = "SELECT p1.pageId FROM ${prefix}pages p1, ${prefix}pages p2 WHERE p1.internalId = p2.internalId AND p1.lang = '$language' AND p2.pageId = '$page_id'";
        my $sth = $dbh->prepare($sql) || croak $dbh->errstr;
        $sth->execute || croak $dbh->errstr;
        my $hash_ref = $sth->fetchrow_hashref;
	if ($hash_ref) {
		$sth->finish;
		return $hash_ref->{pageId} if exists $hash_ref->{pageId};
		croak "could not translate $page_id to $language";
	}
	croak $sth->errstr if $sth->err;
	$sth->finish;
	croak "could not translate $page_id to $language";
}

=head2 refer

This function takes an internal id and translated that into the corresponding page but in the same language as the current page.
This way URLs can be search engine friendly irrespective of language.

=cut 

sub refer {
        my $self = shift;
        my $internalid = shift || 0;
        my $prefix = $self->{cgiapp}->pagelookup_prefix(%{$self->{config}});
        my $page_id = $self->{page_id};
        my $dbh = $self->{cgiapp}->dbh;

        # First one pass over the loop
        my $sql = "SELECT p1.pageId FROM ${prefix}pages p1, ${prefix}pages p2 WHERE p1.internalId = $internalid AND p1.lang = p2.lang AND p2.pageId = '$page_id'";
        my $sth = $dbh->prepare($sql) || croak $dbh->errstr;
        $sth->execute || croak $dbh->errstr;
        my $hash_ref = $sth->fetchrow_hashref;
        if ($hash_ref) {
                $sth->finish;
                return $hash_ref->{pageId} if exists $hash_ref->{pageId};
                croak "could not find $internalid page";
        }
        croak $sth->errstr if $sth->err;
        $sth->finish;
        croak "could not find $internalid page";
}

=head1 AUTHOR

Nicholas Bamber, C<< <nicholas at periapt.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-cgi-application-plugin-pagelookup at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Application-Plugin-PageLookup>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CGI::Application::Plugin::PageLookup::Href


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

1; # End of CGI::Application::Plugin::PageLookup::Href
