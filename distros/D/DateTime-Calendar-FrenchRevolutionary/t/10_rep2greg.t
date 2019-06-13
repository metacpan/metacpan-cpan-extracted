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
use DateTime::Calendar::FrenchRevolutionary;
use DateTime;
use utf8;
use strict;
use warnings;

# Empty class test:
package dtcfr;
use base 'DateTime::Calendar::FrenchRevolutionary';
package dt;
use base 'DateTime';
package main;

my $n = 1;

# Using the regular classes
sub r2g {
  my ($n, $date_g, $y, $m, $d, $H, $M, $S) = @_;
  my $date_r = DateTime::Calendar::FrenchRevolutionary->new(year => $y, month => $m, day => $d
                                , hour => $H, minute => $M, second => $S);
  my $date_resul = DateTime->from_object(object => $date_r)->strftime("%Y %b %e %H %M %S");
  if ($date_g eq $date_resul)
    { print "ok $n\n" }
  else
    { print "not ok $n : expected $date_g, got $date_resul\n" }
}

# Empty class test:
sub r2g_em {
  my ($n, $date_g, $y, $m, $d, $H, $M, $S) = @_;
  my $date_r = dtcfr::->new(year => $y, month => $m, day => $d
                                , hour => $H, minute => $M, second => $S);
  my $date_resul = dt::->from_object(object => $date_r)->strftime("%Y %b %e %H %M %S");
  if ($date_g eq $date_resul)
    { print "ok $n\n" }
  else
    { print "not ok $n : expected $date_g, got $date_resul\n" }
}

my @tests = (["1792 Sep 22 02 24 00",   1,  1,  1,  1,  0,  0], 
             ["1793 Oct 23 06 00 00",   2,  2,  2,  2, 50,  0],
             ["1794 Jul 27 00 00 00",   2, 11,  9,  0,  0,  0], # the demise of Robespierre
             ["1794 Nov 23 10 00 00",   3,  3,  3,  4, 16, 67],
             ["1795 Oct  5 00 00 00",   4,  1, 13,  0,  0,  0], # Saint-Roch church demonstration
             ["1795 Dec 25 16 00 00",   4,  4,  4,  6, 66, 67],
             ["1797 Jan 24 16 59 59",   5,  5,  5,  7,  8, 33],
             ["1798 Feb 24 17 00 00",   6,  6,  6,  7,  8, 34],
             ["1799 Nov  9 00 00 00",   8,  2, 18,  0,  0,  0], # Bonaparte's coup
             ["1801 Mar 29 07 12 00",   9,  7,  8,  3,  0,  0],
             ["1804 Apr 30 00 00 08",  12,  8, 10,  0,  0, 10],
             ["1807 Jun  1 00 01 26",  15,  9, 12,  0,  1,  0],
             ["1810 Jul  3 00 00 00",  18, 10, 14,  0,  0,  0],
             ["1813 Aug  4 00 00 00",  21, 11, 16,  0,  0,  0],
             ["1816 Sep  4 00 00 00",  24, 12, 18,  0,  0,  0],
             ["2000 Jan  1 00 00 00", 208,  4, 12,  0,  0,  0], # Y2K compatible? Will your computer freeze or what?
             ["2001 May 11 00 00 00", 209,  8, 22,  0,  0,  0], # So long, Douglas, and thanks for all the fun
             ["2791 Sep 23 00 00 00", 1000,  1,  1,  0,  0,  0],
             ["2792 Sep 22 00 00 00", 1001,  1,  1,  0,  0,  0],
             ["3791 Sep 22 00 00 00", 2000,  1,  1,  0,  0,  0],
             ["3792 Sep 22 00 00 00", 2001,  1,  1,  0,  0,  0],
             ["4791 Sep 23 00 00 00", 3000,  1,  1,  0,  0,  0],
             ["4792 Sep 22 00 00 00", 3001,  1,  1,  0,  0,  0],
             ["5791 Sep 22 00 00 00", 4000,  1,  1,  0,  0,  0],
             ["5792 Sep 21 00 00 00", 4001,  1,  1,  0,  0,  0],
             ["6791 Sep 22 00 00 00", 5000,  1,  1,  0,  0,  0],
             ["6792 Sep 21 00 00 00", 5001,  1,  1,  0,  0,  0],
             ["7791 Sep 21 00 00 00", 6000,  1,  1,  0,  0,  0],
             ["7792 Sep 21 00 00 00", 6001,  1,  1,  0,  0,  0],
             );

printf "1..%d\n", 2 * scalar @tests;

foreach (@tests) { r2g    $n++, @$_ }
foreach (@tests) { r2g_em $n++, @$_ }
