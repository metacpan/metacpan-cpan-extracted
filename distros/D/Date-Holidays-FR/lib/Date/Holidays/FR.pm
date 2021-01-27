# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Perl module to compute the French holidays in a given year.
#     Copyright (c) 2004, 2019, 2021 Fabien Potencier and Jean Forget, all rights reserved
#
#     See the license in the embedded documentation below.
#
package Date::Holidays::FR;

use utf8;
use strict;
use warnings;
use Time::Local qw(timelocal_modern);
use Date::Easter;
use Readonly;
use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(is_fr_holiday is_holiday holidays fr_holidays);

our $VERSION = '0.04';

Readonly::Scalar my $easter_offset    => 1;
Readonly::Scalar my $ascension_offset => 39;
Readonly::Scalar my $pentecost_offset => 50;
Readonly::Scalar my $seconds_in_day   => 60 * 60 * 24;
Readonly::Scalar my $false            => 0;

Readonly::Scalar my $localtime_month_idx => 4;
Readonly::Scalar my $localtime_day_idx   => 3;

sub get_easter {
        my ($year) = @_;

        return Date::Easter::easter($year);
}

sub get_ascension {
        my ($year) = @_;

        return _compute_date_from_easter($year, $ascension_offset);
}

sub get_pentecost {
        my ($year) = @_;

        return _compute_date_from_easter($year, $pentecost_offset);
}

sub _compute_date_from_easter {
        my ($year, $delta) = @_;

        my ($easter_month, $easter_day) = get_easter($year);
        my $easter_date = timelocal_modern(0, 0, 1, $easter_day, $easter_month - 1, $year);
        my ($date_month, $date_day) = (localtime($easter_date + $delta * $seconds_in_day))[$localtime_month_idx, $localtime_day_idx];
        $date_month++;

        return ($date_month, $date_day);
}

sub is_holiday {
    return is_fr_holiday(@_);
}

sub is_fr_holiday {
    my ($year, $month, $day) = @_;

    my $date = _format_segment($month) . _format_segment($day);
    my $dates = _get_dates($year);

    return $dates->{$date} || $false;
}

sub holidays {
    return fr_holidays(shift);
}

sub fr_holidays {
        my $year = shift;

        my $holidays = {};

        my $dates = _get_dates($year);

        foreach my $date (keys %{$dates}) {
            my ($month, $day) = $date =~ m/(\d{2})(\d{2})/;

            my $holiday = is_fr_holiday($year, $month, $day);

            if ($holiday) {
                $holidays->{$date} = $holiday;
            }
        };

        return $holidays;
}

sub _get_dates {
    my $year = shift;

    my $dates = {
        '0101' => 'Nouvel an',
        '0501' => 'Fête du travail',
        '0508' => 'Armistice 1939-1945',
        '0714' => 'Fête nationale',
        '0815' => 'Assomption',
        '1101' => 'Toussaint',
        '1111' => 'Armistice 1914-1918',
        '1225' => 'Noël',
    };

    my ($easter_month,    $easter_day)    = _compute_date_from_easter($year, $easter_offset);
    my ($ascension_month, $ascension_day) = _compute_date_from_easter($year, $ascension_offset);
    my ($pentecost_month, $pentecost_day) = _compute_date_from_easter($year, $pentecost_offset);

    $dates->{_format_segment($easter_month) . _format_segment($easter_day)} = 'Lundi de Pâques';
    $dates->{_format_segment($ascension_month) . _format_segment($ascension_day)} = 'Ascension';
    $dates->{_format_segment($pentecost_month) . _format_segment($pentecost_day)} = 'Lundi de Pentecôte';

    return $dates;
}

sub _format_segment {
    return sprintf('%02d', shift);
}

# And instead of a plain, boring "1" to end the module source, let us
# celebrate the 14th of July, closely associated with the Bastille:

"-- À la Bastille on l'aime bien Nini Peau-d'chien,
    Elle est si douce et si gentille !
    On l'aime bien...
 -- QUI ÇA ?
 -- Nini Peau-d'chien...
 -- OÙ ÇA ?
 -- À la Basti-i-ille";

__END__

=encoding utf-8

=head1 NAME

Date::Holidays::FR - Determine French holidays

=head1 SYNOPSIS

Checking one day

  use Date::Holidays::FR;
  my ($year, $month, $day) = (localtime)[5, 4, 3];
  $year  += 1900;
  $month +=    1;
  print "Woohoo" if is_fr_holiday($year, $month, $day);

Computing the mobile days

  use Date::Holidays::FR;
  my ($month, $day) = get_easter($year);
  my ($month, $day) = get_ascension($year);
  my ($month, $day) = get_pentecost($year);

Checking a whole year

  use Date::Holidays::FR;
  my $days_off = holidays($year);
  for my $mmdd (sort keys  %$days_off) {
    print "$mmdd $days_off->{$mmdd}\n";
  }

