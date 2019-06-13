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
sub g2r {
  my ($n, $date_r, $format, $y, $m, $d) = @_;
  my $date_g = DateTime->new(year => $y, month => $m, day => $d);
  my $date_resul = DateTime::Calendar::FrenchRevolutionary->from_object(object => $date_g)->strftime($format);
  if ($date_r eq $date_resul)
    { print "ok $n\n" }
  else
    { print "not ok $n : expected $date_r, got $date_resul\n" }
}

# Using the empty classes
sub g2r_em {
  my ($n, $date_r, $format, $y, $m, $d) = @_;
  my $date_g = dt::->new(year => $y, month => $m, day => $d);
  my $date_resul = dtcfr::->from_object(object => $date_g)->strftime($format);
  if ($date_r eq $date_resul)
    { print "ok $n\n" }
  else
    { print "not ok $n : expected $date_r, got $date_resul\n" }
}

my @tests = ([" 1 Vendémiaire I",    "%e %B %EY", 1792,  9, 22],
             [" 2 Brumaire II",      "%e %B %EY", 1793, 10, 23],
             [" 9 Thermidor II",     "%e %B %EY", 1794,  7, 27],
             [" 3 Frimaire III",     "%e %B %EY", 1794, 11, 23],
             ["13 Vendémiaire IV",   "%e %B %EY", 1795, 10,  5],
             [" 4 Nivôse IV",        "%e %B %EY", 1795, 12, 25],
             [" 5 Pluviôse V",       "%e %B %EY", 1797,  1, 24],
             [" 6 Ventôse VI",       "%e %B %EY", 1798,  2, 24],
             ["18 Brumaire VIII",    "%e %B %EY", 1799, 11,  9],
             [" 8 Germinal IX",      "%e %B %EY", 1801,  3, 29],
             ["10 Floréal XII",      "%e %B %EY", 1804,  4, 30],
             ["12 Prairial XV",      "%e %B %EY", 1807,  6,  1],
             ["14 Messidor XVIII",   "%e %B %EY", 1810,  7,  3],
             ["16 Thermidor XXI",    "%e %B %EY", 1813,  8,  4],
             ["18 Fructidor XXIV",   "%e %B %EY", 1816,  9,  4],
             ["12 Nivôse CCVIII",    "%e %B %EY", 2000,  1,  1], # Y2K compatible?
             ["22 Floréal CCIX",     "%e %B %EY", 2001,  5, 11],
             ["12 Nivôse MCCVIII",   "%e %B %EY", 3000,  1,  1],
             ["11 Nivôse MCCIX",     "%e %B %EY", 3001,  1,  1],
             ["12 Nivôse MMCCVIII",  "%e %B %EY", 4000,  1,  1],
             ["12 Nivôse MMCCIX",    "%e %B %EY", 4001,  1,  1],
             ["12 Nivôse MMMCCVIII", "%e %B %EY", 5000,  1,  1],
             ["11 Nivôse MMMCCIX",   "%e %B %EY", 5001,  1,  1],
             ["13 Nivôse 4208",      "%e %B %EY", 6000,  1,  1],
             ["13 Nivôse 4209",      "%e %B %EY", 6001,  1,  1],
             );

printf "1..%d\n", 2 * scalar @tests;

foreach (@tests) { g2r    $n++, @$_ }
foreach (@tests) { g2r_em $n++, @$_ }

