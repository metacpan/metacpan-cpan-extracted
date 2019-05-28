package Date::Utils;

$Date::Utils::VERSION   = '0.26';
$Date::Utils::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

Date::Utils - Common date functions as Moo Role.

=head1 VERSION

Version 0.26

=cut

use 5.006;
use Data::Dumper;
use POSIX qw/floor/;
use Term::ANSIColor::Markup;

use Moo::Role;
use namespace::autoclean;

use Date::Exception::InvalidDay;
use Date::Exception::InvalidMonth;
use Date::Exception::InvalidYear;

requires qw(months days);

has gregorian_epoch => (is => 'ro', default => sub { 1721425.5 });

=head1 DESCRIPTION

Common date functions as Moo Role. It is being used by the following distributions:

=over 4

=item * L<Date::Bahai::Simple>

=item * L<Date::Gregorian::Simple>

=item * L<Date::Hebrew::Simple>

=item * L<Date::Hijri::Simple>

=item * L<Date::Julian::Simple>

=item * L<Date::Persian::Simple>

=item * L<Date::Saka::Simple>

=back

=head1 METHODS

=head2 jwday($julian_date)

Returns day of week for the given Julian date C<$julian_date>, with 0 for Sunday.

=cut

sub jwday {
    my ($self, $julian_date) = @_;

    return floor($julian_date + 1.5) % 7;
}

=head2 gregorian_to_julian($year, $month, $day)

Returns Julian date equivalent of the given Gregorian date.

=cut

sub gregorian_to_julian {
    my ($self, $year, $month, $day) = @_;

    return ($self->gregorian_epoch - 1) +
           (365 * ($year - 1)) +
           floor(($year - 1) / 4) +
           (-floor(($year - 1) / 100)) +
           floor(($year - 1) / 400) +
           floor((((367 * $month) - 362) / 12) +
           (($month <= 2) ? 0 : ($self->is_gregorian_leap_year($year) ? -1 : -2)) +
           $day);
}

=head2 julian_to_gregorian($julian_date)

Returns Gregorian date as list  (year, month, day) equivalent of the given Julian
date C<$julian_date>.

=cut

sub julian_to_gregorian {
    my ($self, $julian) = @_;

    my $wjd        = floor($julian - 0.5) + 0.5;
    my $depoch     = $wjd - $self->gregorian_epoch;
    my $quadricent = floor($depoch / 146097);
    my $dqc        = $depoch % 146097;
    my $cent       = floor($dqc / 36524);
    my $dcent      = $dqc % 36524;
    my $quad       = floor($dcent / 1461);
    my $dquad      = $dcent % 1461;
    my $yindex     = floor($dquad / 365);
    my $year       = ($quadricent * 400) + ($cent * 100) + ($quad * 4) + $yindex;

    $year++ unless (($cent == 4) || ($yindex == 4));

    my $yearday = $wjd - $self->gregorian_to_julian($year, 1, 1);
    my $leapadj = (($wjd < $self->gregorian_to_julian($year, 3, 1)) ? 0 : (($self->is_gregorian_leap_year($year) ? 1 : 2)));
    my $month   = floor(((($yearday + $leapadj) * 12) + 373) / 367);
    my $day     = ($wjd - $self->gregorian_to_julian($year, $month, 1)) + 1;

    return ($year, $month, $day);
}

=head2 is_gregorian_leap_year($year)

Returns 0 or 1 if the given Gregorian year C<$year> is a leap year or not.

=cut

sub is_gregorian_leap_year {
    my ($self, $year) = @_;

    return (($year % 4) == 0) && (!((($year % 100) == 0) && (($year % 400) != 0)));
}

=head2 get_month_number($month_name)

Returns the month number starting with 1 for the given C<$month_name>.

=cut

sub get_month_number {
    my ($self, $month_name) = @_;

    if (defined $month_name && ($month_name !~ /^\d+$/)) {
        $self->validate_month_name($month_name);
    }
    else {
        $month_name = $self->get_month_name;
    }

    my $months = $self->months;
    foreach my $index (1..$#$months) {
        return $index if (uc($months->[$index]) eq uc($month_name));
    }

    my @caller = caller(0);
    @caller    = caller(2) if $caller[3] eq '(eval)';

    Date::Exception::InvalidMonth->throw({
        method      => __PACKAGE__."::get_month_number",
        message     => sprintf("ERROR: Invalid month name [%s].", defined($month_name)?($month_name):('')),
        filename    => $caller[1],
        line_number => $caller[2] });
}

