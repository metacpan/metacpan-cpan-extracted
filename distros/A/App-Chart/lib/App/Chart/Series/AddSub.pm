# Copyright 2008, 2009 Kevin Ryde

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

package App::Chart::Series::AddSub;
use 5.008;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);

use App::Chart::Database;
use App::Chart::TZ;
use base 'App::Chart::Series';

use constant DEBUG => 0;

sub new {
  if (DEBUG) { require Data::Dumper;
               print "AddSub new ",Data::Dumper::Dumper(\@_); }
  my ($class, $x, $y, @more) = @_;
  $y->isa('App::Chart::Series')
    or croak 'Can only add two App::Chart::Series objects';

  my $x_timebase = $x->timebase;
  my $y_timebase = $y->timebase;
  if (ref $x_timebase ne ref $y_timebase) {
    croak 'Can only add Series with same timebase scale';
  }

  my $timebase;
  if ($x_timebase->to_iso(0) ge $y_timebase->to_iso(0)) {
    $timebase = $x_timebase;
  } else {
    $timebase = $y_timebase;
  }

  my $x_offset = $timebase->convert_from_floor ($x_timebase, 0);
  my $y_offset = $timebase->convert_from_floor ($y_timebase, 0);

  my $hi = min ($timebase->convert_from_floor ($x_timebase, $x->hi),
                $timebase->convert_from_floor ($y_timebase, $y->hi));

  return $class->SUPER::new
    (timebase => $timebase,
     hi       => $hi,
     parent   => $x,
     parent2  => $y,
     x_offset => $x_offset,
     y_offset => $y_offset,
     arrays   => { map {; $_ => [] } keys %{$x->{'arrays'}} },
  @more);
}

sub fill_part {
  my ($self, $lo, $hi) = @_;

  my $xs = $self->{'parent'};
  my $ys = $self->{'parent2'};
  my $negate   = $self->{'negate'};
  my $x_offset = $self->{'x_offset'};
  my $y_offset = $self->{'y_offset'};

  $xs->fill ($lo - $x_offset, $hi - $x_offset);
  $ys->fill ($lo - $y_offset, $hi - $y_offset);

  my $arrays = $self->{'arrays'};
  while (my ($aname, $sa) = each %$arrays) {
    my $xa = $xs->array($aname);
    my $ya = $ys->array($aname);

    my $hi = min ($hi, $#$xa - $x_offset, $#$ya - $x_offset);
    if ($#$sa < $hi) { $#$sa = $hi; }  # pre-extend

    foreach my $i ($lo .. $hi) {
      my $x = $xa->[$i - $x_offset];
      if (defined $x) {
        my $y = $ya->[$i - $y_offset];
        if (defined $y) {
          $sa->[$i] = $x + ($negate ? - $y : $y);
          if (DEBUG) {print "$i  $x ",($negate ? '-' : '+')," $y $sa->[$i]\n";}
        }
      }
    }
  }
}

1;
__END__

=head1 NAME

App::Chart::Series::AddSub -- ...

=head1 SYNOPSIS

 use App::Chart::Series::AddSub;
 my $adj_series = App::Chart::Series::AddSub->new ()

=head1 DESCRIPTION

...

=head1 SEE ALSO

L<App::Chart::Series::Database>

=cut
