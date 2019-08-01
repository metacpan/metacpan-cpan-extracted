package Calendar::Persian;

$Calendar::Persian::VERSION   = '0.42';
$Calendar::Persian::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

Calendar::Persian - Interface to Persian Calendar.

=head1 VERSION

Version 0.42

=cut

use 5.006;
use Data::Dumper;

use Date::Persian::Simple;
use Moo;
use namespace::autoclean;
with 'Calendar::Plugin::Renderer';

use overload q{""} => 'as_string', fallback => 1;

has year  => (is => 'rw', predicate => 1);
has month => (is => 'rw', predicate => 1);
has date  => (is => 'ro', default   => sub { Date::Persian::Simple->new });

sub BUILD {
    my ($self) = @_;

    $self->date->validate_year($self->year)   if $self->has_year;
    $self->date->validate_month($self->month) if $self->has_month;

    unless ($self->has_year && $self->has_month) {
        $self->year($self->date->year);
        $self->month($self->date->month);
    }
}

=head1 DESCRIPTION

The Persian  calendar  is  solar, with the particularity that the year defined by
two  successive,  apparent  passages    of  the  Sun  through the vernal (spring)
equinox.  It  is based  on precise astronomical observations, and moreover uses a
sophisticated intercalation system, which makes it more accurate than its younger
European  counterpart,the Gregorian calendar. It is currently used in Iran as the
official  calendar  of  the  country. The  starting  point of the current Iranian
calendar is  the  vernal equinox occurred on Friday March 22 of the year A.D. 622.
Persian Calendar for the month of Farvadin year 1390.

    +---------------------------------------------------------------------------------------------------------------+
    |                                             Farvardin   [1394 BE]                                             |
    +---------------+---------------+---------------+---------------+---------------+---------------+---------------+
    |    Yekshanbeh |     Doshanbeh |    Seshhanbeh | Chaharshanbeh |   Panjshanbeh |         Jomeh |       Shanbeh |
    +---------------+---------------+---------------+---------------+---------------+---------------+---------------+
    |                                                                                               |             1 |
    +---------------+---------------+---------------+---------------+---------------+---------------+---------------+
    |             2 |             3 |             4 |             5 |             6 |             7 |             8 |
    +---------------+---------------+---------------+---------------+---------------+---------------+---------------+
    |             9 |            10 |            11 |            12 |            13 |            14 |            15 |
    +---------------+---------------+---------------+---------------+---------------+---------------+---------------+
    |            16 |            17 |            18 |            19 |            20 |            21 |            22 |
    +---------------+---------------+---------------+---------------+---------------+---------------+---------------+
    |            23 |            24 |            25 |            26 |            27 |            28 |            29 |
    +---------------+---------------+---------------+---------------+---------------+---------------+---------------+
    |            30 |            31 |                                                                               |
    +---------------+---------------+---------------+---------------+---------------+---------------+---------------+

The package L<App::calendr> provides command line tool  C<calendr> to display the
supported calendars on the terminal.

=head1 SYNOPSIS

    use strict; use warnings;
    use Calendar::Persian;

    # prints current month calendar
    print Calendar::Persian->new, "\n";
    print Calendar::Persian->new->current, "\n";

    # prints persian month calendar for the first month of year 1394.
    print Calendar::Persian->new({ month => 1, year => 1394 }), "\n";

    # prints persian month calendar in which the given gregorian date falls in.
    print Calendar::Persian->new->from_gregorian(2015, 1, 14), "\n";

    # prints persian month calendar in which the given julian date falls in.
    print Calendar::Persian->new->from_julian(2457102.5), "\n";

    # prints current month persian calendar in SVG format.
    print Calendar::Persian->new->as_svg;

    # prints current month persian calendar in text format.
    print Calendar::Persian->new->as_text;

