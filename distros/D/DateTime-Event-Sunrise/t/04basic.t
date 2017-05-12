# -*- encoding: utf-8; indent-tabs-mode: nil -*-
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
use DateTime::Duration;
use DateTime::Event::Sunrise;

my @data = data();
plan tests => 2 * @data;
my $fudge = 2;

for  (@data) {
    my ($yyyy, $mm, $dd, $city, $ltd, $ltm, $ltc,  $lgd, $lgm, $lgc, $altitude, $upper_limb, $result)
         = $_ =~ /^(\d{4})\s+(\d\d?)\s+(\d\d?)
                   \s+(\w+)
                   \s+(\d+)\s+(\d+)\s+(\w)
                   \s+(\d+)\s+(\d+)\s+(\w)
                   \s+([-.0-9]+)
                   \s+([01])
                   \s+(.*)$/x;

    my ($lat, $long, $offset, $expected_rise_low, $expected_rise_high, $expected_set_low, $expected_set_high);
    if ($result =~ /sunrise: (\d\d):(\d\d):(\d\d)\s+sunset:\s+(\d\d):(\d\d):(\d\d)/) {
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
    elsif ( $long > 0 ) {
        $offset = DateTime::TimeZone::offset_as_string( floor( $long / 15 ) * 60 * 60 );
    }

    my $sunrise = DateTime::Event::Sunrise->new(
                longitude  => $long,
                latitude   => $lat,
                altitude   => $altitude,
                upper_limb => $upper_limb,
    );

    #my $dt = DateTime->new(year => $yyyy, month => $mm, day => $dd, time_zone => $offset);
    my $dt = DateTime->new(year => $yyyy, month => $mm, day => $dd);
    my $tmp_rise = $sunrise->sunrise_datetime($dt);
    my $tmp_set  = $sunrise->sunset_datetime ($dt);

    my $sun_rise = $tmp_rise->strftime("%H:%M");
    my $sun_set  = $tmp_set->strftime("%H:%M");

    ok( $tmp_rise >= $expected_rise_low && $tmp_rise <= $expected_rise_high, join ' ', "Sunrise for $city", $tmp_rise->ymd, $expected_rise_low->hms, $tmp_rise->hms, $expected_rise_high->hms, $upper_limb, $altitude);
    ok( $tmp_set  >= $expected_set_low  && $tmp_set  <= $expected_set_high,  join ' ', "Sunset  for $city", $tmp_set->ymd, $expected_set_low->hms, $tmp_set->hms, $expected_set_high->hms, $upper_limb, $altitude);

}

#
# The data below have been prepared by a C program which includes
# Paul Schlyter's code. Therefore, what is tested is the compatibility
# of the Perl code with the C code.
#
# See how this C program is generated in
# https://github.com/jforget/Astro-Sunrise/blob/master/util/mktest-04
#
# Why those locations?
# Greenwich because it is located on the eponymous prime meridian
# Reykjavik, because it is close to the Northern Arctic Circle, so it can be used to check polar night and midnight sun
# Quito because it is near the prime parallel, better known as "equator"
# El Hierro, because it is located on a former prime meridian
#
sub data {
  return split "\n", <<'DATA';
2013  1  1 Greenwich            51 28 N   0  0 E 10         0 sunrise: 09:50:02 sunset: 14:17:18
2013  1  1 Greenwich            51 28 N   0  0 E 10         1 sunrise: 09:46:41 sunset: 14:20:39
2013  1  1 Greenwich            51 28 N   0  0 E 0          0 sunrise: 08:12:14 sunset: 15:55:06
2013  1  1 Greenwich            51 28 N   0  0 E 0          1 sunrise: 08:10:00 sunset: 15:57:19
2013  1  1 Greenwich            51 28 N   0  0 E -0.583     0 sunrise: 08:07:28 sunset: 15:59:52
2013  1  1 Greenwich            51 28 N   0  0 E -0.583     1 sunrise: 08:05:16 sunset: 16:02:04
2013  1  1 Greenwich            51 28 N   0  0 E -0.833     0 sunrise: 08:05:26 sunset: 16:01:54
2013  1  1 Greenwich            51 28 N   0  0 E -0.833     1 sunrise: 08:03:15 sunset: 16:04:05
2013  1  1 Greenwich            51 28 N   0  0 E -12        0 sunrise: 06:42:43 sunset: 17:24:37
2013  1  1 Greenwich            51 28 N   0  0 E -12        1 sunrise: 06:40:50 sunset: 17:26:29
2013  1  1 Greenwich            51 28 N   0  0 E -18        0 sunrise: 06:02:08 sunset: 18:05:12
2013  1  1 Greenwich            51 28 N   0  0 E -18        1 sunrise: 06:00:20 sunset: 18:07:00
2013  1  1 Reykjavik            64  4 N  21 58 W 10         0 sunrise: 13:31:34 sunset: 13:31:34 polar night or midnight sun
2013  1  1 Reykjavik            64  4 N  21 58 W 10         1 sunrise: 13:31:34 sunset: 13:31:34 polar night or midnight sun
2013  1  1 Reykjavik            64  4 N  21 58 W 0          0 sunrise: 11:33:53 sunset: 15:29:14
2013  1  1 Reykjavik            64  4 N  21 58 W 0          1 sunrise: 11:28:31 sunset: 15:34:36
2013  1  1 Reykjavik            64  4 N  21 58 W -0.583     0 sunrise: 11:22:35 sunset: 15:40:32
2013  1  1 Reykjavik            64  4 N  21 58 W -0.583     1 sunrise: 11:17:37 sunset: 15:45:30
2013  1  1 Reykjavik            64  4 N  21 58 W -0.833     0 sunrise: 11:18:00 sunset: 15:45:07
2013  1  1 Reykjavik            64  4 N  21 58 W -0.833     1 sunrise: 11:13:11 sunset: 15:49:56
2013  1  1 Reykjavik            64  4 N  21 58 W -12        0 sunrise: 08:54:40 sunset: 18:08:27
2013  1  1 Reykjavik            64  4 N  21 58 W -12        1 sunrise: 08:51:52 sunset: 18:11:16
2013  1  1 Reykjavik            64  4 N  21 58 W -18        0 sunrise: 07:55:22 sunset: 19:07:46
2013  1  1 Reykjavik            64  4 N  21 58 W -18        1 sunrise: 07:52:47 sunset: 19:10:20
2013  1  1 Quito                 0 15 S  78 35 W 10         0 sunrise: 12:01:09 sunset: 22:35:03
2013  1  1 Quito                 0 15 S  78 35 W 10         1 sunrise: 11:59:58 sunset: 22:36:14
2013  1  1 Quito                 0 15 S  78 35 W 0          0 sunrise: 11:17:41 sunset: 23:18:31
2013  1  1 Quito                 0 15 S  78 35 W 0          1 sunrise: 11:16:30 sunset: 23:19:42
2013  1  1 Quito                 0 15 S  78 35 W -0.583     0 sunrise: 11:15:09 sunset: 23:21:03
2013  1  1 Quito                 0 15 S  78 35 W -0.583     1 sunrise: 11:13:58 sunset: 23:22:14
2013  1  1 Quito                 0 15 S  78 35 W -0.833     0 sunrise: 11:14:03 sunset: 23:22:08
2013  1  1 Quito                 0 15 S  78 35 W -0.833     1 sunrise: 11:12:53 sunset: 23:23:19
2013  1  1 Quito                 0 15 S  78 35 W -12        0 sunrise: 10:25:28 sunset: 24:10:44
2013  1  1 Quito                 0 15 S  78 35 W -12        1 sunrise: 10:24:17 sunset: 24:11:55
2013  1  1 Quito                 0 15 S  78 35 W -18        0 sunrise: 09:59:13 sunset: 24:36:59
2013  1  1 Quito                 0 15 S  78 35 W -18        1 sunrise: 09:58:02 sunset: 24:38:10
2013  1  1 El_Hierro            27 44 N  18  3 W 10         0 sunrise: 08:59:14 sunset: 17:32:33
2013  1  1 El_Hierro            27 44 N  18  3 W 10         1 sunrise: 08:57:46 sunset: 17:34:00
2013  1  1 El_Hierro            27 44 N  18  3 W 0          0 sunrise: 08:07:22 sunset: 18:24:25
2013  1  1 El_Hierro            27 44 N  18  3 W 0          1 sunrise: 08:06:00 sunset: 18:25:47
2013  1  1 El_Hierro            27 44 N  18  3 W -0.583     0 sunrise: 08:04:26 sunset: 18:27:21
2013  1  1 El_Hierro            27 44 N  18  3 W -0.583     1 sunrise: 08:03:04 sunset: 18:28:42
2013  1  1 El_Hierro            27 44 N  18  3 W -0.833     0 sunrise: 08:03:11 sunset: 18:28:36
2013  1  1 El_Hierro            27 44 N  18  3 W -0.833     1 sunrise: 08:01:49 sunset: 18:29:58
2013  1  1 El_Hierro            27 44 N  18  3 W -12        0 sunrise: 07:08:28 sunset: 19:23:19
2013  1  1 El_Hierro            27 44 N  18  3 W -12        1 sunrise: 07:07:10 sunset: 19:24:37
2013  1  1 El_Hierro            27 44 N  18  3 W -18        0 sunrise: 06:39:53 sunset: 19:51:53
2013  1  1 El_Hierro            27 44 N  18  3 W -18        1 sunrise: 06:38:36 sunset: 19:53:10
2013  3 21 Greenwich            51 28 N   0  0 E 10         0 sunrise: 07:09:42 sunset: 17:04:32
2013  3 21 Greenwich            51 28 N   0  0 E 10         1 sunrise: 07:07:57 sunset: 17:06:17
2013  3 21 Greenwich            51 28 N   0  0 E 0          0 sunrise: 06:05:03 sunset: 18:09:11
2013  3 21 Greenwich            51 28 N   0  0 E 0          1 sunrise: 06:03:19 sunset: 18:10:54
2013  3 21 Greenwich            51 28 N   0  0 E -0.583     0 sunrise: 06:01:18 sunset: 18:12:56
2013  3 21 Greenwich            51 28 N   0  0 E -0.583     1 sunrise: 05:59:35 sunset: 18:14:39
2013  3 21 Greenwich            51 28 N   0  0 E -0.833     0 sunrise: 05:59:42 sunset: 18:14:32
2013  3 21 Greenwich            51 28 N   0  0 E -0.833     1 sunrise: 05:57:58 sunset: 18:16:15
2013  3 21 Greenwich            51 28 N   0  0 E -12        0 sunrise: 04:46:55 sunset: 19:27:18
2013  3 21 Greenwich            51 28 N   0  0 E -12        1 sunrise: 04:45:08 sunset: 19:29:06
2013  3 21 Greenwich            51 28 N   0  0 E -18        0 sunrise: 04:05:46 sunset: 20:08:28
2013  3 21 Greenwich            51 28 N   0  0 E -18        1 sunrise: 04:03:52 sunset: 20:10:22
2013  3 21 Reykjavik            64  4 N  21 58 W 10         0 sunrise: 09:04:39 sunset: 18:05:17
2013  3 21 Reykjavik            64  4 N  21 58 W 10         1 sunrise: 09:02:03 sunset: 18:07:53
2013  3 21 Reykjavik            64  4 N  21 58 W 0          0 sunrise: 07:31:22 sunset: 19:38:33
2013  3 21 Reykjavik            64  4 N  21 58 W 0          1 sunrise: 07:28:55 sunset: 19:41:00
2013  3 21 Reykjavik            64  4 N  21 58 W -0.583     0 sunrise: 07:26:02 sunset: 19:43:54
2013  3 21 Reykjavik            64  4 N  21 58 W -0.583     1 sunrise: 07:23:35 sunset: 19:46:21
2013  3 21 Reykjavik            64  4 N  21 58 W -0.833     0 sunrise: 07:23:45 sunset: 19:46:11
2013  3 21 Reykjavik            64  4 N  21 58 W -0.833     1 sunrise: 07:21:18 sunset: 19:48:38
2013  3 21 Reykjavik            64  4 N  21 58 W -12        0 sunrise: 05:37:19 sunset: 21:32:37
2013  3 21 Reykjavik            64  4 N  21 58 W -12        1 sunrise: 05:34:33 sunset: 21:35:23
2013  3 21 Reykjavik            64  4 N  21 58 W -18        0 sunrise: 04:29:59 sunset: 22:39:57
2013  3 21 Reykjavik            64  4 N  21 58 W -18        1 sunrise: 04:26:35 sunset: 22:43:20
2013  3 21 Quito                 0 15 S  78 35 W 10         0 sunrise: 12:01:24 sunset: 22:41:22
2013  3 21 Quito                 0 15 S  78 35 W 10         1 sunrise: 12:00:19 sunset: 22:42:26
2013  3 21 Quito                 0 15 S  78 35 W 0          0 sunrise: 11:21:23 sunset: 23:21:22
2013  3 21 Quito                 0 15 S  78 35 W 0          1 sunrise: 11:20:19 sunset: 23:22:27
2013  3 21 Quito                 0 15 S  78 35 W -0.583     0 sunrise: 11:19:04 sunset: 23:23:42
2013  3 21 Quito                 0 15 S  78 35 W -0.583     1 sunrise: 11:17:59 sunset: 23:24:47
2013  3 21 Quito                 0 15 S  78 35 W -0.833     0 sunrise: 11:18:04 sunset: 23:24:42
2013  3 21 Quito                 0 15 S  78 35 W -0.833     1 sunrise: 11:16:59 sunset: 23:25:47
2013  3 21 Quito                 0 15 S  78 35 W -12        0 sunrise: 10:33:23 sunset: 24:09:23
2013  3 21 Quito                 0 15 S  78 35 W -12        1 sunrise: 10:32:19 sunset: 24:10:27
2013  3 21 Quito                 0 15 S  78 35 W -18        0 sunrise: 10:09:23 sunset: 24:33:23
2013  3 21 Quito                 0 15 S  78 35 W -18        1 sunrise: 10:08:19 sunset: 24:34:27
2013  3 21 El_Hierro            27 44 N  18  3 W 10         0 sunrise: 08:03:38 sunset: 18:34:58
2013  3 21 El_Hierro            27 44 N  18  3 W 10         1 sunrise: 08:02:25 sunset: 18:36:11
2013  3 21 El_Hierro            27 44 N  18  3 W 0          0 sunrise: 07:18:23 sunset: 19:20:13
2013  3 21 El_Hierro            27 44 N  18  3 W 0          1 sunrise: 07:17:11 sunset: 19:21:25
2013  3 21 El_Hierro            27 44 N  18  3 W -0.583     0 sunrise: 07:15:45 sunset: 19:22:51
2013  3 21 El_Hierro            27 44 N  18  3 W -0.583     1 sunrise: 07:14:33 sunset: 19:24:03
2013  3 21 El_Hierro            27 44 N  18  3 W -0.833     0 sunrise: 07:14:38 sunset: 19:23:58
2013  3 21 El_Hierro            27 44 N  18  3 W -0.833     1 sunrise: 07:13:25 sunset: 19:25:11
2013  3 21 El_Hierro            27 44 N  18  3 W -12        0 sunrise: 06:24:01 sunset: 20:14:35
2013  3 21 El_Hierro            27 44 N  18  3 W -12        1 sunrise: 06:22:48 sunset: 20:15:48
2013  3 21 El_Hierro            27 44 N  18  3 W -18        0 sunrise: 05:56:35 sunset: 20:42:01
2013  3 21 El_Hierro            27 44 N  18  3 W -18        1 sunrise: 05:55:22 sunset: 20:43:14
2013  6 21 Greenwich            51 28 N   0  0 E 10         0 sunrise: 05:06:09 sunset: 18:57:30
2013  6 21 Greenwich            51 28 N   0  0 E 10         1 sunrise: 05:04:17 sunset: 18:59:22
2013  6 21 Greenwich            51 28 N   0  0 E 0          0 sunrise: 03:49:54 sunset: 20:13:45
2013  6 21 Greenwich            51 28 N   0  0 E 0          1 sunrise: 03:47:42 sunset: 20:15:56
2013  6 21 Greenwich            51 28 N   0  0 E -0.583     0 sunrise: 03:45:00 sunset: 20:18:39
2013  6 21 Greenwich            51 28 N   0  0 E -0.583     1 sunrise: 03:42:47 sunset: 20:20:52
2013  6 21 Greenwich            51 28 N   0  0 E -0.833     0 sunrise: 03:42:53 sunset: 20:20:46
2013  6 21 Greenwich            51 28 N   0  0 E -0.833     1 sunrise: 03:40:38 sunset: 20:23:00
2013  6 21 Greenwich            51 28 N   0  0 E -12        0 sunrise: 01:40:50 sunset: 22:22:48
2013  6 21 Greenwich            51 28 N   0  0 E -12        1 sunrise: 01:36:28 sunset: 22:27:11
2013  6 21 Greenwich            51 28 N   0  0 E -18        0 sunrise: 00:01:49 sunset: 24:01:49 polar night or midnight sun
2013  6 21 Greenwich            51 28 N   0  0 E -18        1 sunrise: 00:01:49 sunset: 24:01:49 polar night or midnight sun
2013  6 21 Reykjavik            64  4 N  21 58 W 10         0 sunrise: 05:40:30 sunset: 21:18:55
2013  6 21 Reykjavik            64  4 N  21 58 W 10         1 sunrise: 05:37:35 sunset: 21:21:49
2013  6 21 Reykjavik            64  4 N  21 58 W 0          0 sunrise: 03:17:28 sunset: 23:41:56
2013  6 21 Reykjavik            64  4 N  21 58 W 0          1 sunrise: 03:11:33 sunset: 23:47:52
2013  6 21 Reykjavik            64  4 N  21 58 W -0.583     0 sunrise: 03:03:50 sunset: 23:55:34
2013  6 21 Reykjavik            64  4 N  21 58 W -0.583     1 sunrise: 02:57:03 sunset: 24:02:21
2013  6 21 Reykjavik            64  4 N  21 58 W -0.833     0 sunrise: 02:57:23 sunset: 24:02:01
2013  6 21 Reykjavik            64  4 N  21 58 W -0.833     1 sunrise: 02:50:06 sunset: 24:09:19
2013  6 21 Reykjavik            64  4 N  21 58 W -12        0 sunrise: 01:29:42 sunset: 25:29:42 polar night or midnight sun
2013  6 21 Reykjavik            64  4 N  21 58 W -12        1 sunrise: 01:29:42 sunset: 25:29:42 polar night or midnight sun
2013  6 21 Reykjavik            64  4 N  21 58 W -18        0 sunrise: 01:29:42 sunset: 25:29:42 polar night or midnight sun
2013  6 21 Reykjavik            64  4 N  21 58 W -18        1 sunrise: 01:29:42 sunset: 25:29:42 polar night or midnight sun
2013  6 21 Quito                 0 15 S  78 35 W 10         0 sunrise: 12:00:17 sunset: 22:32:07
2013  6 21 Quito                 0 15 S  78 35 W 10         1 sunrise: 11:59:08 sunset: 22:33:16
2013  6 21 Quito                 0 15 S  78 35 W 0          0 sunrise: 11:16:38 sunset: 23:15:46
2013  6 21 Quito                 0 15 S  78 35 W 0          1 sunrise: 11:15:29 sunset: 23:16:55
2013  6 21 Quito                 0 15 S  78 35 W -0.583     0 sunrise: 11:14:06 sunset: 23:18:19
2013  6 21 Quito                 0 15 S  78 35 W -0.583     1 sunrise: 11:12:57 sunset: 23:19:27
2013  6 21 Quito                 0 15 S  78 35 W -0.833     0 sunrise: 11:13:00 sunset: 23:19:24
2013  6 21 Quito                 0 15 S  78 35 W -0.833     1 sunrise: 11:11:52 sunset: 23:20:33
2013  6 21 Quito                 0 15 S  78 35 W -12        0 sunrise: 10:24:15 sunset: 24:08:09
2013  6 21 Quito                 0 15 S  78 35 W -12        1 sunrise: 10:23:07 sunset: 24:09:18
2013  6 21 Quito                 0 15 S  78 35 W -18        0 sunrise: 09:57:56 sunset: 24:34:28
2013  6 21 Quito                 0 15 S  78 35 W -18        1 sunrise: 09:56:47 sunset: 24:35:38
2013  6 21 El_Hierro            27 44 N  18  3 W 10         0 sunrise: 07:10:48 sunset: 19:17:16
2013  6 21 El_Hierro            27 44 N  18  3 W 10         1 sunrise: 07:09:32 sunset: 19:18:32
2013  6 21 El_Hierro            27 44 N  18  3 W 0          0 sunrise: 06:21:20 sunset: 20:06:44
2013  6 21 El_Hierro            27 44 N  18  3 W 0          1 sunrise: 06:20:00 sunset: 20:08:04
2013  6 21 El_Hierro            27 44 N  18  3 W -0.583     0 sunrise: 06:18:23 sunset: 20:09:41
2013  6 21 El_Hierro            27 44 N  18  3 W -0.583     1 sunrise: 06:17:03 sunset: 20:11:01
2013  6 21 El_Hierro            27 44 N  18  3 W -0.833     0 sunrise: 06:17:07 sunset: 20:10:57
2013  6 21 El_Hierro            27 44 N  18  3 W -0.833     1 sunrise: 06:15:47 sunset: 20:12:17
2013  6 21 El_Hierro            27 44 N  18  3 W -12        0 sunrise: 05:18:16 sunset: 21:09:48
2013  6 21 El_Hierro            27 44 N  18  3 W -12        1 sunrise: 05:16:49 sunset: 21:11:15
2013  6 21 El_Hierro            27 44 N  18  3 W -18        0 sunrise: 04:44:08 sunset: 21:43:56
2013  6 21 El_Hierro            27 44 N  18  3 W -18        1 sunrise: 04:42:35 sunset: 21:45:29
2013  8 31 Greenwich            51 28 N   0  0 E 10         0 sunrise: 06:21:59 sunset: 17:38:31
2013  8 31 Greenwich            51 28 N   0  0 E 10         1 sunrise: 06:20:18 sunset: 17:40:12
2013  8 31 Greenwich            51 28 N   0  0 E 0          0 sunrise: 05:17:07 sunset: 18:43:23
2013  8 31 Greenwich            51 28 N   0  0 E 0          1 sunrise: 05:15:22 sunset: 18:45:08
2013  8 31 Greenwich            51 28 N   0  0 E -0.583     0 sunrise: 05:13:15 sunset: 18:47:15
2013  8 31 Greenwich            51 28 N   0  0 E -0.583     1 sunrise: 05:11:30 sunset: 18:49:00
2013  8 31 Greenwich            51 28 N   0  0 E -0.833     0 sunrise: 05:11:36 sunset: 18:48:54
2013  8 31 Greenwich            51 28 N   0  0 E -0.833     1 sunrise: 05:09:50 sunset: 18:50:40
2013  8 31 Greenwich            51 28 N   0  0 E -12        0 sunrise: 03:53:42 sunset: 20:06:48
2013  8 31 Greenwich            51 28 N   0  0 E -12        1 sunrise: 03:51:44 sunset: 20:08:46
2013  8 31 Greenwich            51 28 N   0  0 E -18        0 sunrise: 03:06:10 sunset: 20:54:20
2013  8 31 Greenwich            51 28 N   0  0 E -18        1 sunrise: 03:03:54 sunset: 20:56:36
2013  8 31 Reykjavik            64  4 N  21 58 W 10         0 sunrise: 07:50:06 sunset: 19:06:06
2013  8 31 Reykjavik            64  4 N  21 58 W 10         1 sunrise: 07:47:41 sunset: 19:08:31
2013  8 31 Reykjavik            64  4 N  21 58 W 0          0 sunrise: 06:16:55 sunset: 20:39:17
2013  8 31 Reykjavik            64  4 N  21 58 W 0          1 sunrise: 06:14:21 sunset: 20:41:51
2013  8 31 Reykjavik            64  4 N  21 58 W -0.583     0 sunrise: 06:11:14 sunset: 20:44:58
2013  8 31 Reykjavik            64  4 N  21 58 W -0.583     1 sunrise: 06:08:39 sunset: 20:47:33
2013  8 31 Reykjavik            64  4 N  21 58 W -0.833     0 sunrise: 06:08:47 sunset: 20:47:25
2013  8 31 Reykjavik            64  4 N  21 58 W -0.833     1 sunrise: 06:06:11 sunset: 20:50:01
2013  8 31 Reykjavik            64  4 N  21 58 W -12        0 sunrise: 04:00:45 sunset: 22:55:27
2013  8 31 Reykjavik            64  4 N  21 58 W -12        1 sunrise: 03:56:51 sunset: 22:59:21
2013  8 31 Reykjavik            64  4 N  21 58 W -18        0 sunrise: 01:28:06 sunset: 25:28:06 polar night or midnight sun
2013  8 31 Reykjavik            64  4 N  21 58 W -18        1 sunrise: 01:28:06 sunset: 25:28:06 polar night or midnight sun
2013  8 31 Quito                 0 15 S  78 35 W 10         0 sunrise: 11:55:06 sunset: 22:33:55
2013  8 31 Quito                 0 15 S  78 35 W 10         1 sunrise: 11:54:02 sunset: 22:35:00
2013  8 31 Quito                 0 15 S  78 35 W 0          0 sunrise: 11:14:40 sunset: 23:14:22
2013  8 31 Quito                 0 15 S  78 35 W 0          1 sunrise: 11:13:36 sunset: 23:15:26
2013  8 31 Quito                 0 15 S  78 35 W -0.583     0 sunrise: 11:12:18 sunset: 23:16:43
2013  8 31 Quito                 0 15 S  78 35 W -0.583     1 sunrise: 11:11:14 sunset: 23:17:47
2013  8 31 Quito                 0 15 S  78 35 W -0.833     0 sunrise: 11:11:18 sunset: 23:17:44
2013  8 31 Quito                 0 15 S  78 35 W -0.833     1 sunrise: 11:10:13 sunset: 23:18:48
2013  8 31 Quito                 0 15 S  78 35 W -12        0 sunrise: 10:26:08 sunset: 24:02:53
2013  8 31 Quito                 0 15 S  78 35 W -12        1 sunrise: 10:25:04 sunset: 24:03:58
2013  8 31 Quito                 0 15 S  78 35 W -18        0 sunrise: 10:01:52 sunset: 24:27:10
2013  8 31 Quito                 0 15 S  78 35 W -18        1 sunrise: 10:00:47 sunset: 24:28:14
2013  8 31 El_Hierro            27 44 N  18  3 W 10         0 sunrise: 07:40:03 sunset: 18:44:50
2013  8 31 El_Hierro            27 44 N  18  3 W 10         1 sunrise: 07:38:51 sunset: 18:46:01
2013  8 31 El_Hierro            27 44 N  18  3 W 0          0 sunrise: 06:54:30 sunset: 19:30:22
2013  8 31 El_Hierro            27 44 N  18  3 W 0          1 sunrise: 06:53:17 sunset: 19:31:35
2013  8 31 El_Hierro            27 44 N  18  3 W -0.583     0 sunrise: 06:51:50 sunset: 19:33:02
2013  8 31 El_Hierro            27 44 N  18  3 W -0.583     1 sunrise: 06:50:37 sunset: 19:34:15
2013  8 31 El_Hierro            27 44 N  18  3 W -0.833     0 sunrise: 06:50:41 sunset: 19:34:11
2013  8 31 El_Hierro            27 44 N  18  3 W -0.833     1 sunrise: 06:49:28 sunset: 19:35:24
2013  8 31 El_Hierro            27 44 N  18  3 W -12        0 sunrise: 05:58:50 sunset: 20:26:02
2013  8 31 El_Hierro            27 44 N  18  3 W -12        1 sunrise: 05:57:35 sunset: 20:27:17
2013  8 31 El_Hierro            27 44 N  18  3 W -18        0 sunrise: 05:30:17 sunset: 20:54:35
2013  8 31 El_Hierro            27 44 N  18  3 W -18        1 sunrise: 05:29:00 sunset: 20:55:52
2013  9 21 Greenwich            51 28 N   0  0 E 10         0 sunrise: 06:54:59 sunset: 16:51:01
2013  9 21 Greenwich            51 28 N   0  0 E 10         1 sunrise: 06:53:14 sunset: 16:52:45
2013  9 21 Greenwich            51 28 N   0  0 E 0          0 sunrise: 05:50:20 sunset: 17:55:39
2013  9 21 Greenwich            51 28 N   0  0 E 0          1 sunrise: 05:48:38 sunset: 17:57:21
2013  9 21 Greenwich            51 28 N   0  0 E -0.583     0 sunrise: 05:46:36 sunset: 17:59:24
2013  9 21 Greenwich            51 28 N   0  0 E -0.583     1 sunrise: 05:44:53 sunset: 18:01:06
2013  9 21 Greenwich            51 28 N   0  0 E -0.833     0 sunrise: 05:44:59 sunset: 18:01:00
2013  9 21 Greenwich            51 28 N   0  0 E -0.833     1 sunrise: 05:43:17 sunset: 18:02:42
2013  9 21 Greenwich            51 28 N   0  0 E -12        0 sunrise: 04:32:11 sunset: 19:13:48
2013  9 21 Greenwich            51 28 N   0  0 E -12        1 sunrise: 04:30:24 sunset: 19:15:35
2013  9 21 Greenwich            51 28 N   0  0 E -18        0 sunrise: 03:50:58 sunset: 19:55:01
2013  9 21 Greenwich            51 28 N   0  0 E -18        1 sunrise: 03:49:05 sunset: 19:56:54
2013  9 21 Reykjavik            64  4 N  21 58 W 10         0 sunrise: 08:49:55 sunset: 17:51:46
2013  9 21 Reykjavik            64  4 N  21 58 W 10         1 sunrise: 08:47:21 sunset: 17:54:20
2013  9 21 Reykjavik            64  4 N  21 58 W 0          0 sunrise: 07:16:41 sunset: 19:25:00
2013  9 21 Reykjavik            64  4 N  21 58 W 0          1 sunrise: 07:14:16 sunset: 19:27:25
2013  9 21 Reykjavik            64  4 N  21 58 W -0.583     0 sunrise: 07:11:21 sunset: 19:30:20
2013  9 21 Reykjavik            64  4 N  21 58 W -0.583     1 sunrise: 07:08:55 sunset: 19:32:46
2013  9 21 Reykjavik            64  4 N  21 58 W -0.833     0 sunrise: 07:09:04 sunset: 19:32:37
2013  9 21 Reykjavik            64  4 N  21 58 W -0.833     1 sunrise: 07:06:38 sunset: 19:35:03
2013  9 21 Reykjavik            64  4 N  21 58 W -12        0 sunrise: 05:22:33 sunset: 21:19:08
2013  9 21 Reykjavik            64  4 N  21 58 W -12        1 sunrise: 05:19:48 sunset: 21:21:53
2013  9 21 Reykjavik            64  4 N  21 58 W -18        0 sunrise: 04:15:03 sunset: 22:26:38
2013  9 21 Reykjavik            64  4 N  21 58 W -18        1 sunrise: 04:11:40 sunset: 22:30:01
2013  9 21 Quito                 0 15 S  78 35 W 10         0 sunrise: 11:47:16 sunset: 22:27:14
2013  9 21 Quito                 0 15 S  78 35 W 10         1 sunrise: 11:46:12 sunset: 22:28:18
2013  9 21 Quito                 0 15 S  78 35 W 0          0 sunrise: 11:07:15 sunset: 23:07:14
2013  9 21 Quito                 0 15 S  78 35 W 0          1 sunrise: 11:06:12 sunset: 23:08:18
2013  9 21 Quito                 0 15 S  78 35 W -0.583     0 sunrise: 11:04:55 sunset: 23:09:34
2013  9 21 Quito                 0 15 S  78 35 W -0.583     1 sunrise: 11:03:52 sunset: 23:10:38
2013  9 21 Quito                 0 15 S  78 35 W -0.833     0 sunrise: 11:03:55 sunset: 23:10:34
2013  9 21 Quito                 0 15 S  78 35 W -0.833     1 sunrise: 11:02:52 sunset: 23:11:38
2013  9 21 Quito                 0 15 S  78 35 W -12        0 sunrise: 10:19:15 sunset: 23:55:15
2013  9 21 Quito                 0 15 S  78 35 W -12        1 sunrise: 10:18:12 sunset: 23:56:18
2013  9 21 Quito                 0 15 S  78 35 W -18        0 sunrise: 09:55:15 sunset: 24:19:15
2013  9 21 Quito                 0 15 S  78 35 W -18        1 sunrise: 09:54:12 sunset: 24:20:18
2013  9 21 El_Hierro            27 44 N  18  3 W 10         0 sunrise: 07:49:21 sunset: 18:21:01
2013  9 21 El_Hierro            27 44 N  18  3 W 10         1 sunrise: 07:48:08 sunset: 18:22:13
2013  9 21 El_Hierro            27 44 N  18  3 W 0          0 sunrise: 07:04:06 sunset: 19:06:15
2013  9 21 El_Hierro            27 44 N  18  3 W 0          1 sunrise: 07:02:54 sunset: 19:07:27
2013  9 21 El_Hierro            27 44 N  18  3 W -0.583     0 sunrise: 07:01:28 sunset: 19:08:53
2013  9 21 El_Hierro            27 44 N  18  3 W -0.583     1 sunrise: 07:00:16 sunset: 19:10:05
2013  9 21 El_Hierro            27 44 N  18  3 W -0.833     0 sunrise: 07:00:20 sunset: 19:10:01
2013  9 21 El_Hierro            27 44 N  18  3 W -0.833     1 sunrise: 06:59:08 sunset: 19:11:13
2013  9 21 El_Hierro            27 44 N  18  3 W -12        0 sunrise: 06:09:44 sunset: 20:00:37
2013  9 21 El_Hierro            27 44 N  18  3 W -12        1 sunrise: 06:08:31 sunset: 20:01:50
2013  9 21 El_Hierro            27 44 N  18  3 W -18        0 sunrise: 05:42:18 sunset: 20:28:03
2013  9 21 El_Hierro            27 44 N  18  3 W -18        1 sunrise: 05:41:04 sunset: 20:29:17
2013 12 31 Greenwich            51 28 N   0  0 E 10         0 sunrise: 09:50:37 sunset: 14:15:32
2013 12 31 Greenwich            51 28 N   0  0 E 10         1 sunrise: 09:47:15 sunset: 14:18:54
2013 12 31 Greenwich            51 28 N   0  0 E 0          0 sunrise: 08:12:21 sunset: 15:53:48
2013 12 31 Greenwich            51 28 N   0  0 E 0          1 sunrise: 08:10:07 sunset: 15:56:02
2013 12 31 Greenwich            51 28 N   0  0 E -0.583     0 sunrise: 08:07:34 sunset: 15:58:35
2013 12 31 Greenwich            51 28 N   0  0 E -0.583     1 sunrise: 08:05:22 sunset: 16:00:47
2013 12 31 Greenwich            51 28 N   0  0 E -0.833     0 sunrise: 08:05:32 sunset: 16:00:37
2013 12 31 Greenwich            51 28 N   0  0 E -0.833     1 sunrise: 08:03:20 sunset: 16:02:49
2013 12 31 Greenwich            51 28 N   0  0 E -12        0 sunrise: 06:42:40 sunset: 17:23:29
2013 12 31 Greenwich            51 28 N   0  0 E -12        1 sunrise: 06:40:47 sunset: 17:25:22
2013 12 31 Greenwich            51 28 N   0  0 E -18        0 sunrise: 06:02:03 sunset: 18:04:06
2013 12 31 Greenwich            51 28 N   0  0 E -18        1 sunrise: 06:00:15 sunset: 18:05:54
2013 12 31 Reykjavik            64  4 N  21 58 W 10         0 sunrise: 13:30:58 sunset: 13:30:58 polar night or midnight sun
2013 12 31 Reykjavik            64  4 N  21 58 W 10         1 sunrise: 13:30:58 sunset: 13:30:58 polar night or midnight sun
2013 12 31 Reykjavik            64  4 N  21 58 W 0          0 sunrise: 11:35:19 sunset: 15:26:38
2013 12 31 Reykjavik            64  4 N  21 58 W 0          1 sunrise: 11:29:51 sunset: 15:32:05
2013 12 31 Reykjavik            64  4 N  21 58 W -0.583     0 sunrise: 11:23:51 sunset: 15:38:06
2013 12 31 Reykjavik            64  4 N  21 58 W -0.583     1 sunrise: 11:18:49 sunset: 15:43:08
2013 12 31 Reykjavik            64  4 N  21 58 W -0.833     0 sunrise: 11:19:12 sunset: 15:42:45
2013 12 31 Reykjavik            64  4 N  21 58 W -0.833     1 sunrise: 11:14:19 sunset: 15:47:37
2013 12 31 Reykjavik            64  4 N  21 58 W -12        0 sunrise: 08:55:02 sunset: 18:06:54
2013 12 31 Reykjavik            64  4 N  21 58 W -12        1 sunrise: 08:52:13 sunset: 18:09:43
2013 12 31 Reykjavik            64  4 N  21 58 W -18        0 sunrise: 07:55:38 sunset: 19:06:19
2013 12 31 Reykjavik            64  4 N  21 58 W -18        1 sunrise: 07:53:03 sunset: 19:08:53
2013 12 31 Quito                 0 15 S  78 35 W 10         0 sunrise: 12:00:35 sunset: 22:34:26
2013 12 31 Quito                 0 15 S  78 35 W 10         1 sunrise: 11:59:24 sunset: 22:35:37
2013 12 31 Quito                 0 15 S  78 35 W 0          0 sunrise: 11:17:05 sunset: 23:17:56
2013 12 31 Quito                 0 15 S  78 35 W 0          1 sunrise: 11:15:54 sunset: 23:19:07
2013 12 31 Quito                 0 15 S  78 35 W -0.583     0 sunrise: 11:14:33 sunset: 23:20:28
2013 12 31 Quito                 0 15 S  78 35 W -0.583     1 sunrise: 11:13:22 sunset: 23:21:39
2013 12 31 Quito                 0 15 S  78 35 W -0.833     0 sunrise: 11:13:28 sunset: 23:21:33
2013 12 31 Quito                 0 15 S  78 35 W -0.833     1 sunrise: 11:12:17 sunset: 23:22:44
2013 12 31 Quito                 0 15 S  78 35 W -12        0 sunrise: 10:24:50 sunset: 24:10:11
2013 12 31 Quito                 0 15 S  78 35 W -12        1 sunrise: 10:23:39 sunset: 24:11:22
2013 12 31 Quito                 0 15 S  78 35 W -18        0 sunrise: 09:58:34 sunset: 24:36:27
2013 12 31 Quito                 0 15 S  78 35 W -18        1 sunrise: 09:57:23 sunset: 24:37:39
2013 12 31 El_Hierro            27 44 N  18  3 W 10         0 sunrise: 08:58:57 sunset: 17:31:39
2013 12 31 El_Hierro            27 44 N  18  3 W 10         1 sunrise: 08:57:30 sunset: 17:33:06
2013 12 31 El_Hierro            27 44 N  18  3 W 0          0 sunrise: 08:07:02 sunset: 18:23:34
2013 12 31 El_Hierro            27 44 N  18  3 W 0          1 sunrise: 08:05:40 sunset: 18:24:56
2013 12 31 El_Hierro            27 44 N  18  3 W -0.583     0 sunrise: 08:04:06 sunset: 18:26:30
2013 12 31 El_Hierro            27 44 N  18  3 W -0.583     1 sunrise: 08:02:44 sunset: 18:27:52
2013 12 31 El_Hierro            27 44 N  18  3 W -0.833     0 sunrise: 08:02:50 sunset: 18:27:45
2013 12 31 El_Hierro            27 44 N  18  3 W -0.833     1 sunrise: 08:01:29 sunset: 18:29:07
2013 12 31 El_Hierro            27 44 N  18  3 W -12        0 sunrise: 07:08:05 sunset: 19:22:31
2013 12 31 El_Hierro            27 44 N  18  3 W -12        1 sunrise: 07:06:47 sunset: 19:23:49
2013 12 31 El_Hierro            27 44 N  18  3 W -18        0 sunrise: 06:39:29 sunset: 19:51:07
2013 12 31 El_Hierro            27 44 N  18  3 W -18        1 sunrise: 06:38:12 sunset: 19:52:24
DATA
}
