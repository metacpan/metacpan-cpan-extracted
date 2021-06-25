#!/usr/bin/perl
# Copyright (C) 2009-2021  Alex Schroeder <alex@gnu.org>
# Copyright (C) 2020       Christian Carey
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program. If not, see <http://www.gnu.org/licenses/>.

package Traveller::System;
use Mojo::Base -base;
use List::Util qw(any);

has 'name';
has 'x';
has 'y';
has 'starport';
has 'size';
has 'atmosphere';
has 'temperature';
has 'hydro';
has 'population';
has 'government';
has 'law';
has 'tech';
has 'consulate';
has 'pirate';
has 'TAS';
has 'research';
has 'naval';
has 'scout';
has 'gasgiant';
has 'tradecodes';
has 'travelzone';
has 'culture';

sub compute_name {
  my $self = shift;
  my $digraphs = shift;
  my $max = scalar(@$digraphs);
  my $length = 3 + rand(3); # length of name before adding one more
  my $name = '';
  while (length($name) < $length) {
    my $i = 2*int(rand($max/2));
    $name .= $digraphs->[$i];
    $name .= $digraphs->[$i+1];
  }
  $name =~ s/\.//g;
  return ucfirst($name);
}

sub roll1d6 {
  return 1+int(rand(6));
}

sub roll2d6 {
  my $self = shift;
  return $self->roll1d6() + $self->roll1d6();
}

sub compute_starport {
  my $self = shift;
  my %map = ( 2=>'X', 3=>'E', 4=>'E', 5=>'D', 6=>'D', 7=>'C',
	      8=>'C', 9=>'B', 10=>'B', 11=>'A', 12=>'A' );
  return $map{$self->roll2d6()};
}

sub compute_bases {
  my $self = shift;
  if ($self->starport eq 'A') {
    $self->naval($self->roll2d6() >= 8);
    $self->scout($self->roll2d6() >= 10);
    $self->research($self->roll2d6() >= 8);
    $self->TAS($self->roll2d6() >= 4);
    $self->consulate($self->roll2d6() >= 6);
  } elsif ($self->starport eq 'B') {
    $self->naval($self->roll2d6() >= 8);
    $self->scout($self->roll2d6() >= 8);
    $self->research($self->roll2d6() >= 10);
    $self->TAS($self->roll2d6() >= 6);
    $self->consulate($self->roll2d6() >= 8);
    $self->pirate($self->roll2d6() >= 12);
  } elsif ($self->starport eq 'C') {
    $self->scout($self->roll2d6() >= 8);
    $self->research($self->roll2d6() >= 10);
    $self->TAS($self->roll2d6() >= 10);
    $self->consulate($self->roll2d6() >= 10);
    $self->pirate($self->roll2d6() >= 10);
  } elsif ($self->starport eq 'D') {
    $self->scout($self->roll2d6() >= 7);
    $self->pirate($self->roll2d6() >= 12);
  } elsif ($self->starport eq 'E') {
    $self->pirate($self->roll2d6() >= 12);
  }
  $self->gasgiant($self->roll2d6() < 10);
}

sub compute_atmosphere {
  my $self = shift;
  my $atmosphere = $self->roll2d6() -7 + $self->size;
  $atmosphere = 0 if $atmosphere < 0;
  return $atmosphere;
}

sub compute_temperature {
  my $self = shift;
  my $temperature = $self->roll2d6();
  my $atmosphere = $self->atmosphere;
  $temperature -= 2
    if $atmosphere == 2
    or $atmosphere == 3;
  $temperature -= 1
    if $atmosphere == 3
    or $atmosphere == 4
    or $atmosphere == 14;                      # E
  $temperature += 1
    if $atmosphere == 8
    or $atmosphere == 9;
  $temperature += 2
    if $atmosphere == 10                       # A
    or $atmosphere == 13                       # D
    or $atmosphere == 15;                      # F
  $temperature += 6
    if $atmosphere == 11                       # B
    or $atmosphere == 12;                      # C
  return $temperature;
}

