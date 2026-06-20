package Algorithm::QuadTree::XS;
$Algorithm::QuadTree::XS::VERSION = '0.06';
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

B<XS>

	Benchmark: ran clear, find_circle, find_rectangle, insert_circles, insert_rectangles.
	            clear: 9.1155e-05 +- 6.2e-08 wallclock secs (0.0680%) @ (10970.3 +-    7.5)/s (n=207)
	      find_circle: 5.4967e-05 +- 2.5e-08 wallclock secs (0.0455%) @ (18192.9 +-    8.3)/s (n=204)
	   find_rectangle: 4.7784e-05 +- 2.0e-08 wallclock secs (0.0419%) @ (20927.4 +-    8.7)/s (n=205)
	   insert_circles: 2.36597e-04 +- 9.6e-08 wallclock secs (0.0406%) @ (4226.6 +-   1.7)/s (n=208)
	insert_rectangles: 2.15474e-04 +- 7.3e-08 wallclock secs (0.0339%) @ (4640.9 +-   1.6)/s (n=201)

B<PP>

	Benchmark: ran clear, find_circle, find_rectangle, insert_circles, insert_rectangles.
	            clear: 2.2492e-03 +- 1.3e-06 wallclock secs (0.0578%) @ (444.61 +-  0.26)/s (n=204)
	      find_circle: 2.59805e-04 +- 7.9e-08 wallclock secs (0.0304%) @ ( 3849 +-   1.2)/s (n=208)
	   find_rectangle: 1.64389e-04 +- 5.4e-08 wallclock secs (0.0328%) @ (6083.1 +-     2)/s (n=208)
	   insert_circles: 5.7887e-03 +- 1.8e-06 wallclock secs (0.0311%) @ (172.75 +-  0.054)/s (n=202)
	insert_rectangles: 1.80404e-03 +- 3.2e-07 wallclock secs (0.0177%) @ (554.311 +-  0.097)/s (n=206)

=head1 SEE ALSO

L<Algorithm::QuadTree>

=head1 AUTHOR

Bartosz Jarzyna, E<lt>bbrtj.pro@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) by Bartosz Jarzyna

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

