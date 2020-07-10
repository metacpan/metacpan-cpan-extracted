#
#     Test script for DateTime::Event::Sunrise
#     Copyright © 2013, 2020 Ron Hill and Jean Forget
#
#     This program is distributed under the same terms as Perl 5.16.3:
#     GNU Public License version 1 or later and Perl Artistic License
#
#     You can find the text of the licenses in the F<LICENSE> file or at
#     L<https://dev.perl.org/licenses/artistic.html>
#     and L<https://www.gnu.org/licenses/gpl-1.0.html>.
#
#     Here is the summary of GPL:
#
#     This program is free software; you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation; either version 1, or (at your option)
#     any later version.
#
#     This program is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
#
#     You should have received a copy of the GNU General Public License
#     along with this program; if not, write to the Free Software Foundation,
#     Inc., <https://www.fsf.org/>.
#
use strict;
use POSIX qw(floor ceil);
use Test::More;
use DateTime;
use DateTime::Event::Sunrise;

# Values for Paris (2°20'E, 48°50' N) computed with Stellarium
my @tests = split "\n", <<'TEST';
2.33  48.83 1 20 18:03:53
2.33  48.83 1 21 18:05:23
2.33  48.83 1 22 18:06:54
92.33 48.83 0 20 12:03:10
92.33 48.83 0 21 12:04:41
92.33 48.83 0 22 12:06:11
TEST

plan (tests => scalar @tests);

foreach (@tests) {
  my ($lon, $lat, $precise, $dd, $expected) = split ' ', $_;
  my $sunset = DateTime::Event::Sunrise->sunset(longitude  => $lon,
                                                 latitude  => $lat,
                                                 precise   => $precise,
                                                 upper_limb => 0,
                                                );
  my  $day =  DateTime->new(year => 2008, month => 3, day => $dd, time_zone => 'UTC');
  my  $set = $sunset->next($day);
  # fuzz factor ± 1 mn
  my  $sunset    = $set->clone                        ->strftime("%H:%M:%S");
  my  $sunset_lo = $set->clone->subtract(minutes => 1)->strftime("%H:%M:%S");
  my  $sunset_hi = $set->clone->add     (minutes => 1)->strftime("%H:%M:%S");

  ok ($sunset_lo le $expected && $sunset_hi ge $expected, "comparing $sunset with $expected");

}


