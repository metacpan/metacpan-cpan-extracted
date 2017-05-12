package Data::BitStream::Code::ExponentialGolomb;
use strict;
use warnings;
BEGIN {
  $Data::BitStream::Code::ExponentialGolomb::AUTHORITY = 'cpan:DANAJ';
  $Data::BitStream::Code::ExponentialGolomb::VERSION   = '0.08';
}

our $CODEINFO = { package   => __PACKAGE__,
                  name      => 'ExpGolomb',
                  universal => 1,
                  params    => 1,
                  encodesub => sub {shift->put_expgolomb(@_)},
                  decodesub => sub {shift->get_expgolomb(@_)}, };

use Moo::Role;
requires qw(put_rice put_gamma get_rice get_gamma);

# Basic put implementation:
#
#   my $k = shift;
#   foreach my $val (@_) {
#     $self->put_gamma($val >> $k);
#     $self->write($k, $val);
#   }
#

sub put_expgolomb {
  my $self = shift;
  $self->put_rice( sub { shift->put_gamma(@_); }, @_ );
}

sub get_expgolomb {
  my $self = shift;
  $self->get_rice( sub { shift->get_gamma(@_); }, @_ );
}

no Moo::Role;
1;

# ABSTRACT: A Role implementing Exponential-Golomb codes

=pod

=head1 NAME

Data::BitStream::Code::ExponentialGolomb - A Role implementing Exponential-Golomb codes

=head1 VERSION

version 0.08

=head1 DESCRIPTION

A role written for L<Data::BitStream> that provides get and set methods for
Exponential-Golomb codes.  The role applies to a stream object.

Exponential-Golomb codes are Rice codes using an Elias Gamma code instead of
a Unary code for the upper bits.  Rice codes in turn are Golomb codes
where the parameter m is a power of two.  Hence:

               Rice(k)  ~  Golomb(2^k)
  ExponentialGolomb(k)  ~  GammaGolomb(2^k)

=head1 METHODS

=head2 Provided Object Methods

=over 4

=item B< put_expgolomb($k, $value) >

=item B< put_expgolomb($k, @values) >

Insert one or more values as Exponential-Golomb codes with parameter k.
Returns 1.

=item B< get_expgolomb($k) >

=item B< get_expgolomb($k, $count) >

Decode one or more Exponential-Golomb codes from the stream.  If count is
omitted, one value will be read.  If count is negative, values will be read
until the end of the stream is reached.  In scalar context it returns the
last code read; in array context it returns an array of all codes read.

=back

=head2 Parameters

The parameter C<k> must be an integer greater than or equal to 0.

The quotient C<value E<gt>E<gt> k> is encoded using an Elias Gamma code,
followed by the lowest C<k> bits.

Note: if C<k == 0> then the result will be coded purely using gamma coding.

Note: this is a special case of a C<GammaGolomb(m)> code where C<m = 2^k>.

=head2 Required Methods

=over 4

=item B< put_rice >

=item B< put_gamma >

=item B< get_rice >

=item B< get_gamma >

These methods are required for the role.

=back

=head1 SEE ALSO

=over 4

=item L<Data::BitStream::Code::Golomb>

=item L<Data::BitStream::Code::Rice>

=item L<Data::BitStream::Code::GammaGolomb>

=item L<http://en.wikipedia.org/wiki/Exponential-Golomb_coding>

=back

=head1 AUTHORS

Dana Jacobsen <dana@acm.org>

=head1 COPYRIGHT

Copyright 2011 by Dana Jacobsen <dana@acm.org>

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
