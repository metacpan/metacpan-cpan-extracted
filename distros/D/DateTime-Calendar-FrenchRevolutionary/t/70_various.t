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
use utf8;
use strict;
use warnings;


#my $nb_tests = @tests;
my $n = 1;
my $nb_tests = 28;

print "1..$nb_tests\n";

# Testing the epoch
# The 1e9 wraparound was on 9 September 2001, 01:46:40, that is,
# 23 Fructidor CCIX, 0:74:07 (plus or minus 1 second)
my $d = DateTime::Calendar::FrenchRevolutionary->from_epoch(epoch => 1_000_000_000);
if ($d->year == 209 && $d->month == 12 && $d->day == 23 && $d->hour == 0
     && $d->minute == 74 && $d->second >= 6 && $d->second <= 8)
  { print "ok 1\n" }
else
  { print "not ok 1, got ", $d->strftime("%Y %m %d %H %M %S%n") }

# Testing the nanoseconds
my $d1 = DateTime->new(year => 2003, month => 12, day => 4,
           hour => 12, minute => 30, second => 45, nanosecond => 123456789);
my $d2 = DateTime::Calendar::FrenchRevolutionary->from_object(object => $d1);
my $d3 = DateTime->from_object(object => $d2);
if ($d1->nanosecond == $d3->nanosecond)
  { print "ok 2\n" }
else
  { print "not ok 2, got ", $d3->nanosecond }

# Testing the locales
my $lo;
eval { $d = DateTime::Calendar::FrenchRevolutionary->new( year  => 8,
                                         month =>  2,
                                         day   => 18,
 locale => 'fr') };
if ($@ eq '' && $d->strftime("%A %d %B %Y") eq "Octidi 18 Brumaire 0008")
  { print "ok 3\n" }
elsif ($@)
  { print "not ok 3, error $@\n" }
else
  { printf "not ok 3, result %s\n", $d->strftime("%A %d %B %Y") }

eval { $d = DateTime::Calendar::FrenchRevolutionary->new( year  => 8,
                                         month =>  2,
                                         day   => 18,
 locale => 'en') };
if ($@ eq '' && $d->strftime("%A %d %B %Y") eq "Eightday 18 Fogarious 0008")
  { print "ok 4\n" }
elsif ($@)
  { print "not ok 4, error $@\n" }
else
  { printf "not ok 4, result %s\n", $d->strftime("%A %d %B %Y") }

eval {
 $lo = DateTime::Calendar::FrenchRevolutionary::Locale->load('fr');
 $d = DateTime::Calendar::FrenchRevolutionary->new( year  => 8,
                                         month =>  2,
                                         day   => 18,
 locale => $lo) };
if ($@ eq '' && $d->strftime("%A %d %B %Y") eq "Octidi 18 Brumaire 0008")
  { print "ok 5\n" }
elsif ($@)
  { print "not ok 5, error $@\n" }
else
  { printf "not ok 5, result %s\n", $d->strftime("%A %d %B %Y") }

eval {
 $lo = DateTime::Calendar::FrenchRevolutionary::Locale->load('en');
 $d = DateTime::Calendar::FrenchRevolutionary->new( year  => 8,
                                         month =>  2,
                                         day   => 18,
 locale => $lo) };
if ($@ eq '' && $d->strftime("%A %d %B %Y") eq "Eightday 18 Fogarious 0008")
  { print "ok 6\n" }
elsif ($@)
  { print "not ok 6, error $@\n" }
else
  { printf "not ok 6, result %s\n", $d->strftime("%A %d %B %Y") }

eval { $d = DateTime::Calendar::FrenchRevolutionary->new( year  => 8,
                                         month =>  2,
                                         day   => 18,
 locale => 'de') };
if ($@)
  { print "ok 7\n" }
else
  { print "not ok 7, unexpected success with locale 'de'\n" }

eval {
 $lo = DateTime::Calendar::FrenchRevolutionary::Locale->load('de');
 $d = DateTime::Calendar::FrenchRevolutionary->new( year  => 8,
                                         month =>  2,
                                         day   => 18,
 locale => $lo) };
if ($@)
  { print "ok 8\n" }
else
  { print "not ok 8, unexpected success with locale 'de'\n" }

# Testing the timezones
my $tz;

eval { $d = DateTime::Calendar::FrenchRevolutionary->new( year  => 8,
                                         month =>  2,
                                         day   => 18,
 time_zone => 'floating') };
if ($@ eq '' && $d->strftime("%A %d %B %Y") eq "Octidi 18 Brumaire 0008")
  { print "ok 9\n" }
elsif ($@)
  { print "not ok 9, error $@\n" }
else
  { printf "not ok 9, result %s\n", $d->strftime("%A %d %B %Y") }

$tz = DateTime::TimeZone->new(name => "floating");
eval { $d = DateTime::Calendar::FrenchRevolutionary->new( year  => 8,
                                         month =>  2,
                                         day   => 18,
 time_zone => $tz) };
if ($@ eq '' && $d->strftime("%A %d %B %Y") eq "Octidi 18 Brumaire 0008")
  { print "ok 10\n" }
elsif ($@)
  { print "not ok 10, error $@\n" }
else
  { printf "not ok 10, result %s\n", $d->strftime("%A %d %B %Y") }

