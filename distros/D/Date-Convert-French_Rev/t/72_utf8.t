# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Test script for Date::Convert::French_Rev
#     Copyright (C) 2015 Jean Forget
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
# Check the fix to the mojibake bug (similar to RT ticket 100311 for DT::C::FR)
# Generate a UTF-8 string and check its length, to be sure that it is generated
# as an UTF-8 string and not a mojibake ISO-8859 string.

use utf8;
use strict;
use warnings;
use Date::Convert::French_Rev;

#my $nb_tests = @tests;
my $n = 1;
my $nb_tests = 11;

print "1..$nb_tests\n";

# "Octidi 08 Pluviôse, jour du Mézéréon"
# and not "Octidi 08 PluviÃ´se, jour du MÃ©zÃ©rÃ©on"
my $d1 = Date::Convert::French_Rev->new(223, 5, 8);
my $l = length($d1->date_string("%B"));
if ($l == 8)
  { print "ok 1\n" }
else
  { print "not ok 1, expected 8, actual ", $l, "\n" }

$l = length($d1->date_string("%Oj"));
if ($l == 8) 
  { print "ok 2\n" }
else
  { print "not ok 2, expected 8, actual ", $l, "\n" }


$l = length($d1->date_string("%Ej"));
if ($l == 16) 
  { print "ok 3\n" }
else
  { print "not ok 3, expected 16, actual ", $l, "\n" }

$l = length($d1->date_string("%EJ"));
if ($l == 16) 
  { print "ok 4\n" }
else
  { print "not ok 4, expected 16, actual ", $l, "\n" }

$l = length($d1->date_string("%A %d %B, %Ej"));
if ($l == 36) 
  { print "ok 5\n" }
else
  { print "not ok 5, expected 36, actual ", $l, "\n" }

# "Décadi 10 Nivôse, jour du Fléau"
# and not "DÃ©cadi 08 NivÃ´se, jour du FlÃ©au"
$d1 = Date::Convert::French_Rev->new(223, 4, 10);
$l = length($d1->date_string("%A"));
if ($l == 6)
  { print "ok 6\n" }
else
  { print "not ok 6, expected 6, actual ", $l, "\n" }

$l = length($d1->date_string("%B"));
if ($l == 6)
  { print "ok 7\n" }
else
  { print "not ok 7, expected 6, actual ", $l, "\n" }

$l = length($d1->date_string("%Oj"));
if ($l == 5) 
  { print "ok 8\n" }
else
  { print "not ok 8, expected 5, actual ", $l, "\n" }

$l = length($d1->date_string("%Ej"));
if ($l == 13) 
  { print "ok 9\n" }
else
  { print "not ok 9, expected 13, actual ", $l, "\n" }

$l = length($d1->date_string("%EJ"));
if ($l == 13) 
  { print "ok 10\n" }
else
  { print "not ok 10, expected 13, actual ", $l, "\n" }

$l = length($d1->date_string("%A %d %B, %Ej"));
if ($l == 31) 
  { print "ok 11\n" }
else
  { print "not ok 11, expected 31, actual ", $l, "\n" }
