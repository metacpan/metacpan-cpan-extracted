package Algorithm::BIT::XS;

use 5.014000;
use strict;
use warnings;

our $VERSION = '0.002';

require XSLoader;
XSLoader::load('Algorithm::BIT::XS', $VERSION);

sub new {
	my ($class, $len) = @_;
	create($len);
}

sub get {
	my ($b, $idx) = @_;
	$b->query($idx) - $b->query($idx - 1);
}

sub set {
	my ($b, $idx, $value) = @_;
	$b->update($idx, $value - $b->get($idx))
}

1;
__END__

=encoding utf-8

=head1 NAME

Algorithm::BIT::XS - Binary indexed trees / Fenwick trees

=head1 SYNOPSIS

  use Algorithm::BIT::XS;
  my $bit = Algorithm::BIT::XS->new(100);
  $bit->update(1, 5);  # bit[1] += 5
  $bit->update(3, 6);  # bit[3] += 6
  say 'bit[1..2]  == ', $bit->query(2);  # 5
  say 'bit[1..3]  == ', $bit->query(3);  # 11
  say 'bit[1..20] == ', $bit->query(20); # 11

  $bit->update(3, 10); # bit[3] += 10
  say 'bit[1..3]  == ', $bit->query(3);  # 21
  say 'bit[3] == ', $bit->get(3); # 16

  $bit->set(3, 10); # bit[3] = 10
  say 'bit[3] == ', $bit->get(3); # 10

  $bit->clear;
  say 'bit[1..100] == ', $bit->query(100); # 0
  $bit->set(100, 5);
  say 'bit[1..100] == ', $bit->query(100); # 5

=head1 DESCRIPTION

A binary indexed tree is a data structure similar to an array of integers.
The two main operations are updating an element and calculating a
prefix sum, both of which run in time logarithmic in the size of the tree.

=over

=item Algorithm::BIT::XS->B<new>(I<$len>)

Create a new binary indexed tree of length I<$len>. As binary indexed
trees are 1-indexed, its indexes are [1..I<$len>]. It is initially
filled with zeroes.

=item $bit->B<clear>()

Clears the binary indexed tree (sets all elements to 0).

=item $bit->B<query>(I<$idx>)

Returns the prefix sum I<$bit>[1] + I<$bit>[2] + ... + I<$bit>[I<$idx>].

=item $bit->B<update>(I<$idx>, I<$value>)

Adds I<$value> to I<$bit>[I<$idx>].

=item $bit->B<get>(I<$idx>)

Returns the value of I<$bit>[I<$idx>].

=item $bit->B<set>(I<$idx>, I<$value>)

Sets I<$bit>[I<$idx>] to I<$value>.

=back

=head1 SEE ALSO

L<Algorithm::BIT>, L<Algorithm::BIT2D::XS>, L<https://en.wikipedia.org/wiki/Fenwick_tree>

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