sub compute_hydro {
  my $self = shift;
  my $hydro = $self->roll2d6() - 7 + $self->size;
  $hydro -= 4
    if $self->atmosphere == 0
    or $self->atmosphere == 1
    or $self->atmosphere == 10                       # A
    or $self->atmosphere == 11                       # B
    or $self->atmosphere == 12;                      # C
  $hydro -= 2
    if $self->atmosphere != 13                      # D
    and $self->temperature >= 10
    and $self->temperature <= 11;
  $hydro -= 6
    if $self->atmosphere != 13                      # D
    and $self->temperature >= 12;
  $hydro = 0
    if $self->size <= 1
    or $hydro < 0;
  $hydro = 10 if $hydro > 10;
  return $hydro;
}

sub compute_government {
  my $self = shift;
  my $government = $self->roll2d6() - 7 + $self->population; # max 15
  $government = 0
    if $government < 0
    or $self->population == 0;
  return $government;
}

sub compute_law {
  my $self = shift;
  my $law = $self->roll2d6()-7+$self->government; # max 20!
  $law = 0
    if $law < 0
    or $self->population == 0;
  return $law;
}

sub compute_tech {
  my $self = shift;
  my $tech = $self->roll1d6();
  $tech += 6 if $self->starport eq 'A';
  $tech += 4 if $self->starport eq 'B';
  $tech += 2 if $self->starport eq 'C';
  $tech -= 4 if $self->starport eq 'X';
  $tech += 2 if $self->size <= 1;
  $tech += 1 if $self->size >= 2 and $self->size <= 4;
  $tech += 1 if $self->atmosphere <= 3 or $self->atmosphere >= 10;
  $tech += 1 if $self->hydro == 0 or $self->hydro == 9;
  $tech += 2 if $self->hydro == 10;
  $tech += 1 if $self->population >= 1 and $self->population <= 5;
  $tech += 1 if $self->population == 9;
  $tech += 2 if $self->population == 10;
  $tech += 3 if $self->population == 11; # impossible?
  $tech += 4 if $self->population == 12; # impossible?
  $tech += 1 if $self->government == 0 or $self->government == 5;
  $tech += 2 if $self->government == 7;
  $tech -= 2 if $self->government == 13 or $self->government == 14;
  $tech = 0 if $self->population == 0;
  $tech = 15 if $tech > 15;
  return $tech;
}

sub check_doom {
  my $self = shift;
  my $doomed = 0;
  $doomed = 1 if $self->atmosphere <= 1 and $self->tech < 8;
  $doomed = 1 if $self->atmosphere <= 3 and $self->tech < 5;
  $doomed = 1 if ($self->atmosphere == 4
		  or $self->atmosphere == 7
		  or $self->atmosphere == 9) and $self->tech < 3;
  $doomed = 1 if $self->atmosphere == 10 and $self->tech < 8;
  $doomed = 1 if $self->atmosphere == 11 and $self->tech < 9;
  $doomed = 1 if $self->atmosphere == 12 and $self->tech < 10;
  $doomed = 1 if ($self->atmosphere == 13
		  and $self->atmosphere == 14) and $self->tech < 5;
  $doomed = 1 if $self->atmosphere == 15 and $self->tech < 8;
  if ($doomed) {
    $self->population(0);
    $self->government(0);
    $self->law(0);
    $self->tech(0);
  }
}

