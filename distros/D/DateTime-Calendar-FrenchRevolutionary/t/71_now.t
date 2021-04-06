# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Test script for DateTime::Calendar::FrenchRevolutionary
#     Copyright (C) 2012, 2014, 2016, 2019, 2021 Jean Forget. All rights reserved.
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


#my $nb_tests = @tests;
my $n = 1;
my $nb_tests = 1;

print "1..$nb_tests\n";

# Testing the now constructor
# You should not run this test script around midnight

my $d1 = DateTime->today;
my $d2 = DateTime::Calendar::FrenchRevolutionary->now;
my $d3 = DateTime::Calendar::FrenchRevolutionary->from_object(object => $d1);

if ($d2->strftime("%Y-%m-%d") eq $d3->strftime("%Y-%m-%d"))
  { print "ok 1\n" }
else
  { print "not ok 1, got ", $d2->strftime("%Y-%m-%d"), ' and ', $d3->strftime("%Y-%m-%d") }
