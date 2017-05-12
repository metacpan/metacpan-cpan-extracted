#!/usr/bin/env perl
# ABSTRACT: Compute distance matrix for any distance metric

package Algorithm::DistanceMatrix;
BEGIN {
  $Algorithm::DistanceMatrix::VERSION = '0.04';
}
use Moose;

has 'mode' =>(
    is => 'rw',
    isa => 'Str',
    default => 'lower',
    );

  
has 'metric' => (
    is=>'rw',
    isa=>'CodeRef',
    default=>sub{abs($_[0]-$_[1])},
    );


has 'objects' => (
    is => 'rw',
    isa => 'ArrayRef',
    );
    
    
sub distancematrix {
    my ($self, ) = @_;
    # Callback function
    my $metric = $self->metric;
    my $objects = $self->objects;
    my $n = @$objects;
    my $distances = [];
    for (my $i = 0; $i < $n; $i++) {
        # This initialization is required to prevent 'undef' at [0,0], 
        $distances->[$i] ||= [];
        # Diagonal or full matrix?
        my $start = $self->mode =~ /full/i ? 0 : $i+1;
        for (my $j = $start; $j < $n; $j++) {
            # Use a pointer, then determine if it's row-major or col-major order
            # Swap i and j if lower diagonal (default)
            my $ref = $self->mode =~ /lower/i ? 
                \$distances->[$j][$i] : \$distances->[$i][$j];  
            # Callback function provides the distance
            $$ref = $metric->($objects->[$i], $objects->[$j]);
        }
    }
    # Last diagonal element is undef, unless explicitly computed
    $distances->[$n-1] = [(undef)x$n] if $self->mode =~ /upper/i;
    return $distances;
}


__PACKAGE__->meta->make_immutable;
no Moose;
1;
__END__
=pod

=head1 NAME

Algorithm::DistanceMatrix - Compute distance matrix for any distance metric

=head1 VERSION

version 0.04

=head1 SYNOPSIS

 use Algorithm::DistanceMatrix;
 my $m = Algorithm::DistanceMatrix->new(
     metric=>\&mydistance,objects=\@myarray);
 my $distmatrix =  $m->distancematrix;
 
 use Algorithm::Cluster qw/treecluster/;
 # method=>
 # s: single-linkage clustering
 # http://en.wikipedia.org/wiki/Single-linkage_clustering
 # m: maximum- (or complete-) linkage clustering
 # http://en.wikipedia.org/wiki/Complete_linkage_clustering
 # a: average-linkage clustering (UPGMA)
 # http://en.wikipedia.org/wiki/UPGMA
 
 my $tree = treecluster(data=>$distmat, method=>'a');
 
 # Get your objects and the cluster IDs they belong to, assuming 5 clusters
 my $cluster_ids = $tree->cut(5);
 # Index corresponds to that of the original objects
 print $objects->[2], ' belongs to cluster ', $cluster_ids->[2], "\n";

=head1 DESCRIPTION

This is a small helper package for L<Algorithm::Cluster>. That module provides 
many facilities for clustering data. It also provides a C<distancematrix> function,
but assumes tabular data, which is the standard for gene expression data. 

If your data is tabular, you should first have a look at C<distancematrix> in
L<Algorithm::Cluster>

 http://cpansearch.perl.org/src/MDEHOON/Algorithm-Cluster-1.48/doc/cluster.pdf

Otherwise, this package provides a simple distance matrix, given an arbitrary 
distance function. It does not assume anything about your data. You simply 
provide a callback function for measuring the distance between any two objects.
It produces a lower diagonal (by default) distance matrix that is fit to be used
by the clustering algorithms of L<Algorithm::Cluster>.

=head1 NAME

Algorithm::DistanceMatrix - Compute distance matrix for any distance metric

=head1 VERSION

version 0.04

=head1 METHODS

=head2 mode

One of C<qw/lower upper full/> for a lower diagonal, upper diagonal, or full 
distance matrix.

=head2 metric

Callback for computing the distance, similarity, or whatever measure you like.

 $matrix->metric(\@mydistance);

Where C<mydistance> receives two objects as it's first two arguments.

If you need to pass special parameters to your method:

 $matrix->metric(sub{my($x,$y)=@_;mydistance(first=>$x,second=>$y,mode=>'fast')};

You may use any metric, and may return any number or object. Note that if you 
plan to use this with L<Algorithm::Cluster> this needs to be a distance metric.
So, if you're measure how similar two things are, on a scale of 1-10, then you
should return C<10-$similarity> to get a distance.

Default is the absolute values of the scalar difference (i.e. C<abs(X-Y)>)

=head2 objects

Array reference. Doesn't matter what kind of objects are in the array, as long
as your C<metric> can process them.

=head2 distancematrix

2D array of distances (or similarities, or whatever) between your objects.

(An ArrayRef of ArrayRefs.)

=head1 AUTHOR

Chad A. Davis <chad.a.davis@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Chad A. Davis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

