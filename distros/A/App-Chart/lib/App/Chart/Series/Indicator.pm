# Copyright 2008, 2009, 2013 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3, or (at your option) any later version.
#
# Chart is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along
# with Chart.  If not, see <http://www.gnu.org/licenses/>.

package App::Chart::Series::Indicator;
use 5.010;
use strict;
use warnings;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series';

use constant DEBUG => 0;

use constant decimals => 0; # none needed normally

sub name {
  my ($self) = @_;
  my $name = $self->shortname;
  if (my $parameters = $self->{'parameters'}) {
    my $parameter_info = $self->parameter_info;
    my @parameters;
    foreach my $i (0 .. $#$parameters) {
      my $pinfo = $parameter_info->[$i];
      if ($pinfo->{'type'} eq 'boolean') {
        $parameters[$i] = ($parameters->[$i] ? $pinfo->{'name'} : '');
      } elsif ($pinfo->{'type'} eq 'float') {
        # display just 1 decimal is that's enough
        my $nf = App::Chart::number_formatter();
        my $value = $parameters->[$i];
        my $percent = $pinfo->{'type_hint'}//'' eq 'percent';
        my $decimals = max ($pinfo->{'decimals'} // 0,
                            App::Chart::count_decimals($value));
        $parameters[$i] = $nf->format_number ($value, $decimals, 1);
        if ($percent) {
          $parameters[$i] .= '%';
        }
      } else {
        $parameters[$i] = $parameters->[$i];
      }
    }
    $parameters = join (__p('separator',',') . ' ', @parameters);
    $name = join (' ', $name, $parameters);
  }
  my $parent_name = $self->parent->name;
  if (defined $parent_name) {
    $name = join (' - ', $parent_name, $name);
  }
  return $name;
}

sub fill_part_from_proc {
  my ($self, $lo, $hi) = @_;
  if (DEBUG) { say "fill_part_from_proc $lo $hi,",
                 " self=$self parent=$self->{'parent'}"; }
  my $parent = $self->{'parent'};

  my $warmup_count = $self->warmup_count_for_position ($lo);
  my $start = $parent->find_before ($lo, $warmup_count);
  $parent->fill ($lo, $hi);
  my $p = $parent->values_array;

  my $s = $self->values_array;
  $hi = min ($hi, $#$p);
  if ($#$s < $hi) { $#$s = $hi; }  # pre-extend

  my $proc = $self->proc (@{$self->{'parameters'}});
  if (DEBUG) { print "  start $start\n"; }

  foreach my $i ($start .. $lo-1) {
    my $value = $p->[$i] // next;
    $proc->($value);
  }
  foreach my $i ($lo .. $hi) {
    my $value = $p->[$i] // next;
    $s->[$i] = $proc->($value);
  }
}
sub warmup_count_for_position {
  my ($self, $lo) = @_;
  return $self->warmup_count (@{$self->{'parameters'}});
}

1;
__END__
