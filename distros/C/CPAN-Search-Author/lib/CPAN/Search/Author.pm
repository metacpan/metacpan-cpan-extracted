package CPAN::Search::Author;

$CPAN::Search::Author::VERSION   = '0.04';
$CPAN::Search::Author::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

CPAN::Search::Author - Interface to search CPAN module author.

=head1 VERSION

Version 0.04

=cut

use 5.006;
use strict; use warnings;
use overload q("") => \&as_string, fallback => 1;

use Data::Dumper;
use HTTP::Request;
use LWP::UserAgent;
use HTML::Entities qw/decode_entities/;

our $DEBUG   = 0;

=head1 DESCRIPTION

CPAN::Search::Author is  an  attempt to provide  programmatical interface to CPAN
Search engine. CPAN Search is a search engine for the distributions,modules, docs,
and ID's on CPAN.  It was conceived  and  built by  Graham Barr  as a way to make
things easier to navigate.  Originally named TUCS [ The Ultimate CPAN Search ] it
was later named CPAN Search or Search DOT CPAN.

=cut

sub new {
    my $class = shift;
    my $self  = { _browser => LWP::UserAgent->new() };

    bless $self, $class;
    return $self;
}

=head1 METHODS

=head2 by_id()

This method  accepts CPAN ID exactly as provided by CPAN. It does realtime search
on  CPAN site and  fetch  the author name for the given CPAN ID. However it would
croak if it can't access the CPAN site / unable to get any response for the given
CPAN ID.

    use strict; use warnings;
    use CPAN::Search::Author;

    my $result = CPAN::Search::Author->new->by_id('MANWAR');

=cut

sub by_id
{
    my $self     = shift;
    my $id       = shift;

    my $browser  = $self->{_browser};
    $browser->env_proxy;
    my $request  = HTTP::Request->new(POST=>qq[http://search.cpan.org/search?query=$id&mode=author]);
    my $response = $browser->request($request);
    print {*STDOUT} "Search By Id [$id] Status: " . $response->status_line . "\n" if $DEBUG;
    die("ERROR: Couldn't connect to search.cpan.org.\n") unless $response->is_success;

    my $contents = $response->content;
    my @contents = split(/\n/,$contents);
    foreach (@contents) {
        chomp;
        s/^\s+//g;
        s/\s+$//g;
        if (/\<p\>\<h2 class\=sr\>\<a href\=\"\/\~(.*)\/\"\><b>(.*)<\/b\>/) {
            if (uc($id) eq uc($1)) {
                $self->{result} = decode_entities($2);
                return $self->{result};
            }
        }
    }

    $self->{result} = undef;
    return;
}

=head2 where_id_starts_with()

This method accepts an alphabet (A-Z) and get the list of authors that start with
the  given alphabet  from  CPAN site realtime. However it would croak if it can't
access the CPAN site or unable to get any response for the given CPAN ID.

    use strict; use warnings;
    use CPAN::Search::Author;

    my $result = CPAN::Search::Author->new->where_id_starts_with('M');

=cut

sub where_id_starts_with {
    my ($self, $letter) = @_;

    die("ERROR: Invalid letter [$letter].\n") unless ($letter =~ /[A-Z]/i);

    my $browser  = $self->{_browser};
    $browser->env_proxy;
    my $request  = HTTP::Request->new(POST=>qq[http://search.cpan.org/author/?$letter]);
    my $response = $browser->request($request);
    print {*STDOUT} "Search Id Starts With [$letter] Status: " . $response->status_line . "\n" if $DEBUG;
    die("ERROR: Couldn't connect to search.cpan.org.\n") unless $response->is_success;

    my $contents = $response->content;
    my @contents = split(/\n/,$contents);

    my @authors;
    foreach (@contents) {
        chomp;
        s/^\s+//g;
        s/\s+$//g;
        if (/<a href\=\"\/\~(.*)\/\"/) {
            push @authors, $1;
        }
    }

    return @authors;
}

=head2 where_name_contains()

This method accepts  a search string and look for the string in the author's name
of all the CPAN modules realtime and returns the a reference to a hash containing
id,name pair  containing  the search  string. It  croaks if  unable to access the
search.cpan.org.

    use strict; use warnings;
    use CPAN::Search::Author;

    my $result = CPAN::Search::Author->new-search->where_name_contains('MAN');

=cut

sub where_name_contains {
    my ($self, $query) = @_;

    my $browser  = $self->{_browser};
    $browser->env_proxy;
    my $request  = HTTP::Request->new(POST=>qq[http://search.cpan.org/search?query=$query&mode=author]);
    my $response = $browser->request($request);
    print {*STDOUT} "Search By Name Contains [$query] Status: " . $response->status_line . "\n" if $DEBUG;
    die("ERROR: Couldn't connect to search.cpan.org.\n") unless $response->is_success;

    my $contents = $response->content;
    my @contents = split(/\n/,$contents);

    my $authors;
    foreach (@contents) {
        chomp;
        s/^\s+//g;
        s/\s+$//g;
        $authors->{$1} = decode_entities($2)
            if (/\<p\>\<h2 class\=sr\>\<a href\=\"\/\~(.*)\/\"\><b>(.*)<\/b\>/);
    }

    $self->{result} = $authors;
    return $authors;
}

=head2 as_string()

Return the last search result in human readable format.

    use strict; use warnings;
    use CPAN::Search::Author;

    my $result = CPAN::Search::Author->new->where_name_contains('MAN');

=cut

sub as_string {
    my ($self) = @_;
    return $self->{result} unless ref($self->{result});

    my $string;
    foreach (keys %{$self->{result}}) {
        $string .= sprintf("%s: %s\n", $_, $self->{result}->{$_});
    }
    return $string;
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/Manwar/CPAN-Search-Author>

=head1 BUGS

Please   report  any bugs or feature requests to C<bug-cpan-search-author at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CPAN-Search-Author>.
I   will  be  notified,  and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CPAN::Search::Author

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CPAN::Search::Author>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CPAN-Search-Author>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CPAN-Search-Author>

=item * Search CPAN

L<http://search.cpan.org/dist/CPAN-Search-Author/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011 - 2015 Mohammad S Anwar.

This  program  is  free software; you can redistribute it and/or  modify it under
the  terms  of the the Artistic License (2.0). You may obtain a  copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of CPAN::Search::Author
