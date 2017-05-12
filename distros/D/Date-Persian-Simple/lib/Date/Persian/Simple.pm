package Date::Persian::Simple;

$Date::Persian::Simple::VERSION   = '0.17';
$Date::Persian::Simple::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

Date::Persian::Simple - Represents Persian date.

=head1 VERSION

Version 0.17

=cut

use 5.006;
use Data::Dumper;
use Time::localtime;
use POSIX qw/floor ceil/;
use Date::Calc qw/Delta_Days/;

use Moo;
use namespace::clean;

use overload q{""} => 'as_string', fallback => 1;

=head1 DESCRIPTION

Represents the Persian date.

=cut

our $PERSIAN_MONTHS = [
    '',
    'Farvardin',  'Ordibehesht',  'Khordad',  'Tir',  'Mordad',  'Shahrivar',
    'Mehr'     ,  'Aban'       ,  'Azar'   ,  'Dey',  'Bahman',  'Esfand'
];

our $PERSIAN_DAYS = [
    'Yekshanbeh', 'Doshanbeh', 'Seshhanbeh', 'Chaharshanbeh',
    'Panjshanbeh', 'Jomeh', 'Shanbeh'
];

has persian_epoch  => (is => 'ro', default => sub { 1948320.5       });
has days           => (is => 'ro', default => sub { $PERSIAN_DAYS   });
has months         => (is => 'ro', default => sub { $PERSIAN_MONTHS });

has year  => (is => 'rw', predicate => 1);
has month => (is => 'rw', predicate => 1);
has day   => (is => 'rw', predicate => 1);

with 'Date::Utils';

sub BUILD {
    my ($self) = @_;

    $self->validate_year($self->year)   if $self->has_year;
    $self->validate_month($self->month) if $self->has_month;
    $self->validate_day($self->day)     if $self->has_day;

    unless ($self->has_year && $self->has_month && $self->has_day) {
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
    use Date::Persian::Simple;

    # prints today's Persian date.
    print Date::Persian::Simple->new, "\n";

    # prints the given Persian date.
    print Date::Persian::Simple->new({ year => 1394, month => 1, day => 1 })->as_string;

    # prints the equivalent Julian date.
    print $date->to_julian, "\n";

    # prints the equivalent Gregorian date.
    print sprintf("%04d-%02d-%02d", $date->to_gregorian), "\n";

    # prints the equivalent Persian date of the given Julian date
    print $date->from_julian(2455538.5), "\n";

    # prints the equivalent Persian date of the Gregorian date.
    print $date->from_gregorian(2015, 6, 25), "\n";

    # prints day of the week index (0 for Yekshanbeh, 1 for Doshanbehl and so on.
    print $date->day_of_week, "\n";

=head1 METHODS

=head2 to_julian()

Returns julian date equivalent of the Bahai date.

=cut

sub to_julian {
    my ($self) = @_;

    my $epbase = $self->year - (($self->year >= 0) ? 474 : 473);
    my $epyear = 474 + ($epbase % 2820);

    return $self->day + (($self->month <= 7)?(($self->month - 1) * 31):((($self->month - 1) * 30) + 6)) +
           floor((($epyear * 682) - 110) / 2816) +
           ($epyear - 1) * 365 +
           floor($epbase / 2820) * 1029983 +
           ($self->persian_epoch - 1);
}

=head2 from_julian($julian_date)

Returns Persian  date as an object of type L<Date::Persian::Simple> equivalent of
the Julian date C<$julian_date>.

=cut

sub from_julian {
    my ($self, $julian_date) = @_;

    $julian_date = floor($julian_date) + 0.5;
    my $depoch = $julian_date - Date::Persian::Simple->new({ year => 475, month => 1, day => 1 })->to_julian;
    my $cycle  = floor($depoch / 1029983);
    my $cyear  = $depoch % 1029983;

    my $ycycle;
    if ($cyear == 1029982) {
        $ycycle = 2820;
    }
    else {
        my $aux1 = floor($cyear / 366);
        my $aux2 = $cyear % 366;
        $ycycle = floor(((2134 * $aux1) + (2816 * $aux2) + 2815) / 1028522) + $aux1 + 1;
    }

    my $year = $ycycle + (2820 * $cycle) + 474;
    if ($year <= 0) {
        $year--;
    }

    my $a_persian = Date::Persian::Simple->new({ year => $year, month => 1, day => 1 });
    my $yday      = ($julian_date - $a_persian->to_julian) + 1;
    my $month     = ($yday <= 186) ? ceil($yday / 31) : ceil(($yday - 6) / 30);
    my $b_persian = Date::Persian::Simple->new({ year => $year, month => $month, day => 1 });
    my $day       = ($julian_date - $b_persian->to_julian) + 1;

    return Date::Persian::Simple->new({ year => $year, month => $month, day => $day });
}

=head2 to_gregorian()

Returns gregorian date as list (yyyy,mm,dd) equivalent of the Persian date.

=cut

sub to_gregorian {
    my ($self) = @_;

    return $self->julian_to_gregorian($self->to_julian);
}

=head2 from_gregorian($year, $month, $day)

Returns Persian  date as an object of type L<Date::Persian::Simple> equivalent of
the given Gregorian date C<$year>, C<$month> and C<$day>.

=cut

sub from_gregorian {
    my ($self, $year, $month, $day) = @_;

    $self->validate_date($year, $month, $day);
    my $julian = $self->gregorian_to_julian($year, $month, $day) +
                 (floor(0 + 60 * (0 + 60 * 0) + 0.5) / 86400.0);
    return $self->from_julian($julian);
}

=head2 day_of_week()

Returns day of the week, starting 0 for Yekshanbeh, 1 for Doshanbehl and so on.

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

=cut

sub day_of_week {
    my ($self) = @_;

    return $self->jwday($self->to_julian);
}

=head2 is_leap_year($year)

Returns 0 or 1 if the given Persian year C<$year> is a leap year or not.

=cut

sub is_leap_year {
    my ($self, $year) = @_;

    return (((((($year - (($year > 0) ? 474 : 473)) % 2820) + 474) + 38) * 682) % 2816) < 682;
}

sub days_in_month_year {
    my ($self, $month, $year) = @_;

    $self->validate_year($year);
    $self->validate_month($month);

    my @start = Date::Persian::Simple->new({
        year  => $year,
        month => $month,
        day   => 1 })->to_gregorian;

    if ($month == 12) {
        $year += 1;
        $month = 1;
    }
    else {
        $month += 1;
    }

    my @end = Date::Persian::Simple->new({
        year  => $year,
        month => $month,
        day   => 1 })->to_gregorian;

    return Delta_Days(@start, @end);
}

sub as_string {
    my ($self) = @_;

    return sprintf("%d, %s %d", $self->day, $self->get_month_name, $self->year);
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Date-Persian-Simple>

=head1 SEE ALSO

=over 4

=item L<Date::Bahai::Simple>

=item L<Date::Gregorian::Simple>

=item L<Date::Hijri::Simple>

=item L<Date::Saka::Simple>

=back

=head1 BUGS

Please report any bugs / feature requests to C<bug-date-persian-simple at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Date-Persian-Simple>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Date::Persian::Simple

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Date-Persian-Simple>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Date-Persian-Simple>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Date-Persian-Simple>

=item * Search CPAN

L<http://search.cpan.org/dist/Date-Persian-Simple/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2015 - 2016 Mohammad S Anwar.

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

1; # End of Date::Persian::Simple