eval { $d = DateTime::Calendar::FrenchRevolutionary->new( year  => 8,
                                         month =>  2,
                                         day   => 18,
 time_zone => 'Europe/Paris') };
if ($@)
  { print "ok 11\n" }
else
  { printf "not ok 11, unexpected success with time zone Paris\n" }

$tz = DateTime::TimeZone->new(name => "Europe/Paris");
eval { $d = DateTime::Calendar::FrenchRevolutionary->new( year  => 8,
                                         month =>  2,
                                         day   => 18,
 time_zone => $tz) };
if ($@)
  { print "ok 12\n" }
else
  { printf "not ok 12, unexpected success with time zone Paris\n" }

# Checking the dummy set_time_zone method
my $iso_paris = $d->iso8601;
my $iso_chicago;
eval { $d->set_time_zone("America/Chicago");
       $iso_chicago = $d->iso8601; };

if ($@ eq '' && $iso_paris eq $iso_chicago ) {
  print "ok 13\n";
}
elsif ($@) {
  print "not ok 13, error $@\n";
}
else {
  print "not ok 13, changed from $iso_paris to $iso_chicago\n";
}

# Checking the on_date method
$d = DateTime::Calendar::FrenchRevolutionary->new( year  => 8,
                                         month =>  2,
                                         day   => 18,
                                         locale => 'fr');
my $event_fr = <<'EOF';
18 Brumaire I Prise de la ville de Tournay par les Français.

18 Brumaire III Armée du Nord. Entrée triomphante des Français dans
Nimègue.

18 Brumaire VIII Coup d'état de Bonaparte : fin du Directoire, début du Consulat.

EOF
my $event_en = <<'EOF';
18 Brumaire I The French capture Tournay.

18 Brumaire III Army of the North. Triumphant entry of the French
into Nimègue.

18 Brumaire VIII Bonaparte's coup: end of Directorate, beginning of Consulate.

EOF
if ($d->on_date eq $event_fr) {
  print "ok 14\n";
}
else {
  print "not ok 14, wrong French event\n";
}

if ($d->on_date('en') eq $event_en) {
  print "ok 15\n";
}
else {
  print "not ok 15, wrong English event\n";
}

# Checking the on_date method on an eventless day
$d = DateTime::Calendar::FrenchRevolutionary->new( year  => 8,
                                         month =>  2,
                                         day   => 10,
                                         locale => 'fr');
if ($d->on_date eq '') {
  print "ok 16\n";
}
else {
  print "not ok 16, wrong French lack of event\n";
}

if ($d->on_date('en') eq '') {
  print "ok 17\n";
}
else {
  print "not ok 17, wrong English lack of event\n";
}

# Checking the dmy and mdy methods
if ($d->dmy eq '10-02-0008') {
  print "ok 18\n";
}
else {
  printf "not ok 18, dmy = '%s' instead of '10-02-0008'\n", $d->dmy;
}

if ($d->dmy('.') eq '10.02.0008') {
  print "ok 19\n";
}
else {
  printf "not ok 19, dmy = '%s' instead of '10.02.0008'\n", $d->dmy('.');
}

if ($d->mdy eq '02-10-0008') {
  print "ok 20\n";
}
else {
  printf "not ok 20, mdy = '%s' instead of '02-10-0008'\n", $d->mdy;
}

if ($d->mdy('.') eq '02.10.0008') {
  print "ok 21\n";
}
else {
  printf "not ok 21, mdy = '%s' instead of '02.10.0008'\n", $d->mdy('.');
}

$d = DateTime::Calendar::FrenchRevolutionary->from_epoch(epoch => 1_000_000_000);
if ($d->epoch == 1_000_000_000) {
  print "ok 22\n";
}
else {
  printf "not ok 22, epoch = %d instead of 1_000_000_000\n", $d->epoch;
}
if (int($d->jd) == 2452161) {
  print "ok 23\n";
}
else {
  printf "not ok 23, jd = %d instead of\n", $d->jd;
}
if (int($d->mjd) == 52161) {
  print "ok 24\n";
}
else {
  printf "not ok 24, mjd = %d instead of\n", $d->mjd;
}
my @decade = $d->decade;
if ($decade[0] == 209 && $decade[1] == 36) {
  print "ok 25\n";
}
else {
  print "not ok 25, decade = ($decade[0], $decade[1]) instead of (209, 36)\n";
}

$d1 = $d->clone;
if ($d1->year == $d->year && $d1->month == $d->month && $d1->day == $d->day) {
  print "ok 26\n";
}
else {
  print "not ok 26, clone failed\n";
}

# Checking the on_date method for the new locales
$d = DateTime::Calendar::FrenchRevolutionary->new( year   => 8,
                                                   month  =>  2,
                                                   day    => 18,
                                                   locale => 'es');
if ($d->on_date eq '') {
  print "ok 27\n";
}
else {
  print "not ok 27, wrong Spanish event\n";
}
$d = DateTime::Calendar::FrenchRevolutionary->new( year   => 8,
                                                   month  =>  2,
                                                   day    => 18,
                                                   locale => 'it');
if ($d->on_date eq '') {
  print "ok 28\n";
}
else {
  print "not ok 28, wrong Spanish event\n";
}