=head1 PERSIAN MONTHS

    +-------+-------------------------------------------------------------------+
    | Month | Persian Name                                                      |
    +-------+-------------------------------------------------------------------+
    |     1 | Farvardin                                                         |
    |     2 | Ordibehesht                                                       |
    |     3 | Xordad                                                            |
    |     4 | Tir                                                               |
    |     5 | Amordad                                                           |
    |     6 | Sahrivar                                                          |
    |     7 | Mehr                                                              |
    |     8 | Aban                                                              |
    |     9 | Azar                                                              |
    |    10 | Dey                                                               |
    |    11 | Bahman                                                            |
    |    12 | Esfand                                                            |
    +-------+-------------------------------------------------------------------+

=head1 PERSIAN DAYS

    +-------+---------------+---------------------------------------------------+
    | Index | Persian Name  | English Name                                      |
    +-------+---------------+---------------------------------------------------+
    |     0 | Yekshanbeh    | Sunday                                            |
    |     1 | Doshanbeh     | Monday                                            |
    |     2 | Seshhanbeh    | Tuesday                                           |
    |     3 | Chaharshanbeh | Wednesday                                         |
    |     4 | Panjshanbeh   | Thursday                                          |
    |     5 | Jomeh         | Friday                                            |
    |     6 | Shanbeh       | Saturday                                          |
    +-------+---------------+---------------------------------------------------+

=head1 CONSTRUCTOR

It expects month and year optionally.By default it gets current Persian month and
year.

=head1 METHODS

=head2 current()

Returns current month of the Persian calendar.

=cut

sub current {
    my ($self) = @_;

    return $self->as_text($self->date->month, $self->date->year);
}

=head2 from_gregorian($year, $month, $day)

Returns persian month calendar in which the given gregorian date falls in.

=cut

sub from_gregorian {
    my ($self, $year, $month, $day) = @_;

    return $self->from_julian($self->date->gregorian_to_julian($year, $month, $day));
}

=head2 from_julian($julian_date)

Returns persian month calendar in which the given julian date falls in.

=cut

sub from_julian {
    my ($self, $julian_date) = @_;

    my $date = $self->date->from_julian($julian_date);
    return $self->as_text($date->month, $date->year);
}

=head2 as_svg($month, $year)

Returns calendar for the given C<$month> and C<$year> rendered  in SVG format. If
C<$month> and C<$year> missing, it would return current calendar month.

=cut

sub as_svg {
    my ($self, $month, $year) = @_;

    ($month, $year) = $self->validate_params($month, $year);
    my $date = Date::Persian::Simple->new({ year => $year, month => $month, day => 1 });

    return $self->svg_calendar({
        start_index => $date->day_of_week,
        month_name  => $date->get_month_name,
        days        => $date->days_in_month_year($month, $year),
        year        => $year });
}

=head2 as_text($month, $year)

Returns  color  coded  Persian  calendar for the given C<$month> and C<$year>. If
C<$month> and C<$year> missing, it would return current calendar month.

=cut

sub as_text {
    my ($self, $month, $year) = @_;

    ($month, $year) = $self->validate_params($month, $year);
    my $date = Date::Persian::Simple->new({ year => $year, month => $month, day => 1 });

    return $self->text_calendar(
        {
            start_index => $date->day_of_week,
            month_name  => $date->get_month_name,
            days        => $date->days_in_month_year($month, $year),
            day_names   => $date->days,
            year        => $year
        });
}

sub as_string {
    my ($self) = @_;

    return $self->as_text($self->month, $self->year);
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Calendar-Persian>

=head1 SEE ALSO

=over 4

=item L<Calendar::Bahai>

=item L<Calendar::Hijri>

=item L<Calendar::Gregorian>

=item L<Calendar::Saka>

=back

=head1 BUGS

Please report any bugs or feature requests to C<bug-calendar-persian at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Calendar-Persian>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Calendar::Persian

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Calendar-Persian>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Calendar-Persian>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Calendar-Persian>

=item * Search CPAN

L<http://search.cpan.org/dist/Calendar-Persian/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011 - 2016 Mohammad S Anwar.

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

1; # End of Calendar::Persian
