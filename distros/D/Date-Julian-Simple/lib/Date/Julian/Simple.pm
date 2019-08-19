package Date::Julian::Simple;

$Date::Julian::Simple::VERSION   = '0.10';
$Date::Julian::Simple::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

Date::Julian::Simple - Represents Julian date.

=head1 VERSION

Version 0.10

=cut

use 5.006;
use Data::Dumper;
use POSIX qw/floor/;
use Time::localtime;
use Date::Exception::InvalidDay;

use Moo;
use namespace::autoclean;

use overload q{""} => 'as_string', fallback => 1;

=head1 DESCRIPTION

Represents the Julian date.

=cut

our $JULIAN_MONTHS = [
    undef,
    qw(January February March     April   May      June
       July    August   September October November December)
];

our $JULIAN_DAYS = [
    qw(Sunday Monday Tuesday Wednesday Thursday Friday Saturday)
];

our $JULIAN_MONTH_DAYS = [
    qw(31 28 31 30 31 30
       31 31 30 31 30 31)
];

has julian_epoch => (is => 'ro', default => sub { 1721423.5      });
has days         => (is => 'ro', default => sub { $JULIAN_DAYS   });
has months       => (is => 'ro', default => sub { $JULIAN_MONTHS });

has year  => (is => 'rw', predicate => 1);
has month => (is => 'rw', predicate => 1);
has day   => (is => 'rw', predicate => 1);

with 'Date::Utils';

sub BUILD {
    my ($self) = @_;

    if ($self->has_year && $self->has_month && $self->has_day) {
        $self->validate_year($self->year);
        $self->validate_month($self->month);
        if ($self->is_leap_year($self->year)) {
            my $day    = $self->day;
            my @caller = caller(0);
            @caller    = caller(2) if $caller[3] eq '(eval)';

            Date::Exception::InvalidDay->throw({
                method      => __PACKAGE__."::validate_day",
                message     => sprintf("ERROR: Invalid day [%s].", defined($day)?($day):('')),
                filename    => $caller[1],
                line_number => $caller[2] })
                unless (defined($day) && ($day =~ /^\d+$/) && ($day >= 1) && ($day <= 29));
        }
        else {
            $self->validate_day($self->day);
        }
    }
    else {
        my $today = localtime;
        my $year  = $today->year + 1900;
        my $month = $today->mon + 1;
        my $day   = $today->mday;
        my $date  = $self->from_gregorian($year, $month, $day);
        $self->year($date->year);
        $self->month($date->month);
        $self->day($date->day);
    }
}

=head1 SYNOPSIS

    use strict; use warnings;
    use Date::Julian::Simple;

    # prints today's Julian date.
    print Date::Julian::Simple->new, "\n";

=head1 METHODS

=head2 to_julian()

Returns julian day equivalent of the Julian date.

=cut

sub to_julian {
    my ($self, $year, $month, $day) = @_;

    $day    = $self->day   unless defined $day;
    $month  = $self->month unless defined $month;
    $year   = $self->year  unless defined $year;

    # Adjust negative common era years to the zero-based notation we use.
    if ($year < 1) {
        $year++;
    }

    # Algorithm as given in Meeus, Astronomical Algorithms, Chapter 7, page 61.
    if ($month <= 2) {
        $year--;
        $month += 12;
    }

    return ((floor((365.25 * ($year + 4716))) + floor((30.6001 * ($month + 1))) + $day) - 1524.5);
}

=head2 from_julian($julian_day)

Returns Julian date as an object of type L<Date::Julian::Simple> equivalent of the
C<$julian_day>.

=cut

sub from_julian {
    my ($self, $julian_day) = @_;

    $julian_day += 0.5;
    my $a = floor($julian_day);
    my $b = $a + 1524;
    my $c = floor(($b - 122.1) / 365.25);
    my $d = floor(365.25 * $c);
    my $e = floor(($b - $d) / 30.6001);

    my $month = floor(($e < 14) ? ($e - 1) : ($e - 13));
    my $year  = floor(($month > 2) ? ($c - 4716) : ($c - 4715));
    my $day   = $b - $d - floor(30.6001 * $e);

    # If year is less than 1, subtract one to convert from
    # a zero based date system to the common era system in
    # which the year -1 (1 B.C.E) is followed by year 1 (1 C.E)
    if ($year < 1) {
        $year--;
    }

    return Date::Julian::Simple->new({ year => $year, month => $month, day => $day });
}

=head2 to_gregorian()

Returns Gregorian date as list (yyyy,mm,dd) equivalent of the Julian date.

=cut

sub to_gregorian {
    my ($self) = @_;

    return $self->julian_to_gregorian($self->to_julian);
}

=head2 from_gregorian($year, $month, $day)

Returns Julian date as an object of type L<Date::Julian::Simple> equivalent of the
given Gregorian date C<$year>, C<$month> and C<$day>.

=cut

sub from_gregorian {
    my ($self, $year, $month, $day) = @_;

    $self->validate_date($year, $month, $day);
    return $self->from_julian($self->gregorian_to_julian($year, $month, $day));
}

=head2 day_of_week()

Returns day of the week, starting 0 for Sunday, 1 for Monday and so on.

    +-------+-------------------------------------------------------------------+
    | Index | English Name                                                      |
    +-------+-------------------------------------------------------------------+
    |   0   | Sunday                                                            |
    |   1   | Monday                                                            |
    |   2   | Tuesday                                                           |
    |   3   | Wednesday                                                         |
    |   4   | Thursday                                                          |
    |   5   | Friday                                                            |
    |   6   | Saturday                                                          |
    +-------+-------------------------------------------------------------------+

=cut

sub day_of_week {
    my ($self) = @_;

    return $self->jwday($self->to_julian);
}

=head2 is_leap_year($year)

Returns 0 or 1 if the given Julian year C<$year> is a leap year or not.

=cut

sub is_leap_year {
    my ($self, $year) = @_;

    return (($year % 4) == (($year > 0) ? 0 : 3));
}

sub days_in_year {
    my ($self, $year) = @_;

    ($self->is_leap_year($year))
    ?
    (return 366)
    :
    (return 365);
}

sub days_in_month_year {
    my ($self, $month, $year) = @_;

    if ($self->is_leap_year($year)) {
        return 29 if ($month == 2);
    }

    return $JULIAN_MONTH_DAYS->[$month-1];
}

sub as_string {
    my ($self) = @_;

    return sprintf("%d, %s %d", $self->day, $self->get_month_name, $self->year);
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Date-Julian-Simple>

=head1 SEE ALSO

=over 4

=item L<Date::Bahai::Simple>

=item L<Date::Gregorian::Simple>

=item L<Date::Hebrew::Simple>

=item L<Date::Hijri::Simple>

=item L<Date::Persian::Simple>

=item L<Date::Saka::Simple>

=back

=head1 BUGS

Please report any bugs / feature requests to C<bug-date-julian-simple at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Date-Julian-Simple>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Date::Julian::Simple

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Date-Julian-Simple>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Date-Julian-Simple>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Date-Julian-Simple>

=item * Search CPAN

L<http://search.cpan.org/dist/Date-Julian-Simple/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2017 Mohammad S Anwar.

This program  is  free software; you can redistribute it and / or modify it under
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

1; # End of Date::Julian::Simple
