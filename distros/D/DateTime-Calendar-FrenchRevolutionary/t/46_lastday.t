# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Test script for DateTime::Calendar::FrenchRevolutionary
#     Copyright (C) 2010, 2011, 2012, 2014, 2016, 2019 Jean Forget. All rights reserved.
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
# For some reasons, 45-lastday.t fails on some CPAN tester's machines.
# To investigate, here is a variant of the same test.

use DateTime::Calendar::FrenchRevolutionary;
use utf8;
use strict;
use warnings;

my $n = 1;

sub check_last {
  my ($l_m, $l_d, $y, $m, $H, $M, $S) = @_;
  my $dt = DateTime::Calendar::FrenchRevolutionary->last_day_of_month(
            year => $y, month => $m, hour => $H, minute => $M, second => $S);
  if ($l_m eq $dt->month) {
     print "ok $n\n";
  }
  else {
    print "not ok $n : expected $l_m, got $dt->month()\n";
  }
  $n ++ ;
  if ($l_d eq $dt->day) {
     print "ok $n\n";
  }
  else {
    print "not ok $n : expected $l_d, got $dt->day()\n";
  }
  $n ++ ;
}


my @tests = ([ 1, 30, 212,  1, 5, 85, 90],
             [ 2, 30, 212,  2, 5, 85, 90],
             [ 3, 30, 211,  3, 0, 17, 90],
             [10, 30, 211, 10, 9, 17, 99],
             [12, 30, 211, 12, 9,  7,  9],
             [13,  5, 211, 13, 8,  1,  1],
             [13,  6, 212, 13, 8,  1,  1],
             );

printf "1..%d\n", 2 * scalar @tests;

foreach (@tests) {
  check_last @$_;
}
