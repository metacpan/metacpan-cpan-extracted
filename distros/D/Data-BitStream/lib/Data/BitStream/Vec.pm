package Data::BitStream::Vec;
use strict;
use warnings;
BEGIN {
  $Data::BitStream::Vec::AUTHORITY = 'cpan:DANAJ';
}
BEGIN {
  $Data::BitStream::Vec::VERSION = '0.08';
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

# Evil, but must access the raw vector.
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

  my $val = 0;
  my $rvec = $self->_vecref;
  foreach my $bit (0 .. $bits-1) {
    $val = ($val << 1) | vec($$rvec, $pos+$bit, 1);
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
  my $rvec = $self->_vecref;

  if ($val == 0) {
    # nothing
  } elsif ($val == 1) {
    vec($$rvec, $len + $bits - 1, 1) = 1;
  } else {
    $self->error_code('param', 'bits must be <= ' . $self->maxbits) if $bits > $self->maxbits;

    my $wpos = $len + $bits-1;
    foreach my $bit (0 .. $bits-1) {
      vec($$rvec, $wpos - $bit, 1) = 1  if  (($val >> $bit) & 1);
    }
  }

  $self->_setlen( $len + $bits);
  1;
}

sub put_unary {
  my $self = shift;
  $self->error_stream_mode('write') unless $self->writing;

  my $rvec = $self->_vecref;
  my $len = $self->len;

  foreach my $val (@_) {
    $self->error_code('zeroval') unless defined $val and $val >= 0;
    vec($$rvec, $len + $val+1 - 1, 1) = 1;
    $len += $val+1;
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

    my $v = 0;
    $onepos++ while ( ($onepos < $len) && ($onepos % 8 != 0) && (($v = vec($$rvec, $onepos, 1) ) == 0) );
    if ( ($v == 0) && ($onepos < $len) ) {
      # Skip forward quickly
      if ($onepos % 8 == 0) {
        my $byte_pos = $onepos >> 3;
        my $start_byte_pos = $byte_pos;
        my $last_byte_pos = ($len+7) >> 3;
      {
        # Reading off the end of a stream will cause these warnings.
        no warnings qw(uninitialized substr);
        $byte_pos += 32 while ( (($byte_pos+31) <= $last_byte_pos) &&
                                (substr($$rvec,$byte_pos,32) eq "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00") );
        $byte_pos += 4 while ( (($byte_pos+3) <= $last_byte_pos) &&
                                (substr($$rvec,$byte_pos,4) eq "\x00\x00\x00\x00") );
      }
        $byte_pos++ while ( ($byte_pos <= $last_byte_pos) &&
                            (vec($$rvec, $byte_pos, 8) == 0) );
        $onepos += 8*($byte_pos-$start_byte_pos);
      }
      $onepos++ while ( ($onepos < $len) && (vec($$rvec, $onepos, 1) == 0) );
    }
    $self->error_off_stream() if $onepos >= $len;

    push @vals, $onepos - $pos;
    $pos = $onepos + 1;
  }

  $self->_setpos( $pos );
  wantarray ? @vals : $vals[-1];
}

# Using default read_string, put_string

sub to_string {
  my $self = shift;
  $self->write_close;
  my $len = $self->len;
  my $rvec = $self->_vecref;
  my $str = unpack("b$len", $$rvec);
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
  $$rvec = pack("b*", $str);
  $self->_setlen($bits);

  $self->rewind_for_read;
}

# Using default to_raw, from_raw

sub to_store {
  my $self = shift;
  $self->write_close;
  $self->_vec;
}
sub from_store {
  my $self = shift;
  my $vec  = shift;
  my $bits = shift || length($vec);
  $self->write_open;
  $self->_vec( $vec );
  $self->_setlen( $bits );
  $self->rewind_for_read;
}

__PACKAGE__->meta->make_immutable;
no Moo;
1;

# ABSTRACT: A Vector-1 implementation of Data::BitStream

=pod

=head1 NAME

Data::BitStream::Vec - A Vector-1 implementation of Data::BitStream

=head1 SYNOPSIS

  use Data::BitStream::Vec;
  my $stream = Data::BitStream::Vec->new;
  $stream->put_gamma($_) for (1 .. 20);
  $stream->rewind_for_read;
  my @values = $stream->get_gamma(-1);

=head1 DESCRIPTION

An implementation of L<Data::BitStream>.  See the documentation for that
module for many more examples, and L<Data::BitStream::Base> for the API.
This document only describes the unique features of this implementation,
which is of limited value to people purely using L<Data::BitStream>.

This implementation uses a Perl C<vec> to store the data.  The vector is
accessed in 1-bit units, which makes it easy and portable, however it is slow.
It really is deprecated in favor of L<Data::BitStream::WordVec>.

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

=item B< to_string >

=item B< from_string >

=item B< to_store >

=item B< from_store >

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

Copyright 2011-2012 by Dana Jacobsen E<lt>dana@acm.orgE<gt>

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
