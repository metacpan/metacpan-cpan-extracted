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

package Traveller::Subsector;
use List::Util qw(shuffle);
use Traveller::Util qw(nearby in);
use Traveller::System::Classic::MPTS;
use Traveller::System::Classic;
use Traveller::System;
use Mojo::Base -base;

has 'systems' => sub { [] };

sub one {
  my $i = int(rand(scalar @_));
  return $_[$i];
}

sub compute_digraphs {
  my @first = qw(b c d f g h j k l m n p q r s t v w x y z .
		 sc ng ch gh ph rh sh th wh zh wr qu
		 st sp tr tw fl dr pr dr);
  # make missing vowel rare
  my @second = qw(a e i o u a e i o u a e i o u .);
  my @d;
  for (1 .. 10+rand(20)) {
    push(@d, one(@first));
    push(@d, one(@second));
  }
  return \@d;
}

sub add {
  my ($self, $system) = @_;
  push(@{$self->systems}, $system);
}

sub init {
  my ($self, $width, $height, $rules, $density) = @_;
  $density ||= 0.5;
  my $digraphs = $self->compute_digraphs;
  $width //= 8;
  $height //= 10;
  for my $x (1..$width) {
    for my $y (1..$height) {
      if (rand() < $density) {
	my $system;
        if ($rules eq 'mpts') {
	  $system = Traveller::System::Classic::MPTS->new();
	} elsif ($rules eq 'ct') {
	  $system = Traveller::System::Classic->new();
	} else {
	  $system = Traveller::System->new();
	}
	$self->add($system->init($x, $y, $digraphs));
      }
    }
  }
  # Rename some systems: assume a jump-2 and a jump-1 culture per every
  # subsector of 8×10×½ systems. Go through the list in random order.
  for my $system (shuffle(grep { rand(20) < 1 } @{$self->systems})) {
    $self->spread(
      $system,
      $self->compute_digraphs,
      1 + int(rand(2)),  # jump distance
      1 + int(rand(3))); # jump number
  }
  return $self;
}

sub spread {
  my ($self, $system, $digraphs, $jump_distance, $jump_number) = @_;
  my $culture = $system->compute_name($digraphs);
  # warn sprintf("%02d%02d %s %d %d\n", $system->x, $system->y, $culture, $jump_distance, $jump_number);
  my $network = [$system];
  $self->grow($system, $jump_distance, $jump_number, $network);
  for my $other (@$network) {
    $other->culture($culture);
    $other->name($other->compute_name($digraphs));
  }
}

sub grow {
  my ($self, $system, $jump_distance, $jump_number, $network) = @_;
  my @new_neighbours =
      grep { not $_->culture or int(rand(2)) }
      grep { not Traveller::Util::in($_, @$network) }
  $self->neighbours($system, $jump_distance, $jump_number);
  # for my $neighbour (@new_neighbours) {
  #   warn sprintf(" added %02d%02d %d %d\n", $neighbour->x, $neighbour->y, $jump_distance, $jump_number);
  # }
  push(@$network, @new_neighbours);
  if ($jump_number > 0) {
    for my $neighbour (@new_neighbours) {
      $self->grow($neighbour, $jump_distance, $jump_number - 1, $network);
    }
  }
}

sub neighbours {
  my ($self, $system, $jump_distance, $jump_number) = @_;
  my @neighbours = nearby($system, $jump_distance, $self->systems);
  return @neighbours;
}

sub str {
  my $self = shift;
  my $subsector;
  foreach my $system (@{$self->systems}) {
    $subsector .= $system->str . "\n";
  }
  return $subsector;
}

1;
