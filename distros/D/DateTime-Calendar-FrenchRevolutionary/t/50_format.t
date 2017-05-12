# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Test script for DateTime::Calendar::FrenchRevolutionary
#     Copyright (C) 2003, 2004, 2010, 2011, 2012, 2014, 2016 Jean Forget. All rights reserved.
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
use DateTime::Calendar::FrenchRevolutionary;
use DateTime;
use utf8;
use strict;
use warnings;

# Checking dates with default French locale
sub g2r {
  my ($n, $date_r, $format, $y, $m, $d) = @_;
  my $date_g = DateTime->new(year => $y, month => $m, day => $d);
  my $date_resul = DateTime::Calendar::FrenchRevolutionary->from_object(object => $date_g)->strftime($format);
  if ($date_r eq $date_resul) {
    print "ok $n\n";
  }
  else {
    print "not ok $n : expected $date_r, got $date_resul\n";
  }
}

# Checking dates with alternate English locale
sub g2r_en {
  my ($n, $date_r, $format, $y, $m, $d) = @_;
  my $date_g = DateTime->new(year => $y, month => $m, day => $d);
  my $date_resul = DateTime::Calendar::FrenchRevolutionary->from_object(object => $date_g)->set(locale => 'en')->strftime($format);
  if ($date_r eq $date_resul) {
    print "ok $n\n";
  }
  else {
    print "not ok $n : expected $date_r, got $date_resul\n";
  }
}

# checking times and dates-times
sub fr_t {
  my ($n, $date_r, $format, $locale, $y, $m, $d, $H, $M, $S) = @_;
  my $date_resul = DateTime::Calendar::FrenchRevolutionary->new(
        year => $y, month => $m, day => $d, hour => $H, minute => $M, second => $S,
          )->set(locale => $locale)->strftime($format);
  if ($date_r eq $date_resul) {
    print "ok $n\n";
  }
  else {
    print "not ok $n : expected $date_r, got $date_resul\n";
  }
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
             ["Primidi 11 Vendémiaire ccix, Jour de la Pomme de terre", 
                "%A %d %B %Ey, %EJ", 2000, 10, 2],
             ["Primidi 11 Vendémiaire CCXIX, jour de la pomme de terre", 
                "%A %d %B %EY, %*", 2010, 10, 2],
             ["Quintidi 25 Vendémiaire CCXIX, jour du bœuf", 
                "%A %d %B %EY, %*", 2010, 10, 16],
             ["Sextidi 16 Prairial CCXIX, jour de l'œillet", 
                "%A %d %B %EY, %*", 2011,  6,  4],
             [" 5 jour complémentaire 09, Jour des Récompenses", 
                "%e %B %y, %EJ", 2001, 9, 21],
             ["5 jour complémentaire 209, Jour des Récompenses",
                "%{day} %{month_name} %{year}, %{feast_caps}", 2001, 9, 21],
             ["mois : 02  2, jour 046, jour du chervis",
                "mois : %m %f, jour %j, %Ej", 2000, 11, 6],
             ["mois : 2 Bru, jour 46, jour du chervis",
                "mois : %{month} %{month_abbr}, jour %{doy}, %{feast_long}", 2000, 11, 6],
             ["6 (Sextidi), jour de la bagarade", "%w (%A), %Ej", 2001, 9, 12],
             ["6 (Sextidi), jour de la bagarade",
                "%{wday} (%{day_name}), %{feast_long}", 2001, 9, 12],
             ["Décadi Déc 10 10", "%A %a %d %u", 1794, 7, 28],
             );

my @tests_en = (["Nineday 09 Heatidor II", "%A %d %B %EY", 1794,  7, 27],
       ["Firsday 11 Vintagearious ccix, Potato Day", "%A %d %B %Ey, %EJ", 2000, 10, 2],
       ["Firsday 11 Vintagearious 209, Potato Day", 
        "%{day_name} %{day} %{month_name} %{year}, %{feast_caps}", 2000, 10, 2],
       [" 5 additional day 09, Rewards Day", "%e %B %y, %EJ", 2001, 9, 21],
       ["Tenday Ten 10", "%A %a %d", 1794, 7, 28],
             );

