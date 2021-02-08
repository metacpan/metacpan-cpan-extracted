# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Test script for Astro::Sunrise: checking degree trigonometry
#     Copyright (C) 2015, 2017, 2021 Ron Hill and Jean Forget
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
use Test::More;
use Astro::Sunrise qw(:trig);

# Hand copied from "Tables numériques de fonctions élémentaires", J. LABORDE, publ Dunod, ISBN 2-04-010181-0
my @table1 = ( [   0, 0       , 1       , 0       , 6],
               [  10, 0.173648, 0.984808, 0.176327, 6],
               [  30, 0.5     , 0.866025, 0.577350, 6],
               [  45, 0.707107, 0.707107, 1       , 6],
               [  60, 0.866025, 0.5     , 1.73205 , 6],
               [  77, 0.974370, 0.224951, 4.3315  , 5],
              );

my @table2 = ( [ 0, 1,  0   ],
               [ 1, 3, 18.4 ],
               [ 1, 2, 26.6 ],
               [ 2, 3, 33.7 ],
               [ 3, 3, 45   ],
               [ 7, 4, 60.3 ],
               [ 1, 0, 90   ],
             );

plan(tests => 6 * @table1 + @table2);
for (@table1) {
  my ($angle, $sind, $cosd, $tand, $pres) = @$_;
  ok(equal(sind($angle), $sind,  6), "sin($angle) = $sind");
  ok(equal(cosd($angle), $cosd,  6), "cos($angle) = $cosd");
  ok(equal(tand($angle), $tand,  3), "tan($angle) = $tand");
  ok(equal(asind($sind), $angle, 3), "asin($sind) = $angle");
  ok(equal(acosd($cosd), $angle, 3), "acos($cosd) = $angle");
  ok(equal(atand($tand), $angle, 3), "atan($tand) = $angle");
}
for (@table2) {
  my ($num, $den, $angle) = @$_;
  ok(equal(atan2d($num, $den), $angle, 3), "atan($num/$den) = $angle");
}

