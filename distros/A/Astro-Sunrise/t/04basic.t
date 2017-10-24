#!/usr/bin/perl
# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Test script for Astro::Sunrise
#     Copyright (C) 2015, 2017 Ron Hill and Jean Forget
#
#     This program is distributed under the same terms as Perl 5.16.3:
#     GNU Public License version 1 or later and Perl Artistic License
#
#     You can find the text of the licenses in the F<LICENSE> file or at
#     L<http://www.perlfoundation.org/artistic_license_1_0>
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
use warnings;
use POSIX qw(floor ceil);
use Astro::Sunrise;
use Test::More;

my @data = load_data();
plan(tests => 2 * @data); # I prefer having Perl counting my tests than myself

my ($long, $lat, $offset);
my $fudge = 0; # in minutes

for (@data) {
    my ($yyyy, $mm, $dd, $loc, $lat_d, $lat_m, $lat_x, $lon_d, $lon_m, $lon_x, $alt, $upper_limb, $expect_r, $expect_s)
       = $_ =~ /(\d+)\s+(\d+)\s+(\d+)     # date in YYYY MM DD format $1 $2 $3
               \s+(\w+)                   # location $4
               \s+(\d+)\s+(\d+)\s+(\w)    # latitude $5 $6 $7
               \s+(\d+)\s+(\d+)\s+(\w)    # longitude $8 $9 $10
               \s+(\S+)                   # altitude $11
               \s+(\d)                    # upper limb $12
               \s+sunrise:\s+(\d+:\d+)    # sunrise $13
               \s+sunset:\s+(\d+:\d+)/x;  # sunset $14
    if ( $lat_x eq 'N' ) {
      $lat = sprintf( "%.3f", ( $lat_d + ( $lat_m / 60 ) ) );
    }
    elsif ( $lat_x eq 'S' ) {
      $lat = sprintf( "%.3f", -( $lat_d + ( $lat_m / 60 ) ) );
    }

    if ( $lon_x eq 'E' ) {
      $long = sprintf( "%.3f", $lon_d + ( $lon_m / 60 ) );
    }
    elsif ( $lon_x eq 'W' ) {
      $long = sprintf( "%.3f", -( $lon_d + ( $lon_m / 60 ) ) );
    }

    if ($long < 0) {
      $offset = ceil( $long / 15 );
    }
    elsif ($long > 0) {
      $offset = floor( $long /15 );
    }
    else {
      $offset = 0;
    }

    my ( $sunrise, $sunset ) = sunrise( { year => $yyyy, month => $mm,  day => $dd,
                                          lon  => $long, lat   => $lat, tz  => $offset,
                                          alt  => $alt,  upper_limb => $upper_limb } );

    my $exp_h = fudge_h($expect_r, $fudge);
    my $exp_l = fudge_l($expect_r, $fudge);
    ok ($sunrise ge $exp_l && $sunrise le $exp_h
         , "Sunrise for $loc $yyyy-$mm-$dd  $alt $upper_limb $exp_l $sunrise $exp_h");
    $exp_h = fudge_h($expect_s, $fudge);
    $exp_l = fudge_l($expect_s, $fudge);
    ok ($sunset ge $exp_l && $sunset le $exp_h
         , "Sunset  for $loc $yyyy-$mm-$dd  $alt $upper_limb $exp_l $sunset $exp_h");

}

sub fudge_h {
  my ($exp, $fudge) = @_;
  my ($hh, $mn) = $exp =~ /^(\d\d):(\d\d)$/;
  $mn += $fudge;
  if ($mn > 59) {
    $hh ++;
    $mn -= 60;
  }
  if ($hh > 23) {
    $hh -= 24;
  }
  elsif ($hh < 0) {
    $hh += 24;
  }
  return sprintf("%02d:%02d", $hh, $mn);
}

sub fudge_l {
  my ($exp, $fudge) = @_;
  my ($hh, $mn) = $exp =~ /^(\d\d):(\d\d)$/;
  $mn -= $fudge;
  if ($mn < 0) {
    $hh --;
    $mn += 60;
  }
  if ($hh > 23) {
    $hh -= 24;
  }
  elsif ($hh < 0) {
    $hh += 24;
  }
  return sprintf("%02d:%02d", $hh, $mn);
}

