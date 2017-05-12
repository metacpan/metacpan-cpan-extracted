package Algorithm::KNN::XS;
use 5.006001;
use strict;
use warnings;

our $VERSION = '0.01001';

require XSLoader;
XSLoader::load('Algorithm::KNN::XS', $VERSION);

our %ANN_SPLIT_RULE = (
    'ANN_KD_SUGGEST'  => 0,
    'ANN_KD_STD'      => 1,
    'ANN_KD_MIDPT'    => 2,
    'ANN_KD_FAIR'     => 3,
    'ANN_KD_SL_MIDPT' => 4,
    'ANN_KD_SL_FAIR'  => 5,
);

our %ANN_SHRINK_RULE = (
    'ANN_BD_SUGGEST'  => 0,
    'ANN_BD_NONE'     => 1,
    'ANN_BD_SIMPLE'   => 2,
    'ANN_BD_CENTROID' => 3,
);

=head1 NAME

Algorithm::KNN::XS - A class interface to perform a fast k neareast neighbor
search using libANN via XS.

=head1 SYNOPSIS

    use Algorithm::KNN::XS;
    
    # define data points in a N dimensional space
    my @points = (
      [7.45, 2],
      [16.56, 32.1],
    );
    
    # create a new knn object
    my $knn = Algorithm::KNN::XS->new(points => \@points);
    
    # perform a k nearest neighbor search at the given query point, the result
    # contains all neighbors and their distance to the query point.
    my $result = $knn->annkSearch(query_point => [4.23, 2.45]);

=head1 DESCRIPTION

A class interface todo a fast k nearest neighbor search using libANN via XS.

The XS Module automatically creates the namespace
Algorithm::KNN::XS::LibANNInterface.

More information about libANN can be found with the following links.

libANN main page: L<http://www.cs.umd.edu/~mount/ANN/>
libANN manual: L<http://www.cs.umd.edu/~mount/ANN/Files/1.1.2/ANNmanual_1.1.pdf>

If you want to use another Minkowski distance metric than "Euclidean" you must
compile another libANN library with the correct options before building this
Module. Possible other distances are "Manhatten" and "Max".

=head1 USAGE

=head2 Methods

=over 4

=item * Algorithm::KNN::XS->new ( ... )

This class method instantiates a new kd or bd tree from a points array or a
string of a dumped tree.

If points and a dump string is given, the dump string will be ignored.

The method will croak if something goes wrong.

libANN will do a exit(1) which is not catchable via eval if a wrong dump
string is given, so make sure that the dump is valid before using that
parameter.

    my $knn = Algorithm::KNN::XS->new(
        points      => [
            [3.453, 2.324],
            [6.874, 4.874],
        ],
        dump        => '',
        bd_tree     => 1,
        bucket_size => 1,
        split_rule  => 'ANN_KD_SUGGEST',
        shrink_rule => 'ANN_BD_SUGGEST',
    );

=over 8

=item * points

The number of points provided in each element also sets the dimension of the
tree that is going to be created. Each item must have the same amount of
points.

Either this or the dump parameter is mandatory.

=item * dump

A String of a tree that got dumped via the method Dump(points => 1) of this
module.

You can use a dump of a kd tree to create a bd tree but not the other way
around.

libANN will do a exit(1) which is not catchable via eval if you try to input
a string that was dumped without the "points" parameter set to 1 or if the
string is not a valid dump.

Either this or the points parameter is mandatory.

=item * bd_tree

If set to 1 a bd tree will be created, otherwise a kd tree is used.

=item * bucket_size

Must be greater 1 and influences the split and shrinking rule behaviour.

Please refer the libANN manual for further information.

The default value is 1.

=item * split_rule

A String which sets the splitting rule. Possible values are: ANN_KD_SUGGEST,
ANN_KD_STD, ANN_KD_MIDPT, ANN_KD_FAIR, ANN_KD_SL_MIDPT and ANN_KD_SL_FAIR.

Please refer the libANN manual for the meaning of these values but for the
most people ANN_KD_SUGGEST should work well.

The default value is ANN_KD_SUGGEST.

=item * shrink_rule

A String which sets the shrinking rule. Possible values are: ANN_BD_SUGGEST,
ANN_BD_NONE, ANN_BD_SIMPLE, ANN_BD_CENTROID.

Please refer the libANN manual for the meaning of these values but for the
most people ANN_BD_SUGGEST should work well.

This parameter only affects bd trees.

The default value is ANN_BD_SUGGEST.

=back

=back

=cut