=head1 DESCRIPTION

is_fr_holiday method return true value when the day is holiday.

There are 11 holidays in France:

=over 4

=item * 1er janvier : Nouvel an / New Year's Day

=item * Lundi de Pâques / Easter Monday

=item * 1er mai : Fête du travail / Labour Day

=item * 8 mai : Armistice 1939-1945

=item * Ascension

=item * Lundi de Pentecôte / Pentecost Monday

=item * 14 juillet : Fête nationale / Bastille Day

=item * 15 août : Assomption / Assumption

=item * 1er novembre : Toussaint / All Saints' Day

=item * 11 novembre : Armistice 1914-1918

=item * 25 décembre : Noël / Christmas

=back

Easter is computed with L<Date::Easter> module.

Ascension is 39 days after Easter.

Pentecost monday is 50 days after Easter.

=head1 SUBROUTINES

=head2 is_fr_holiday($year, $month, $day), is_holiday($year, $month, $day)

Returns the name of the holiday in french that falls on the given day,
or a false value if there is none.

C<is_holiday> is a wrapper for  C<is_fr_holiday> to be compatible with
the naming conventions of L<Date::Holidays>.

=head2 fr_holidays($year), holidays($year)

Returns a hashref containing all  the holidays for the requested year.
Keys are the dates in C<MMDD> format, values are French labels for the
holidays.

C<holidays> is a wrapper for  C<fr_holidays> to be compatible with the
naming conventions of L<Date::Holidays>.

=head2 get_easter($year)

Returns the month and day of easter monday for the given year.

=head2 get_ascension($year)

Returns the month and day of ascension day for the given year.

=head2 get_pentecost($year)

Returns the month and day of pentecost monday for the given year.

=head1 BUGS AND ISSUES

No known bugs.

On rare instances  (last one was in  1913, next one will  be on 2160),
the Ascension falls on 1st May, same day as the I<Fête du Travail>. In
this case,  the C<fr_holidays>  (or C<holidays>) subroutine  refers to
this date as Ascension, not as I<Fête du Travail>.

Likewise, on  some years the Ascension  falls on 8th May,  same day as
I<Armistice 1939-1945>.  As above,  the Ascension takes  precedence on
the Armistice. This  conflict is much more frequent  than the conflict
with 1st May. For example, it occurred in 1975, 1986 and 1997, it will
occur again in 2070, 2081 and 2092.

This behaviour is subject to change,  in future releases the I<Fête du
Travail> or I<Armistice 1939-1945>  might preempt Ascension instead of
the other way around.

=head1 SUPPORT

Please  report any  requests, suggestions  or bugs  via Github.  Go to
L<https://github.com/jforget/Date-Holidays-FR>, and create an issue or
submit a pull request.

If you have no feedback after a week  or so, you can reach me by email
at JFORGET  at cpan dot org.  Please mention the distribution  name in
the subject, so  my spam filter and me will  easily dispatch the email
to the proper folder.

On the other hand, I may be on vacation. Do not be upset if the answer
arrives after one or  two months. Be upset only if  you do not receive
an answer to several emails over at least one year.

=head1 AUTHORS

Module creator: Fabien Potencier

Current maintainer: Jean Forget (JFORGET at cpan dot org)

=head2 Thanks

Many  thanks to  JONASBN,  for maintaining  L<Date::Holidays> and  for
suggesting some cleanup of the code.

=head1 LICENSE

Copyright (c) 2004,  2019, 2021 Fabien Potencier and  Jean Forget. All
rights reserved. This  program is free software;  you can redistribute
it and/or  modify it under the  same terms as Perl  itself: GNU Public
License version 1 or later and Perl Artistic License.

The full text of the license can be found in the F<LICENSE> file
included with this module or at
L<https://dev.perl.org/licenses/artistic.html>
and L<https://www.gnu.org/licenses/gpl-1.0.html>.

Here is the summary of GPL:

This program is  free software; you can redistribute  it and/or modify
it under the  terms of the GNU General Public  License as published by
the Free  Software Foundation; either  version 1, or (at  your option)
any later version.

This program  is distributed in the  hope that it will  be useful, but
WITHOUT   ANY  WARRANTY;   without  even   the  implied   warranty  of
MERCHANTABILITY  or FITNESS  FOR A  PARTICULAR PURPOSE.   See  the GNU
General Public License for more details.

You should  have received  a copy  of the  GNU General  Public License
along with this program;  if not, see L<https://www.gnu.org/licenses/>
or contact the Free Software Foundation, Inc., L<https://fsf.org>.

=head1 SEE ALSO

perl(1), L<Date::Holidays>, L<Date::Holidays::UK>, L<Date::Holidays::DE>.

=cut
