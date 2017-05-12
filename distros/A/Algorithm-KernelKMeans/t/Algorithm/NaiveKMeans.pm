# very rough implementation of naive k-means algorithm for comparison
package Algorithm::NaiveKMeans;

use 5.010;
use strict;
use warnings;

use Carp;
use List::Util qw/sum shuffle/;
use List::MoreUtils qw/natatime/;
use Moose;
use MooseX::Types::Common::Numeric qw/PositiveNum/;
use MooseX::Types::Moose qw/ArrayRef HashRef CodeRef/;
use POSIX qw/floor/;

use ExtUtils::testlib;
use Algorithm::KernelKMeans::Util qw/centroid/;

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

sub sub_vector {
  my ($x1, $x2) = @_;
  my %tmp; @tmp{keys %$x1, keys %$x2} = ();
  my %sub = map {
    my ($e1, $e2) = (($x1->{$_} // 0), ($x2->{$_} // 0));
    ($_ => $e1 - $e2);
  } keys %tmp;
  \%sub;
}

sub norm {
  my $vec = shift;
  sqrt sum map { $_ ** 2 } values %$vec;
}

sub score {
  my ($self, $clusters) = @_;
  my $score = 0;
  for my $cluster (@$clusters) {
    my $centroid = centroid $cluster;
    for my $vertex (@$cluster) { $score += norm sub_vector($vertex, $centroid) }
  }
  return $score;
}

sub init_clusters {
  my ($self, $k, $shuffle) = @_;
  my @vertices = $shuffle ? shuffle @{ $self->vertices } : @{ $self->vertices };
  my $n = floor(@vertices / $k);
  my $iter = natatime $n, @vertices;
  my @clusters;
  while (my @cluster = $iter->()) { push @clusters, \@cluster; }
  if (@{ $clusters[-1] } < $n) {
    my $last_cluster = pop @clusters;
    push @{ $clusters[-1] }, @$last_cluster;
  }
  return \@clusters;
}

sub step {
  my ($self, $clusters) = @_;
  my @centroids = map { centroid $_ } @$clusters;
  my @new_clusters = map { [] } (1 .. @$clusters);
  for my $vertex (map { (@$_) } @$clusters) {
    my $i = 0;
    my ($nearest) = sort { $a->[1] <=> $b->[1] } map {
      [ $i++ => norm(sub_vector($vertex, $_)) ]
    } @centroids;
    push @{ $new_clusters[$nearest->[0]] }, $vertex;
  }
  [ grep { @$_ != 0 } @new_clusters ];
}

sub run {
  my ($self, %opts) = @_;
  my $k = delete $opts{k} // croak 'Required argument "k" missing';
  my $k_min = delete $opts{k_min} // $k;
  my $converged = delete $opts{converged} // sub {
    my ($score, $new_score) = @_;
    $score == $new_score;
  };
  my $shuffle = delete $opts{shuffle} // 1;

  my $clusters = $self->init_clusters($k, $shuffle);
  my $new_score = $self->score($clusters);
  while (1) {
    $clusters = $self->step($clusters);
    my $score = $new_score;
    $new_score = $self->score($clusters);
    return $clusters if $converged->($score, $new_score);
  }
}

__PACKAGE__->meta->make_immutable;
