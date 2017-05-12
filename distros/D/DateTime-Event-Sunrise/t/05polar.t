# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Test script for DateTime::Event::Sunrise
#     Copyright (C) 2014 Ron Hill and Jean Forget
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
use DateTime::Duration;
use DateTime::Event::Sunrise;

my @data = data();
plan tests => 5 * @data;
my $fudge = 2;

for  (@data) {
    my ($yyyy, $mm, $dd, $city, $ltd, $ltm, $ltc,  $lgd, $lgm, $lgc, $altitude, $upper_limb, $pn, $dn, $pd, $result)
         = $_ =~ /^(\d{4})\s+(\d\d?)\s+(\d\d?)
                   \s+(\w+)
                   \s+(\d+)\s+(\d+)\s+(\w)
                   \s+(\d+)\s+(\d+)\s+(\w)
                   \s+([-.0-9]+)
                   \s+([01])
                   \s+([01])
                   \s+([01])
                   \s+([01])
                   \s+(.*?)$/x;

    my ($lat, $long, $offset, $expected_rise_low, $expected_rise_high, $expected_set_low, $expected_set_high);
    if ($result =~ /sunrise: ([-0-9]{2}):(\d\d):(\d\d)\s+sunset:\s+(\d\d):(\d\d):(\d\d)/) {
      my ($hh1, $mm1, $ss1, $hh2, $mm2, $ss2) = ($1, $2, $3, $4, $5, $6);
      $expected_rise_low  = DateTime->new(year => $yyyy, month => $mm, day => $dd) + DateTime::Duration->new(hours => $hh1, minutes => $mm1, seconds => $ss1 - $fudge);
      $expected_rise_high = DateTime->new(year => $yyyy, month => $mm, day => $dd) + DateTime::Duration->new(hours => $hh1, minutes => $mm1, seconds => $ss1 + $fudge);
      $expected_set_low   = DateTime->new(year => $yyyy, month => $mm, day => $dd) + DateTime::Duration->new(hours => $hh2, minutes => $mm2, seconds => $ss2 - $fudge);
      $expected_set_high  = DateTime->new(year => $yyyy, month => $mm, day => $dd) + DateTime::Duration->new(hours => $hh2, minutes => $mm2, seconds => $ss2 + $fudge);
    }
    if ( $ltc eq 'N' ) {
      $lat = sprintf("%.3f", $ltd + $ltm / 60);
    }
    elsif ( $ltc eq 'S' ) {
      $lat = sprintf("%.3f", -($ltd + $ltm / 60));
    }

    if ( $lgc eq 'E' ) {
      $long = sprintf("%.3f", $lgd + $lgm / 60);
    }
    elsif ( $lgc eq 'W' ) {
      $long = sprintf("%.3f", -($lgd + $lgm / 60));
    }

    if ( $long < 0 ) {
        $offset = DateTime::TimeZone::offset_as_string( ceil( $long / 15 ) * 60 * 60 );
    }
    else {
        $offset = DateTime::TimeZone::offset_as_string( floor( $long / 15 ) * 60 * 60 );
    }

    my $sunrise = DateTime::Event::Sunrise->new(
                longitude  => $long,
                latitude   => $lat,
                altitude   => $altitude,
                upper_limb => $upper_limb,
                silent     => 1,
    );

    #my $dt = DateTime->new(year => $yyyy, month => $mm, day => $dd, time_zone => $offset);
    my $dt = DateTime->new(year => $yyyy, month => $mm, day => $dd);
    my $tmp_rise = $sunrise->sunrise_datetime($dt);
    my $tmp_set  = $sunrise->sunset_datetime ($dt);

    my $sun_rise = $tmp_rise->strftime("%H:%M");
    my $sun_set  = $tmp_set->strftime("%H:%M");

    ok( $tmp_rise >= $expected_rise_low && $tmp_rise <= $expected_rise_high, join ' ', "Sunrise for $city", $tmp_rise->ymd, $expected_rise_low->hms, $tmp_rise->hms, $expected_rise_high->hms, $upper_limb, $altitude);
    ok( $tmp_set  >= $expected_set_low  && $tmp_set  <= $expected_set_high,  join ' ', "Sunset  for $city", $tmp_set->ymd, $expected_set_low->hms, $tmp_set->hms, $expected_set_high->hms, $upper_limb, $altitude);
    is (0 + $sunrise->is_polar_night  ($dt), $pn);
    is (0 + $sunrise->is_day_and_night($dt), $dn);
    is (0 + $sunrise->is_polar_day    ($dt), $pd);

}

