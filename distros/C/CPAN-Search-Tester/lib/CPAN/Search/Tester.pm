package CPAN::Search::Tester;

$CPAN::Search::Tester::VERSION   = '0.04';
$CPAN::Search::Tester::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

CPAN::Search::Tester - Interface to search CPAN module tester.

=head1 VERSION

Version 0.04

=cut

use 5.006;
use Data::Dumper;
use WWW::Mechanize;

use Moo;
use namespace::clean;

my $URL = 'http://stats.cpantesters.org/cpanmail.html';

=head1 DESCRIPTION

This module is a very thin wrapper for "Find A Tester" feature provided by cpantesters.org.

=cut

has 'browser' => (is => 'ro', default => sub { return new WWW::Mechanize(autocheck => 1); });

=head1 METHODS

=head2 search()

Search a CPAN Tester  for the given ID or GUID. Please use with care and do *NOT*
generate spam attacks on testers.
Currently CPAN Testers reports are publicly available via   CPAN Testers  Reports
site,  using  a  unique  ID  used  by  'cpanstats' database or a GUID used by the
Metabase data store. Either of these  can  be used to perform a lookup. The ID or
GUID is displayed via the report display on the CPAN Testers Reports site.

For example,

    http://www.cpantesters.org/cpan/report/7019327
    http://www.cpantesters.org/cpan/report/07019335-b19f-3f77-b713-d32bba55d77f

Here 7019327 is the ID and 07019335-b19f-3f77-b713-d32bba55d77f is the GUID.

    use strict; use warnings;
    use CPAN::Search::Tester;

    print CPAN::Search::Tester->new->search('7019327') . "\n";
    print CPAN::Search::Tester->new->search('07019335-b19f-3f77-b713-d32bba55d77f') . "\n";

=cut

sub search {
    my ($self, $param) = @_;

    die "ERROR: Invalid ID or GUID received."
        unless (defined $param
                &&
                (($param =~ /^\d+$/)
                 ||
                 ($param =~ /^[a-z0-9]+\-[a-z0-9]+\-[a-z0-9]+\-[a-z0-9]+\-[a-z0-9]+$/)));

    $self->{browser}->get($URL);
    $self->{browser}->form_number(1);
    $self->{browser}->field('id', $param);
    $self->{browser}->submit();
    my $content = $self->{browser}->content;
    return "No data found.\n" unless defined $content;

    ($content =~ /\<tr\>\<th\>Address\:\<\/th\>\<td\>(.*)\<\/td\>\<\/tr\>/)
    ?
    (return $1)
    :
    (return "No data found.\n");
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/Manwar/CPAN-Search-Tester>

=head1 BUGS

Please report any bugs  or  feature requests to C<bug-cpan-search-tester at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CPAN-Search-Tester>.
I  will be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CPAN::Search::Tester

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CPAN-Search-Tester>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CPAN-Search-Tester>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CPAN-Search-Tester>

=item * Search CPAN

L<http://search.cpan.org/dist/CPAN-Search-Tester/>

=back

=head1 ACKNOWLEDGEMENT

This wouldn't have been possible without the service of cpantesters.org.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011 - 2015 Mohammad S Anwar.

This  program  is  free software; you can redistribute it and/or modify it under
the  terms  of the the Artistic License (2.0). You may obtain a copy of the full
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

1; # End of CPAN::Search::Tester
