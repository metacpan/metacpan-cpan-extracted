# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Test script for DateTime::Calendar::FrenchRevolutionary
#     Copyright (C) 2004, 2010, 2011, 2012, 2014, 2016, 2019, 2021 Jean Forget. All rights reserved.
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
use DateTime::Calendar::FrenchRevolutionary;
use utf8;
use strict;
use warnings;

my $n = 1;

sub check_last {
  my ($n, $date_r, $y, $m, $H, $M, $S) = @_;
  my $dt = DateTime::Calendar::FrenchRevolutionary->last_day_of_month(
            year => $y, month => $m, hour => $H, minute => $M, second => $S);
  my $resul = $dt->iso8601;
  if ($date_r eq $resul) {
    print "ok $n\n";
  }
  else {
    print "not ok $n : expected $date_r, got $resul\n";
  }
}

my @tests = (["0001-13-05T5:85:90",    1, 13, 5, 85, 90],
             ["0002-13-05T5:85:90",    2, 13, 5, 85, 90],
             ["0003-13-06T5:85:90",    3, 13, 5, 85, 90],
             ["0006-13-05T5:85:90",    6, 13, 5, 85, 90],
             ["0007-13-06T5:85:90",    7, 13, 5, 85, 90],
             ["0010-13-05T5:85:90",   10, 13, 5, 85, 90],
             ["0011-13-06T5:85:90",   11, 13, 5, 85, 90],
             ["0014-13-05T5:85:90",   14, 13, 5, 85, 90],
             ["0015-13-06T5:85:90",   15, 13, 5, 85, 90],
             ["0099-13-05T5:85:90",   99, 13, 5, 85, 90],
             ["0100-13-05T5:85:90",  100, 13, 5, 85, 90],
             ["0199-13-05T5:85:90",  199, 13, 5, 85, 90],
             ["0200-13-05T5:85:90",  200, 13, 5, 85, 90],
             ["0212-01-30T5:85:90",  212,  1, 5, 85, 90],
             ["0212-02-30T5:85:90",  212,  2, 5, 85, 90],
             ["0211-03-30T0:17:90",  211,  3, 0, 17, 90],
             ["0211-10-30T9:17:99",  211, 10, 9, 17, 99],
             ["0211-12-30T9:07:09",  211, 12, 9,  7,  9],
             ["0211-13-05T8:01:01",  211, 13, 8,  1,  1],
             ["0212-13-06T8:01:01",  212, 13, 8,  1,  1],
             ["0299-13-05T5:85:90",  299, 13, 5, 85, 90],
             ["0300-13-05T5:85:90",  300, 13, 5, 85, 90],
             ["0399-13-05T5:85:90",  399, 13, 5, 85, 90],
             ["0400-13-06T5:85:90",  400, 13, 5, 85, 90],
             ["3999-13-05T5:85:90", 3999, 13, 5, 85, 90],
             ["4000-13-05T5:85:90", 4000, 13, 5, 85, 90],
             );

printf "1..%d\n", scalar @tests;

foreach (@tests) { check_last $n++, @$_ }
