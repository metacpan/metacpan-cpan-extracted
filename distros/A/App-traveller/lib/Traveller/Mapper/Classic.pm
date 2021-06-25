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

package Traveller::Mapper::Classic;
use Mojo::Base 'Traveller::Mapper';
use Traveller::Util qw(distance);

sub communications {
  # do nothing
}

sub trade {
  # connect starports to each other based on a table
  # see https://talestoastound.wordpress.com/2015/10/30/traveller-out-of-the-box-interlude-the-1977-edition-over-the-1981-edition/
  my ($self) = @_;
  return if $self->trade_set;
  my @edges;
  my @candidates = grep { $_->starport =~ /^[A-E]$/ } @{$self->hexes};
  my @others = @candidates;
  # every system has a link to its partners
  foreach my $hex (@candidates) {
    foreach my $other (@others) {
      next if $hex == $other;
      my $d = distance($hex, $other) - 1;
      next if $d > 3; # 0-4!
      my ($from, $to) = sort $hex->starport, $other->starport;
      my $target;
      if ($from eq 'A' and $to eq 'A') {
	$target = [1,2,4,5]->[$d];
      } elsif ($from eq 'A' and $to eq 'B') {
	$target = [1,3,4,5]->[$d];
      } elsif ($from eq 'A' and $to eq 'C') {
	$target = [1,4,6]->[$d];
      } elsif ($from eq 'A' and $to eq 'D') {
	$target = [1,5]->[$d];
      } elsif ($from eq 'A' and $to eq 'E') {
	$target = [2]->[$d];
      } elsif ($from eq 'B' and $to eq 'B') {
	$target = [1,3,4,6]->[$d];
      } elsif ($from eq 'B' and $to eq 'C') {
	$target = [2,4,6]->[$d];
      } elsif ($from eq 'B' and $to eq 'D') {
	$target = [3,6]->[$d];
      } elsif ($from eq 'B' and $to eq 'E') {
	$target = [4]->[$d];
      } elsif ($from eq 'C' and $to eq 'C') {
	$target = [3,6]->[$d];
      } elsif ($from eq 'C' and $to eq 'D') {
	$target = [4]->[$d];
      } elsif ($from eq 'C' and $to eq 'E') {
	$target = [4]->[$d];
      } elsif ($from eq 'D' and $to eq 'D') {
	$target = [4]->[$d];
      } elsif ($from eq 'D' and $to eq 'E') {
	$target = [5]->[$d];
      } elsif ($from eq 'E' and $to eq 'E') {
	$target = [6]->[$d];
      }
      if ($target and Traveller::System::roll1d6() >= $target) {
	push(@edges, [$hex, $other, $d + 1]);
      }
    }
    shift(@others);
  }
  # $self->routes($self->minimal_spanning_tree(@edges));
  $self->routes(\@edges);
}

sub trade_svg {
  my $self = shift;
  my $data = '';
  my $scale = 100;
  foreach my $edge (sort { $b->[2] cmp $a->[2] } @{$self->routes}) {
    my $u = @{$edge}[0];
    my $v = @{$edge}[1];
    my $d = @{$edge}[2];
    my ($x1, $y1) = ($u->x, $u->y);
    my ($x2, $y2) = ($v->x, $v->y);
    $data .= sprintf(qq{    <line class="trade d$d" x1="%.3f" y1="%.3f" x2="%.3f" y2="%.3f" />\n},
		     (1 + ($x1-1) * 1.5) * $scale, ($y1 - $x1%2/2) * sqrt(3) * $scale,
		     (1 + ($x2-1) * 1.5) * $scale, ($y2 - $x2%2/2) * sqrt(3) * $scale);
  }
  return $data;
}

sub legend {
  my $self = shift;
  my $scale = 100;
  my $doc;
  $doc .= sprintf(qq{    <text class="legend" x="%.3f" y="%.3f">◉ gas giant}
		  . qq{ – ▲ scout base}
		  . qq{ – ★ navy base}
		  . qq{ – <tspan class="trade">▮</tspan> trade},
		  -10, ($self->height + 1) * sqrt(3) * $scale);
  if ($self->source) {
    $doc .= ' – <a xlink:href="' . $self->source . '">UWP</a>';
  }
  $doc .= qq{</text>\n};
  $doc .= sprintf(qq{    <text class="direction" x="%.3f" y="%.3f">coreward</text>\n},
		  $self->width/2 * 1.5 * $scale, -0.13 * $scale);
  $doc .= sprintf(qq{    <text transform="translate(%.3f,%.3f) rotate(90)"}
		  . qq{ class="direction">trailing</text>\n},
		  ($self->width + 0.4) * 1.5 * $scale, $self->height/2 * sqrt(3) * $scale);
  $doc .= sprintf(qq{    <text class="direction" x="%.3f" y="%.3f">rimward</text>\n},
		  $self->width/2 * 1.5 * $scale, ($self->height + 0.7) * sqrt(3) * $scale);
  $doc .= sprintf(qq{    <text transform="translate(%.3f,%.3f) rotate(-90)"}
		  . qq{ class="direction">spinward</text>\n},
		  -0.1 * $scale, $self->height/2 * sqrt(3) * $scale);
  return $doc;
}

1;
