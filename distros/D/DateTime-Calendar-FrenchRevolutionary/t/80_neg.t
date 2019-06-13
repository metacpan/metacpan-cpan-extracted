# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Test script for DateTime::Calendar::FrenchRevolutionary
#     Copyright (C) 2003, 2004, 2010, 2011, 2012, 2014, 2016, 2019 Jean Forget. All rights reserved.
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
#
# Checking negative dates. What matters is only that you can convert *to*
# a negative revolutionary date and then *from* the same date and get
# the same result.
# That is, we do not check the dates are correct, we check the conversions are consistent.
#
use DateTime::Calendar::FrenchRevolutionary;
use DateTime;
use utf8;
use strict;
use warnings;

sub check {
  my ($n, $y, $m, $d, $H, $M, $S) = @_;
  my $date_g1  = DateTime->new(year => $y, month => $m, day => $d
                                , hour => $H, minute => $M, second => $S);
  my $date_rev = DateTime::Calendar::FrenchRevolutionary->from_object(object => $date_g1);
  my $date_g2  = DateTime->from_object(object => $date_rev);
  if ($date_g1 eq $date_g2)
    { print "ok $n\n" }
  else
    { print "not ok $n : expected $date_g1, got $date_g2\n" }
}

my @tests = ([1789, 7, 14, 16, 15, 0] # Storming of the Bastille
           , [1515, 9, 13,  8, 30, 0] # Battle of Marignan
           , [1792, 9, 21,  8, 30, 0] # 1 day before the DT-C-FR epoch
           , [1792, 9, 22,  8, 30, 0] # the DT-C-FR epoch
);
printf "1..%d\n", scalar @tests;
my $n = 1;

foreach (@tests) { check $n++, @$_ }
