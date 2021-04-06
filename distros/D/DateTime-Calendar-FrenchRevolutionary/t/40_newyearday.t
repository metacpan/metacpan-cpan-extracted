# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Test script for DateTime::Calendar::FrenchRevolutionary
#     Copyright (C) 2003, 2004, 2010, 2011, 2012, 2014, 2016, 2019, 2021 Jean Forget. All rights reserved.
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

my $n = 1;

sub g2r {
  my ($n, $date_r, $format, $y, $m, $d) = @_;
  my $date_g = DateTime->new(year => $y, month => $m, day => $d);
  my $date_resul = DateTime::Calendar::FrenchRevolutionary->from_object(object => $date_g)->strftime($format);
  if ($date_r eq $date_resul)
    { print "ok $n\n" }
  else
    { print "not ok $n : expected $date_r, got $date_resul\n" }
}


my @tests = ([" 1 Vendémiaire I",            "%e %B %EY", 1792,  9, 22],
             ["Jour des Récompenses I",        "%EJ %EY", 1793,  9, 21],
             [" 1 Vendémiaire II",           "%e %B %EY", 1793,  9, 22],
             ["Jour des Récompenses II",       "%EJ %EY", 1794,  9, 21],
             [" 1 Vendémiaire III",          "%e %B %EY", 1794,  9, 22],
             ["Jour de la Révolution III",     "%EJ %EY", 1795,  9, 22],
             [" 1 Vendémiaire IV",           "%e %B %EY", 1795,  9, 23],
             ["Jour des Récompenses IV",       "%EJ %EY", 1796,  9, 21],
             [" 1 Vendémiaire V",            "%e %B %EY", 1796,  9, 22],
             ["Jour des Récompenses V",        "%EJ %EY", 1797,  9, 21],
             [" 1 Vendémiaire VI",           "%e %B %EY", 1797,  9, 22],
             ["Jour des Récompenses VI",       "%EJ %EY", 1798,  9, 21],
             [" 1 Vendémiaire VII",          "%e %B %EY", 1798,  9, 22],
             ["Jour de la Révolution VII",     "%EJ %EY", 1799,  9, 22],
             [" 1 Vendémiaire VIII",         "%e %B %EY", 1799,  9, 23],
             ["Jour des Récompenses VIII",     "%EJ %EY", 1800,  9, 22],
             [" 1 Vendémiaire IX",           "%e %B %EY", 1800,  9, 23],
             ["Jour des Récompenses IX",       "%EJ %EY", 1801,  9, 22],
             [" 1 Vendémiaire X",            "%e %B %EY", 1801,  9, 23],
             ["Jour des Récompenses X",        "%EJ %EY", 1802,  9, 22],
             [" 1 Vendémiaire LVI",          "%e %B %EY", 1847,  9, 23],
             ["Jour de la Révolution LVI",     "%EJ %EY", 1848,  9, 22],
             [" 1 Vendémiaire LVII",         "%e %B %EY", 1848,  9, 23],
             ["Jour des Récompenses LVII",     "%EJ %EY", 1849,  9, 22],
             [" 1 Vendémiaire LVIII",        "%e %B %EY", 1849,  9, 23],
             ["Jour des Récompenses LVIII",    "%EJ %EY", 1850,  9, 22],
             [" 1 Vendémiaire C",            "%e %B %EY", 1891,  9, 23],
             ["Jour des Récompenses C",        "%EJ %EY", 1892,  9, 21],
             [" 1 Vendémiaire CI",           "%e %B %EY", 1892,  9, 22],
             ["Jour des Récompenses CI",       "%EJ %EY", 1893,  9, 21],
             [" 1 Vendémiaire CVIII",        "%e %B %EY", 1899,  9, 22],
             ["Jour de la Révolution CVIII",   "%EJ %EY", 1900,  9, 22],
             [" 1 Vendémiaire CC",           "%e %B %EY", 1991,  9, 23],
             ["Jour des Récompenses CC",       "%EJ %EY", 1992,  9, 21],
             [" 1 Vendémiaire CCI",          "%e %B %EY", 1992,  9, 22],
             ["Jour des Récompenses CCI",      "%EJ %EY", 1993,  9, 21],
             [" 1 Vendémiaire CCVIII",       "%e %B %EY", 1999,  9, 22],
             ["Jour de la Révolution CCVIII",  "%EJ %EY", 2000,  9, 21],
             [" 1 Vendémiaire CCC",          "%e %B %EY", 2091,  9, 22],
             ["Jour des Récompenses CCC",      "%EJ %EY", 2092,  9, 20],
             [" 1 Vendémiaire CCCI",         "%e %B %EY", 2092,  9, 21],
             ["Jour des Récompenses CCCI",     "%EJ %EY", 2093,  9, 20],
             [" 1 Vendémiaire CCCVIII",      "%e %B %EY", 2099,  9, 21],
             ["Jour de la Révolution CCCVIII", "%EJ %EY", 2100,  9, 21],
             [" 1 Vendémiaire CD",           "%e %B %EY", 2191,  9, 22],
             ["Jour de la Révolution CD",      "%EJ %EY", 2192,  9, 21],
             [" 1 Vendémiaire CDI",          "%e %B %EY", 2192,  9, 22],
             ["Jour des Récompenses CDI",      "%EJ %EY", 2193,  9, 21],
             [" 1 Vendémiaire CDVIII",       "%e %B %EY", 2199,  9, 22],
             ["Jour de la Révolution CDVIII",  "%EJ %EY", 2200,  9, 22],
             );

printf "1..%d\n", scalar @tests;

foreach (@tests) { g2r $n++, @$_ }
