package Data::BitStream::WordVec;
use strict;
use warnings;
BEGIN {
  $Data::BitStream::WordVec::AUTHORITY = 'cpan:DANAJ';
}
BEGIN {
  $Data::BitStream::WordVec::VERSION = '0.08';
}

use Moo;

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

has '_vec' => (is => 'rw', default => sub{''});

# Access the raw vector.
sub _vecref {
  my $self = shift;
  \$self->{_vec};
}
after 'erase' => sub {
  my $self = shift;
  $self->_vec('');
  1;
};


sub read {
  my $self = shift;
  $self->error_stream_mode('read') if $self->writing;
  my $bits = shift;
  $self->error_code('param', 'bits must be in range 1-' . $self->maxbits)
         unless defined $bits && $bits > 0 && $bits <= $self->maxbits;
  my $peek = (defined $_[0]) && ($_[0] eq 'readahead');

  my $pos = $self->pos;
  my $len = $self->len;
  return if $pos >= $len;
  $self->error_off_stream if !$peek && ($pos+$bits) > $len;

  my $wpos = $pos >> 5;       # / 32
  my $bpos = $pos & 0x1F;     # % 32
  my $rvec = $self->_vecref;
  my $val = 0;

  if ( $bpos <= (32-$bits) ) {   # optimize single word read
    $val = (vec($$rvec, $wpos, 32) >> (32-$bpos-$bits))
           &  (0xFFFFFFFF >> (32-$bits));
  } else {
    my $bits_left = $bits;
    while ($bits_left > 0) {
      my $epos = (($bpos+$bits_left) > 32)  ?  32  :  $bpos+$bits_left;
      my $bits_to_read = $epos - $bpos;  # between 0 and 32
      my $v = vec($$rvec, $wpos, 32);
      $v >>= (32-$epos);
      $v &= (0xFFFFFFFF >> (32-$bits_to_read));

      $val = ($val << $bits_to_read) | $v;

      $wpos++;
      $bits_left -= $bits_to_read;
      $bpos = 0;
    }
  }

  $self->_setpos( $pos + $bits ) unless $peek;
  $val;
}
sub write {
  my $self = shift;
  $self->error_stream_mode('write') unless $self->writing;
  my $bits = shift;
  $self->error_code('param', 'bits must be > 0') unless defined $bits && $bits > 0;
  my $val  = shift;
  $self->error_code('zeroval') unless defined $val and $val >= 0;

  my $len  = $self->len;
  my $new_len = $len + $bits;

  if ($val == 0) {                # optimize writing 0
    $self->_setlen( $new_len );
    return 1;
  }

  if ($val == 1) { $len += $bits-1; $bits = 1; }

  $self->error_code('param', 'bits must be <= ' . $self->maxbits) if $bits > $self->maxbits;

  my $wpos = $len >> 5;       # / 32
  my $bpos = $len & 0x1F;     # % 32
  my $rvec = $self->_vecref;

  my $wlen = 32-$bits;
  if ( $bpos <= $wlen ) {   # optimize single word write
    vec($$rvec, $wpos, 32) |=  ($val & (0xFFFFFFFF >> $wlen)) << ($wlen-$bpos);
  } else {
    while ($bits > 0) {
      my $epos = (($bpos+$bits) > 32)  ?  32  :  $bpos+$bits;
      my $bits_to_write = $epos - $bpos;  # between 0 and 32

      # get rid of parts of val to the right that we aren't writing yet
      my $val_to_write = $val >> ($bits - $bits_to_write);
      # get rid of parts of val to the left
      $val_to_write &= 0xFFFFFFFF >> (32-$bits_to_write);

      vec($$rvec, $wpos, 32)  |=  ($val_to_write << (32-$epos));

      $wpos++;
      $bits -= $bits_to_write;
      $bpos = 0;
    }
  }

  $self->_setlen( $new_len );
  1;
}

sub put_unary {
  my $self = shift;
  $self->error_stream_mode('write') unless $self->writing;

  my $len  = $self->len;
  my $rvec = $self->_vecref;

  foreach my $val (@_) {
    $self->error_code('zeroval') unless defined $val and $val >= 0;
    # We're writing $val 0's, so just skip them
    $len += $val;
    my $wpos = $len >> 5;      # / 32
    my $bpos = $len & 0x1F;    # % 32

    # Write a 1 in the correct position
    vec($$rvec, $wpos, 32) |= (1 << ((32-$bpos) - 1));
    $len++;
  }

  $self->_setlen( $len );
  1;
}

