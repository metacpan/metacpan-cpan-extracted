package Algorithm::BIT2D::XS;

use 5.014000;
use strict;
use warnings;

our $VERSION = '0.002';

use Algorithm::BIT::XS;

sub new {
	my ($class, $n, $m) = @_;
	create($n, $m);
}

sub get {
	my ($b, $i1, $i2) = @_;
	$b->query($i1, $i2) + $b->query($i1 - 1, $i2 - 1)
	  - $b->query($i1 - 1, $i2) - $b->query($i1, $i2 - 1);
}

sub set {
	my ($b, $i1, $i2, $value) = @_;
	$b->update($i1, $i2, $value - $b->get($i1, $i2))
}

1;
__END__

=encoding utf-8

=head1 NAME

Algorithm::BIT2D::XS - 2D Binary indexed trees / Fenwick trees

=head1 SYNOPSIS

  use Algorithm::BIT2D::XS;
  my $bit = Algorithm::BIT2D::XS->new(100, 100);
  $bit->update(1, 2, 5);  # bit[1][2] += 5
  $bit->update(3, 3, 6);  # bit[3][3] += 6
  say 'bit[1..2][1..10]  == ', $bit->query(2, 10);  # 5
  say 'bit[1..3][1..2]   == ', $bit->query(3, 2);  # 5
  say 'bit[1..20][1..10] == ', $bit->query(20, 10); # 11

  $bit->update(3, 1, 10); # bit[3][1] += 10
  say 'bit[1..3][1..3]  == ', $bit->query(3, 3);  # 21
  say 'bit[3][3] == ', $bit->get(3, 3); # 6

  $bit->set(3, 3, 10); # bit[3][3] = 10
  say 'bit[3][3] == ', $bit->get(3, 3); # 10

  $bit->clear;
  say 'bit[1..100][1..10] == ', $bit->query(100, 10); # 0
  $bit->set(100, 10, 5);
  say 'bit[1..100][1..10] == ', $bit->query(100, 10); # 5

=head1 DESCRIPTION

A binary indexed tree is a data structure similar to an array of integers.
The two main operations are updating an element and calculating a
prefix sum, both of which run in time logarithmic in the size of the tree.

=over

=item Algorithm::BIT2D::XS->B<new>(I<$n>, I<$m>)

Create a new 2D binary indexed tree of length I<$n> x I<$m>. As binary
indexed trees are 1-indexed, its indexes are [1..I<$n>][1..I<$m>].
It is initially filled with zeroes.

=item $bit->B<clear>()

Clears the binary indexed tree (sets all elements to 0).

=item $bit->B<query>(I<$i1>, I<$i2>)

Returns the rectangle sum from I<$bit>[1][1] to I<$bit>[I<$i1>][I<$i2>].

=item $bit->B<update>(I<$i1>, I<$i2>, I<$value>)

Adds I<$value> to I<$bit>[I<$i1>][I<$i2>].

=item $bit->B<get>(I<$i1>, I<$i2>)

Returns the value of I<$bit>[I<$i1>][I<$i2>].

=item $bit->B<set>(I<$i1>, I<$i2>, I<$value>)

Sets I<$bit>[I<$i1>][I<$i2>] to I<$value>.

=back

=head1 SEE ALSO

L<Algorithm::BIT>, L<Algorithm::BIT::XS>, L<https://en.wikipedia.org/wiki/Fenwick_tree>

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
