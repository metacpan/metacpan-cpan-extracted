package Algorithm::QuadTree::XS;
$Algorithm::QuadTree::XS::VERSION = '0.07';
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

# NOTE: this implementation lives here for XS to load properly, but a separate
# file including this module is present to allow regular perl module loading to
# find it by name
package Algorithm::QuadTree::XS::NoBackRefs;
$Algorithm::QuadTree::XS::NoBackRefs::VERSION = '0.07';
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

Generated using C<tools/benchmark.pl> available in the GitHub repository. Tree depth was 6.

L<Algorithm::QuadTree::XS::NoBackRefs>

	Benchmark: ran clear, find_circle, find_rectangle, insert_circles, insert_rectangles.
	            clear: 1.68907e-05 +- 1.3e-09 wallclock secs (0.00770%) @ (59204.2 +-    4.7)/s (n=211)
	      find_circle: 3.5331e-05 +- 1.1e-08 wallclock secs (0.0311%) @ (28303.6 +-    8.6)/s (n=201)
	   find_rectangle: 3.6176e-05 +- 1.3e-08 wallclock secs (0.0359%) @ (27643 +-    10)/s (n=203)
	   insert_circles: 1.03584e-04 +- 1.7e-08 wallclock secs (0.0164%) @ ( 9654 +-   1.6)/s (n=204)
	insert_rectangles: 1.01218e-04 +- 1.3e-08 wallclock secs (0.0128%) @ (9879.7 +-   1.3)/s (n=202)

B<Algorithm::QuadTree::XS>

	Benchmark: ran clear, find_circle, find_rectangle, insert_circles, insert_rectangles.
	            clear: 5.7209e-05 +- 4.6e-08 wallclock secs (0.0804%) @ (17480 +-    14)/s (n=203)
	      find_circle: 3.3665e-05 +- 3.0e-08 wallclock secs (0.0891%) @ (29705 +-    26)/s (n=205)
	   find_rectangle: 2.7731e-05 +- 1.9e-08 wallclock secs (0.0685%) @ (36061 +-    25)/s (n=269)
	   insert_circles: 1.46677e-04 +- 5.8e-08 wallclock secs (0.0395%) @ (6817.7 +-   2.7)/s (n=207)
	insert_rectangles: 1.35100e-04 +- 3.4e-08 wallclock secs (0.0252%) @ (7401.9 +-   1.9)/s (n=211)

B<Algorithm::QuadTree::PP>

	Benchmark: ran clear, find_circle, find_rectangle, insert_circles, insert_rectangles.
	            clear: 1.40270e-03 +- 1.6e-07 wallclock secs (0.0114%) @ (712.91 +-  0.084)/s (n=212)
	      find_circle: 1.58290e-04 +- 2.9e-08 wallclock secs (0.0183%) @ (6317.5 +-   1.2)/s (n=207)
	   find_rectangle: 1.01350e-04 +- 3.5e-08 wallclock secs (0.0345%) @ (9866.8 +-   3.4)/s (n=207)
	   insert_circles: 3.59243e-03 +- 4.4e-07 wallclock secs (0.0122%) @ (278.363 +-  0.034)/s (n=208)
	insert_rectangles: 1.129783e-03 +- 9.4e-08 wallclock secs (0.00832%) @ (885.125 +-  0.074)/s (n=210)

=head1 SEE ALSO

L<Algorithm::QuadTree>

L<Algorithm::QuadTree::XS::NoBackRefs>

=head1 AUTHOR

Bartosz Jarzyna, E<lt>bbrtj.pro@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) by Bartosz Jarzyna

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

