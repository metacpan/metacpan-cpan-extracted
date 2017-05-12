package Algorithm::Cluster::Thresh;
BEGIN {
  $Algorithm::Cluster::Thresh::VERSION = '0.05';
}
# ABSTRACT: Adds thresholding to hierarchical clustering of Algorithm::Cluster
use Algorithm::Cluster;



# Add new method to standard package:
package Algorithm::Cluster::Tree;
BEGIN {
  $Algorithm::Cluster::Tree::VERSION = '0.05';
}
use strict;
use warnings;
use 5.008;

sub cutthresh {
    my ($tree, $thresh) = @_;   
    my @nodecluster;
    my @leafcluster;
    # Binary tree: number of internal nodes is 1 less than # of leafs
    # Last node is the root, walking down the tree
    my $icluster = 0;
    # Elements in tree
    my $length = $tree->length;
    # Root node belongs to cluster 0
    $nodecluster[$length-1] = $icluster++;
    for (my $i = $length-1; $i >= 0; $i--) {        
        my $node = $tree->get($i);
#        print sprintf "%3d %3d %.3f\n", $i,$nodecluster[$i], $node->distance;
        my $left = $node->left;
        # Nodes are numbered -1,-2,... Leafs are numbered 0,1,2,...
        my $leftref = $left < 0 ? \$nodecluster[-$left-1] : \$leafcluster[$left];
        my $assigncluster = $nodecluster[$i];
        # Left is always the same as the parent node's cluster
        $$leftref = $assigncluster;
#        print sprintf "\tleft  %3d %3d\n", $left, $$leftref;
        my $right = $node->right;
        # Put right into a new cluster, when thresh not satisfied
        if ($node->distance > $thresh) { $assigncluster = $icluster++ }
        my $rightref = $right < 0 ? \$nodecluster[-$right-1] : \$leafcluster[$right];
        $$rightref = $assigncluster;
#        print sprintf "\tright %3d %3d\n", $right, $$rightref;
    }
    return wantarray ? @leafcluster : \@leafcluster;
}

1;

__END__
=pod

=head1 NAME

Algorithm::Cluster::Thresh - Adds thresholding to hierarchical clustering of Algorithm::Cluster

=head1 VERSION

version 0.05

=head1 SYNOPSIS

 use Algorithm::Cluster::Thresh;
 
 # Assuming you have a lower diagonal distance matrix ...
 # See L<Algorithm::Cluster> and / or L<Algorithm::DistanceMatrix>
 my $distmatrix; 
 
 use Algorithm::Cluster qw/treecluster/;
 my $tree = treecluster(data=>$distmatrix, method=>'a'); # 'a'verage linkage
 
 # Get your objects and the cluster IDs they belong to
 # Clusters are within 5.5 of each other (based on average linkage here)
 my $cluster_ids = $tree->cutthresh(5.5);

 # Index corresponds to that of the original objects
 print 'Object 2 belongs to cluster number ', $cluster_ids->[2], "\n";

=head1 DESCRIPTION

This is a small helper package for L<Algorithm::Cluster>, but not an official
part of it. That manual can be found here:

 http://cpansearch.perl.org/src/MDEHOON/Algorithm-Cluster-1.48/doc/cluster.pdf

This package adds a simple method C<$tree->cutthresh(5.5)> to permit clustering
by thresholds, rather than by needing to pre-define the number of clusters to 
be created.

This is a Pure Perl module. It's not as efficient as the XS approach, which has
already been submitted as a patch:

 https://rt.cpan.org/Public/Bug/Display.html?id=68482

In the meantime, this module provides a Pure Perl implementation.

=head1 NAME

Algorithm::Cluster::Thresh - Hierarchical clustering with variable thresholds

=head1 VERSION

version 0.05

=head1 SOURCE

 https://github.com/chadadavis/Algorithm-Cluster-Thresh

=head1 METHODS

=head2 cutthresh

Returns an array, where the value of each array element is the integer cluster
ID of that object.

Returns a reference to the array in scalar context.

=head1 AUTHOR

Chad A. Davis <chad.a.davis@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Chad A. Davis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

