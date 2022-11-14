package Algorithm::QuadTree::XS;
$Algorithm::QuadTree::XS::VERSION = '0.04';
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

This implementation is compatible with C<Algorithm::QuadTree::PP>. Benchmarks
on author's machine show it runs at least five times faster (depending on the
tree depth).

B<Beta quality>: while this module works well in general cases, it may also
contain errors common to C code like memory leaks or access violations. Please
do report if you encounter any problems.

=head1 SEE ALSO

L<Algorithm::QuadTree>

=head1 AUTHOR

Bartosz Jarzyna, E<lt>bbrtj.pro@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) by Bartosz Jarzyna

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