sub new {
    my ($class, %args) = @_;

    $args{split_rule}  = 'ANN_KD_SUGGEST'
        if !$args{split_rule} || !$ANN_SPLIT_RULE{$args{split_rule}};

    $args{shrink_rule} = 'ANN_BD_SUGGEST'
        if !$args{shrink_rule} || !$ANN_SHRINK_RULE{$args{shrink_rule}};

    my $self = {
        _tree => Algorithm::KNN::XS::LibANNInterface->new(
            $args{points} || [],
            $args{dump} || '',
            $args{bd_tree} ? 1 : 0,
            $args{bucket_size} || 1,
            $ANN_SPLIT_RULE{$args{split_rule}},
            $ANN_SHRINK_RULE{$args{shrink_rule}},
        ),
    };

    bless $self, $class;
    return $self;
}

=over 4

=item * $knn->tree()

This class method returns the current tree object and can be used to access
the XS methods directly.

    my $tree = $knn->tree();

=back

=cut

sub tree {
    return shift->{_tree};
}

=over 4

=item * $knn->set_annMaxPtsVisit( ... )

This class method sets the maximum number of points that the search methods
are going to process before they abort. They can return more points than the
set value because the abort condition is only checked before processing a
leaf node.

    $knn->set_annMaxPtsVisit(
        max_points => 5,
    );

=over 8

=item * max_points

Must be 0 or greater. The value 0 means no limit.

The default value is 0.

=back

=back

=cut

sub set_annMaxPtsVisit {
    my ($self, %args) = @_;

    return $self->tree->set_annMaxPtsVisit($args{max_points} || 0);
}

=over 4

=item * $knn->annkSearch( ... )

This class method performs a k nearest neighbor search.

    my %result = $knn->annkSearch(
        query_point      => [],
        limit_neighbors => 0,
        epsilon          => 0,
    );

=over 8

=item * query_point

A list of points which must be the same dimension as the tree.

=item * limit_neighbors

Determines how many neighbors should be returned. The value 0 means no limit.

The default value is 0.

=item * epsilon

The relative error bound for approximate nearest neighbor searching. Please
refer the libANN manual for more information.

The default value is 0.

=item * Return value

Following structure is returned:

    my $result = [
        # 'distance' is the squared distance to the given query point
        # (the query point found itself in this case)
        {
            'distance' => '0',
            'point' => [
                '1.1345', 
                '2.657'
            ]
        }, {
            'distance' => '15.00963986',
            'point' => [
                '4.023',
                '5.2389'
            ]
        }
    ];

=back

=back

=cut

sub annkSearch {
    my ($self, %args) = @_;

    return $self->_restructure_return_value(
        $self->tree->annkSearch($args{query_point}, $args{limit_neighbors} || 0, $args{epsilon} || 0)
    );
}

=over 4

=item * $knn->annkPriSearch( ... )

This class method performs a k nearest neighbor priority search as described
by Arya and Mount, please refer the libANN manual for further information.

    my %result = $knn->annkPriSearch(
        query_point      => [],
        limit_neighbors => 0,
        epsilon          => 0,
    );

=over 8

=item * query_point

A list of points which must be the same dimension as the tree.

=item * limit_neighbors

Determines how many neighbors should be returned. The value 0 means no limit.

The default value is 0.

=item * epsilon

The relative error bound for approximate nearest neighbor searching. Please
refer the libANN manual for more information.

The default value is 0.

=item * Return value

Following structure is returned:

    my $result = [
        # 'distance' is the squared distance to the given query point
        # (the query point found itself in this case)
        {
            'distance' => '0',
            'point' => [
                '1.1345', 
                '2.657'
            ]
        }, {
            'distance' => '15.00963986',
            'point' => [
                '4.023',
                '5.2389'
            ]
        }
    ];

=back

=back

=cut

sub annkPriSearch {
    my ($self, %args) = @_;

    return $self->_restructure_return_value(
        $self->tree->annkPriSearch($args{query_point}, $args{limit_neighbors} || 0, $args{epsilon} || 0)
    );
}

=over 4

=item * $knn->annkFRSearch( ... )

This class method performs a fixed radius k nearest neighbor search.

    my %result = $knn->annkFRSearch(
        query_point      => [],
        limit_neighbors => 0,
        epsilon          => 0,
        radius           => 10,
    );

=over 8

=item * query_point

A list of points which must be the same dimension as the tree.

=item * limit_neighbors

Determines how many neighbors should be returned. The value 0 means no limit.

The default value is 0.

=item * epsilon

The relative error bound for approximate nearest neighbor searching. Please
refer the libANN manual for more information.

The default value is 0.

=item * radius

The radius in which the search should take place.

Defaults to 0.

=item * Return value

Following Structure is returned:

Following structure is returned:

    my $result = [
        # 'distance' is the squared distance to the given query point
        # (the query point found itself in this case)
        {
            'distance' => '0',
            'point' => [
                '1.1345', 
                '2.657'
            ]
        }, {
            'distance' => '15.00963986',
            'point' => [
                '4.023',
                '5.2389'
            ]
        }
    ];

