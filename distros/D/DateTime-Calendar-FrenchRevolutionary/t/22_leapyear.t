# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Test script for DateTime::Calendar::FrenchRevolutionary
#     Copyright (C) 2011, 2012, 2014, 2016, 2019, 2021 Jean Forget. All rights reserved.
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

my %years = qw/ 1 0  2 0  3 1  4 0  5 0  6 0  7 1  8 0  9 0 10 0
               11 1 12 0 13 0 14 0 15 1 16 0 17 0 18 0 19 0 20 1
               21 0 22 0 23 0 24 1 25 0 26 0 27 0 28 1 29 0 30 0
                100 0  200 0  300 0  400 1  500 0  600 0  700 0  800 1
               1000 0 2000 1 3000 0 4000 0 5000 0 6000 1 7000 0 8000 0
              /;
my $nb_tests = keys %years;

my $n = 1;

print "1..$nb_tests\n";

for my $y (sort { $a <=> $b } keys %years) {
  my $d = DateTime::Calendar::FrenchRevolutionary->new(year => $y, month => 1, day => 1);
  if ($d->is_leap_year == $years{$y}) {
    print "ok ", $n++, "\n";
  }
  else {
    print "not ok ", $n++, ", year $y wrong\n";
  }
}
