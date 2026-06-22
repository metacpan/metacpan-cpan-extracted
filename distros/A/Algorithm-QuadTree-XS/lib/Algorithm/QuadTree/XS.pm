package Algorithm::QuadTree::XS;
$Algorithm::QuadTree::XS::VERSION = '0.09';
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

# NOTE: this implementation lives here for XS to load properly, but a separate
# file including this module is present to allow regular perl module loading to
# find it by name
package Algorithm::QuadTree::XS::NoBackRefs;
$Algorithm::QuadTree::XS::NoBackRefs::VERSION = '0.09';
use strict;
use warnings;
use Exporter qw(import);
use Carp qw(croak);

our @EXPORT = qw(
	_AQT_init
	_AQT_deinit
	_AQT_addObject
	_AQT_findObjects
	_AQT_delete
	_AQT_clear
);

use constant UNIQUE_RESULTS => 1;

sub _AQT_delete
{
	croak 'delete is not supported with ' . __PACKAGE__;
}

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

	# backend: Algorithm::QuadTree::XS::NoBackRefs

	     clear: 1.460114e-05 +- 9.1e-10 wallclock secs (0.00623%) @ (68487.8 +-    4.3)/s (n=201)
	  find_100: 2.96563e-05 +- 8.4e-09 wallclock secs (0.0283%) @ (33719.6 +-    9.6)/s (n=203)
	insert_100: 1.22024e-04 +- 3.6e-08 wallclock secs (0.0295%) @ (8195.1 +-   2.4)/s (n=216)

	# backend: Algorithm::QuadTree::XS

	     clear: 5.5851e-05 +- 6.8e-08 wallclock secs (0.122%) @ (17905 +-    22)/s (n=206)
	  find_100: 2.79711e-05 +- 4.0e-09 wallclock secs (0.0143%) @ (35751.2 +-    5.2)/s (n=202)
	insert_100: 1.7825e-04 +- 1.2e-07 wallclock secs (0.0673%) @ (5610.2 +-   3.7)/s (n=228)

	# backend: Algorithm::QuadTree::PP

	     clear: 1.43388e-03 +- 2.4e-07 wallclock secs (0.0167%) @ (697.41 +-  0.12)/s (n=200)
	  find_100: 2.57478e-04 +- 5.6e-08 wallclock secs (0.0217%) @ (3883.82 +-   0.85)/s (n=201)
	insert_100: 2.29717e-03 +- 2.0e-07 wallclock secs (0.00871%) @ (435.318 +-  0.038)/s (n=211)


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

L<Algorithm::QuadTree::XS::NoBackRefs>

=head1 AUTHOR

Bartosz Jarzyna, E<lt>bbrtj.pro@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) by Bartosz Jarzyna

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

