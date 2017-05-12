package Algorithm::Kmeanspp;

use strict;
use warnings;
use base qw(Class::Accessor::Fast);
use Carp qw(croak);
use List::Util qw(shuffle);

our $VERSION = '0.03';

__PACKAGE__->mk_accessors($_) for qw(vectors centroids clusters);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( {@_} );
    $self->vectors({})  if !$self->vectors;
    $self->centroids([])  if !$self->centroids;
    $self->clusters([])  if !$self->clusters;
    return $self;
}

sub add_document {
    my ($self, $id, $vector) = @_;
    return if !defined $id || !$vector;
    $self->vectors->{$id} = $vector;
}

sub do_clustering {
    my ($self, $num_cluster, $num_iter) = @_;
    croak 'The number of clusters must be less than the number of input documents.'
        if $num_cluster > scalar(keys %{ $self->vectors });
    croak 'The number of clusters must be greater than zero.'
        if $num_cluster <= 0;

    map { push @{ $self->clusters }, [] } (0 .. $num_cluster-1);
    $self->_choose_smart_centroids($num_cluster);
    my $assignment = $self->_assign_cluster;
    for (my $i = 0; $i < $num_iter; $i++) {
        $self->_move_centroids;
        my $new_assignment = $self->_assign_cluster;
        my $is_changed = 0;
        foreach my $id (keys %{ $assignment }) {
            if ($assignment->{$id} != $new_assignment->{$id}) {
                $is_changed = 1;
                last;
            }
        }
        last if !$is_changed;
        $assignment = $new_assignment if $new_assignment;
    }
}

sub _choose_smart_centroids {
    my ($self, $num_cluster) = @_;
    my $cur_potential = 0;

    # choose one random centroid
    my $vector = (shuffle values %{ $self->vectors })[0];
    push @{ $self->centroids }, $vector;
    my %closest_dist;
    foreach my $id (keys %{ $self->vectors }) {
        $closest_dist{$id} = $self->_squared_euclid_distance(
            $self->vectors->{$id}, $vector);
        $cur_potential += $closest_dist{$id};
    }
    # choose each centroid
    for (my $i = 1; $i < $num_cluster; $i++) {
        my $randval = rand() * $cur_potential;
        my $centroid_id;
        foreach my $id (keys %{ $self->vectors }) {
            $centroid_id = $id;
            last if $randval <= $closest_dist{$id};
            $randval -= $closest_dist{$id};
        }
        my $new_potential = 0;
        foreach my $id (keys %{ $self->vectors }) {
            my $dist = $self->_squared_euclid_distance(
                $self->vectors->{$id}, $self->vectors->{$centroid_id});
            $closest_dist{$id} = $dist if $dist < $closest_dist{$id};
            $new_potential += $closest_dist{$id};
        }
        push @{ $self->centroids }, $self->vectors->{$centroid_id};
        $cur_potential = $new_potential;
    }
}

sub _assign_cluster {
    my $self = shift;
    my $num_cluster = scalar @{ $self->centroids };
    map { $self->clusters->[$_] = [] } (0 .. $num_cluster-1);

    my %assignment;
    foreach my $id (keys %{ $self->vectors }) {
        my $min_dist = -1;
        my $min_index;
        for (my $i = 0; $i < $num_cluster; $i++) {
            my $dist = $self->_squared_euclid_distance(
                $self->vectors->{$id}, $self->centroids->[$i]);
            if ($min_dist < 0 || $min_dist > $dist) {
                $min_dist = $dist;
                $min_index = $i;
            }
        }
        $assignment{$id} = $min_index;
        push @{ $self->clusters->[$min_index] }, $id;
    }
    return \%assignment;
}

sub _move_centroids {
    my ($self, $assignment) = @_;
    for (my $i = 0; $i < scalar @{ $self->centroids }; $i++) {
        my $cluster = $self->clusters->[$i];
        next if !$cluster;
        my %new_centroid;
        foreach my $id (@{ $cluster }) {
            my $vector = $self->vectors->{$id};
            map { $new_centroid{$_} += $vector->{$_} }
                keys %{ $self->vectors->{$id} };
        }
        map { $new_centroid{$_} /= scalar(keys %new_centroid) }
            keys %new_centroid;
        $self->centroids->[$i] = \%new_centroid;
    }
}

sub _squared_euclid_distance {
    my ($self, $vec1, $vec2) = @_;
    my %keys;
    map { $keys{$_} = 1 } keys %{ $vec1 };
    map { $keys{$_} = 1 } keys %{ $vec2 };
    my $dist = 0;
    foreach my $key (keys %keys) {
        my $val1 = $vec1->{$key} || 0;
        my $val2 = $vec2->{$key} || 0;
        $dist += ($val1 - $val2) ** 2;
    }
    return $dist;
}

1;

__END__

=head1 NAME

Algorithm::Kmeanspp - perl implementation of K-means++

=head1 SYNOPSIS

  use Algorithm::Kmeanspp;
  
  # input documents
  my %documents = (
      Alex => { 'Pop'     => 10, 'R&B'    => 6, 'Rock'   => 4 },
      Bob  => { 'Jazz'    => 8,  'Reggae' => 9                },
      Dave => { 'Classic' => 4,  'World'  => 4                },
      Ted  => { 'Jazz'    => 9,  'Metal'  => 2, 'Reggae' => 6 },
      Fred => { 'Hip-hop' => 3,  'Rock'   => 3, 'Pop'    => 3 },
      Sam  => { 'Classic' => 8,  'Rock'   => 1                },
  );
  
  my $kmp = Algorithm::Kmeanspp->new;
  
  foreach my $id (keys %documents) {
      $kmp->add_document($id, $documents{$id});
  }
  
  my $num_cluster = 3;
  my $num_iter    = 20;
  $kmp->do_clustering($num_cluster, $num_iter);             
  
  # show clustering result
  foreach my $cluster (@{ $kmp->clusters }) {
      print join "\t", @{ $cluster };
      print "\n";
  }
  # show cluster centroids
  foreach my $centroid (@{ $kmp->centroids }) {
      print join "\t", map { sprintf "%s:%.4f", $_, $centroid->{$_} }
          keys %{ $centroid };
      print "\n";
  }

=head1 DESCRIPTION

Algorithm::Kmeanspp is a perl implementation of K-means++.

=head1 METHODS

=head2 new

Create a new instance.

=head2 add_document($id, $vector)

Add an input document to the instance of Algorithm::Kmeanspp. $id parameter is the identifier of a document, and $vector parameter is the feature vector of a document. $vector parameter must be a hash reference, each key of $vector parameter is the identifier of the feature of documents and each value of $vector is the degree of the feature.

=head2 do_clustering($num_cluster, $num_iter)

Do clustering input documents. $num_cluster parameter specifies the number of output clusters, and $num_iter parameter specifies the number of clustering iterations.

=head2 clusters

This method is the accessor of clustering result. The output of the method is a array reference, and each item in the array reference includes the list of the identifiers of input documents in each cluster.

  # format of output clusters
  [
      [ document_id1, document_id2, ... ],  # cluster-1
      [ document_id3, document_id4, ... ],  # cluster-2
      ...
  ]

=head2 centroids

This method is the accessor of the vectors of cluster centroids.

=head1 AUTHOR

Mizuki Fujisawa E<lt>fujisawa@bayon.ccE<gt>

=head1 SEE ALSO

=over

=item Wikipedia: K-means++

http://en.wikipedia.org/wiki/K-means%2B%2B

=back

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
