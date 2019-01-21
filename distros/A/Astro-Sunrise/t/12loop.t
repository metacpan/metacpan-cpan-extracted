#!/usr/bin/perl
# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Test script for Astro::Sunrise
#     Copyright (C) 2015, 2017, 2019 Ron Hill and Jean Forget
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
use warnings;
use POSIX qw(floor ceil);
use Astro::Sunrise;
use Test::More;

plan(tests => 4);

my ($rise, $set) = sunrise({ year    => 2015,
                             month   =>   11,
                             day     =>   28,
                             lon     =>  177,
                             lat     =>  -37.66667,
                             tz      =>    0,
                             isdst   =>    0,
                             alt     =>    6,
                             precise =>    1 });
is($rise, "17:24", "Sunrise on 28 November");  # 17:23:26 on Stellarium, actually the day before on 27 nov
is($set,  "06:36", "Sunset on 28 November");   # 06:36:15 on Stellarium

($rise, $set) = sunrise({ year    => 2015,
                          month   =>   11,
                          day     =>   29,
                          lon     =>  177,
                          lat     =>  -37.66667,
                          tz      =>    0,
                          isdst   =>    0,
                          alt     =>    6,
                          precise =>    1 });
is($rise, "17:24", "Sunrise on 29 November");  # 17:23:11 on Stellarium, actually the day before on 28 nov
is($set,  "06:37", "Sunset on 29 November");   # 06:37:10 on Stellarium
