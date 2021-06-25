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

package Traveller::System::Classic::MPTS;
use Mojo::Base 'Traveller::System::Classic';

sub compute_tradecodes {
  my $self = shift;
  my $tradecodes = '';
  $tradecodes .= ' Ag' if $self->atmosphere >= 4 and $self->atmosphere <= 9
      and $self->hydro >= 4 and $self->hydro <= 8
      and $self->population >= 5 and $self->population <= 7;
  $tradecodes .= ' As' if $self->size == 0
      and $self->atmosphere == 0
      and $self->hydro == 0;
  $tradecodes .= ' Ba' if $self->population == 0
      and $self->government == 0
      and $self->law == 0;
  $tradecodes .= ' De' if $self->atmosphere >= 2 and $self->hydro == 0;
  $tradecodes .= ' Fl' if $self->atmosphere =~ /^[ABC]$/ # erratum
      and $self->hydro >= 1;
  $tradecodes .= ' Hi' if $self->population >= 9;
  $tradecodes .= ' Ic' if $self->atmosphere <= 1 and $self->hydro >= 1;
  $tradecodes .= ' In' if $self->atmosphere =~ /^[012479]$/ and $self->population >= 9;
  $tradecodes .= ' Lo' if $self->population <= 3;
  $tradecodes .= ' Na' if $self->atmosphere <= 3 and $self->hydro <= 3
      and $self->population >= 6;
  $tradecodes .= ' Ni' if $self->population <= 6;
  $tradecodes .= ' Po' if $self->atmosphere >= 2 and $self->atmosphere <= 5
      and $self->hydro <= 3;
  $tradecodes .= ' Ri' if $self->atmosphere =~ /^[68]$/
      and $self->population >= 6 and $self->population <= 8
      and $self->government >= 4 and $self->government <= 9;
  $tradecodes .= ' Va' if $self->atmosphere == 0;
  $tradecodes .= ' Wa' if $self->hydro == 10;
  return $tradecodes;
}

1;
