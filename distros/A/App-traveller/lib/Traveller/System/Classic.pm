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

package Traveller::System::Classic;
use List::Util qw(min max);
use Mojo::Base 'Traveller::System';

sub compute_starport {
  my $self = shift;
  my %map = ( 2=>'A', 3=>'A', 4=>'A', 5=>'B', 6=>'B', 7=>'C',
	      8=>'C', 9=>'D', 10=>'E', 11=>'E', 12=>'X' );
  return $map{$self->roll2d6()};
}

sub compute_bases {
  my $self = shift;
  if ($self->starport =~ /^[AB]$/) {
    $self->naval($self->roll2d6() >= 8);
  }
  if ($self->starport eq 'A') {
    $self->scout($self->roll2d6() >= 10);
  } elsif ($self->starport eq 'B') {
    $self->scout($self->roll2d6() >= 9);
  } elsif ($self->starport eq 'C') {
    $self->scout($self->roll2d6() >= 8);
  } elsif ($self->starport eq 'D') {
    $self->scout($self->roll2d6() >= 7);
  }
  $self->gasgiant($self->roll2d6() < 10);
}

sub compute_atmosphere {
  my $self = shift;
  my $atmosphere = $self->size == 0 ? 0 : ($self->roll2d6() - 7 + $self->size);
  $atmosphere = min(max($atmosphere, 0), 15);
  return $atmosphere;
}

sub compute_temperature {
  # do nothing
}

sub compute_hydro {
  my $self = shift;
  my $hydro = $self->roll2d6() - 7 + $self->atmosphere; # erratum
  $hydro -= 4
    if $self->atmosphere <= 1
      or $self->atmosphere >= 10;
  $hydro = 0 if $self->size <= 1;
  $hydro = min(max($hydro, 0), 10);
  return $hydro;
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
  $tech += 1 if $self->hydro == 9;
  $tech += 2 if $self->hydro == 10;
  $tech += 1 if $self->population >= 1 and $self->population <= 5;
  $tech += 2 if $self->population == 9;
  $tech += 4 if $self->population == 10;
  $tech += 1 if $self->government == 0 or $self->government == 5;
  $tech -= 2 if $self->government == 13;
  return $tech;
}

sub check_doom {
  # do nothing
}

sub compute_travelzone {
  # do nothing
}

sub compute_tradecodes {
  my $self = shift;
  my $tradecodes = '';
  $tradecodes .= ' Ri' if $self->atmosphere =~ /^[68]$/
      and $self->population >= 6 and $self->population <= 8
      and $self->government >= 4 and $self->government <= 9;
  $tradecodes .= ' Po' if $self->atmosphere >= 2 and $self->atmosphere <= 5
      and $self->hydro <= 3;
  $tradecodes .= ' Ag' if $self->atmosphere >= 4 and $self->atmosphere <= 9
      and $self->hydro >= 4 and $self->hydro <= 8
      and $self->population >= 5 and $self->population <= 7;
  $tradecodes .= ' Na' if $self->atmosphere <= 3 and $self->hydro <= 3
      and $self->population >= 6;
  $tradecodes .= ' In' if $self->atmosphere =~ /^[012479]$/ and $self->population >= 9;
  $tradecodes .= ' Ni' if $self->population <= 6;
  $tradecodes .= ' Wa' if $self->hydro == 10;
  $tradecodes .= ' De' if $self->atmosphere >= 2 and $self->hydro == 0;
  $tradecodes .= ' Va' if $self->atmosphere == 0;
  $tradecodes .= ' As' if $self->size == 0;
  $tradecodes .= ' Ic' if $self->atmosphere <= 1 and $self->hydro >= 1;
  return $tradecodes;
}

sub code {
  my $num = shift;
  my $code = '0123456789ABCDEFGHJKLMNPQRSTUVWXYZ'; # 'I' and 'O' are omitted
  return '?' if !defined $num or $num !~ /^\d{1,2}$/ or $num >= length($code);
  return substr($code, $num, 1);
}

sub str {
  my $self = shift;
  my $uwp = sprintf('%-16s %02u%02u  ', $self->name, $self->x, $self->y);
  $uwp .= $self->starport;
  $uwp .= code($self->size);
  $uwp .= code($self->atmosphere);
  $uwp .= code($self->hydro);
  $uwp .= code($self->population);
  $uwp .= code($self->government);
  $uwp .= code($self->law);
  $uwp .= '-';
  $uwp .= code($self->tech);
  my $bases = '';
  $bases .= 'N' if $self->naval;
  $bases .= 'S' if $self->scout;
  $bases .= 'R' if $self->research;
  $bases .= 'T' if $self->TAS;
  $bases .= 'C' if $self->consulate;
  $bases .= 'P' if $self->pirate;
  $bases .= 'G' if $self->gasgiant;
  $uwp .= sprintf('%7s', $bases);
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