sub compute_tradecodes {
  my $self = shift;
  my $tradecodes = '';
  $tradecodes .= " Ag" if $self->atmosphere >= 4 and $self->atmosphere <= 9
    and $self->hydro >= 4 and $self->hydro <= 8
    and $self->population >= 5 and $self->population <= 7;
  $tradecodes .= " As" if $self->size == 0 and $self->atmosphere == 0 and $self->hydro == 0;
  $tradecodes .= " Ba" if $self->population == 0 and $self->government == 0 and $self->law == 0;
  $tradecodes .= " De" if $self->atmosphere >= 2 and $self->hydro == 0;
  $tradecodes .= " Fl" if $self->atmosphere >= 10 and $self->hydro >= 1;
  $tradecodes .= " Ga" if $self->size >= 5
    and $self->atmosphere >= 4 and $self->atmosphere <= 9
    and $self->hydro >= 4 and $self->hydro <= 8;
  $tradecodes .= " Hi" if $self->population >= 9;
  $tradecodes .= " Ht" if $self->tech >= 12;
  $tradecodes .= " Ic" if $self->atmosphere <= 1 and $self->hydro >= 1;
  $tradecodes .= " In" if $self->population >= 9 and any { $_ == $self->atmosphere } qw(0 1 2 4 7 9);
  $tradecodes .= " Lo" if $self->population >= 1 and $self->population <= 3;
  $tradecodes .= " Lt" if $self->tech >= 1 and $self->tech <= 5;
  $tradecodes .= " Na" if $self->atmosphere <= 3 and $self->hydro <= 3 and $self->population >= 6;
  $tradecodes .= " Ni" if $self->population >= 4 and $self->population <= 6;
  $tradecodes .= " Po" if $self->atmosphere >= 2 and $self->atmosphere <= 5 and $self->hydro <= 3;
  $tradecodes .= " Ri" if $self->population >= 6 and $self->population <= 8 and any { $_ == $self->atmosphere } qw(6 8);
  $tradecodes .= " Wa" if $self->hydro >= 10;
  $tradecodes .= " Va" if $self->atmosphere == 0;
  return $tradecodes;
}

sub compute_travelzone {
  my $self = shift;
  my $danger = 0;
  $danger++ if $self->atmosphere >= 10;
  $danger++ if $self->population and $self->government == 0;
  $danger++ if $self->government == 7;
  $danger++ if $self->government == 10;
  $danger++ if $self->population and $self->law == 0;
  $danger++ if $self->law >= 9;
  return 'R' if $danger and $self->pirate;
  return 'A' if $danger;
}

sub init {
  my $self = shift;
  $self->x(shift);
  $self->y(shift);
  $self->name($self->compute_name(shift));
  $self->starport($self->compute_starport);
  $self->compute_bases;
  $self->size($self->roll2d6()-2);
  $self->atmosphere($self->compute_atmosphere);
  $self->temperature($self->compute_temperature);
  $self->hydro($self->compute_hydro);
  $self->population($self->roll2d6()-2); # How to get to B and C in the table?
  $self->government($self->compute_government);
  $self->law($self->compute_law);
  $self->tech($self->compute_tech);
  $self->check_doom;
  $self->tradecodes($self->compute_tradecodes);
  $self->travelzone($self->compute_travelzone);
  return $self;
}

sub code {
  my $num = shift;
  return $num if $num < 10;
  return chr(65-10+$num);
}

sub str {
  my $self = shift;
  my $uwp = sprintf("%-16s %02d%02d  ", $self->name, $self->x, $self->y);
  $uwp .= $self->starport;
  $uwp .= code($self->size);
  $uwp .= code($self->atmosphere);
  $uwp .= code($self->hydro);
  $uwp .= code($self->population);
  $uwp .= code($self->government);
  $uwp .= code($self->law);
  $uwp .= '-';
  $uwp .= sprintf("%-2d", $self->tech);
  my $bases = '';
  $bases .= 'N' if $self->naval;
  $bases .= 'S' if $self->scout;
  $bases .= 'R' if $self->research;
  $bases .= 'T' if $self->TAS;
  $bases .= 'C' if $self->consulate;
  $bases .= 'P' if $self->pirate;
  $bases .= 'G' if $self->gasgiant;
  $uwp .= sprintf("%7s", $bases);
  $uwp .= '  ' . $self->tradecodes;
  $uwp .= ' ' . $self->travelzone if $self->travelzone;
  if ($self->culture) {
    my $spaces = 20 - length($self->tradecodes);
    $spaces -= 1 + length($self->travelzone) if $self->travelzone;
    $uwp .= ' ' x $spaces;
    $uwp .= '[' . $self->culture . ']';
  }
  return $uwp;
}

1;
