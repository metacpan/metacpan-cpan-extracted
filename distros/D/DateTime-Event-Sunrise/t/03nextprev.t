#
#     Test script for DateTime::Event::Sunrise (see RT ticket 36532)
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
1212537601 46.74575  -65.2488
1212536601 64.74575 -220.2488
TEST

plan (tests => 4 * scalar @tests);

foreach (@tests) {
  my ($epoch, $lat, $lon) = split ' ', $_;
  my $sunrise = DateTime::Event::Sunrise->sunrise(longitude => $lon,
                                                  latitude  => $lat,
                                                  precise   => 1,
                                                  );
  my $sunset  = DateTime::Event::Sunrise->sunset (longitude => $lon,
                                                  latitude  => $lat,
                                                  precise   => 1,
                                                  );
  my $dt = DateTime->from_epoch(epoch => $epoch);

  my $next_sunrise = $sunrise->next($dt);
  my $next_sunset  = $sunset ->next($dt);
  my $prev_sunrise = $sunrise->previous($dt);
  my $prev_sunset  = $sunset ->previous($dt);

  ok($next_sunrise->epoch() > $epoch, "Next sunrise ($next_sunrise) should be after dt ($dt)");
  ok($next_sunset ->epoch() > $epoch, "Next sunset  ($next_sunset) should be after dt ($dt)");
  ok($prev_sunrise->epoch() < $epoch, "Prev sunrise ($prev_sunrise) should be before dt ($dt)");
  ok($prev_sunset ->epoch() < $epoch, "Prev sunset  ($prev_sunset) should be before dt ($dt)");
}


