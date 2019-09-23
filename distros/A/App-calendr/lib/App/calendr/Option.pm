package App::calendr::Option;

$App::calendr::Option::VERSION   = '0.26';
$App::calendr::Option::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

App::calendr::Option - Option as Moo Role for App::calendr.

=head1 VERSION

Version 0.26

=cut

use 5.006;
use Data::Dumper;

use Moo::Role;
use namespace::autoclean;

use Types::Standard -all;
use MooX::Options;

has calendars => (is => 'rw');
option name   => (is => 'ro', order => 1, isa => Str, format => 's', doc => "Calendar name e.g. Bahai,Gregorian,Hebrew,Hijri,Julian,Persian,Saka.\n\tDefault is Gregorian.");
option month  => (is => 'ro', order => 2, isa => Str, format => 's', doc => 'Month number/name e.g. 1,2,3... or January,February...');
option year   => (is => 'ro', order => 3, isa => Int, format => 'i', doc => 'Year number (3/4 digits)');
option gdate  => (is => 'ro', order => 4, isa => Str, format => 's', doc => 'Gregorian date (YYYY-MM-DD)');
option jday   => (is => 'ro', order => 5, isa => Str, format => 'i', doc => 'Julian day');
option as_svg => (is => 'ro', order => 6, doc => 'Generate calendar in SVG format');
option list_month_names => (is => 'ro', order => 7, doc => 'List calendar month names');

=head1 DESCRIPTION

B<FOR INTERNAL USE ONLY>

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/App-calendr>

=head1 BUGS

Please  report any bugs or feature requests to C<bug-app-calendr at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-calendr>.
I will  be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::calendr::Option

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-calendr>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-calendr>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-calendr>

=item * Search CPAN

L<http://search.cpan.org/dist/App-calendr/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2015 - 2017 Mohammad S Anwar.

This program  is  free software; you can redistribute it and / or modify it under
the  terms  of the the Artistic License (2.0). You may obtain  a copy of the full
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

1; # End of App::calendr::Option
