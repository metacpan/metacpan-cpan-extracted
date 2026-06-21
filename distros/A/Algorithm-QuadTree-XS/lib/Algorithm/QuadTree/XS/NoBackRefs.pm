use Algorithm::QuadTree::XS;

1;
__END__

=head1 NAME

Algorithm::QuadTree::XS::NoBackRefs - Faster implementation that can't track objects

=head1 SYNOPSIS

	BEGIN { $ENV{ALGORITHM_QUADTREE_BACKEND} = 'Algorithm::QuadTree::XS::NoBackRefs'; }
	use Algorithm::QuadTree;

=head1 DESCRIPTION

This XS backend for quad trees is speed-boosted at the expense of the C<delete>
operations. The extra speed is achieved by skipping storing backreferences,
which allow to quickly find all nodes containing the object, so it can be
deleted much more quickly. In scenarios where the quad tree is constantly
cleared and all objects are inserted from scratch, backreferences are a
liability which force extra costly hash operations on each inserted object, in
each of the tree's leaves.

When this backend is used and a C<delete> method is called, an exception will be thrown.

This implementation is not fully compatible with C<Algorithm::QuadTree::PP>.

=head1 SEE ALSO

L<Algorithm::QuadTree>

L<Algorithm::QuadTree::XS>

