package Algorithm::FuzzyCmeans;

use strict;
use warnings;
use base qw(Class::Accessor::Fast);
use Carp;
use List::MoreUtils qw(any);
use List::Util qw(shuffle);
use UNIVERSAL::require;

our $VERSION = '0.02';

__PACKAGE__->mk_accessors($_) for qw(vectors centroids memberships m distance);

use constant DEFAULT_M => 2.0;

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( {@_} );
    $self->vectors({})  if !$self->vectors;
    $self->centroids([])  if !$self->centroids;
    $self->memberships({})  if !$self->memberships;
    $self->m(DEFAULT_M) if !defined $self->m;
    croak '`m\' parameter must be more than 1.0' if $self->m <= 1.0;

    my $dist_class = delete $self->{distance_class};
    $dist_class ||= 'Algorithm::FuzzyCmeans::Distance::Cosine';
    $dist_class->require or croak $@;
    $self->distance($dist_class->new());
    return $self;
}

sub add_document {
    my ($self, $id, $vector) = @_;
    return if !defined $id || !$vector;
    $self->vectors->{$id} = $vector;
}

sub do_clustering {
    my ($self, $num_cluster, $num_iter) = @_;
    $self->_choose_random_centroids($num_cluster);
    for (my $i = 0; $i < $num_iter; $i++) {
        $self->_calc_memberships();
        $self->_calc_centroids($num_cluster);
    }
}

sub _choose_random_centroids {
    my ($self, $num_centroid) = @_;
    my @ids = keys %{ $self->vectors };
    @ids = shuffle @ids;
    my @centroids = map { $self->vectors->{$_} } @ids[0 .. $num_centroid-1];
    $self->centroids(\@centroids);
}

sub _calc_memberships {
    my $self = shift;
    $self->memberships({});
    my $num_centroid = scalar @{ $self->centroids };
    foreach my $id (keys %{ $self->vectors }) {
        my @distances;
        foreach my $centroid (@{ $self->centroids }) {
            my $dist = $self->distance->distance(
                $self->vectors->{$id}, $centroid);
            push @distances, $dist;
        }
        if (any { $_ == 0 } @distances) {
            foreach my $dist (@distances) {
                push @{ $self->memberships->{$id} }, $dist == 0 ? 1 : 0;
            }
        }
        else {
            for (my $i = 0; $i < $num_centroid; $i++) {
                my $membership;
                for (my $j = 0; $j < $num_centroid; $j++) {
                    my $x = $distances[$i] / $distances[$j];
                    $membership += $x * $x;
                }
                $membership **= (-1) / ($self->m - 1);
                push @{ $self->memberships->{$id} }, $membership;
            }
        }
    }
}

sub _calc_centroids {
    my ($self, $num_centroid) = @_;

    # initialize centroids
    $self->centroids([]);
    map { push @{ $self->centroids }, {} } (0 .. $num_centroid-1);

    # sum of memberships
    my @membership_sums;
    for (my $i = 0; $i < $num_centroid; $i++) {
        push @membership_sums, 0;
    }
    foreach my $id (keys %{ $self->memberships} ) {
        for (my $i = 0; $i < $num_centroid; $i++) {
            $membership_sums[$i] += $self->memberships->{$id}[$i] ** 2;
        }
    }
    
    # calc centroid position
    foreach my $id (keys %{ $self->vectors }) {
        for (my $i = 0; $i < $num_centroid; $i++) {
            foreach my $key (keys %{ $self->vectors->{$id} }) {
                $self->centroids->[$i]{$key} += $self->memberships->{$id}[$i] ** 2
                    * $self->vectors->{$id}{$key} / $membership_sums[$i];
            }
        }
    }
}

1;

__END__

=head1 NAME

Algorithm::FuzzyCmeans - perl implementation of Fuzzy c-means clustering

=head1 SYNOPSIS

  use Algorithm::FuzzyCmeans;
  
  # input documents
  my %documents = (
      Alex => { 'Pop'     => 10, 'R&B'    => 6, 'Rock'   => 4 },
      Bob  => { 'Jazz'    => 8,  'Reggae' => 9                },
      Dave => { 'Classic' => 4,  'World'  => 4                },
      Ted  => { 'Jazz'    => 9,  'Metal'  => 2, 'Reggae' => 6 },
      Fred => { 'Hip-hop' => 3,  'Rock'   => 3, 'Pop'    => 3 },
      Sam  => { 'Classic' => 8,  'Rock'   => 1                },
  );
  
  my $fcm = Algorithm::FuzzyCmeans->new(
      distance_class => 'Algorithm::FuzzyCmeans::Distance::Cosine',
      m              => 2.0,
  );
  foreach my $id (keys %documents) {
      $fcm->add_document($id, $documents{$id});
  }
  
  my $num_cluster = 3;
  my $num_iter    = 20;
  $fcm->do_clustering($num_cluster, $num_iter);             
  
  # show clustering result
  foreach my $id (sort { $a cmp $b } keys %{ $fcm->memberships }) {
      printf "%s\t%s\n", $id,
          join "\t", map { sprintf "%.4f", $_ } @{ $fcm->memberships->{$id} };
  }
  # show cluster centroids
  foreach my $centroid (@{ $fcm->centroids }) {
      print join "\t", map { sprintf "%s:%.4f", $_, $centroid->{$_} }
          keys %{ $centroid };
      print "\n";
  }

=head1 DESCRIPTION

Algorithm::FuzzyCmeans is a perl implementation of Fuzzy c-means clustering.

=head1 METHODS

=head2 new

Create a new instance.

`m' option is a fuzzyness coefficient, and must be more than 1.0 (default: 2.0).

`distance_class' option is a class name with distance function between vectors. Currently, 'Algorithm::FuzzyCmeans::Distance::Euclid'(euclid distance) and 'Algorithm::FuzzyCmeans::Distance::Cosine'(cosine distance) are supported (default: cosine).

=head2 add_document($id, $vector)

Add an input document to the instance of Algorithm::FuzzyCmeans. $id parameter is the identifier of a document, and $vector parameter is the feature vector of a document. $vector parameter must be a hash reference, each key of $vector parameter is the identifier of the feature of documents and each value of $vector is the degree of the feature.

=head2 do_clustering($num_cluster, $num_iter)

Do clustering input documents. $num_cluster parameter specifies the number of output clusters, and $num_iter parameter specifies the number of clustering iterations.

=head2 memberships

This method is the accessor of clustering result. The output of the method is a hash reference, the key is the identifier of each input document, and the value is the list of the degrees of membership of each input document in output clusters.

=head2 centroids

This method is the accessor of the vectors of cluster centroids.

=head1 AUTHOR

Mizuki Fujisawa E<lt>fujisawa@bayon.ccE<gt>

=head1 SEE ALSO

=over

=item Wikipedia: Fuzzy c-means clustering
http://en.wikipedia.org/wiki/Cluster_Analysis#Fuzzy_c-means_clustering

=back

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