#
# The data below have been prepared by a C program which includes
# Paul Schlyter's code. Therefore, what is tested is the compatibility
# of the Perl code with the C code.
#
# See how this C program is generated in
# https://github.com/jforget/Astro-Sunrise/blob/master/util/mktest-04a
#
# Why those locations?
# Greenwich because it is located on the eponymous prime meridian
# Reykjavik, because it is close to the Northern Arctic Circle, so it can be used to check polar night and midnight sun
# Quito because it is near the prime parallel, better known as "equator"
# El Hierro, because it is located on a former prime meridian
#
# Warning: as you can see, the computation of sunrise and sunset is called with an altitude -0.833
# and with upper_limb = 1. This is silly, because that means that the radius is accounted
# twice instead of just once. But the purpose of this programme is just to check
# that the Perl implementation of the algorithm is compatible with the C implementation.
sub load_data {
    return split "\n", <<'EOD';
2013  1  1 Greenwich            51 28 N   0  0 E 10         0 sunrise: 09:50 sunset: 14:17
2013  1  1 Greenwich            51 28 N   0  0 E 10         1 sunrise: 09:47 sunset: 14:21
2013  1  1 Greenwich            51 28 N   0  0 E 0          0 sunrise: 08:12 sunset: 15:55
2013  1  1 Greenwich            51 28 N   0  0 E 0          1 sunrise: 08:10 sunset: 15:57
2013  1  1 Greenwich            51 28 N   0  0 E -0.583     0 sunrise: 08:07 sunset: 16:00
2013  1  1 Greenwich            51 28 N   0  0 E -0.583     1 sunrise: 08:05 sunset: 16:02
2013  1  1 Greenwich            51 28 N   0  0 E -0.833     0 sunrise: 08:05 sunset: 16:02
2013  1  1 Greenwich            51 28 N   0  0 E -0.833     1 sunrise: 08:03 sunset: 16:04
2013  1  1 Greenwich            51 28 N   0  0 E -12        0 sunrise: 06:43 sunset: 17:25
2013  1  1 Greenwich            51 28 N   0  0 E -12        1 sunrise: 06:41 sunset: 17:26
2013  1  1 Greenwich            51 28 N   0  0 E -18        0 sunrise: 06:02 sunset: 18:05
2013  1  1 Greenwich            51 28 N   0  0 E -18        1 sunrise: 06:00 sunset: 18:07
2013  1  1 Reykjavik            64  4 N  21 58 W 10         0 sunrise: 12:32 sunset: 12:32 polar night or midnight sun
2013  1  1 Reykjavik            64  4 N  21 58 W 10         1 sunrise: 12:32 sunset: 12:32 polar night or midnight sun
2013  1  1 Reykjavik            64  4 N  21 58 W 0          0 sunrise: 10:34 sunset: 14:29
2013  1  1 Reykjavik            64  4 N  21 58 W 0          1 sunrise: 10:29 sunset: 14:35
2013  1  1 Reykjavik            64  4 N  21 58 W -0.583     0 sunrise: 10:23 sunset: 14:41
2013  1  1 Reykjavik            64  4 N  21 58 W -0.583     1 sunrise: 10:18 sunset: 14:46
2013  1  1 Reykjavik            64  4 N  21 58 W -0.833     0 sunrise: 10:18 sunset: 14:45
2013  1  1 Reykjavik            64  4 N  21 58 W -0.833     1 sunrise: 10:13 sunset: 14:50
2013  1  1 Reykjavik            64  4 N  21 58 W -12        0 sunrise: 07:55 sunset: 17:08
2013  1  1 Reykjavik            64  4 N  21 58 W -12        1 sunrise: 07:52 sunset: 17:11
2013  1  1 Reykjavik            64  4 N  21 58 W -18        0 sunrise: 06:55 sunset: 18:08
2013  1  1 Reykjavik            64  4 N  21 58 W -18        1 sunrise: 06:53 sunset: 18:10
2013  1  1 Quito                 0 15 S  78 35 W 10         0 sunrise: 07:01 sunset: 17:35
2013  1  1 Quito                 0 15 S  78 35 W 10         1 sunrise: 07:00 sunset: 17:36
2013  1  1 Quito                 0 15 S  78 35 W 0          0 sunrise: 06:18 sunset: 18:19
2013  1  1 Quito                 0 15 S  78 35 W 0          1 sunrise: 06:17 sunset: 18:20
2013  1  1 Quito                 0 15 S  78 35 W -0.583     0 sunrise: 06:15 sunset: 18:21
2013  1  1 Quito                 0 15 S  78 35 W -0.583     1 sunrise: 06:14 sunset: 18:22
2013  1  1 Quito                 0 15 S  78 35 W -0.833     0 sunrise: 06:14 sunset: 18:22
2013  1  1 Quito                 0 15 S  78 35 W -0.833     1 sunrise: 06:13 sunset: 18:23
2013  1  1 Quito                 0 15 S  78 35 W -12        0 sunrise: 05:25 sunset: 19:11
2013  1  1 Quito                 0 15 S  78 35 W -12        1 sunrise: 05:24 sunset: 19:12
2013  1  1 Quito                 0 15 S  78 35 W -18        0 sunrise: 04:59 sunset: 19:37
2013  1  1 Quito                 0 15 S  78 35 W -18        1 sunrise: 04:58 sunset: 19:38
2013  1  1 El_Hierro            27 44 N  18  3 W 10         0 sunrise: 07:59 sunset: 16:33
2013  1  1 El_Hierro            27 44 N  18  3 W 10         1 sunrise: 07:58 sunset: 16:34
2013  1  1 El_Hierro            27 44 N  18  3 W 0          0 sunrise: 07:07 sunset: 17:24
2013  1  1 El_Hierro            27 44 N  18  3 W 0          1 sunrise: 07:06 sunset: 17:26
2013  1  1 El_Hierro            27 44 N  18  3 W -0.583     0 sunrise: 07:04 sunset: 17:27
2013  1  1 El_Hierro            27 44 N  18  3 W -0.583     1 sunrise: 07:03 sunset: 17:29
2013  1  1 El_Hierro            27 44 N  18  3 W -0.833     0 sunrise: 07:03 sunset: 17:29
2013  1  1 El_Hierro            27 44 N  18  3 W -0.833     1 sunrise: 07:02 sunset: 17:30
2013  1  1 El_Hierro            27 44 N  18  3 W -12        0 sunrise: 06:08 sunset: 18:23
2013  1  1 El_Hierro            27 44 N  18  3 W -12        1 sunrise: 06:07 sunset: 18:25
2013  1  1 El_Hierro            27 44 N  18  3 W -18        0 sunrise: 05:40 sunset: 18:52
2013  1  1 El_Hierro            27 44 N  18  3 W -18        1 sunrise: 05:39 sunset: 18:53
2013  3 21 Greenwich            51 28 N   0  0 E 10         0 sunrise: 07:10 sunset: 17:05
2013  3 21 Greenwich            51 28 N   0  0 E 10         1 sunrise: 07:08 sunset: 17:06
2013  3 21 Greenwich            51 28 N   0  0 E 0          0 sunrise: 06:05 sunset: 18:09
2013  3 21 Greenwich            51 28 N   0  0 E 0          1 sunrise: 06:03 sunset: 18:11
2013  3 21 Greenwich            51 28 N   0  0 E -0.583     0 sunrise: 06:01 sunset: 18:13
2013  3 21 Greenwich            51 28 N   0  0 E -0.583     1 sunrise: 06:00 sunset: 18:15
2013  3 21 Greenwich            51 28 N   0  0 E -0.833     0 sunrise: 06:00 sunset: 18:15
2013  3 21 Greenwich            51 28 N   0  0 E -0.833     1 sunrise: 05:58 sunset: 18:16
2013  3 21 Greenwich            51 28 N   0  0 E -12        0 sunrise: 04:47 sunset: 19:27
2013  3 21 Greenwich            51 28 N   0  0 E -12        1 sunrise: 04:45 sunset: 19:29
2013  3 21 Greenwich            51 28 N   0  0 E -18        0 sunrise: 04:06 sunset: 20:08
2013  3 21 Greenwich            51 28 N   0  0 E -18        1 sunrise: 04:04 sunset: 20:10
2013  3 21 Reykjavik            64  4 N  21 58 W 10         0 sunrise: 08:05 sunset: 17:05
2013  3 21 Reykjavik            64  4 N  21 58 W 10         1 sunrise: 08:02 sunset: 17:08
2013  3 21 Reykjavik            64  4 N  21 58 W 0          0 sunrise: 06:31 sunset: 18:39
2013  3 21 Reykjavik            64  4 N  21 58 W 0          1 sunrise: 06:29 sunset: 18:41
2013  3 21 Reykjavik            64  4 N  21 58 W -0.583     0 sunrise: 06:26 sunset: 18:44
2013  3 21 Reykjavik            64  4 N  21 58 W -0.583     1 sunrise: 06:24 sunset: 18:46
2013  3 21 Reykjavik            64  4 N  21 58 W -0.833     0 sunrise: 06:24 sunset: 18:46
2013  3 21 Reykjavik            64  4 N  21 58 W -0.833     1 sunrise: 06:21 sunset: 18:49
2013  3 21 Reykjavik            64  4 N  21 58 W -12        0 sunrise: 04:37 sunset: 20:33
2013  3 21 Reykjavik            64  4 N  21 58 W -12        1 sunrise: 04:35 sunset: 20:35
2013  3 21 Reykjavik            64  4 N  21 58 W -18        0 sunrise: 03:30 sunset: 21:40
2013  3 21 Reykjavik            64  4 N  21 58 W -18        1 sunrise: 03:27 sunset: 21:43
2013  3 21 Quito                 0 15 S  78 35 W 10         0 sunrise: 07:01 sunset: 17:41
2013  3 21 Quito                 0 15 S  78 35 W 10         1 sunrise: 07:00 sunset: 17:42
2013  3 21 Quito                 0 15 S  78 35 W 0          0 sunrise: 06:21 sunset: 18:21
2013  3 21 Quito                 0 15 S  78 35 W 0          1 sunrise: 06:20 sunset: 18:22
2013  3 21 Quito                 0 15 S  78 35 W -0.583     0 sunrise: 06:19 sunset: 18:24
2013  3 21 Quito                 0 15 S  78 35 W -0.583     1 sunrise: 06:18 sunset: 18:25
2013  3 21 Quito                 0 15 S  78 35 W -0.833     0 sunrise: 06:18 sunset: 18:25
2013  3 21 Quito                 0 15 S  78 35 W -0.833     1 sunrise: 06:17 sunset: 18:26
2013  3 21 Quito                 0 15 S  78 35 W -12        0 sunrise: 05:33 sunset: 19:09
2013  3 21 Quito                 0 15 S  78 35 W -12        1 sunrise: 05:32 sunset: 19:10
2013  3 21 Quito                 0 15 S  78 35 W -18        0 sunrise: 05:09 sunset: 19:33
2013  3 21 Quito                 0 15 S  78 35 W -18        1 sunrise: 05:08 sunset: 19:34
2013  3 21 El_Hierro            27 44 N  18  3 W 10         0 sunrise: 07:04 sunset: 17:35
2013  3 21 El_Hierro            27 44 N  18  3 W 10         1 sunrise: 07:02 sunset: 17:36
2013  3 21 El_Hierro            27 44 N  18  3 W 0          0 sunrise: 06:18 sunset: 18:20
2013  3 21 El_Hierro            27 44 N  18  3 W 0          1 sunrise: 06:17 sunset: 18:21
2013  3 21 El_Hierro            27 44 N  18  3 W -0.583     0 sunrise: 06:16 sunset: 18:23
2013  3 21 El_Hierro            27 44 N  18  3 W -0.583     1 sunrise: 06:15 sunset: 18:24
2013  3 21 El_Hierro            27 44 N  18  3 W -0.833     0 sunrise: 06:15 sunset: 18:24
2013  3 21 El_Hierro            27 44 N  18  3 W -0.833     1 sunrise: 06:13 sunset: 18:25
2013  3 21 El_Hierro            27 44 N  18  3 W -12        0 sunrise: 05:24 sunset: 19:15
2013  3 21 El_Hierro            27 44 N  18  3 W -12        1 sunrise: 05:23 sunset: 19:16
2013  3 21 El_Hierro            27 44 N  18  3 W -18        0 sunrise: 04:57 sunset: 19:42
2013  3 21 El_Hierro            27 44 N  18  3 W -18        1 sunrise: 04:55 sunset: 19:43
2013  6 21 Greenwich            51 28 N   0  0 E 10         0 sunrise: 05:06 sunset: 18:58
2013  6 21 Greenwich            51 28 N   0  0 E 10         1 sunrise: 05:04 sunset: 18:59
2013  6 21 Greenwich            51 28 N   0  0 E 0          0 sunrise: 03:50 sunset: 20:14
2013  6 21 Greenwich            51 28 N   0  0 E 0          1 sunrise: 03:48 sunset: 20:16
2013  6 21 Greenwich            51 28 N   0  0 E -0.583     0 sunrise: 03:45 sunset: 20:19
2013  6 21 Greenwich            51 28 N   0  0 E -0.583     1 sunrise: 03:43 sunset: 20:21
2013  6 21 Greenwich            51 28 N   0  0 E -0.833     0 sunrise: 03:43 sunset: 20:21
2013  6 21 Greenwich            51 28 N   0  0 E -0.833     1 sunrise: 03:41 sunset: 20:23
2013  6 21 Greenwich            51 28 N   0  0 E -12        0 sunrise: 01:41 sunset: 22:23
2013  6 21 Greenwich            51 28 N   0  0 E -12        1 sunrise: 01:36 sunset: 22:27
2013  6 21 Greenwich            51 28 N   0  0 E -18        0 sunrise: 00:02 sunset: 24:02 polar night or midnight sun
2013  6 21 Greenwich            51 28 N   0  0 E -18        1 sunrise: 00:02 sunset: 24:02 polar night or midnight sun
2013  6 21 Reykjavik            64  4 N  21 58 W 10         0 sunrise: 04:41 sunset: 20:19
2013  6 21 Reykjavik            64  4 N  21 58 W 10         1 sunrise: 04:38 sunset: 20:22
2013  6 21 Reykjavik            64  4 N  21 58 W 0          0 sunrise: 02:17 sunset: 22:42
2013  6 21 Reykjavik            64  4 N  21 58 W 0          1 sunrise: 02:12 sunset: 22:48
2013  6 21 Reykjavik            64  4 N  21 58 W -0.583     0 sunrise: 02:04 sunset: 22:56
2013  6 21 Reykjavik            64  4 N  21 58 W -0.583     1 sunrise: 01:57 sunset: 23:02
2013  6 21 Reykjavik            64  4 N  21 58 W -0.833     0 sunrise: 01:57 sunset: 23:02
2013  6 21 Reykjavik            64  4 N  21 58 W -0.833     1 sunrise: 01:50 sunset: 23:09
2013  6 21 Reykjavik            64  4 N  21 58 W -12        0 sunrise: 00:30 sunset: 24:30 polar night or midnight sun
2013  6 21 Reykjavik            64  4 N  21 58 W -12        1 sunrise: 00:30 sunset: 24:30 polar night or midnight sun
2013  6 21 Reykjavik            64  4 N  21 58 W -18        0 sunrise: 00:30 sunset: 24:30 polar night or midnight sun
2013  6 21 Reykjavik            64  4 N  21 58 W -18        1 sunrise: 00:30 sunset: 24:30 polar night or midnight sun
2013  6 21 Quito                 0 15 S  78 35 W 10         0 sunrise: 07:00 sunset: 17:32
2013  6 21 Quito                 0 15 S  78 35 W 10         1 sunrise: 06:59 sunset: 17:33
2013  6 21 Quito                 0 15 S  78 35 W 0          0 sunrise: 06:17 sunset: 18:16
2013  6 21 Quito                 0 15 S  78 35 W 0          1 sunrise: 06:15 sunset: 18:17
2013  6 21 Quito                 0 15 S  78 35 W -0.583     0 sunrise: 06:14 sunset: 18:18
2013  6 21 Quito                 0 15 S  78 35 W -0.583     1 sunrise: 06:13 sunset: 18:19
2013  6 21 Quito                 0 15 S  78 35 W -0.833     0 sunrise: 06:13 sunset: 18:19
2013  6 21 Quito                 0 15 S  78 35 W -0.833     1 sunrise: 06:12 sunset: 18:21
2013  6 21 Quito                 0 15 S  78 35 W -12        0 sunrise: 05:24 sunset: 19:08
2013  6 21 Quito                 0 15 S  78 35 W -12        1 sunrise: 05:23 sunset: 19:09
2013  6 21 Quito                 0 15 S  78 35 W -18        0 sunrise: 04:58 sunset: 19:34
2013  6 21 Quito                 0 15 S  78 35 W -18        1 sunrise: 04:57 sunset: 19:36
2013  6 21 El_Hierro            27 44 N  18  3 W 10         0 sunrise: 06:11 sunset: 18:17
2013  6 21 El_Hierro            27 44 N  18  3 W 10         1 sunrise: 06:10 sunset: 18:19
2013  6 21 El_Hierro            27 44 N  18  3 W 0          0 sunrise: 05:21 sunset: 19:07
2013  6 21 El_Hierro            27 44 N  18  3 W 0          1 sunrise: 05:20 sunset: 19:08
2013  6 21 El_Hierro            27 44 N  18  3 W -0.583     0 sunrise: 05:18 sunset: 19:10
2013  6 21 El_Hierro            27 44 N  18  3 W -0.583     1 sunrise: 05:17 sunset: 19:11
2013  6 21 El_Hierro            27 44 N  18  3 W -0.833     0 sunrise: 05:17 sunset: 19:11
2013  6 21 El_Hierro            27 44 N  18  3 W -0.833     1 sunrise: 05:16 sunset: 19:12
2013  6 21 El_Hierro            27 44 N  18  3 W -12        0 sunrise: 04:18 sunset: 20:10
2013  6 21 El_Hierro            27 44 N  18  3 W -12        1 sunrise: 04:17 sunset: 20:11
2013  6 21 El_Hierro            27 44 N  18  3 W -18        0 sunrise: 03:44 sunset: 20:44
2013  6 21 El_Hierro            27 44 N  18  3 W -18        1 sunrise: 03:43 sunset: 20:45
2013  8 31 Greenwich            51 28 N   0  0 E 10         0 sunrise: 06:22 sunset: 17:39
2013  8 31 Greenwich            51 28 N   0  0 E 10         1 sunrise: 06:20 sunset: 17:40
2013  8 31 Greenwich            51 28 N   0  0 E 0          0 sunrise: 05:17 sunset: 18:43
2013  8 31 Greenwich            51 28 N   0  0 E 0          1 sunrise: 05:15 sunset: 18:45
2013  8 31 Greenwich            51 28 N   0  0 E -0.583     0 sunrise: 05:13 sunset: 18:47
2013  8 31 Greenwich            51 28 N   0  0 E -0.583     1 sunrise: 05:12 sunset: 18:49
2013  8 31 Greenwich            51 28 N   0  0 E -0.833     0 sunrise: 05:12 sunset: 18:49
2013  8 31 Greenwich            51 28 N   0  0 E -0.833     1 sunrise: 05:10 sunset: 18:51
2013  8 31 Greenwich            51 28 N   0  0 E -12        0 sunrise: 03:54 sunset: 20:07
2013  8 31 Greenwich            51 28 N   0  0 E -12        1 sunrise: 03:52 sunset: 20:09
2013  8 31 Greenwich            51 28 N   0  0 E -18        0 sunrise: 03:06 sunset: 20:54
2013  8 31 Greenwich            51 28 N   0  0 E -18        1 sunrise: 03:04 sunset: 20:57
2013  8 31 Reykjavik            64  4 N  21 58 W 10         0 sunrise: 06:50 sunset: 18:06
2013  8 31 Reykjavik            64  4 N  21 58 W 10         1 sunrise: 06:48 sunset: 18:09
2013  8 31 Reykjavik            64  4 N  21 58 W 0          0 sunrise: 05:17 sunset: 19:39
2013  8 31 Reykjavik            64  4 N  21 58 W 0          1 sunrise: 05:14 sunset: 19:42
2013  8 31 Reykjavik            64  4 N  21 58 W -0.583     0 sunrise: 05:11 sunset: 19:45
2013  8 31 Reykjavik            64  4 N  21 58 W -0.583     1 sunrise: 05:09 sunset: 19:48
2013  8 31 Reykjavik            64  4 N  21 58 W -0.833     0 sunrise: 05:09 sunset: 19:47
2013  8 31 Reykjavik            64  4 N  21 58 W -0.833     1 sunrise: 05:06 sunset: 19:50
2013  8 31 Reykjavik            64  4 N  21 58 W -12        0 sunrise: 03:01 sunset: 21:55
2013  8 31 Reykjavik            64  4 N  21 58 W -12        1 sunrise: 02:57 sunset: 21:59
2013  8 31 Reykjavik            64  4 N  21 58 W -18        0 sunrise: 00:28 sunset: 24:28 polar night or midnight sun
2013  8 31 Reykjavik            64  4 N  21 58 W -18        1 sunrise: 00:28 sunset: 24:28 polar night or midnight sun
2013  8 31 Quito                 0 15 S  78 35 W 10         0 sunrise: 06:55 sunset: 17:34
2013  8 31 Quito                 0 15 S  78 35 W 10         1 sunrise: 06:54 sunset: 17:35
2013  8 31 Quito                 0 15 S  78 35 W 0          0 sunrise: 06:15 sunset: 18:14
2013  8 31 Quito                 0 15 S  78 35 W 0          1 sunrise: 06:14 sunset: 18:15
2013  8 31 Quito                 0 15 S  78 35 W -0.583     0 sunrise: 06:12 sunset: 18:17
2013  8 31 Quito                 0 15 S  78 35 W -0.583     1 sunrise: 06:11 sunset: 18:18
2013  8 31 Quito                 0 15 S  78 35 W -0.833     0 sunrise: 06:11 sunset: 18:18
2013  8 31 Quito                 0 15 S  78 35 W -0.833     1 sunrise: 06:10 sunset: 18:19
2013  8 31 Quito                 0 15 S  78 35 W -12        0 sunrise: 05:26 sunset: 19:03
2013  8 31 Quito                 0 15 S  78 35 W -12        1 sunrise: 05:25 sunset: 19:04
2013  8 31 Quito                 0 15 S  78 35 W -18        0 sunrise: 05:02 sunset: 19:27
2013  8 31 Quito                 0 15 S  78 35 W -18        1 sunrise: 05:01 sunset: 19:28
2013  8 31 El_Hierro            27 44 N  18  3 W 10         0 sunrise: 06:40 sunset: 17:45
2013  8 31 El_Hierro            27 44 N  18  3 W 10         1 sunrise: 06:39 sunset: 17:46
2013  8 31 El_Hierro            27 44 N  18  3 W 0          0 sunrise: 05:55 sunset: 18:30
2013  8 31 El_Hierro            27 44 N  18  3 W 0          1 sunrise: 05:53 sunset: 18:32
2013  8 31 El_Hierro            27 44 N  18  3 W -0.583     0 sunrise: 05:52 sunset: 18:33
2013  8 31 El_Hierro            27 44 N  18  3 W -0.583     1 sunrise: 05:51 sunset: 18:34
2013  8 31 El_Hierro            27 44 N  18  3 W -0.833     0 sunrise: 05:51 sunset: 18:34
2013  8 31 El_Hierro            27 44 N  18  3 W -0.833     1 sunrise: 05:49 sunset: 18:35
2013  8 31 El_Hierro            27 44 N  18  3 W -12        0 sunrise: 04:59 sunset: 19:26
2013  8 31 El_Hierro            27 44 N  18  3 W -12        1 sunrise: 04:58 sunset: 19:27
2013  8 31 El_Hierro            27 44 N  18  3 W -18        0 sunrise: 04:30 sunset: 19:55
2013  8 31 El_Hierro            27 44 N  18  3 W -18        1 sunrise: 04:29 sunset: 19:56
2013  9 21 Greenwich            51 28 N   0  0 E 10         0 sunrise: 06:55 sunset: 16:51
2013  9 21 Greenwich            51 28 N   0  0 E 10         1 sunrise: 06:53 sunset: 16:53
2013  9 21 Greenwich            51 28 N   0  0 E 0          0 sunrise: 05:50 sunset: 17:56
2013  9 21 Greenwich            51 28 N   0  0 E 0          1 sunrise: 05:49 sunset: 17:57
2013  9 21 Greenwich            51 28 N   0  0 E -0.583     0 sunrise: 05:47 sunset: 17:59
2013  9 21 Greenwich            51 28 N   0  0 E -0.583     1 sunrise: 05:45 sunset: 18:01
2013  9 21 Greenwich            51 28 N   0  0 E -0.833     0 sunrise: 05:45 sunset: 18:01
2013  9 21 Greenwich            51 28 N   0  0 E -0.833     1 sunrise: 05:43 sunset: 18:03
2013  9 21 Greenwich            51 28 N   0  0 E -12        0 sunrise: 04:32 sunset: 19:14
2013  9 21 Greenwich            51 28 N   0  0 E -12        1 sunrise: 04:30 sunset: 19:16
2013  9 21 Greenwich            51 28 N   0  0 E -18        0 sunrise: 03:51 sunset: 19:55
2013  9 21 Greenwich            51 28 N   0  0 E -18        1 sunrise: 03:49 sunset: 19:57
2013  9 21 Reykjavik            64  4 N  21 58 W 10         0 sunrise: 07:50 sunset: 16:52
2013  9 21 Reykjavik            64  4 N  21 58 W 10         1 sunrise: 07:47 sunset: 16:54
2013  9 21 Reykjavik            64  4 N  21 58 W 0          0 sunrise: 06:17 sunset: 18:25
2013  9 21 Reykjavik            64  4 N  21 58 W 0          1 sunrise: 06:14 sunset: 18:27
2013  9 21 Reykjavik            64  4 N  21 58 W -0.583     0 sunrise: 06:11 sunset: 18:30
2013  9 21 Reykjavik            64  4 N  21 58 W -0.583     1 sunrise: 06:09 sunset: 18:33
2013  9 21 Reykjavik            64  4 N  21 58 W -0.833     0 sunrise: 06:09 sunset: 18:33
2013  9 21 Reykjavik            64  4 N  21 58 W -0.833     1 sunrise: 06:07 sunset: 18:35
2013  9 21 Reykjavik            64  4 N  21 58 W -12        0 sunrise: 04:23 sunset: 20:19
2013  9 21 Reykjavik            64  4 N  21 58 W -12        1 sunrise: 04:20 sunset: 20:22
2013  9 21 Reykjavik            64  4 N  21 58 W -18        0 sunrise: 03:15 sunset: 21:27
2013  9 21 Reykjavik            64  4 N  21 58 W -18        1 sunrise: 03:12 sunset: 21:30
2013  9 21 Quito                 0 15 S  78 35 W 10         0 sunrise: 06:47 sunset: 17:27
2013  9 21 Quito                 0 15 S  78 35 W 10         1 sunrise: 06:46 sunset: 17:28
2013  9 21 Quito                 0 15 S  78 35 W 0          0 sunrise: 06:07 sunset: 18:07
2013  9 21 Quito                 0 15 S  78 35 W 0          1 sunrise: 06:06 sunset: 18:08
2013  9 21 Quito                 0 15 S  78 35 W -0.583     0 sunrise: 06:05 sunset: 18:10
2013  9 21 Quito                 0 15 S  78 35 W -0.583     1 sunrise: 06:04 sunset: 18:11
2013  9 21 Quito                 0 15 S  78 35 W -0.833     0 sunrise: 06:04 sunset: 18:11
2013  9 21 Quito                 0 15 S  78 35 W -0.833     1 sunrise: 06:03 sunset: 18:12
2013  9 21 Quito                 0 15 S  78 35 W -12        0 sunrise: 05:19 sunset: 18:55
2013  9 21 Quito                 0 15 S  78 35 W -12        1 sunrise: 05:18 sunset: 18:56
2013  9 21 Quito                 0 15 S  78 35 W -18        0 sunrise: 04:55 sunset: 19:19
2013  9 21 Quito                 0 15 S  78 35 W -18        1 sunrise: 04:54 sunset: 19:20
2013  9 21 El_Hierro            27 44 N  18  3 W 10         0 sunrise: 06:49 sunset: 17:21
2013  9 21 El_Hierro            27 44 N  18  3 W 10         1 sunrise: 06:48 sunset: 17:22
2013  9 21 El_Hierro            27 44 N  18  3 W 0          0 sunrise: 06:04 sunset: 18:06
2013  9 21 El_Hierro            27 44 N  18  3 W 0          1 sunrise: 06:03 sunset: 18:07
2013  9 21 El_Hierro            27 44 N  18  3 W -0.583     0 sunrise: 06:01 sunset: 18:09
2013  9 21 El_Hierro            27 44 N  18  3 W -0.583     1 sunrise: 06:00 sunset: 18:10
2013  9 21 El_Hierro            27 44 N  18  3 W -0.833     0 sunrise: 06:00 sunset: 18:10
2013  9 21 El_Hierro            27 44 N  18  3 W -0.833     1 sunrise: 05:59 sunset: 18:11
2013  9 21 El_Hierro            27 44 N  18  3 W -12        0 sunrise: 05:10 sunset: 19:01
2013  9 21 El_Hierro            27 44 N  18  3 W -12        1 sunrise: 05:09 sunset: 19:02
2013  9 21 El_Hierro            27 44 N  18  3 W -18        0 sunrise: 04:42 sunset: 19:28
2013  9 21 El_Hierro            27 44 N  18  3 W -18        1 sunrise: 04:41 sunset: 19:29
2013 12 31 Greenwich            51 28 N   0  0 E 10         0 sunrise: 09:51 sunset: 14:16
2013 12 31 Greenwich            51 28 N   0  0 E 10         1 sunrise: 09:47 sunset: 14:19
2013 12 31 Greenwich            51 28 N   0  0 E 0          0 sunrise: 08:12 sunset: 15:54
2013 12 31 Greenwich            51 28 N   0  0 E 0          1 sunrise: 08:10 sunset: 15:56
2013 12 31 Greenwich            51 28 N   0  0 E -0.583     0 sunrise: 08:08 sunset: 15:59
2013 12 31 Greenwich            51 28 N   0  0 E -0.583     1 sunrise: 08:05 sunset: 16:01
2013 12 31 Greenwich            51 28 N   0  0 E -0.833     0 sunrise: 08:06 sunset: 16:01
2013 12 31 Greenwich            51 28 N   0  0 E -0.833     1 sunrise: 08:03 sunset: 16:03
2013 12 31 Greenwich            51 28 N   0  0 E -12        0 sunrise: 06:43 sunset: 17:23
2013 12 31 Greenwich            51 28 N   0  0 E -12        1 sunrise: 06:41 sunset: 17:25
2013 12 31 Greenwich            51 28 N   0  0 E -18        0 sunrise: 06:02 sunset: 18:04
2013 12 31 Greenwich            51 28 N   0  0 E -18        1 sunrise: 06:00 sunset: 18:06
2013 12 31 Reykjavik            64  4 N  21 58 W 10         0 sunrise: 12:31 sunset: 12:31 polar night or midnight sun
2013 12 31 Reykjavik            64  4 N  21 58 W 10         1 sunrise: 12:31 sunset: 12:31 polar night or midnight sun
2013 12 31 Reykjavik            64  4 N  21 58 W 0          0 sunrise: 10:35 sunset: 14:27
2013 12 31 Reykjavik            64  4 N  21 58 W 0          1 sunrise: 10:30 sunset: 14:32
2013 12 31 Reykjavik            64  4 N  21 58 W -0.583     0 sunrise: 10:24 sunset: 14:38
2013 12 31 Reykjavik            64  4 N  21 58 W -0.583     1 sunrise: 10:19 sunset: 14:43
2013 12 31 Reykjavik            64  4 N  21 58 W -0.833     0 sunrise: 10:19 sunset: 14:43
2013 12 31 Reykjavik            64  4 N  21 58 W -0.833     1 sunrise: 10:14 sunset: 14:48
2013 12 31 Reykjavik            64  4 N  21 58 W -12        0 sunrise: 07:55 sunset: 17:07
2013 12 31 Reykjavik            64  4 N  21 58 W -12        1 sunrise: 07:52 sunset: 17:10
2013 12 31 Reykjavik            64  4 N  21 58 W -18        0 sunrise: 06:56 sunset: 18:06
2013 12 31 Reykjavik            64  4 N  21 58 W -18        1 sunrise: 06:53 sunset: 18:09
2013 12 31 Quito                 0 15 S  78 35 W 10         0 sunrise: 07:01 sunset: 17:34
2013 12 31 Quito                 0 15 S  78 35 W 10         1 sunrise: 06:59 sunset: 17:36
2013 12 31 Quito                 0 15 S  78 35 W 0          0 sunrise: 06:17 sunset: 18:18
2013 12 31 Quito                 0 15 S  78 35 W 0          1 sunrise: 06:16 sunset: 18:19
2013 12 31 Quito                 0 15 S  78 35 W -0.583     0 sunrise: 06:15 sunset: 18:20
2013 12 31 Quito                 0 15 S  78 35 W -0.583     1 sunrise: 06:13 sunset: 18:22
2013 12 31 Quito                 0 15 S  78 35 W -0.833     0 sunrise: 06:13 sunset: 18:22
2013 12 31 Quito                 0 15 S  78 35 W -0.833     1 sunrise: 06:12 sunset: 18:23
2013 12 31 Quito                 0 15 S  78 35 W -12        0 sunrise: 05:25 sunset: 19:10
2013 12 31 Quito                 0 15 S  78 35 W -12        1 sunrise: 05:24 sunset: 19:11
2013 12 31 Quito                 0 15 S  78 35 W -18        0 sunrise: 04:59 sunset: 19:36
2013 12 31 Quito                 0 15 S  78 35 W -18        1 sunrise: 04:57 sunset: 19:38
2013 12 31 El_Hierro            27 44 N  18  3 W 10         0 sunrise: 07:59 sunset: 16:32
2013 12 31 El_Hierro            27 44 N  18  3 W 10         1 sunrise: 07:58 sunset: 16:33
2013 12 31 El_Hierro            27 44 N  18  3 W 0          0 sunrise: 07:07 sunset: 17:24
2013 12 31 El_Hierro            27 44 N  18  3 W 0          1 sunrise: 07:06 sunset: 17:25
2013 12 31 El_Hierro            27 44 N  18  3 W -0.583     0 sunrise: 07:04 sunset: 17:27
2013 12 31 El_Hierro            27 44 N  18  3 W -0.583     1 sunrise: 07:03 sunset: 17:28
2013 12 31 El_Hierro            27 44 N  18  3 W -0.833     0 sunrise: 07:03 sunset: 17:28
2013 12 31 El_Hierro            27 44 N  18  3 W -0.833     1 sunrise: 07:01 sunset: 17:29
2013 12 31 El_Hierro            27 44 N  18  3 W -12        0 sunrise: 06:08 sunset: 18:23
2013 12 31 El_Hierro            27 44 N  18  3 W -12        1 sunrise: 06:07 sunset: 18:24
2013 12 31 El_Hierro            27 44 N  18  3 W -18        0 sunrise: 05:39 sunset: 18:51
2013 12 31 El_Hierro            27 44 N  18  3 W -18        1 sunrise: 05:38 sunset: 18:52
EOD
}
