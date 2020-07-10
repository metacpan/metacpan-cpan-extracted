# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Test script for DateTime::Event::Sunrise
#     Copyright © 2003, 2004, 2013, 2020 Ron Hill and Jean Forget
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
use DateTime::Duration;
use DateTime::Span;
use DateTime::SpanSet;
use DateTime::Event::Sunrise;

my $fuzz = 2; # fuzz time in minutes
plan tests => 4;
my $dt = DateTime->new( year   => 2015,
                        month  =>   11,
                        day    =>   27,
                         );
my $dt2 = DateTime->new( year   => 2015,
                         month  =>   11,
                         day    =>   27,
                          );

my $sunrise = DateTime::Event::Sunrise ->new(
                     longitude  => '177',
                     latitude   => '-37.66667',
                     altitude   => 6,
                     precise    => 1,
);
my $sunset = DateTime::Event::Sunrise ->new(
                     longitude  => '177',
                     latitude   => '-37.66667',
                     altitude   => 6,
                     precise    => 1,
                     );

my $sunrise_stl = DateTime::Event::Sunrise ->new(
                     longitude  => '177'
                   , latitude   => '-37.66667'
                   , altitude   => 6
                   , precise    => 1
                   );
my $sunset_stl = DateTime::Event::Sunrise ->new(
                     longitude  => '177'
                   , latitude   => '-37.66667'
                   , altitude   => 6
                   , precise    => 1
                   );

my $tmp_rise     = $sunrise    ->sunrise_datetime($dt2);
my $tmp_set      = $sunset     ->sunset_datetime ($dt);
my $tmp_rise_stl = $sunrise_stl->sunrise_datetime($dt2);
my $tmp_set_stl  = $sunset_stl ->sunset_datetime ($dt);

my $expected = '2015-11-26T17:23:47'; # computed with Stellarium

my  $sunrise_00 = $tmp_rise->clone                            ->datetime;
my  $sunrise_lo = $tmp_rise->clone->subtract(minutes => $fuzz)->datetime;
my  $sunrise_hi = $tmp_rise->clone->add     (minutes => $fuzz)->datetime;
ok ($sunrise_lo le $expected && $sunrise_hi ge $expected, "comparing $sunrise_00 with $expected");

$sunrise_00 = $tmp_rise_stl->clone                            ->datetime;
$sunrise_lo = $tmp_rise_stl->clone->subtract(minutes => $fuzz)->datetime;
$sunrise_hi = $tmp_rise_stl->clone->add     (minutes => $fuzz)->datetime;
ok ($sunrise_lo le $expected && $sunrise_hi ge $expected, "comparing $sunrise_00 with $expected");

$expected = '2015-11-27T06:35:20'; # computed with Stellarium

my  $sunset_00 = $tmp_set->clone                            ->datetime;
my  $sunset_lo = $tmp_set->clone->subtract(minutes => $fuzz)->datetime;
my  $sunset_hi = $tmp_set->clone->add     (minutes => $fuzz)->datetime;
ok ($sunset_lo le $expected && $sunset_hi ge $expected, "comparing $sunset_00 with $expected");

$sunset_00 = $tmp_set_stl->clone                            ->datetime;
$sunset_lo = $tmp_set_stl->clone->subtract(minutes => $fuzz)->datetime;
$sunset_hi = $tmp_set_stl->clone->add     (minutes => $fuzz)->datetime;
ok ($sunset_lo le $expected && $sunset_hi ge $expected, "comparing $sunset_00 with $expected");
