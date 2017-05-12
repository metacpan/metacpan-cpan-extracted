# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Test script for Date::Convert::French_Rev
#     Copyright (C) 2001, 2002, 2003, 2013, 2015 Jean Forget
#
#     This program is distributed under the same terms as Perl 5.16.3:
#     GNU Public License version 1 or later and Perl Artistic License
#
#     You can find the text of the licenses in the F<LICENSE> file or at
#     L<http://www.perlfoundation.org/artistic_license_1_0>
#     and L<http://www.gnu.org/licenses/gpl-1.0.html>.
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
#     Inc., <http://www.fsf.org/>.
#
use utf8;
use Test::More;
use Date::Convert::French_Rev;

sub g2r {
  my $date_r = shift;
  my $format = shift;
  my $date   = Date::Convert::Gregorian->new(@_);
  Date::Convert::French_Rev->convert($date);
  my $date_resul = $date->date_string($format);
  is($date_resul, $date_r, "expected $date_r, got $date_resul");
}

my @tests = (["Nonidi 09 Thermidor II", "%A %d %B %EY", 1794,  7, 27],
             ["Oct 18 Bru 0008",  "%a %d %b %Y", 1799, 11,  9],
             ["0008",                      "%Y", 1799, 11,  9],
             ["%Y",                       "%%Y", 1799, 11,  9],
             ["%0008",                   "%%%Y", 1799, 11,  9],
             ["%%Y",                    "%%%%Y", 1799, 11,  9],
             ["13 Vnd, potiron",   "%d %b, %Oj", 1797, 10,  4],
             # Groundhog day? No, jour de l'avelinier
             ["14 Plu, jour de l'avelinier 0209", "%d %b, %Ej %Y", 2001,  2,  2],
             ["14 Plu, Jour de l'Avelinier 0209", "%e %h, %EJ %G", 2001,  2,  2],
             ["14 Pluviôse, avelinier 0209",      "%e %B, %Oj %L", 2001,  2,  2],
             ["Qua 14 Germinal CCIX, jour du hêtre", "%a %d %B %EY, %Ej", 2001, 4, 3],
             ["Primidi 11 Vendémiaire ccix, Jour de la Pomme de terre", "%A %d %B %Ey, %EJ", 2000, 10, 2],
             ["Primidi 11 Vendémiaire CCXIX, jour de la pomme de terre", 
                "%A %d %B %EY, %*", 2010, 10, 2],
             ["Quintidi 25 Vendémiaire CCXIX, jour du bœuf", 
                "%A %d %B %EY, %*", 2010, 10, 16],
             ["Sextidi 16 Prairial CCXIX, jour de l'œillet", 
                "%A %d %B %EY, %*", 2011,  6,  4],
             [" 5 jour complémentaire 09, Jour des Récompenses", "%e %B %y, %EJ", 2001, 9, 21],
             ["mois : 02  2, jour 046, jour du chervis", "mois : %m %f, jour %j, %Ej", 2000, 11, 6],
             [" 6 (Sextidi), jour de la bagarade", "%w (%A), %Ej", 2001, 9, 12],
             ["Décadi Déc 10 10", "%A %a %d %w", 1794, 7, 28],
             ["11 Nivôse MMMCCIX",            "", 5001,  1,  1],
             ["11 Nivôse mmmccix",   "%e %B %Ey", 5001,  1,  1],
             ["13 Nivôse 4209",               "", 6001,  1,  1],
             ["13 Nivôse 4209",      "%e %B %Ey", 6001,  1,  1],
             # almost every specifier
             [<<"RES", <<"FMT",     2004,  8, 17],
a Pri A Primidi b Fru B Fructidor c %c C %C d 01 D %D e  1 f 12 F %F G 0212 g %g
h Fru H %H i %i I %I j 331 J %J k %k K %K l %l L 0212 m 12 M %M o %o p %p P %P q %q Q %Q r %r R %R
s %s S %S T %T u %u U %U V %V w  1 W %W x %x X %X y 12 Y 0212 Ey ccxii EY CCXII z %z Z %Z
Ea %Ea EA %EA Oa %Oa OA %OA E! %E! + \t

RES
a %a A %A b %b B %B c %c C %C d %d D %D e %e f %f F %F G %G g %g
h %h H %H i %i I %I j %j J %J k %k K %K l %l L %L m %m M %M o %o p %p P %P q %q Q %Q r %r R %R
s %s S %S T %T u %u U %U V %V w %w W %W x %x X %X y %y Y %Y Ey %Ey EY %EY z %z Z %Z
Ea %Ea EA %EA Oa %Oa OA %OA E! %E! %+ %t%n
FMT
             );

my $nb_tests = @tests;

plan(tests => $nb_tests);

foreach (@tests) { g2r @$_ }
