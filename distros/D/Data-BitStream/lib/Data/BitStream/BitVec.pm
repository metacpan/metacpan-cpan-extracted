package Data::BitStream::BitVec;
use strict;
use warnings;
BEGIN {
  $Data::BitStream::BitVec::AUTHORITY = 'cpan:DANAJ';
}
BEGIN {
  $Data::BitStream::BitVec::VERSION = '0.08';
}

use Moo;
use MooX::Types::MooseLike::Base qw/InstanceOf/;

with 'Data::BitStream::Base',
     'Data::BitStream::Code::Gamma',
     'Data::BitStream::Code::Delta',
     'Data::BitStream::Code::Omega',
     'Data::BitStream::Code::Levenstein',
     'Data::BitStream::Code::EvenRodeh',
     'Data::BitStream::Code::Fibonacci',
     'Data::BitStream::Code::Golomb',
     'Data::BitStream::Code::Rice',
     'Data::BitStream::Code::GammaGolomb',
     'Data::BitStream::Code::ExponentialGolomb',
     'Data::BitStream::Code::Baer',
     'Data::BitStream::Code::BoldiVigna',
     'Data::BitStream::Code::ARice',
     'Data::BitStream::Code::Additive',
     'Data::BitStream::Code::Comma',
     'Data::BitStream::Code::Taboo',
     'Data::BitStream::Code::BER',
     'Data::BitStream::Code::Varint',
     'Data::BitStream::Code::StartStop';

use Bit::Vector;
use 5.009_002;   # Using pack("Q<", $v) for big endian machines

has '_vec' => (is => 'rw',
               isa => InstanceOf['Bit::Vector'],
               default => sub { return Bit::Vector->new(0) });

after 'erase' => sub {
  my $self = shift;
  $self->_vec->Resize(0);
  1;
};
after 'write_close' => sub {
  my $self = shift;
  $self->_vec->Resize($self->len);
  1;
};

sub read {
  my $self = shift;
  die "get while writing" if $self->writing;
  my $bits = shift;
  die "Invalid bits" unless defined $bits && $bits > 0 && $bits <= $self->maxbits;
  my $peek = (defined $_[0]) && ($_[0] eq 'readahead');

  my $pos = $self->pos;
  my $len = $self->len;
  return if $pos >= $len;
  die "read off end of stream" if !$peek && ($pos+$bits) > $len;
  my $vref = $self->_vec;

  my $val;
  if ($bits == 1) {
    $val = $vref->bit_test($pos);
  } else {
    # Simple but slow code:
    #   $val = 0;
    #   foreach my $bit (0 .. $bits-1) {
    #     last if $pos+$bit >= $len;
    #     $val |= (1 << ($bits-$bit-1))  if $vref->bit_test($pos + $bit);
    #   }
    #
    # Read a chunk.  The returned value has the bits in LSB order.
    my $c = $vref->Chunk_Read($bits, $pos);
    my $pval = ($bits > 32) ? pack("Q<", $c) : pack("V", $c);
    { no warnings 'portable';  $val = oct("0b" . unpack("b$bits", $pval)); }
  }

  $self->_setpos( $pos + $bits ) unless $peek;
  $val;
}
sub write {
  my $self = shift;
  my $bits = shift;
  my $val  = shift;
  die "Bits must be > 0" unless $bits > 0;
  die "put while not writing" unless $self->writing;
  my $len  = $self->len;
  my $vref = $self->_vec;

  #$self->_vec->Resize( $len + $bits );
  # Bit::Vector will spend a LOT of time expanding its vector.  It's >REALLY<
  # slow.  It will exponentially dominate the time taken to write.  Hence
  # I will aggressively expand it.
  {
    my $vsize = $vref->Size();
    if (($len+$bits) > $vsize) {
      $vsize = int( ($len+$bits+2048) * 1.15 );
      $vref->Resize($vsize);
    }
  }

  if ($val == 0) {
    # Nothing
  } elsif ($val == 1) {
    $vref->Bit_On( $len + $bits - 1 );
  } else {
    # Simple method:
    #  my $wpos = $len + $bits-1;
    #  foreach my $bit (0 .. $bits-1) {
    #    $vref->Bit_On( $wpos - $bit )  if  (($val >> $bit) & 1);
    #  }
    # Alternate: reverse the bits of val and use efficient Chunk_Store
    my $pval = ($bits > 32) ? pack("Q<", $val) : pack("V", $val);
    { no warnings 'portable';  $val = oct("0b" . unpack("b$bits", $pval)); }
    $vref->Chunk_Store($bits, $len, $val);
  }

  $self->_setlen( $len + $bits);
  1;
}

sub put_unary {
  my $self = shift;

  my $len  = $self->len;
  my $vref = $self->_vec;
  my $vsize = $vref->Size();

  foreach my $val (@_) {
    die "value must be >= 0" unless defined $val and $val >= 0;
    my $bits = $val+1;
    if (($len+$bits) > $vsize) {
      $vsize = int( ($len+$bits+2048) * 1.15 );
      $vref->Resize($vsize);
    }
    $vref->Bit_On($len + $val);
    $len += $bits;
  }
  $self->_setlen($len);
  1;
}

