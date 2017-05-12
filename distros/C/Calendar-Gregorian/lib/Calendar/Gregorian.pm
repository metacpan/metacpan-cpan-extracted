package Calendar::Gregorian;

$Calendar::Gregorian::VERSION   = '0.15';
$Calendar::Gregorian::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

Calendar::Gregorian - Interface to Gregorian Calendar.

=head1 VERSION

Version 0.15

=cut

use 5.006;
use Data::Dumper;

use Date::Gregorian::Simple;
use Moo;
use namespace::clean;
use overload q{""} => 'as_string', fallback => 1;

has year  => (is => 'rw', predicate => 1);
has month => (is => 'rw', predicate => 1);
has date  => (is => 'ro', default   => sub { Date::Gregorian::Simple->new });
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

Simple Gregorian Calendar interface.

    +-----------------------------------------------------------------------------------+
    |                                  March [2016 BE]                                  |
    +-----------+-----------+-----------+-----------+-----------+-----------+-----------+
    |    Sunday |    Monday |   Tuesday | Wednesday |  Thursday |    Friday |  Saturday |
    +-----------+-----------+-----------+-----------+-----------+-----------+-----------+
    |                       |         1 |         2 |         3 |         4 |         5 |
    +-----------+-----------+-----------+-----------+-----------+-----------+-----------+
    |         6 |         7 |         8 |         9 |        10 |        11 |        12 |
    +-----------+-----------+-----------+-----------+-----------+-----------+-----------+
    |        13 |        14 |        15 |        16 |        17 |        18 |        19 |
    +-----------+-----------+-----------+-----------+-----------+-----------+-----------+
    |        20 |        21 |        22 |        23 |        24 |        25 |        26 |
    +-----------+-----------+-----------+-----------+-----------+-----------+-----------+
    |        27 |        28 |        29 |        30 |        31 |                       |
    +-----------+-----------+-----------+-----------+-----------+-----------+-----------+

The package L<App::calendr> provides command line tool  C<calendr> to display the
supported calendars on the terminal.

=head1 SYNOPSIS

    use strict; use warnings;
    use Calendar::Gregorian;

    # prints current gregorian month calendar.
    print Calendar::Gregorian->new, "\n";
    print Calendar::Gregorian->new->current, "\n";

    # prints gregorian month calendar for the first month of year 2016.
    print Calendar::Gregorian->new({ month => 1, year => 2016 }), "\n";

    # prints gregorian month calendar in which the given julian date falls in.
    print Calendar::Gregorian->new->from_julian(2457102.5), "\n";

    # prints current month gregorian calendar in SVG format.
    print Calendar::Gregorian->new->as_svg;

    # prints current month gregorian calendar in text format.
    print Calendar::Gregorian->new->as_text;

=head1 GREGORIAN MONTHS

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

=head1 GREGORIAN DAYS

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

Returns current month of the Gregorian calendar.

=cut

sub current {
    my ($self) = @_;

    return $self->as_text($self->date->month, $self->date->year);
}

=head2 from_julian($julian_date)

Returns Gregorian month calendar in which the given julian date falls in.

=cut

sub from_julian {
    my ($self, $julian) = @_;

    my $date = $self->date->from_julian($julian);
    return $self->as_text($date->month, $date->year);
}

=head2 as_svg($month, $year)

Returns calendar for the given C<$month> and C<$year> rendered  in SVG format. If
C<$month> and C<$year> missing, it would return current calendar month.

=cut

sub as_svg {
    my ($self, $month, $year) = @_;

    ($month, $year) = $self->validate_params($month, $year);
    my $date = Date::Gregorian::Simple->new({ year => $year, month => $month, day => 1 });

    return $self->svg_calendar(
        {
            start_index => $date->day_of_week,
            month_name  => $date->months->[$month],
            days        => $date->days_in_month_year($month, $year),
            year        => $year
        });
}

=head2 as_text($month, $year)

Returns  color  coded Gregorian calendar for the given C<$month> and C<$year>. If
C<$month> and C<$year> missing, it would return current calendar month.

=cut

sub as_text {
    my ($self, $month, $year) = @_;

    ($month, $year) = $self->validate_params($month, $year);
    my $date = Date::Gregorian::Simple->new({ year => $year, month => $month, day => 1 });

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

L<https://github.com/manwar/Calendar-Gregorian>

=head1 SEE ALSO

=over 4

=item L<Calendar::Bahai>

=item L<Calendar::Hijri>

=item L<Calendar::Persian>

=item L<Calendar::Saka>

=back

=head1 BUGS

Please report any bugs / feature requests to C<bug-calendar-gregorian at rt.cpan.org>
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Calendar-Gregorian>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Calendar::Gregorian

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Calendar-Gregorian>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Calendar-Gregorian>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Calendar-Gregorian>

=item * Search CPAN

L<http://search.cpan.org/dist/Calendar-Gregorian/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2016 Mohammad S Anwar.

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

1; # End of Calendar::Gregorian