#
# The data below have been prepared by a C program which includes
# Paul Schlyter's code. Therefore, what is tested is the compatibility
# of the Perl code with the C code.
#
# See how this C program is generated in
# https://github.com/jforget/Astro-Sunrise/blob/master/util/mktest-05
#
#
sub data {
  return split "\n", <<'DATA';
2013  1  1 North_Pole           89 59 N   0  0 E 0          0 1 0 0 sunrise: 12:03:40 sunset: 12:03:40
2013  1  1 North_Pole           89 59 N   0  0 E 0          1 1 0 0 sunrise: 12:03:40 sunset: 12:03:40
2013  1  1 North_Pole           89 59 N   0  0 E -0.583     0 1 0 0 sunrise: 12:03:40 sunset: 12:03:40
2013  1  1 North_Pole           89 59 N   0  0 E -0.583     1 1 0 0 sunrise: 12:03:40 sunset: 12:03:40
2013  1  1 North_Pole           89 59 N   0  0 E -0.833     0 1 0 0 sunrise: 12:03:40 sunset: 12:03:40
2013  1  1 North_Pole           89 59 N   0  0 E -0.833     1 1 0 0 sunrise: 12:03:40 sunset: 12:03:40
2013  1  1 North_Pole           89 59 N   0  0 E -12        0 1 0 0 sunrise: 12:03:40 sunset: 12:03:40
2013  1  1 North_Pole           89 59 N   0  0 E -12        1 1 0 0 sunrise: 12:03:40 sunset: 12:03:40
2013  1  1 North_Pole           89 59 N   0  0 E -18        0 1 0 0 sunrise: 12:03:40 sunset: 12:03:40
2013  1  1 North_Pole           89 59 N   0  0 E -18        1 1 0 0 sunrise: 12:03:40 sunset: 12:03:40
2013  3 21 North_Pole           89 59 N   0  0 E 0          0 0 0 1 sunrise: 00:07:07 sunset: 24:07:07
2013  3 21 North_Pole           89 59 N   0  0 E 0          1 0 0 1 sunrise: 00:07:07 sunset: 24:07:07
2013  3 21 North_Pole           89 59 N   0  0 E -0.583     0 0 0 1 sunrise: 00:07:07 sunset: 24:07:07
2013  3 21 North_Pole           89 59 N   0  0 E -0.583     1 0 0 1 sunrise: 00:07:07 sunset: 24:07:07
2013  3 21 North_Pole           89 59 N   0  0 E -0.833     0 0 0 1 sunrise: 00:07:07 sunset: 24:07:07
2013  3 21 North_Pole           89 59 N   0  0 E -0.833     1 0 0 1 sunrise: 00:07:07 sunset: 24:07:07
2013  3 21 North_Pole           89 59 N   0  0 E -12        0 0 0 1 sunrise: 00:07:07 sunset: 24:07:07
2013  3 21 North_Pole           89 59 N   0  0 E -12        1 0 0 1 sunrise: 00:07:07 sunset: 24:07:07
2013  3 21 North_Pole           89 59 N   0  0 E -18        0 0 0 1 sunrise: 00:07:07 sunset: 24:07:07
2013  3 21 North_Pole           89 59 N   0  0 E -18        1 0 0 1 sunrise: 00:07:07 sunset: 24:07:07
2013  6 21 North_Pole           89 59 N   0  0 E 0          0 0 0 1 sunrise: 00:01:49 sunset: 24:01:49
2013  6 21 North_Pole           89 59 N   0  0 E 0          1 0 0 1 sunrise: 00:01:49 sunset: 24:01:49
2013  6 21 North_Pole           89 59 N   0  0 E -0.583     0 0 0 1 sunrise: 00:01:49 sunset: 24:01:49
2013  6 21 North_Pole           89 59 N   0  0 E -0.583     1 0 0 1 sunrise: 00:01:49 sunset: 24:01:49
2013  6 21 North_Pole           89 59 N   0  0 E -0.833     0 0 0 1 sunrise: 00:01:49 sunset: 24:01:49
2013  6 21 North_Pole           89 59 N   0  0 E -0.833     1 0 0 1 sunrise: 00:01:49 sunset: 24:01:49
2013  6 21 North_Pole           89 59 N   0  0 E -12        0 0 0 1 sunrise: 00:01:49 sunset: 24:01:49
2013  6 21 North_Pole           89 59 N   0  0 E -12        1 0 0 1 sunrise: 00:01:49 sunset: 24:01:49
2013  6 21 North_Pole           89 59 N   0  0 E -18        0 0 0 1 sunrise: 00:01:49 sunset: 24:01:49
2013  6 21 North_Pole           89 59 N   0  0 E -18        1 0 0 1 sunrise: 00:01:49 sunset: 24:01:49
2013  8 31 North_Pole           89 59 N   0  0 E 0          0 0 0 1 sunrise: 00:00:15 sunset: 24:00:15
2013  8 31 North_Pole           89 59 N   0  0 E 0          1 0 0 1 sunrise: 00:00:15 sunset: 24:00:15
2013  8 31 North_Pole           89 59 N   0  0 E -0.583     0 0 0 1 sunrise: 00:00:15 sunset: 24:00:15
2013  8 31 North_Pole           89 59 N   0  0 E -0.583     1 0 0 1 sunrise: 00:00:15 sunset: 24:00:15
2013  8 31 North_Pole           89 59 N   0  0 E -0.833     0 0 0 1 sunrise: 00:00:15 sunset: 24:00:15
2013  8 31 North_Pole           89 59 N   0  0 E -0.833     1 0 0 1 sunrise: 00:00:15 sunset: 24:00:15
2013  8 31 North_Pole           89 59 N   0  0 E -12        0 0 0 1 sunrise: 00:00:15 sunset: 24:00:15
2013  8 31 North_Pole           89 59 N   0  0 E -12        1 0 0 1 sunrise: 00:00:15 sunset: 24:00:15
2013  8 31 North_Pole           89 59 N   0  0 E -18        0 0 0 1 sunrise: 00:00:15 sunset: 24:00:15
2013  8 31 North_Pole           89 59 N   0  0 E -18        1 0 0 1 sunrise: 00:00:15 sunset: 24:00:15
2013  9 21 North_Pole           89 59 N   0  0 E 0          0 0 0 1 sunrise: -1:53:00 sunset: 23:53:00
2013  9 21 North_Pole           89 59 N   0  0 E 0          1 0 0 1 sunrise: -1:53:00 sunset: 23:53:00
2013  9 21 North_Pole           89 59 N   0  0 E -0.583     0 0 0 1 sunrise: -1:53:00 sunset: 23:53:00
2013  9 21 North_Pole           89 59 N   0  0 E -0.583     1 0 0 1 sunrise: -1:53:00 sunset: 23:53:00
2013  9 21 North_Pole           89 59 N   0  0 E -0.833     0 0 0 1 sunrise: -1:53:00 sunset: 23:53:00
2013  9 21 North_Pole           89 59 N   0  0 E -0.833     1 0 0 1 sunrise: -1:53:00 sunset: 23:53:00
2013  9 21 North_Pole           89 59 N   0  0 E -12        0 0 0 1 sunrise: -1:53:00 sunset: 23:53:00
2013  9 21 North_Pole           89 59 N   0  0 E -12        1 0 0 1 sunrise: -1:53:00 sunset: 23:53:00
2013  9 21 North_Pole           89 59 N   0  0 E -18        0 0 0 1 sunrise: -1:53:00 sunset: 23:53:00
2013  9 21 North_Pole           89 59 N   0  0 E -18        1 0 0 1 sunrise: -1:53:00 sunset: 23:53:00
2013 12 31 North_Pole           89 59 N   0  0 E 0          0 1 0 0 sunrise: 12:03:05 sunset: 12:03:05
2013 12 31 North_Pole           89 59 N   0  0 E 0          1 1 0 0 sunrise: 12:03:05 sunset: 12:03:05
2013 12 31 North_Pole           89 59 N   0  0 E -0.583     0 1 0 0 sunrise: 12:03:05 sunset: 12:03:05
2013 12 31 North_Pole           89 59 N   0  0 E -0.583     1 1 0 0 sunrise: 12:03:05 sunset: 12:03:05
2013 12 31 North_Pole           89 59 N   0  0 E -0.833     0 1 0 0 sunrise: 12:03:05 sunset: 12:03:05
2013 12 31 North_Pole           89 59 N   0  0 E -0.833     1 1 0 0 sunrise: 12:03:05 sunset: 12:03:05
2013 12 31 North_Pole           89 59 N   0  0 E -12        0 1 0 0 sunrise: 12:03:05 sunset: 12:03:05
2013 12 31 North_Pole           89 59 N   0  0 E -12        1 1 0 0 sunrise: 12:03:05 sunset: 12:03:05
2013 12 31 North_Pole           89 59 N   0  0 E -18        0 1 0 0 sunrise: 12:03:05 sunset: 12:03:05
2013 12 31 North_Pole           89 59 N   0  0 E -18        1 1 0 0 sunrise: 12:03:05 sunset: 12:03:05
2013  1  1 Halley_Base          75 35 S  26 39 W 0          0 0 0 1 sunrise: 01:50:18 sunset: 25:50:18
2013  1  1 Halley_Base          75 35 S  26 39 W 0          1 0 0 1 sunrise: 01:50:18 sunset: 25:50:18
2013  1  1 Halley_Base          75 35 S  26 39 W -0.583     0 0 0 1 sunrise: 01:50:18 sunset: 25:50:18
2013  1  1 Halley_Base          75 35 S  26 39 W -0.583     1 0 0 1 sunrise: 01:50:18 sunset: 25:50:18
2013  1  1 Halley_Base          75 35 S  26 39 W -0.833     0 0 0 1 sunrise: 01:50:18 sunset: 25:50:18
2013  1  1 Halley_Base          75 35 S  26 39 W -0.833     1 0 0 1 sunrise: 01:50:18 sunset: 25:50:18
2013  1  1 Halley_Base          75 35 S  26 39 W -12        0 0 0 1 sunrise: 01:50:18 sunset: 25:50:18
2013  1  1 Halley_Base          75 35 S  26 39 W -12        1 0 0 1 sunrise: 01:50:18 sunset: 25:50:18
2013  1  1 Halley_Base          75 35 S  26 39 W -18        0 0 0 1 sunrise: 01:50:18 sunset: 25:50:18
2013  1  1 Halley_Base          75 35 S  26 39 W -18        1 0 0 1 sunrise: 01:50:18 sunset: 25:50:18
2013  3 21 Halley_Base          75 35 S  26 39 W 0          0 0 1 0 sunrise: 08:00:34 sunset: 19:46:49
2013  3 21 Halley_Base          75 35 S  26 39 W 0          1 0 1 0 sunrise: 07:56:16 sunset: 19:51:07
2013  3 21 Halley_Base          75 35 S  26 39 W -0.583     0 0 1 0 sunrise: 07:51:12 sunset: 19:56:11
2013  3 21 Halley_Base          75 35 S  26 39 W -0.583     1 0 1 0 sunrise: 07:46:54 sunset: 20:00:29
2013  3 21 Halley_Base          75 35 S  26 39 W -0.833     0 0 1 0 sunrise: 07:47:11 sunset: 20:00:12
2013  3 21 Halley_Base          75 35 S  26 39 W -0.833     1 0 1 0 sunrise: 07:42:53 sunset: 20:04:30
2013  3 21 Halley_Base          75 35 S  26 39 W -12        0 0 1 0 sunrise: 04:19:13 sunset: 23:28:10
2013  3 21 Halley_Base          75 35 S  26 39 W -12        1 0 1 0 sunrise: 04:11:59 sunset: 23:35:24
2013  3 21 Halley_Base          75 35 S  26 39 W -18        0 0 0 1 sunrise: 01:53:42 sunset: 25:53:42
2013  3 21 Halley_Base          75 35 S  26 39 W -18        1 0 0 1 sunrise: 01:53:42 sunset: 25:53:42
2013  6 21 Halley_Base          75 35 S  26 39 W 0          0 1 0 0 sunrise: 13:48:26 sunset: 13:48:26
2013  6 21 Halley_Base          75 35 S  26 39 W 0          1 1 0 0 sunrise: 13:48:26 sunset: 13:48:26
2013  6 21 Halley_Base          75 35 S  26 39 W -0.583     0 1 0 0 sunrise: 13:48:26 sunset: 13:48:26
2013  6 21 Halley_Base          75 35 S  26 39 W -0.583     1 1 0 0 sunrise: 13:48:26 sunset: 13:48:26
2013  6 21 Halley_Base          75 35 S  26 39 W -0.833     0 1 0 0 sunrise: 13:48:26 sunset: 13:48:26
2013  6 21 Halley_Base          75 35 S  26 39 W -0.833     1 1 0 0 sunrise: 13:48:26 sunset: 13:48:26
2013  6 21 Halley_Base          75 35 S  26 39 W -12        0 0 1 0 sunrise: 11:12:05 sunset: 16:24:48
2013  6 21 Halley_Base          75 35 S  26 39 W -12        1 0 1 0 sunrise: 11:05:05 sunset: 16:31:47
2013  6 21 Halley_Base          75 35 S  26 39 W -18        0 0 1 0 sunrise: 09:06:23 sunset: 18:30:30
2013  6 21 Halley_Base          75 35 S  26 39 W -18        1 0 1 0 sunrise: 09:01:46 sunset: 18:35:07
2013  8 31 Halley_Base          75 35 S  26 39 W 0          0 0 1 0 sunrise: 10:08:00 sunset: 17:25:39
2013  8 31 Halley_Base          75 35 S  26 39 W 0          1 0 1 0 sunrise: 10:02:47 sunset: 17:30:52
2013  8 31 Halley_Base          75 35 S  26 39 W -0.583     0 0 1 0 sunrise: 09:56:36 sunset: 17:37:03
2013  8 31 Halley_Base          75 35 S  26 39 W -0.583     1 0 1 0 sunrise: 09:51:33 sunset: 17:42:06
2013  8 31 Halley_Base          75 35 S  26 39 W -0.833     0 0 1 0 sunrise: 09:51:49 sunset: 17:41:50
2013  8 31 Halley_Base          75 35 S  26 39 W -0.833     1 0 1 0 sunrise: 09:46:50 sunset: 17:46:49
2013  8 31 Halley_Base          75 35 S  26 39 W -12        0 0 1 0 sunrise: 06:45:01 sunset: 20:48:38
2013  8 31 Halley_Base          75 35 S  26 39 W -12        1 0 1 0 sunrise: 06:40:39 sunset: 20:53:00
2013  8 31 Halley_Base          75 35 S  26 39 W -18        0 0 1 0 sunrise: 04:56:24 sunset: 22:37:16
2013  8 31 Halley_Base          75 35 S  26 39 W -18        1 0 1 0 sunrise: 04:50:47 sunset: 22:42:52
2013  9 21 Halley_Base          75 35 S  26 39 W 0          0 0 1 0 sunrise: 07:47:21 sunset: 19:31:48
2013  9 21 Halley_Base          75 35 S  26 39 W 0          1 0 1 0 sunrise: 07:43:05 sunset: 19:36:04
2013  9 21 Halley_Base          75 35 S  26 39 W -0.583     0 0 1 0 sunrise: 07:37:59 sunset: 19:41:10
2013  9 21 Halley_Base          75 35 S  26 39 W -0.583     1 0 1 0 sunrise: 07:33:43 sunset: 19:45:26
2013  9 21 Halley_Base          75 35 S  26 39 W -0.833     0 0 1 0 sunrise: 07:33:58 sunset: 19:45:11
2013  9 21 Halley_Base          75 35 S  26 39 W -0.833     1 0 1 0 sunrise: 07:29:41 sunset: 19:49:27
2013  9 21 Halley_Base          75 35 S  26 39 W -12        0 0 1 0 sunrise: 04:06:36 sunset: 23:12:32
2013  9 21 Halley_Base          75 35 S  26 39 W -12        1 0 1 0 sunrise: 03:59:29 sunset: 23:19:39
2013  9 21 Halley_Base          75 35 S  26 39 W -18        0 0 0 1 sunrise: 01:39:34 sunset: 25:39:34
2013  9 21 Halley_Base          75 35 S  26 39 W -18        1 0 0 1 sunrise: 01:39:34 sunset: 25:39:34
2013 12 31 Halley_Base          75 35 S  26 39 W 0          0 0 0 1 sunrise: 01:49:43 sunset: 25:49:43
2013 12 31 Halley_Base          75 35 S  26 39 W 0          1 0 0 1 sunrise: 01:49:43 sunset: 25:49:43
2013 12 31 Halley_Base          75 35 S  26 39 W -0.583     0 0 0 1 sunrise: 01:49:43 sunset: 25:49:43
2013 12 31 Halley_Base          75 35 S  26 39 W -0.583     1 0 0 1 sunrise: 01:49:43 sunset: 25:49:43
2013 12 31 Halley_Base          75 35 S  26 39 W -0.833     0 0 0 1 sunrise: 01:49:43 sunset: 25:49:43
2013 12 31 Halley_Base          75 35 S  26 39 W -0.833     1 0 0 1 sunrise: 01:49:43 sunset: 25:49:43
2013 12 31 Halley_Base          75 35 S  26 39 W -12        0 0 0 1 sunrise: 01:49:43 sunset: 25:49:43
2013 12 31 Halley_Base          75 35 S  26 39 W -12        1 0 0 1 sunrise: 01:49:43 sunset: 25:49:43
2013 12 31 Halley_Base          75 35 S  26 39 W -18        0 0 0 1 sunrise: 01:49:43 sunset: 25:49:43
2013 12 31 Halley_Base          75 35 S  26 39 W -18        1 0 0 1 sunrise: 01:49:43 sunset: 25:49:43
2013  1  1 South_Pole           89 59 S   0  0 W 0          0 0 0 1 sunrise: 00:03:40 sunset: 24:03:40
2013  1  1 South_Pole           89 59 S   0  0 W 0          1 0 0 1 sunrise: 00:03:40 sunset: 24:03:40
2013  1  1 South_Pole           89 59 S   0  0 W -0.583     0 0 0 1 sunrise: 00:03:40 sunset: 24:03:40
2013  1  1 South_Pole           89 59 S   0  0 W -0.583     1 0 0 1 sunrise: 00:03:40 sunset: 24:03:40
2013  1  1 South_Pole           89 59 S   0  0 W -0.833     0 0 0 1 sunrise: 00:03:40 sunset: 24:03:40
2013  1  1 South_Pole           89 59 S   0  0 W -0.833     1 0 0 1 sunrise: 00:03:40 sunset: 24:03:40
2013  1  1 South_Pole           89 59 S   0  0 W -12        0 0 0 1 sunrise: 00:03:40 sunset: 24:03:40
2013  1  1 South_Pole           89 59 S   0  0 W -12        1 0 0 1 sunrise: 00:03:40 sunset: 24:03:40
2013  1  1 South_Pole           89 59 S   0  0 W -18        0 0 0 1 sunrise: 00:03:40 sunset: 24:03:40
2013  1  1 South_Pole           89 59 S   0  0 W -18        1 0 0 1 sunrise: 00:03:40 sunset: 24:03:40
2013  3 21 South_Pole           89 59 S   0  0 W 0          0 1 0 0 sunrise: 12:07:07 sunset: 12:07:07
2013  3 21 South_Pole           89 59 S   0  0 W 0          1 1 0 0 sunrise: 12:07:07 sunset: 12:07:07
2013  3 21 South_Pole           89 59 S   0  0 W -0.583     0 0 0 1 sunrise: 00:07:07 sunset: 24:07:07
2013  3 21 South_Pole           89 59 S   0  0 W -0.583     1 0 0 1 sunrise: 00:07:07 sunset: 24:07:07
2013  3 21 South_Pole           89 59 S   0  0 W -0.833     0 0 0 1 sunrise: 00:07:07 sunset: 24:07:07
2013  3 21 South_Pole           89 59 S   0  0 W -0.833     1 0 0 1 sunrise: 00:07:07 sunset: 24:07:07
2013  3 21 South_Pole           89 59 S   0  0 W -12        0 0 0 1 sunrise: 00:07:07 sunset: 24:07:07
2013  3 21 South_Pole           89 59 S   0  0 W -12        1 0 0 1 sunrise: 00:07:07 sunset: 24:07:07
2013  3 21 South_Pole           89 59 S   0  0 W -18        0 0 0 1 sunrise: 00:07:07 sunset: 24:07:07
2013  3 21 South_Pole           89 59 S   0  0 W -18        1 0 0 1 sunrise: 00:07:07 sunset: 24:07:07
2013  6 21 South_Pole           89 59 S   0  0 W 0          0 1 0 0 sunrise: 12:01:49 sunset: 12:01:49
2013  6 21 South_Pole           89 59 S   0  0 W 0          1 1 0 0 sunrise: 12:01:49 sunset: 12:01:49
2013  6 21 South_Pole           89 59 S   0  0 W -0.583     0 1 0 0 sunrise: 12:01:49 sunset: 12:01:49
2013  6 21 South_Pole           89 59 S   0  0 W -0.583     1 1 0 0 sunrise: 12:01:49 sunset: 12:01:49
2013  6 21 South_Pole           89 59 S   0  0 W -0.833     0 1 0 0 sunrise: 12:01:49 sunset: 12:01:49
2013  6 21 South_Pole           89 59 S   0  0 W -0.833     1 1 0 0 sunrise: 12:01:49 sunset: 12:01:49
2013  6 21 South_Pole           89 59 S   0  0 W -12        0 1 0 0 sunrise: 12:01:49 sunset: 12:01:49
2013  6 21 South_Pole           89 59 S   0  0 W -12        1 1 0 0 sunrise: 12:01:49 sunset: 12:01:49
2013  6 21 South_Pole           89 59 S   0  0 W -18        0 1 0 0 sunrise: 12:01:49 sunset: 12:01:49
2013  6 21 South_Pole           89 59 S   0  0 W -18        1 1 0 0 sunrise: 12:01:49 sunset: 12:01:49
2013  8 31 South_Pole           89 59 S   0  0 W 0          0 1 0 0 sunrise: 12:00:15 sunset: 12:00:15
2013  8 31 South_Pole           89 59 S   0  0 W 0          1 1 0 0 sunrise: 12:00:15 sunset: 12:00:15
2013  8 31 South_Pole           89 59 S   0  0 W -0.583     0 1 0 0 sunrise: 12:00:15 sunset: 12:00:15
2013  8 31 South_Pole           89 59 S   0  0 W -0.583     1 1 0 0 sunrise: 12:00:15 sunset: 12:00:15
2013  8 31 South_Pole           89 59 S   0  0 W -0.833     0 1 0 0 sunrise: 12:00:15 sunset: 12:00:15
2013  8 31 South_Pole           89 59 S   0  0 W -0.833     1 1 0 0 sunrise: 12:00:15 sunset: 12:00:15
2013  8 31 South_Pole           89 59 S   0  0 W -12        0 0 0 1 sunrise: 00:00:15 sunset: 24:00:15
2013  8 31 South_Pole           89 59 S   0  0 W -12        1 0 0 1 sunrise: 00:00:15 sunset: 24:00:15
2013  8 31 South_Pole           89 59 S   0  0 W -18        0 0 0 1 sunrise: 00:00:15 sunset: 24:00:15
2013  8 31 South_Pole           89 59 S   0  0 W -18        1 0 0 1 sunrise: 00:00:15 sunset: 24:00:15
2013  9 21 South_Pole           89 59 S   0  0 W 0          0 1 0 0 sunrise: 11:53:00 sunset: 11:53:00
2013  9 21 South_Pole           89 59 S   0  0 W 0          1 1 0 0 sunrise: 11:53:00 sunset: 11:53:00
2013  9 21 South_Pole           89 59 S   0  0 W -0.583     0 0 0 1 sunrise: -1:53:00 sunset: 23:53:00
2013  9 21 South_Pole           89 59 S   0  0 W -0.583     1 0 0 1 sunrise: -1:53:00 sunset: 23:53:00
2013  9 21 South_Pole           89 59 S   0  0 W -0.833     0 0 0 1 sunrise: -1:53:00 sunset: 23:53:00
2013  9 21 South_Pole           89 59 S   0  0 W -0.833     1 0 0 1 sunrise: -1:53:00 sunset: 23:53:00
2013  9 21 South_Pole           89 59 S   0  0 W -12        0 0 0 1 sunrise: -1:53:00 sunset: 23:53:00
2013  9 21 South_Pole           89 59 S   0  0 W -12        1 0 0 1 sunrise: -1:53:00 sunset: 23:53:00
2013  9 21 South_Pole           89 59 S   0  0 W -18        0 0 0 1 sunrise: -1:53:00 sunset: 23:53:00
2013  9 21 South_Pole           89 59 S   0  0 W -18        1 0 0 1 sunrise: -1:53:00 sunset: 23:53:00
2013 12 31 South_Pole           89 59 S   0  0 W 0          0 0 0 1 sunrise: 00:03:05 sunset: 24:03:05
2013 12 31 South_Pole           89 59 S   0  0 W 0          1 0 0 1 sunrise: 00:03:05 sunset: 24:03:05
2013 12 31 South_Pole           89 59 S   0  0 W -0.583     0 0 0 1 sunrise: 00:03:05 sunset: 24:03:05
2013 12 31 South_Pole           89 59 S   0  0 W -0.583     1 0 0 1 sunrise: 00:03:05 sunset: 24:03:05
2013 12 31 South_Pole           89 59 S   0  0 W -0.833     0 0 0 1 sunrise: 00:03:05 sunset: 24:03:05
2013 12 31 South_Pole           89 59 S   0  0 W -0.833     1 0 0 1 sunrise: 00:03:05 sunset: 24:03:05
2013 12 31 South_Pole           89 59 S   0  0 W -12        0 0 0 1 sunrise: 00:03:05 sunset: 24:03:05
2013 12 31 South_Pole           89 59 S   0  0 W -12        1 0 0 1 sunrise: 00:03:05 sunset: 24:03:05
2013 12 31 South_Pole           89 59 S   0  0 W -18        0 0 0 1 sunrise: 00:03:05 sunset: 24:03:05
2013 12 31 South_Pole           89 59 S   0  0 W -18        1 0 0 1 sunrise: 00:03:05 sunset: 24:03:05
DATA
}
