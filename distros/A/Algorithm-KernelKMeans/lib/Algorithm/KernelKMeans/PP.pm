package Algorithm::KernelKMeans::PP;

use 5.010;
use namespace::autoclean;

use Carp;
use List::Util qw/shuffle sum/;
use List::MoreUtils qw/natatime pairwise/;
use Moose;
use MooseX::Types::Common::Numeric qw/PositiveNum/;
use MooseX::Types::Moose qw/ArrayRef HashRef CodeRef/;
use POSIX qw/floor/;

use Algorithm::KernelKMeans::Util qw/generate_polynominal_kernel/;

our $DEBUG = 0;
our $VERSION = '0.02';

has 'vertices' => (
  is => 'ro',
  isa => ArrayRef[ HashRef[PositiveNum] ],
  required => 1,
  traits => [qw/Array/],
  handles => +{
    num_vertices => 'count',
    vertex => 'get'
  }
);

has 'weights' => (
  is => 'ro',
  isa => ArrayRef[PositiveNum],
  lazy => 1,
  builder => '_build_weights',
  traits => [qw/Array/],
  handles => +{
    num_weights => 'count',
    weight => 'get'
  }
);

has 'kernel' => (
  is => 'ro',
  isa => CodeRef,
  lazy => 1,
  builder => '_build_kernel'
);

# vertex index -> vertex index -> kernel
# Note that the clusterer only uses lower triangle part of the matrix.
# i.e. It is assumed that K(x1, x2) = K(x2, x1)
has 'kernel_matrix' => (
  is => 'ro',
  isa => ArrayRef[ ArrayRef[PositiveNum] ],
  lazy => 1,
  builder => '_build_kernel_matrix'
);

sub _build_weights { [ (1) x shift->num_vertices ] }

# Polynorminal kernel K(x1, x2) = (1 + x1x2)^2
sub _build_kernel { generate_polynominal_kernel(1, 2) }

sub _build_kernel_matrix {
  my $self = shift;
  my @matrix = map {
    my $i = $_;
    [ map {
      my $j = $_;
      $self->kernel->($self->vertex($i), $self->vertex($j));
    } 0 .. $i ];
  } 0 .. $self->num_vertices - 1;
  return \@matrix;
}

sub BUILD {
  my $self = shift;
  if ($self->num_vertices != $self->num_weights) {
    croak 'Array "vertices" and "weights" must be same size';
  }
  if (@{ $self->kernel_matrix } < $self->num_vertices
        or @{ $self->kernel_matrix->[-1] } < $self->num_vertices ) {
    croak 'Kernel matrix seems too small';
  }
};

sub init_clusters {
  my ($self, $k, $shuffle) = @_;
  my $cluster_size = floor($self->num_vertices / $k);
  my @indices = (0 .. $self->num_vertices - 1);
  @indices = shuffle @indices if $shuffle;
  my $iter = natatime $cluster_size, @indices;
  my @clusters;
  while (my @cluster = $iter->()) { push @clusters, \@cluster }
  if (@{ $clusters[-1] } < $cluster_size) {
    my $last_cluster = pop @clusters;
    push @{ $clusters[-1] }, @$last_cluster;
  }
  return \@clusters;
}

sub vertices_of {
  my ($self, $cluster) = @_;
  [ map { $self->vertex($_) } @$cluster ];
}

sub weights_of {
  my ($self, $cluster) = @_;
  [ map { $self->weight($_) } @$cluster ];
}

sub total_weight_of {
  my ($self, $cluster) = @_;
  sum @{ $self->weights_of($cluster) };
}

sub step {
  my ($self, $clusters, $norms) = @_;
  my @new_clusters = map { [] } 0 .. $#$clusters;
  for my $i (0 .. $self->num_vertices - 1) {
    my ($nearest) = sort { $a->[1] <=> $b->[1] } map {
      [ $_ => $norms->[$i][$_] ]
    } 0 .. $#$clusters;
    push @{ $new_clusters[$nearest->[0]] }, $i;
  }
  return [ grep { @$_ != 0 } @new_clusters ];
}

