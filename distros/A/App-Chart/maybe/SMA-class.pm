# unused




# Copyright 2008, 2009, 2010, 2015 Kevin Ryde

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

package App::Chart::Delayer;
use strict;
use warnings;
use Carp;


sub new {
  my ($class, %self) = @_;
  my $n = $self{'N'};
  ($n > 0) or croak "App::Chart::Delayer: bad N: \"$n\"";
  $self{'array'} = [ ($self{'fill'}) x $n ];
  $self{'pos'} = 0;
  return bless \%self, $class;
}

sub next {
  my ($self, $x) = @_;
  my $array = $self->{'array'};
  my $pos = $self->{'pos'};
  my $ret = $array->[$pos];
  $array->[$pos] = $x;
  $pos++;
  if ($pos >= $self->{'N'}) { $pos = 0; }
  $self->{'pos'} = $pos;
  return $ret;
}

sub warmup_count {
  my ($self) = @_;
  return $self->{'N'} - 1;
}

package App::Chart::Average::SMA;
use strict;
use warnings;
use Carp;


sub new {
  my ($class, %self) = @_;
  my $n = $self{'N'};
  ($n > 0) or croak "App::Chart::Average::SMA bad N: $n";
  $self{'delayer'} = App::Chart::Delayer->new (N => $n, fill => 0);

  $self{'total'} = 0;
use Data::Dumper;
  print Dumper (\%self);
  return bless \%self, $class;
}

sub next {
  my ($self, $x) = @_;

  my $total
    = ($self->{'total'} += $x - $self->{'delayer'}->next ($x));
  return $total / $self->{'N'};
}

sub warmup_count {
  my ($self) = @_;
  return $self->{'N'} - 1;
}

package App::Chart::Average::Median;
use strict;
use warnings;
use Carp;
use List::Util 'min','max';
use Locale::TextDomain ('App-Chart');


use constant
  { name => __('Moving Median'),
    shortname => __('Median'),
    manual    => __p('manual-node','Moving Median'),
    parameter_info => [ { key     => 'N',
                          name    => __('Days'),
                          type    => 'integer',
                          minimum => 1,
                          maximum => 20 },
                        { key     => 'fractile',
                          name    => __('Fractile'),
                          type    => 'percentage',
                          default => 50,
                          minimum => 0,
                          maximum => 100 } ];
  };

sub new {
  my ($class, %self) = @_;
  my $n = $self{'N'};
  ($n > 0) or croak "App::Chart::Average::Median bad N: $n";

  if (! exists $self{'fractile'}) { $self{'fractile'} = 50; }
  $self{'array'} = [ ];
  return bless \%self, $class;
}

sub next {
  my ($self, $x) = @_;
  my $n = $self->{'N'};
  my $array = $self->{'array'};
  push @$array, $x;
  if (@$array > $n) { shift @$array; }

  my @s = sort {$a<=>$b} @$array;
  my $pos = int (scalar(@s) * $self->{'fractile'} / 100);
  return $s[min ($pos, scalar(@s))];
}

sub warmup_count {
  my ($self) = @_;
  return $self->{'N'} - 1;
}

1;
__END__