sub get_unary {
  my $self = shift;
  $self->error_stream_mode('read') if $self->writing;
  my $count = shift;
  if    (!defined $count) { $count = 1;  }
  elsif ($count  < 0)     { $count = ~0; }   # Get everything
  elsif ($count == 0)     { return;      }

  my $pos = $self->pos;
  my $len = $self->len;
  my $rvec = $self->_vecref;

  my @vals;
  while ($count-- > 0) {
    last if $pos >= $len;
    my $onepos = $pos;
    my $wpos = $pos >> 5;      # / 32
    my $bpos = $pos & 0x1F;    # % 32
    # Get the current word, shifted left so current position is leftmost.
    my $v = ( vec($$rvec, $wpos++, 32) << $bpos ) & 0xFFFFFFFF;
    # Optimize common small values.
    if ($v & 0xF0000000) {
      my $val = ($v & 0x80000000) ? 0 :
                ($v & 0x40000000) ? 1 :
                ($v & 0x20000000) ? 2 : 3;
      push @vals, $val;
      $pos += $val+1;
      next;
    }
    if ($v == 0) {
      # If this word is 0, advance words until we find one that is non-zero.
      $onepos += (32-$bpos);
      $v = vec($$rvec, $wpos++, 32);
      if ($v == 0) {
        # We've seen at least 33 zeros.  Start trying to scan quickly.
        $onepos += 32;
        my $startwpos = $wpos;
        my $lastwpos = ($len+31) >> 5;

        # 100us:  //g followed by pos
        #  34us:  unpack("%32W*", substr($$rvec,$wpos*4,32)) == 0
        #  27us:  substr($$rvec,$wpos*4,32) =~ tr/\000/\000/ == 32
        #  24us:  substr($$rvec,$wpos*4,32) eq "\x00 .... \x00"
        #  12us:  tr with 128 then 32

        $wpos += 32 while ( (($wpos+31) < $lastwpos) && (substr($$rvec,$wpos*4,128) =~ tr/\000/\000/ == 128) );
        $wpos += 8 while ( (($wpos+7) < $lastwpos) && (substr($$rvec,$wpos*4,32) =~ tr/\000/\000/ == 32) );
        $wpos++ while ($wpos <= $lastwpos && vec($$rvec, $wpos, 32) == 0);
        $v = vec($$rvec, $wpos, 32);
        $onepos += 32*($wpos - $startwpos);
      }
    }
    $self->error_off_stream() if $onepos >= $len;
    $self->error_code('assert', "v must be 0") if $v == 0;
    # This word is non-zero.  Find the leftmost set bit.
    if (($v & 0xFFFF0000) == 0) { $onepos += 16; $v <<= 16; }
    if (($v & 0xFF000000) == 0) { $onepos +=  8; $v <<=  8; }
    if (($v & 0xF0000000) == 0) { $onepos +=  4; $v <<=  4; }
    if (($v & 0xC0000000) == 0) { $onepos +=  2; $v <<=  2; }
    if (($v & 0x80000000) == 0) { $onepos +=  1; $v <<=  1; }
    push @vals, $onepos - $pos;
    $pos = $onepos+1;
  }
  $self->_setpos( $pos );
  wantarray ? @vals : $vals[-1];
}

# This is pretty important for speed
sub put_gamma {
  my $self = shift;
  $self->error_stream_mode('write') unless $self->writing;

  my $len  = $self->len;
  my $rvec = $self->_vecref;
  my $maxval = $self->maxval();

  foreach my $val (@_) {
    $self->error_code('zeroval') unless defined $val and $val >= 0;

    my $wpos = $len >> 5;      # / 32
    my $bpos = $len & 0x1F;    # % 32

    if ($val == 0) {               # Quickly set zero
      vec($$rvec, $wpos, 32) |= (1 << ((32-$bpos) - 1));
      $len++;
      next;
    } elsif ($val == $maxval) {    # Encode ~0 as unary maxbits
      $len += $self->maxbits;
      $wpos = $len >> 5;      # / 32
      $bpos = $len & 0x1F;    # % 32
      vec($$rvec, $wpos, 32) |= (1 << ((32-$bpos) - 1));
      $len++;
      next;
    }

    my $bits;
    if ($val < 511) {
      $bits = ($val <  1) ?  1 :
              ($val <  3) ?  3 :
              ($val <  7) ?  5 :
              ($val < 15) ?  7 :
              ($val < 31) ?  9 :
              ($val < 63) ? 11 :
              ($val <127) ? 13 :
              ($val <255) ? 15 : 17;
    } else {
      $bits = 2*9+1;
      my $v = ($val+1) >> 9;
      $bits += 2 while ($v >>= 1);
    }

    # Quickly insert if the code fits inside a single word
    if ( $bpos <= (32-$bits) ) {
      vec($$rvec, $wpos, 32) |= ( ($val+1) << ((32-$bpos) - $bits));
      $len += $bits;
      next;
    }

    # Effectively we're doing:
    #
    #   $self->put_unary($base);
    #   $self->write($base, $val+1);
    #
    # which is equivalent to:
    #
    #   $self->write($base, 0);
    #   $self->write($base+1, $val+1);

    my $base = $bits >> 1;
    $len += $base;
    $base += 1;

    # write value in binary using $base bits
    {
      my $v = $val+1;
      my $bits = $base;
      $wpos = $len >> 5;       # / 32
      $bpos = $len & 0x1F;     # % 32

      while ($bits > 0) {
        my $epos = (($bpos+$bits) > 32)  ?  32  :  $bpos+$bits;
        my $bits_to_write = $epos - $bpos;  # between 0 and 32

        # get rid of parts of val to the right that we aren't writing yet
        my $val_to_write = $v >> ($bits - $bits_to_write);
        # get rid of parts of val to the left
        $val_to_write &= 0xFFFFFFFF >> (32-$bits_to_write);

        vec($$rvec, $wpos, 32)  |=  ($val_to_write << (32-$epos));

        $wpos++;
        $bits -= $bits_to_write;
        $bpos = 0;
      }
      $len += $base;
    }
  }
  $self->_setlen( $len );
  1;
}