=back

=back

=cut

sub annkFRSearch {
    my ($self, %args) = @_;

    return $self->_restructure_return_value(
        $self->tree->annkFRSearch($args{query_point}, $args{limit_neighbors} || 0, $args{epsilon} || 0, $args{radius} || 0)
    );
}

=over 4

=item * $knn->annCntNeighbours( ... )

This class method performs a fixed radius k nearest neighbor search and
returns the number of neighbors.

    my $neighbors = $knn->annCntNeighbours(
        query_point      => [],
        epsilon          => 0,
        radius           => 10,
    );

=over 8

=item * query_point

A list of points which must be the same dimension as the tree.

=item * epsilon

The relative error bound for approximate nearest neighbor searching. Please
refer the libANN manual for more information.

The default value is 0.

=item * radius

The radius in which the search should take place.

The default value is 0.

=item * Return value

Number of found neighbors.

=back

=back

=cut

sub annCntNeighbours {
    my ($self, %args) = @_;

    return $self->tree->annCntNeighbours($args{query_point}, $args{epsilon} || 0, $args{radius} || 0);
}

=over 4

=item * $knn->theDim()

Returns the dimension that the points in the current tree have.

    my $dimension = $knn->theDim();

=over 8

=item * Return value

Dimension of the tree points.

=back

=back

=cut

sub theDim {
    return shift->tree->theDim();
}

=over 4

=item * $knn->nPoints()

Returns the number of points in the current tree.

    my $n_points = $knn->nPoints();

=over 8

=item * Return value

Number of points in the tree.

=back

=back

=cut

sub nPoints {
    return shift->tree->nPoints();
}

=over 4

=item * $knn->Print( ... )

Prints the current tree. Normally useful for debugging.

    my $output = $knn->Print(
        points => 1,
    );

=over 8

=item * points

If set to 1 all points will be printed at the top of the output.

The default value is 1.

=item * Return value

A string of the printed tree.

=back

=back

=cut

sub Print {
    my ($self, %args) = @_;
    $args{points}     = 1 if !defined $args{points};

    return $self->tree->Print($args{points});
}

=over 4

=item * $knn->Dump( ... )

Dumps the current tree. The dump can be passed into the new method to
initialize a new tree or to visualize it via the external programm ann2fig.

    my $output = $knn->Dump(
        points => 1,
    );

=over 8

=item * points

If set to 1 all points will be printed at the top of the output. The new
methods only accepts a tree that got dumped with points set to 1.

The default value is 1.

=item * Return value

A string of the dumped tree.

=back

=back

=cut

sub Dump {
    my ($self, %args)   = @_;
    $args{points} = 1 if !defined $args{points};

    return $self->tree->Dump($args{points});
}

=over 4

=item * $knn->getStats()

Returns statistics about the current tree.

    my $stats = $knn->getStats();

=over 8

=item * Return value

A hash reference of the following format:

    my $stats = {
        dimension             => 2,
        n_points              => 7,
        bucket_size           => 1,
        leaves                => 7,
        trvial_leaves         => 0,
        splitting_nodes       => 6,
        shrinking_nodes       => 0,
        depth                 => 4,
        avg_leaf_aspect_ratio => 1.61012744903564,
    };

=back

=back

=cut

sub getStats {
    my $stats = shift->tree->getStats();

    return {
        dimension             => $stats->[0],
        n_points              => $stats->[1],
        bucket_size           => $stats->[2],
        leaves                => $stats->[3],
        trvial_leaves         => $stats->[4],
        splitting_nodes       => $stats->[5],
        shrinking_nodes       => $stats->[6],
        depth                 => $stats->[7],
        avg_leaf_aspect_ratio => $stats->[8],
    };
}

# helper function to get the data in a better to handle array of hashes
sub _restructure_return_value {
    my $self             = shift;
    my $result           = shift;
    my $idx_last_element = $self->tree()->theDim();

    my @return_value;

    foreach my $idx (0 .. scalar @{$result} - 1) {
        foreach my $idx_element (0 .. $idx_last_element) {
            if ($idx_element != $idx_last_element) {
                push @{$return_value[$idx]->{point}}, $result->[$idx]->[$idx_element];
            }
            else {
                $return_value[$idx]->{distance} = $result->[$idx]->[$idx_element];
            }
        }
    }

    return \@return_value;
}

=head1 SEE ALSO

=over 4

=item * L<http://www.cs.umd.edu/~mount/ANN/>

=item * L<http://www.cs.umd.edu/~mount/ANN/Files/1.1.2/ANNmanual_1.1.pdf>

=back

=head1 AUTHOR

Stephan Conrad, E<lt>conrad@stephanconrad.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Stephan Conrad

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6.1 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;

__END__
