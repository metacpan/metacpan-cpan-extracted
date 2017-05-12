#
#     Test script for DateTime::Event::Sunrise
#     Copyright (C) 2013 Ron Hill and Jean Forget
#
#     This program is distributed under the same terms as Perl 5.16.3:
#     GNU Public License version 1 or later and Perl Artistic License
#
#     You can find the text of the licenses in the F<LICENSE> file or at
#     L<http://www.perlfoundation.org/artistic_license_1_0>
#     and L<http://www.gnu.org/licenses/gpl-1.0.html>.
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
#     Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307, USA.
#
use strict;
use POSIX qw(floor ceil);
use Test::More;
use DateTime;
use DateTime::Event::Sunrise;

my @tests = split "\n", <<'TEST';
2.33  48.83 1 20 18:04:42
2.33  48.83 1 21 18:06:12
2.33  48.83 1 22 18:07:43
92.33 48.83 0 20 12:03:10
92.33 48.83 0 21 12:04:41
92.33 48.83 0 22 12:06:11
TEST

plan (tests => scalar @tests);

foreach (@tests) {
  my ($lon, $lat, $precise, $dd, $res) = split ' ', $_;
  my $sunset = DateTime::Event::Sunrise->sunset(longitude  => $lon,
                                                 latitude  => $lat,
                                                 precise   => $precise,
                                                 upper_limb => 0,
                                                );
  my  $day =  DateTime->new(year => 2008, month => 3, day => $dd, time_zone => 'UTC');

  is ($sunset->next($day)->strftime("%H:%M:%S"), $res);

}


