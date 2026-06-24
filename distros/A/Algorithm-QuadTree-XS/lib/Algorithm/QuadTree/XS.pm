package Algorithm::QuadTree::XS;
$Algorithm::QuadTree::XS::VERSION = '0.12';
use strict;
use warnings;
use Exporter qw(import);

our @EXPORT = qw(
	_AQT_init
	_AQT_deinit
	_AQT_addObject
	_AQT_findObjects
	_AQT_delete
	_AQT_clear
);

use constant UNIQUE_RESULTS => 1;

require XSLoader;
XSLoader::load('Algorithm::QuadTree::XS', $Algorithm::QuadTree::XS::VERSION);

1;
__END__

=head1 NAME

Algorithm::QuadTree::XS - XS backend for Algorithm::QuadTree

=head1 SYNOPSIS

  use Algorithm::QuadTree;

  # Algorithm::QuadTree::XS will be used automatically if it is available

=head1 DESCRIPTION

This distribution contains XS implementation of quadtrees.

This implementation is compatible with C<Algorithm::QuadTree::PP>.

=head1 BENCHMARK

	# backend: Algorithm::QuadTree::XS
	        find_100: 5.2622e-05 +- 1.7e-08 wallclock secs (0.0323%) @ (19003.4 +-    6.2)/s (n=208)
	  find_100_check: 5.7178e-05 +- 2.3e-08 wallclock secs (0.0402%) @ (17489.1 +-    6.9)/s (n=200)
	  insert_100_big: 2.57407e-04 +- 7.8e-08 wallclock secs (0.0303%) @ (3884.9 +-   1.2)/s (n=208)
	insert_100_small: 1.50146e-04 +- 3.1e-08 wallclock secs (0.0206%) @ (6660.2 +-   1.4)/s (n=208)

	# backend: Algorithm::QuadTree::PP

	        find_100: 5.9995e-04 +- 1.4e-07 wallclock secs (0.0233%) @ (1666.8 +-   0.39)/s (n=205)
	  find_100_check: 6.7605e-04 +- 1.1e-07 wallclock secs (0.0163%) @ (1479.18 +-   0.23)/s (n=204)
	  insert_100_big: 1.36311e-02 +- 3.3e-06 wallclock secs (0.0242%) @ (73.361 +- 0.018)/s (n=206)
	insert_100_small: 4.3928e-03 +- 1.2e-06 wallclock secs (0.0273%) @ (227.647 +-  0.063)/s (n=209)

Generated using C<tools/benchmark.pl> available in the GitHub repository. Tree
depth was 6.

=over

=item * benchmark C<find_100>

A predeclared tree exists with big 10 elements inserted in the middle of the
area.  Tree is queried 10 times, 5 times with rectangular coordinates and 5
times with circular coordinates. All 10 items are returned each time, resulting
in 100 items returned total. The queried area is as large as the objects in the tree.

=item * benchmark C<find_100_check>

Same as above, but C<CHECK> flag is enabled to check the shapes overlaping.

=item * benchmark C<insert_100_small>

Clears a tree and inserts 50 circles and 50 rectangles to it. Those objects are
placed in a way so that none of them overlap.

=item * benchmark C<insert_100_big>

Same as above, but the objects inserted are 5 times larger. Due to their size,
they overlap.

=back

=head1 SEE ALSO

L<Algorithm::QuadTree>

=head1 AUTHOR

Bartosz Jarzyna, E<lt>bbrtj.pro@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) by Bartosz Jarzyna

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

