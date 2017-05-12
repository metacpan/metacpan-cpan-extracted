package Data::BitStream::Code::Rice;
use strict;
use warnings;
BEGIN {
  $Data::BitStream::Code::Rice::AUTHORITY = 'cpan:DANAJ';
  $Data::BitStream::Code::Rice::VERSION = '0.08';
}

our $CODEINFO = { package   => __PACKAGE__,
                  name      => 'Rice',
                  universal => 0,
                  params    => 1,
                  encodesub => sub {shift->put_rice(@_)},
                  decodesub => sub {shift->get_rice(@_)}, };

use Moo::Role;
requires qw(read write put_unary get_unary);

sub put_rice {
  my $self = shift;
  my $sub = shift if ref $_[0] eq 'CODE';  ## no critic
  my $k = shift;

  $self->error_code('param', 'k must be >= 0') unless $k >= 0;
  return( (defined $sub) ? $sub->($self, @_) : $self->put_unary(@_) ) if $k==0;

  foreach my $val (@_) {
    $self->error_code('zeroval') unless defined $val and $val >= 0;
    my $q = $val >> $k;
    my $r = $val - ($q << $k);
    (defined $sub)  ?  $sub->($self, $q)  :  $self->put_unary($q);
    $self->write($k, $r);
  }
  1;
}
sub get_rice {
  my $self = shift;
  my $sub = shift if ref $_[0] eq 'CODE';  ## no critic  ## no critic
  my $k = shift;

  $self->error_code('param', 'k must be >= 0') unless $k >= 0;
  return( (defined $sub) ? $sub->($self, @_) : $self->get_unary(@_) ) if $k==0;

  my $count = shift;
  if    (!defined $count) { $count = 1;  }
  elsif ($count  < 0)     { $count = ~0; }   # Get everything
  elsif ($count == 0)     { return;      }

  my @vals;
  $self->code_pos_start('Rice');
  while ($count-- > 0) {
    $self->code_pos_set;
    my $q = (defined $sub)  ?  $sub->($self)  :  $self->get_unary();
    last unless defined $q;
    my $remainder = $self->read($k);
    $self->error_off_stream unless defined $remainder;
    push @vals, ($q << $k)  |  $remainder;
  }
  $self->code_pos_end;
  wantarray ? @vals : $vals[-1];
}
no Moo::Role;
1;

# ABSTRACT: A Role implementing Rice codes

=pod

=head1 NAME

Data::BitStream::Code::Rice - A Role implementing Rice codes

=head1 VERSION

version 0.08

=head1 DESCRIPTION

A role written for L<Data::BitStream> that provides get and set methods for
Rice codes.  The role applies to a stream object.

Note that this is just the Rice code (C<Golomb(2^k)>) themselves,
and does not include algorithms for data adaptation.

These codes are sometimes called GPO2 (Golomb-power-of-2) codes.

Beware that with the default unary coding for the quotient, these codes can
become extraordinarily long for values much larger than C<2^k>.

"I<...a Rice code (and by extension a Golomb code) is very well suited to
peaked distributions with few small values or large values.  As noted earlier,
the Rice(k) code is extremely efficient for values in the general range
C<2^(k-1) < N < 2^(k+2)>>"
  -- Lossless Compression Handbook, page 75, by Khalid Sayood

=head1 METHODS

=head2 Provided Object Methods

=over 4

=item B< put_rice($k, $value) >

=item B< put_rice($k, @values) >

Insert one or more values as Rice codes with parameter k.  Returns 1.

=item B< put_rice(sub { ... }, $k, @values) >

Insert one or more values as Rice codes using the user provided subroutine
instead of the traditional Unary code for the base.  For example, the so-called
"Exponential-Golomb" encoding can be performed using the sub:

  sub { shift->put_gamma(@_); }

=item B< get_rice($k) >

=item B< get_rice($k, $count) >

Decode one or more Rice codes from the stream.  If count is omitted,
one value will be read.  If count is negative, values will be read until
the end of the stream is reached.  In scalar context it returns the last
code read; in array context it returns an array of all codes read.

=item B< get_rice(sub { ... }, $k) >

Similar to the regular get method except using the user provided subroutine
instead of unary encoding the base.  For example:

  sub { shift->get_gamma(@_); }

=back

=head2 Parameters

The parameter C<k> must be an integer greater than or equal to 0.

The quotient C<value E<gt>E<gt> k> is encoded using unary (or via the user
supplied subroutine), followed by the lowest C<k> bits.

Note: if C<k == 0> then the result will be coded purely using unary (or the
supplied sub) coding.

Note: this is a special case of a C<Golomb(m)> code where C<m = 2^k>.

Rice coding is often preceded by a step that adapts the parameter to the
data seen so far.  Rice's paper encodes 21-pixel prediction blocks using one
of three codes.  The JPEG-LS LOCO-I algorithm uses a constantly adapting k
parameter to encode the prediction errors.

=head2 Required Methods

=over 4

=item B< read >

=item B< write >

=item B< get_unary >

=item B< put_unary >

These methods are required for the role.

=back

=head1 SEE ALSO

=over 4

=item L<Data::BitStream::Code::Golomb>

=item L<Data::BitStream::Code::GammaGolomb>

=item L<Data::BitStream::Code::ExponentialGolomb>

=item L<http://en.wikipedia.org/wiki/Golomb_coding>

=item S.W. Golomb, "Run-length encodings", IEEE Transactions on Information Theory, vol 12, no 3, pp 399-401, 1966.

=item R.F. Rice and R. Plaunt, "Adaptive Variable-Length Coding for Efficient Compression of Spacecraft Television Data", IEEE Transactions on Communications, vol 16, no 9, pp 889-897, Dec. 1971.

=back

=head1 AUTHORS

Dana Jacobsen <dana@acm.org>

=head1 COPYRIGHT

Copyright 2011 by Dana Jacobsen <dana@acm.org>

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