my @tests_time = ([" 1 Fructidor 0212, 6:95:80", "%e %B %Y, %H:%M:%S", 'fr', 212, 12, 1, 6, 95, 80],
        ["6:95:80 PM", "%T %p", 'fr', 212, 12, 1, 6, 95, 80],
        ["6:95:80 PM", "%r",    'fr', 212, 12, 1, 6, 95, 80],
        ["3:95:80 AM", "%r",    'fr', 212, 12, 1, 3, 95, 80],
        ["3:95:80 AM", "%r",    'en', 212, 12, 1, 3, 95, 80],
        # almost every accessor at once
        [<<"RES", <<"FMT",      'fr', 212, 12, 1, 2, 51, 25],
year: 212
month: 12, 11, Fructidor, Fru
day of month: 1, 1, 1, 0, 0, 0
day of decade: 1, 1, 1, 1, 1, Primidi, Pri
day of decade: 0, 0, 0, 0, 0
day of year: 331, 331, 330, 330
feast: prune, jour de la prune, Jour de la Prune, 1prune
composite: 0212-12-01, 01-12-0212, 12-01-0212, 0212-12-01T2:51:25
decimal time: 2, 51, 25, 25, 2:51:25
sexagesimal time: 6, 1, 48, 06:01:48
decade: 34, 34
wrong method: %{wrong_method}
RES
year: %{year}
month: %{month}, %{month_0}, %{month_name}, %{month_abbr}
day of month: %{day}, %{day_of_month}, %{mday}, %{day_0}, %{day_of_month_0}, %{mday_0}
day of decade: %{day_of_decade}, %{dod}, %{day_of_week}, %{dow}, %{wday}, %{day_name}, %{day_abbr}
day of decade: %{day_of_decade_0}, %{dod_0}, %{day_of_week_0}, %{dow_0}, %{wday_0}
day of year: %{day_of_year}, %{doy}, %{day_of_year_0}, %{doy_0}
feast: %{feast_short}, %{feast_long}, %{feast_caps}, %{_raw_feast}
composite: %{ymd}, %{dmy}, %{mdy}, %{iso8601}
decimal time: %{hour}, %{minute}, %{second}, %{sec}, %{hms}
sexagesimal time: %{abt_hour}, %{abt_minute}, %{abt_second}, %{abt_hms}
decade: %{decade_number}, %{week_number}
wrong method: %{wrong_method}
FMT
        # almost every specifier
        [<<"RES", <<"FMT",      'fr', 212, 12, 1, 6, 95, 80],
a Pri A Primidi b Fru B Fructidor C 2 d 01 D 12/01/12 e  1 F 0212-12-01 G 0212 g 12
h Fru H 6 I 6 j 331 k  6 l  6 m 12 M 95 p PM P pm r 6:95:80 PM R 6:95
S 80 T 6:95:80 u  1 U 34 V 34 w 1 W 34 y 12 Y 0212 Ey ccxii EY CCXII z +0000 Z floating
Ea Pri EA Primidi Oa Pri OA Primidi E! E!
RES
a %a A %A b %b B %B C %C d %d D %D e %e F %F G %G g %g
h %h H %H I %I j %j k %k l %l m %m M %M p %p P %P r %r R %R
S %S T %T u %u U %U V %V w %w W %W y %y Y %Y Ey %Ey EY %EY z %z Z %Z
Ea %Ea EA %EA Oa %Oa OA %OA E! %E!
FMT
        # same thing in English
        [<<"RES", <<"FMT",      'en', 212, 12, 1, 2, 51, 25],
year: 212
month: 12, 11, Fruitidor, Fru
day of month: 1, 1, 1, 0, 0, 0
day of decade: 1, 1, 1, 1, 1, Firsday, Fir
day of decade: 0, 0, 0, 0, 0
day of year: 331, 331, 330, 330
feast: plum, plum day, Plum Day, plum
composite: 0212-12-01, 01-12-0212, 12-01-0212, 0212-12-01T2:51:25
decimal time: 2, 51, 25, 25, 2:51:25
sexagesimal time: 6, 1, 48, 06:01:48
decade: 34, 34
wrong method: %{wrong_method}
RES
year: %{year}
month: %{month}, %{month_0}, %{month_name}, %{month_abbr}
day of month: %{day}, %{day_of_month}, %{mday}, %{day_0}, %{day_of_month_0}, %{mday_0}
day of decade: %{day_of_decade}, %{dod}, %{day_of_week}, %{dow}, %{wday}, %{day_name}, %{day_abbr}
day of decade: %{day_of_decade_0}, %{dod_0}, %{day_of_week_0}, %{dow_0}, %{wday_0}
day of year: %{day_of_year}, %{doy}, %{day_of_year_0}, %{doy_0}
feast: %{feast_short}, %{feast_long}, %{feast_caps}, %{_raw_feast}
composite: %{ymd}, %{dmy}, %{mdy}, %{iso8601}
decimal time: %{hour}, %{minute}, %{second}, %{sec}, %{hms}
sexagesimal time: %{abt_hour}, %{abt_minute}, %{abt_second}, %{abt_hms}
decade: %{decade_number}, %{week_number}
wrong method: %{wrong_method}
FMT
        # almost every specifier
        [<<"RES", <<"FMT",      'en', 212, 12, 1, 6, 95, 80],
a Fir A Firsday b Fru B Fruitidor C 2 d 01 D 12/01/12 e  1 F 0212-12-01 G 0212 g 12
h Fru H 6 I 6 j 331 k  6 l  6 m 12 M 95 p PM P pm r 6:95:80 PM R 6:95
S 80 T 6:95:80 u  1 U 34 V 34 w 1 W 34 y 12 Y 0212 Ey ccxii EY CCXII z +0000 Z floating
Ea Fir EA Firsday Oa Fir OA Firsday E! E!
RES
a %a A %A b %b B %B C %C d %d D %D e %e F %F G %G g %g
h %h H %H I %I j %j k %k l %l m %m M %M p %p P %P r %r R %R
S %S T %T u %u U %U V %V w %w W %W y %y Y %Y Ey %Ey EY %EY z %z Z %Z
Ea %Ea EA %EA Oa %Oa OA %OA E! %E!
FMT
        );

my $nb_tests = @tests + @tests_en + @tests_time;
my $n = 1;

print "1..$nb_tests\n";

foreach (@tests     ) { g2r    $n++, @$_ }
foreach (@tests_en  ) { g2r_en $n++, @$_ }
foreach (@tests_time) { fr_t   $n++, @$_ }