=head2 get_month_name($month)

Returns the month name for the given C<$month> number (1,2,3 etc).

=cut

sub get_month_name {
    my ($self, $month) = @_;

    if (defined $month) {
        $self->validate_month($month);
    }
    else {
        $month = $self->month;
    }

    return $self->months->[$month];
}

=head2 validate_year($year)

Validates the given C<$year>. It has to be > 0 and numbers only.

=cut

sub validate_year {
    my ($self, $year) = @_;

    my @caller = caller(0);
    @caller    = caller(2) if $caller[3] eq '(eval)';

    Date::Exception::InvalidYear->throw({
        method      => __PACKAGE__."::validate_year",
        message     => sprintf("ERROR: Invalid year [%s].", defined($year)?($year):('')),
        filename    => $caller[1],
        line_number => $caller[2] })
        unless (defined($year) && ($year =~ /^\d+$/) && ($year > 0));
}

=head2 validate_month($month)

Validates the given C<$month>. It has to be between 1 and 12 or month name.

=cut

sub validate_month {
    my ($self, $month) = @_;

    if (defined $month && ($month !~ /^[-+]?\d+$/)) {
        return $self->validate_month_name($month);
    }

    my @caller = caller(0);
    @caller    = caller(2) if $caller[3] eq '(eval)';

    Date::Exception::InvalidMonth->throw({
        method      => __PACKAGE__."::validate_month",
        message     => sprintf("ERROR: Invalid month [%s].", defined($month)?($month):('')),
        filename    => $caller[1],
        line_number => $caller[2] })
        unless (defined($month) && ($month =~ /^\+?\d+$/) && ($month >= 1) && ($month <= 12));
}

=head2 validate_month_name($month_name)

Validates the given C<$month_name>.

=cut

sub validate_month_name {
    my ($self, $month_name) = @_;

    my @caller = caller(0);
    @caller    = caller(2) if $caller[3] eq '(eval)';

    my $months = $self->months;
    Date::Exception::InvalidMonth->throw({
        method      => __PACKAGE__."::validate_month_name",
        message     => sprintf("ERROR: Invalid month name [%s].", defined($month_name)?($month_name):('')),
        filename    => $caller[1],
        line_number => $caller[2] })
        unless (defined($month_name) && ($month_name !~ /^[-+]?\d+$/) && (grep /$month_name/i, @{$months}[1..$#$months]));
}

=head2 validate_day($day)

Validates the given C<$day>. It has to be between 1 and 31.

=cut

sub validate_day {
    my ($self, $day) = @_;

    my @caller = caller(0);
    @caller    = caller(2) if $caller[3] eq '(eval)';

    Date::Exception::InvalidDay->throw({
        method      => __PACKAGE__."::validate_day",
        message     => sprintf("ERROR: Invalid day [%s].", defined($day)?($day):('')),
        filename    => $caller[1],
        line_number => $caller[2] })
        unless (defined($day) && ($day =~ /^\d+$/) && ($day >= 1) && ($day <= 31));
}

=head2 validate_date($year, $month, $day)

Validates the given C<$year>, C<$month> and C<$day>.

=cut

sub validate_date {
    my ($self, $year, $month, $day) = @_;

    $self->validate_year($year);
    $self->validate_month($month);
    $self->validate_day($day);
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Date-Utils>

=head1 ACKNOWLEDGEMENTS

Entire logic is based on the L<code|http://www.fourmilab.ch/documents/calendar> written by John Walker.

=head1 SEE ALSO

=over 4

=item * L<Calendar::Bahai>

=item * L<Calendar::Gregorian>

=item * L<Calendar::Hebrew>

=item * L<Calendar::Hijri>

=item * L<Calendar::Julian>

=item * L<Calendar::Persian>

=item * L<Calendar::Saka>

=back

=head1 BUGS

Please report any bugs / feature requests to C<bug-date-utils at rt.cpan.org>, or
through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Date-Utils>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Date::Utils

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Date-Utils>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Date-Utils>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Date-Utils>

=item * Search CPAN

L<http://search.cpan.org/dist/Date-Utils/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2015 - 2017 Mohammad S Anwar.

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

1; # End of Date::Utils
