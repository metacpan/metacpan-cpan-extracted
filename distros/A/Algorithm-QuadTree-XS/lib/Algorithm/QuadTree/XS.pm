package Algorithm::QuadTree::XS;
$Algorithm::QuadTree::XS::VERSION = '0.10';
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

	     clear: 1.64694e-05 +- 1.7e-09 wallclock secs (0.0103%) @ (60718.8 +-    6.1)/s (n=204)
	  find_100: 2.70163e-05 +- 4.8e-09 wallclock secs (0.0178%) @ (37014.7 +-    6.6)/s (n=203)
	insert_100: 1.37381e-04 +- 3.5e-08 wallclock secs (0.0255%) @ ( 7279 +-   1.8)/s (n=215)

	# backend: Algorithm::QuadTree::PP

	     clear: 1.24342e-03 +- 2.7e-07 wallclock secs (0.0217%) @ (804.23 +-  0.18)/s (n=205)
	  find_100: 2.45547e-04 +- 2.7e-08 wallclock secs (0.0110%) @ (4072.54 +-   0.45)/s (n=208)
	insert_100: 2.13336e-03 +- 3.6e-07 wallclock secs (0.0169%) @ (468.744 +-  0.079)/s (n=206)

Generated using C<tools/benchmark.pl> available in the GitHub repository. Tree
depth was 6.

=over

=item * benchmark C<clear>

Inserts into a tree a giant object which spans the entire area, then clear the
tree. This forces clearing procedure to go into each leaf and clear it, which
is worst-case scenario.

=item * benchmark C<find_100>

A predeclared tree exists with 10 elements inserted in the middle of the area.
Tree is queried 10 times, 5 times with rectangular coordinates and 5 times with
circular coordinates. All 10 items are returned each time, resulting in 100
items returned total.

=item * benchmark C<insert_100>

Clears a tree and inserts 50 circles and 50 rectangles to it. Those objects are
placed in a way so that none of them overlap.

=back

=head1 SEE ALSO

L<Algorithm::QuadTree>

=head1 AUTHOR

Bartosz Jarzyna, E<lt>bbrtj.pro@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) by Bartosz Jarzyna

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

