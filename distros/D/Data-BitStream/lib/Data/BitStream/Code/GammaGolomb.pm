package Data::BitStream::Code::GammaGolomb;
use strict;
use warnings;
BEGIN {
  $Data::BitStream::Code::GammaGolomb::AUTHORITY = 'cpan:DANAJ';
  $Data::BitStream::Code::GammaGolomb::VERSION   = '0.08';
}

our $CODEINFO = { package   => __PACKAGE__,
                  name      => 'GammaGolomb',
                  universal => 1,
                  params    => 1,
                  encodesub => sub {shift->put_gammagolomb(@_)},
                  decodesub => sub {shift->get_gammagolomb(@_)}, };

use Moo::Role;
requires qw(put_golomb put_gamma get_golomb get_gamma);

sub put_gammagolomb {
  my $self = shift;
  $self->put_golomb( sub { shift->put_gamma(@_); }, @_ );
}
sub get_gammagolomb {
  my $self = shift;
  $self->get_golomb( sub { shift->get_gamma(@_); }, @_ );
}
no Moo::Role;
1;

# ABSTRACT: A Role implementing Gamma-Golomb codes

=pod

=head1 NAME

Data::BitStream::Code::GammaGolomb - A Role implementing Gamma-Golomb codes

=head1 VERSION

version 0.08

=head1 DESCRIPTION

A role written for L<Data::BitStream> that provides get and set methods for
Gamma-Golomb codes.  The role applies to a stream object.

Gamma-Golomb codes are basically Golomb codes using the Elias Gamma code
for the quotient instead of a Unary code.  This makes them suitable for
occasional large outliers that would otherwise use thousands or millions of
bits to encode.

In particular, the GammaGolomb(3) code is interesting for some distributions.

=head1 METHODS

=head2 Provided Object Methods

=over 4

=item B< put_gammagolomb($m, $value) >

=item B< put_gammagolomb($m, @values) >

Insert one or more values as Gamma-Golomb codes with parameter m.  Returns 1.

=item B< get_gammagolomb($m) >

=item B< get_gammagolomb($m, $count) >

Decode one or more Gamma-Golomb codes from the stream.  If count is omitted,
one value will be read.  If count is negative, values will be read until
the end of the stream is reached.  In scalar context it returns the last
code read; in array context it returns an array of all codes read.

=back

=head2 Parameters

The parameter C<m> must be an integer greater than or equal to 1.

The quotient of C<value / m> is encoded using an Elias Gamma code,
followed by the remainder in truncated binary form.

Note: if C<m == 1> then the result will be coded purely using gamma coding.

Note: if C<m> is a power of 2 (C<m = 2^k> for some non-negative integer
C<k>), then the result is equal to the simpler C<ExpGolomb(k)> code, where the
operations devolve into a shift and mask.

=head2 Required Methods

=over 4

=item B< put_golomb >

=item B< put_gamma >

=item B< get_golomb >

=item B< get_gamma >

These methods are required for the role.

=back

=head1 SEE ALSO

=over 4

=item L<Data::BitStream::Code::Golomb>

=item L<Data::BitStream::Code::Rice>

=item L<Data::BitStream::Code::ExponentialGolomb>

=item L<http://en.wikipedia.org/wiki/Exponential-Golomb_coding>

=item S.W. Golomb, "Run-length encodings", IEEE Transactions on Information Theory, vol 12, no 3, pp 399-401, 1966.

=item R.F. Rice and R. Plaunt, "Adaptive Variable-Length Coding for Efficient Compression of Spacecraft Television Data", IEEE Transactions on Communications, vol 16, no 9, pp 889-897, Dec. 1971.

=back

=head1 AUTHORS

Dana Jacobsen <dana@acm.org>

=head1 COPYRIGHT

Copyright 2011 by Dana Jacobsen <dana@acm.org>

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