sub compute_score {
  my ($self, $clusters, $norms) = @_;
  my $score = 0;
  for my $cluster_idx (0 .. $#$clusters) {
    my $cluster = $clusters->[$cluster_idx];
    $score += sum map {
      $self->weight($_) * $norms->[$_][$cluster_idx]
    } @$cluster;
  }
  return $score;
}

sub compute_norms {
  my ($self, $clusters) = @_;
  my @total_weights = map { $self->total_weight_of($_) } @$clusters;

  my @term3_denoms = map {
    $self->_norm_term3_denom_of($_)
  } @$clusters;
  my @term3s = pairwise { $a / ($b ** 2) } @term3_denoms, @total_weights;

  my @norms = map {
    my $i = $_;
    my $term1 = $self->kernel_matrix->[$i][$i];
    [ map {
      my $cluster_idx = $_;
      my $cluster = $clusters->[$cluster_idx];
      my $total_weight = $total_weights[$cluster_idx];

      my $weights = $self->weights_of($cluster);
      my $term2 = -2 * sum(pairwise {
        my ($s, $t) = $i >= $a ? ($i, $a) : ($a, $i);
        $self->kernel_matrix->[$s][$t] * $b
      } @$cluster, @$weights) / $total_weight;
      my $term3 = $term3s[$cluster_idx];

      $term1 + $term2 + $term3;
    } 0 .. $#$clusters ]
  } 0 .. $self->num_vertices - 1;
  return \@norms;
}

sub _norm_term3_denom_of {
  my ($self, $cluster) = @_;
  sum map {
    my $i = $_;
    map {
      my $j = $_;
      my ($s, $t) = $i >= $_ ? ($i, $_) : ($_, $i);
      $self->weight($s) * $self->weight($t) * $self->kernel_matrix->[$s][$t];
    } @$cluster;
  } @$cluster;
}

sub run {
  my ($self, %opts) = @_;
  my $k = delete $opts{k} // croak 'Required argument "k" missing';
  my $k_min = delete $opts{k_min} // $k;
  croak '"k_min" must be less than or equal to "k"' if $k_min > $k;
  my $converged = delete $opts{converged} // sub {
    my ($score, $new_score) = @_;
    $score == $new_score;
  };
  my $shuffle = delete $opts{shuffle} // 1;
  if (keys %opts) {
    croak 'Unknown argument(s): ', join ', ', map { qq/"$_"/ } sort keys %opts;
  }

  # cluster index -> [vertex index]
  my $clusters = $self->init_clusters($k, $shuffle);
  # vertex index -> cluster index -> norm
  my $norms = $self->compute_norms($clusters);
  my $score;
  my $new_score = $self->compute_score($clusters, $norms);
  do {
    $clusters = $self->step($clusters, $norms);
    croak "Number of clusters became less than k_min=$k_min"
      if @$clusters < $k_min;
    $norms = $self->compute_norms($clusters);
    $score = $new_score;
    $new_score = $self->compute_score($clusters, $norms);
  } until $converged->($score, $new_score);

  [ map { $self->vertices_of($_) } @$clusters ];
}

__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

Algorithm::KernelKMeans::PP

=head1 SYNOPSIS

  use Algorithm::KernelKMeans::PP;

=head1 DESCRIPTION

This class is a pure-Perl implementation of weighted kernel k-means algorithm.

L<Algorithm::KernelKMeans> inherits this class by default.

=head1 AUTHOR

Koichi SATOH E<lt>sekia@cpan.orgE<gt>

=head1 SEE ALSO

L<Algorithm::KernelKMeans>

L<Algorithm::KernelKMeans::XS> - Yet another implementation. Fast!

=head1 LICENSE

The MIT License

Copyright (C) 2010 by Koichi SATOH

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=cut