# Using default read_string

sub put_string {
  my $self = shift;
  $self->error_stream_mode('write') unless $self->writing;

  my $len = $self->len;
  my $rvec = $self->_vecref;

  foreach my $str (@_) {
    next unless defined $str;
    $self->error_code('string') if $str =~ tr/01//c;
    my $bits = length($str);
    next unless $bits > 0;

    my $wpos = $len >> 5;
    my $bpos = $len & 0x1F;
    my $bits_to_write = $bits;
    # First get the part that fills the last word.
    my $first_bits = ($bpos == 0)  ?  0  :  32-$bpos;
    if ($bpos > 0) {
      my $newvec = pack("B*", substr($str, 0, $first_bits) );
      vec($$rvec, $wpos++, 32) |= vec($newvec, 0, 32) >> $bpos;
      $bits_to_write -= $first_bits;
    } else {
      # The fast part below does a string concat, which means we have to
      # make sure the vector is extended properly.  This happens if we have
      # written zeros with the write() method, which just extends $len.
      vec($$rvec, $wpos-1, 32) |= 0  if $wpos > 0;
    }
    # Now put the rest of the string in place quickly.
    if ($bits_to_write > 0) {
      $$rvec .= pack("B*", substr($str, $first_bits));
    }

    $len += $bits;
  }
  $self->_setlen($len);
  1;
}

sub to_string {
  my $self = shift;
  $self->write_close;
  my $len = $self->len;
  my $rvec = $self->_vecref;
  my $str = unpack("B$len", $$rvec);
  # unpack sometimes drops 0 bits at the end, so we need to check and add them.
  my $strlen = length($str);
  $self->error_code('assert', "string length") if $strlen > $len;
  if ($strlen < $len) {
    $str .= "0" x ($len - $strlen);
  }
  $str;
}
sub from_string {
  my $self = shift;
  my $str  = shift;
  $self->error_code('string') if $str =~ tr/01//c;
  my $bits = shift || length($str);
  $self->write_open;

  my $rvec = $self->_vecref;
  $$rvec = pack("B*", $str);
  $self->_setlen($bits);

  $self->rewind_for_read;
}

# Our internal format is a big-endian vector, so to_raw and from_raw
# are easy.  We default to_store and from_store.

sub to_raw {
  my $self = shift;
  $self->write_close;
  my $rvec = $self->_vecref;
  return $$rvec;
}

sub from_raw {
  my $self = $_[0];
  # data comes in 2nd argument
  my $bits = $_[2] || 8*length($_[1]);

  $self->write_open;

  my $rvec = $self->_vecref;
  $$rvec = $_[1];

  $self->_setlen( $bits );
  $self->rewind_for_read;
}

__PACKAGE__->meta->make_immutable;
no Moo;
1;

# ABSTRACT: A Vector-32 implementation of Data::BitStream

=pod

=head1 NAME

Data::BitStream::WordVec - A Vector-32 implementation of Data::BitStream

=head1 SYNOPSIS

  use Data::BitStream::WordVec;
  my $stream = Data::BitStream::WordVec->new;
  $stream->put_gamma($_) for (1 .. 20);
  $stream->rewind_for_read;
  my @values = $stream->get_gamma(-1);

=head1 DESCRIPTION

An implementation of L<Data::BitStream>.  See the documentation for that
module for many more examples, and L<Data::BitStream::Base> for the API.
This document only describes the unique features of this implementation,
which is of limited value to people purely using L<Data::BitStream>.

This implementation uses a Perl C<vec> to store the data.  The vector is
accessed in 32-bit units, which makes it safe for 32-bit and 64-bit machines
as well as reasonably time efficient.

This is the default L<Data::BitStream> implementation.

=head2 DATA

=over 4

=item B< _vec >

A private scalar holding the data as a vector.

=back

=head2 CLASS METHODS

=over 4

=item B< _vecref >

Retrieves a reference to the private vector.

=item I<after> B< erase >

Sets the private vector to the empty string C<''>.

=item B< read >

=item B< write >

=item B< put_unary >

=item B< get_unary >

=item B< put_gamma >

=item B< put_string >

=item B< to_string >

=item B< from_string >

=item B< from_raw >

=item B< to_raw >

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

=item L<Data::BitStream::String>

=back

=head1 AUTHORS

Dana Jacobsen E<lt>dana@acm.orgE<gt>

=head1 COPYRIGHT

Copyright 2011-2012 by Dana Jacobsen E<lt>dana@acm.orgE<gt>

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