sub get_unary {
  my $self = shift;
  die "get while writing" if $self->writing;
  my $count = shift;
  if    (!defined $count) { $count = 1;  }
  elsif ($count  < 0)     { $count = ~0; }   # Get everything
  elsif ($count == 0)     { return;      }

  my $pos = $self->pos;
  my $len = $self->len;
  my $vref = $self->_vec;

  my @vals;
  while ($count-- > 0) {
    last if $pos >= $len;

    # Interval_Scan is very, very fast.  It could spend some time finding the
    # max position that we don't care about, but that is rare, and it is more
    # than an order of magnitude faster than doing this via pure Perl.
    my ($onepos, undef) = $vref->Interval_Scan_inc($pos);
    die "get_unary read off end of vector" unless defined $onepos;

    push @vals, $onepos - $pos;
    $pos = $onepos + 1;
  }
  $self->_setpos( $pos );
  wantarray ? @vals : $vals[-1];
}


# It'd be nice to use to_Bin and new_Bin for strings since they're super fast.
# But they return the result in little endian so would require some string
# massaging to make into big-endian.

# Using default read_string, put_string
# Using default to_string, from_string
# Using default to_raw, from_raw
# Using default to_store, from_store

__PACKAGE__->meta->make_immutable;
no Moo;
1;

# ABSTRACT: A Bit::Vector implementation of Data::BitStream

=pod

=head1 NAME

Data::BitStream::BitVec - A L<Bit::Vector> implementation of L<Data::BitStream>

=head1 SYNOPSIS

  use Data::BitStream::BitVec;
  my $stream = Data::BitStream::BitVec->new;
  $stream->put_gamma($_) for (1 .. 20);
  $stream->rewind_for_read;
  my @values = $stream->get_gamma(-1);

=head1 DESCRIPTION

An implementation of L<Data::BitStream>.  See the documentation for that
module for many more examples, and L<Data::BitStream::Base> for the API.
This document only describes the unique features of this implementation,
which is of limited value to people purely using L<Data::BitStream>.

This implementation uses the L<Bit::Vector> module for internal data storage,
as that module has a number of very efficient methods for manipulating
vectors.  However, L<Bit::Vector> stores and accesses all its data in
little-endian form, making it extremely difficult to use as a bit stream.
Hence some functions such as C<get_unary> are blazing fast, as we can use
one of the nice L<Bit::Vector> functions.  Many other functions are just as
difficult or more difficult to create as regular vectors, and often turn
out slower.

Another interesting observation is that L<Bit::Vector> is quite slow to resize
the vector.  Hence this implementation takes a rather aggressive stance in
resizing, bumping up the size to C<1.15 * (needed_bits + 2048)> when the
vector needs to grow.  When the stream is closed for writing, it is resized
to just the size needed.

Hence this implementation mainly serves as an example.  An XS implementation
of a big-endian vector would make this extremely fast.

=head2 DATA

=over 4

=item B< _vec >

A private L<Bit::Vector> object.

=back

=head2 CLASS METHODS

=over 4

=item I<after> B< erase >

Resizes the vector to 0.

=item I<after> B< write_close >

Resizes the vector to the actual length.

=item B< read >

=item B< write >

=item B< put_unary >

=item B< get_unary >

These methods have custom implementations.

=back

=head2 ROLES

The following roles are included.

=over 4

=item L<Data::BitStream::Code::Base>

=item L<Data::BitStream::Code::Gamma>

=item L<Data::BitStream::Code::Delta>

=item L<Data::BitStream::Code::Omega>

=item L<Data::BitStream::Code::Levenstein>

=item L<Data::BitStream::Code::EvenRodeh>

=item L<Data::BitStream::Code::Fibonacci>

=item L<Data::BitStream::Code::Golomb>

=item L<Data::BitStream::Code::Rice>

=item L<Data::BitStream::Code::GammaGolomb>

=item L<Data::BitStream::Code::ExponentialGolomb>

=item L<Data::BitStream::Code::StartStop>

=item L<Data::BitStream::Code::Baer>

=item L<Data::BitStream::Code::BoldiVigna>

=item L<Data::BitStream::Code::ARice>

=item L<Data::BitStream::Code::Additive>

=item L<Data::BitStream::Code::Comma>

=item L<Data::BitStream::Code::Taboo>

=back

=head1 SEE ALSO

=over 4

=item L<Data::BitStream>

=item L<Data::BitStream::Base>

=item L<Data::BitStream::WordVec>

=back

=head1 AUTHORS

Dana Jacobsen E<lt>dana@acm.orgE<gt>

=head1 COPYRIGHT

Copyright 2011 by Dana Jacobsen E<lt>dana@acm.orgE<gt>

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
