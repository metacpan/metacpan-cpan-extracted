package Calendar::Julian;

$Calendar::Julian::VERSION   = '0.08';
$Calendar::Julian::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

Calendar::Julian - Interface to Julian Calendar.

=head1 VERSION

Version 0.08

=cut

use 5.006;
use Data::Dumper;

use Date::Julian::Simple;
use Moo;
use namespace::autoclean;
use overload q{""} => 'as_string', fallback => 1;

has year  => (is => 'rw', predicate => 1);
has month => (is => 'rw', predicate => 1);
has date  => (is => 'ro', default   => sub { Date::Julian::Simple->new });
with 'Calendar::Plugin::Renderer';

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

The Julian  calendar  was  proclaimed  by Julius Cesar  in  46 B.C. and underwent
several modifications before reaching its final form in 8 C.E.The Julian calendar
differs  from  the Gregorian only in the determination of leap years, lacking the
correction  for  years divisible by 100 and 400 in the Gregorian calendar. In the
Julian calendar, any  positive year  is  a leap year if divisible by 4. (Negative
years are leap years if the absolute value divided by 4 yields a remainder of 1.)
Days are considered to begin at midnight.

In the Julian calendar the average year has a  length of 365.25 days. compared to
the actual solar tropical year of 365.24219878 days.The calendar thus accumulates
one  day  of error with respect to the solar year every 128 years. Being a purely
solar  calendar, no  attempt  is  made to  synchronise the start of months to the
phases of the Moon.

    +-----------------------------------------------------------------------------------+
    |                                  July [2017 BE]                                   |
    +-----------+-----------+-----------+-----------+-----------+-----------+-----------+
    |    Sunday |    Monday |   Tuesday | Wednesday |  Thursday |    Friday |  Saturday |
    +-----------+-----------+-----------+-----------+-----------+-----------+-----------+
    |                                                           |         1 |         2 |
    +-----------+-----------+-----------+-----------+-----------+-----------+-----------+
    |         3 |         4 |         5 |         6 |         7 |         8 |         9 |
    +-----------+-----------+-----------+-----------+-----------+-----------+-----------+
    |        10 |        11 |        12 |        13 |        14 |        15 |        16 |
    +-----------+-----------+-----------+-----------+-----------+-----------+-----------+
    |        17 |        18 |        19 |        20 |        21 |        22 |        23 |
    +-----------+-----------+-----------+-----------+-----------+-----------+-----------+
    |        24 |        25 |        26 |        27 |        28 |        29 |        30 |
    +-----------+-----------+-----------+-----------+-----------+-----------+-----------+
    |        31 |                                                                       |
    +-----------+-----------+-----------+-----------+-----------+-----------+-----------+

The package L<App::calendr> provides command line tool  C<calendr> to display the
supported calendars on the terminal. Support for  C<Julian Calendar>  is provided
by L<App::calendr> v0.17 or above.

=head1 SYNOPSIS

    use strict; use warnings;
    use Calendar::Julian;

    # prints current julian month calendar.
    print Calendar::Julian->new, "\n";
    print Calendar::Julian->new->current, "\n";

    # prints julian month calendar in which the given julian day falls in.
    print Calendar::Julian->new->from_julian(2457102.5), "\n";

    # prints current month julian calendar in SVG format.
    print Calendar::Julian->new->as_svg;

    # prints current month julian calendar in text format.
    print Calendar::Julian->new->as_text;

=head1 JULIAN MONTHS

    +--------+------------------------------------------------------------------+
    | Number | Name                                                             |
    +--------+------------------------------------------------------------------+
    |   1    | January                                                          |
    |   2    | February                                                         |
    |   3    | March                                                            |
    |   4    | April                                                            |
    |   5    | May                                                              |
    |   6    | June                                                             |
    |   7    | July                                                             |
    |   8    | August                                                           |
    |   9    | September                                                        |
    |  10    | October                                                          |
    |  11    | November                                                         |
    |  12    | December                                                         |
    +--------+------------------------------------------------------------------+

=head1 JULIAN DAYS

    +---------------------------------------------------------------------------+
    | English Name                                                              |
    +---------------------------------------------------------------------------+
    | Sunday                                                                    |
    | Monday                                                                    |
    | Tuesday                                                                   |
    | Wednesday                                                                 |
    | Thursday                                                                  |
    | Friday                                                                    |
    | Saturday                                                                  |
    +---------------------------------------------------------------------------+

=head1 METHODS

=head2 current()

Returns current month of the Julian calendar.

=cut

sub current {
    my ($self) = @_;

    return $self->as_text($self->date->month, $self->date->year);
}

=head2 from_julian($julian_day)

Returns Julian month calendar in which the given C<$julian_day> falls in.

=cut

sub from_julian {
    my ($self, $julian_day) = @_;

    my $date = $self->date->from_julian($julian_day);
    return $self->as_text($date->month, $date->year);
}

=head2 as_svg($month, $year)

Returns calendar for the given C<$month> and C<$year> rendered  in SVG format. If
C<$month> and C<$year> missing, it would return current calendar month.

=cut

sub as_svg {
    my ($self, $month, $year) = @_;

    ($month, $year) = $self->validate_params($month, $year);
    my $date = Date::Julian::Simple->new({ year => $year, month => $month, day => 1 });

    return $self->svg_calendar(
        {
            start_index => $date->day_of_week,
            month_name  => $date->months->[$month],
            days        => $date->days_in_month_year($month, $year),
            year        => $year
        });
}

=head2 as_text($month, $year)

Returns  color  coded Julian calendar for the  given  C<$month>  and C<$year>. If
C<$month> and C<$year> missing, it would return current calendar month.

=cut

sub as_text {
    my ($self, $month, $year) = @_;

    ($month, $year) = $self->validate_params($month, $year);
    my $date = Date::Julian::Simple->new({ year => $year, month => $month, day => 1 });

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

L<https://github.com/manwar/Calendar-Julian>

=head1 SEE ALSO

=over 4

=item L<Calendar::Bahai>

=item L<Calendar::Hebrew>

=item L<Calendar::Hijri>

=item L<Calendar::Gregorian>

=item L<Calendar::Persian>

=item L<Calendar::Saka>

=back

=head1 BUGS

Please report any bugs / feature requests to C<bug-calendar-julian at rt.cpan.org>
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Calendar-Julian>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Calendar::Julian

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Calendar-Julian>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Calendar-Julian>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Calendar-Julian>

=item * Search CPAN

L<http://search.cpan.org/dist/Calendar-Julian/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2017 Mohammad S Anwar.

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

1; # End of Calendar::Julian
