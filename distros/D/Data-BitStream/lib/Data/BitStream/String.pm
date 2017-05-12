package Data::BitStream::String;
use strict;
use warnings;
BEGIN {
  $Data::BitStream::String::AUTHORITY = 'cpan:DANAJ';
}
BEGIN {
  $Data::BitStream::String::VERSION = '0.08';
}

use Moo;

with 'Data::BitStream::Base',
     'Data::BitStream::Code::Gamma',  # implemented here
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

has '_str' => (is => 'rw', default => sub{''});

# Evil, reference to underlying string
sub _strref {
  my $self = shift;
 \$self->{_str};
}
after 'erase' => sub {
  my $self = shift;
  $self->_str('');
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

  my $rstr = $self->_strref;
  my $str = substr($$rstr, $pos, $bits);
  { # This is for readahead.  We should use a write-close method instead.
    my $strlen = length($str);
    $str .= "0" x ($bits-$strlen)  if $strlen < $bits;
  }
  my $val;
  # We could do something like:
  #    $val = unpack("N", pack("B32", substr("0" x 32 . $str, -32)));
  # and combine for more than 32-bit values, but this works better.
  {
    no warnings 'portable';
    $val = oct "0b$str";
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

  my $rstr = $self->_strref;

  if ($val == 0) {
    $$rstr .= '0' x $bits;
  } elsif ($val == 1) {
    $$rstr .= '0' x ($bits-1)   if $bits > 1;
    $$rstr .= '1';
  } else {

    $self->error_code('param', 'bits must be <= ' . $self->maxbits) if $bits > $self->maxbits;

    # The following is typically fastest with 5.9.2 and later:
    #
    #   $$rstr .= scalar reverse unpack("b$bits",($bits>32) ? pack("Q>",$val)
    #                                                       : pack("V" ,$val));
    #
    # With 5.9.2 and later on a 64-bit machine, this will work quickly:
    #
    #   $$rstr .= substr(unpack("B64", pack("Q>", $val)), -$bits);
    #
    # This is the best compromise that works with 5.8.x, BE/LE, and 32-bit:
    if ($bits > 32) {
      #$$rstr .= substr(unpack("B64", pack("Q>", $val)), -$bits); # needs v5.9.2
      $$rstr .=   substr(unpack("B32", pack("N", $val>>32)), -($bits-32))
                . unpack("B32", pack("N", $val));
    } else {
      #$$rstr .= substr(unpack("B32", pack("N", $val)), -$bits);
      $$rstr .= scalar reverse unpack("b$bits", pack("V", $val));
    }
  }

  $self->_setlen( $self->len + $bits);
  1;
}

sub put_unary {
  my $self = shift;
  $self->error_stream_mode('write') unless $self->writing;

  my $rstr = $self->_strref;
  my $len = $self->len;

  foreach my $val (@_) {
    $self->error_code('zeroval') unless defined $val and $val >= 0;
    $$rstr .= '0' x ($val) . '1';
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
  my $rstr = $self->_strref;

  my @vals;
  while ($count-- > 0) {
    last if $pos >= $len;
    my $onepos = index( $$rstr, '1', $pos );
    $self->error_off_stream() if $onepos == -1;
    my $val = $onepos - $pos;
    $pos = $onepos + 1;
    push @vals, $val;
  }
  $self->_setpos( $pos );
  wantarray ? @vals : $vals[-1];
}

sub put_unary1 {
  my $self = shift;
  $self->error_stream_mode('write') unless $self->writing;

  my $rstr = $self->_strref;
  my $len = $self->len;

  foreach my $val (@_) {
    $self->error_code('zeroval') unless defined $val and $val >= 0;
    $$rstr .= '1' x ($val) . '0';
    $len += $val+1;
  }

  $self->_setlen( $len );
  1;
}
sub get_unary1 {
  my $self = shift;
  $self->error_stream_mode('read') if $self->writing;
  my $count = shift;
  if    (!defined $count) { $count = 1;  }
  elsif ($count  < 0)     { $count = ~0; }   # Get everything
  elsif ($count == 0)     { return;      }

  my $pos = $self->pos;
  my $len = $self->len;
  my $rstr = $self->_strref;

  my @vals;
  while ($count-- > 0) {
    last if $pos >= $len;
    my $onepos = index( $$rstr, '0', $pos );
    $self->error_off_stream() if $onepos == -1;
    my $val = $onepos - $pos;
    $pos = $onepos + 1;
    push @vals, $val;
  }
  $self->_setpos( $pos );
  wantarray ? @vals : $vals[-1];
}

sub put_gamma {
  my $self = shift;
  $self->error_stream_mode('write') unless $self->writing;

  my $rstr = $self->_strref;
  my $len = $self->len;
  my $maxval = $self->maxval();

  foreach my $val (@_) {
    $self->error_code('zeroval') unless defined $val and $val >= 0;
    my $vstr;
    if    ($val == 0)  { $vstr = '1'; }
    elsif ($val == 1)  { $vstr = '010'; }
    elsif ($val == 2)  { $vstr = '011'; }
    elsif ($val == $maxval) { $vstr = '0' x $self->maxbits . '1'; }
    else {
      my $base = 0;
      { my $v = $val+1; $base++ while ($v >>= 1); }
      $vstr = '0' x $base . '1';
      if ($base > 32) {
        $vstr .=   substr(unpack("B32", pack("N", ($val+1)>>32)), -($base-32))
                  . unpack("B32", pack("N", $val+1));
      } else {
        $vstr .= scalar reverse unpack("b$base", pack("V", $val+1));
      }
    }
    $$rstr .= $vstr;
    $len += length($vstr);
  }

  $self->_setlen( $len );
  1;
}

sub get_gamma {
  my $self = shift;
  $self->error_stream_mode('read') if $self->writing;
  my $count = shift;
  if    (!defined $count) { $count = 1;  }
  elsif ($count  < 0)     { $count = ~0; }   # Get everything
  elsif ($count == 0)     { return;      }

  my $pos = $self->pos;
  my $len = $self->len;
  my $rstr = $self->_strref;
  my $maxbits = $self->maxbits;

  my @vals;
  while ($count-- > 0) {
    last if $pos >= $len;
    my $onepos = index( $$rstr, '1', $pos );
    $self->error_off_stream() if $onepos == -1;
    my $base = $onepos - $pos;
    $pos = $onepos + 1;
    if    ($base == 0) {  push @vals, 0; }
    elsif ($base == $maxbits) { push @vals, $self->maxval(); }
    elsif ($base  > $maxbits) { $self->error_code('base', $base); }
    else  {
      $self->error_off_stream() if ($pos+$base) > $len;
      my $vstr = substr($$rstr, $pos, $base);
      $pos += $base;
      my $rval;
      { no warnings 'portable';  $rval = oct "0b$vstr"; }
      push @vals, ((1 << $base) | $rval)-1;
    }
  }
  $self->_setpos( $pos );
  wantarray ? @vals : $vals[-1];
}

sub put_string {
  my $self = shift;
  $self->error_stream_mode('write') unless $self->writing;

  my $len = $self->len;
  my $rstr = $self->_strref;

  foreach my $str (@_) {
    next unless defined $str;
    $self->error_code('string') if $str =~ tr/01//c;
    my $bits = length($str);
    next unless $bits > 0;

    $$rstr .= $str;
    $len += $bits;
  }
  $self->_setlen( $len );
  1;
}
sub read_string {
  my $self = shift;
  $self->error_stream_mode('read') if $self->writing;
  my $bits = shift;
  $self->error_code('param', "bits must be >= 0") unless defined $bits && $bits >= 0;

  my $len = $self->len;
  my $pos = $self->pos;
  $self->error_code('short') unless $bits <= ($len - $pos);
  my $rstr = $self->_strref;

  $self->_setpos( $pos + $bits );
  substr($$rstr, $pos, $bits);
}

# Given the custom read_string and put_string, these aren't really necessary.
sub to_string {
  my $self = shift;
  $self->write_close;
  $self->_str;
}
sub from_string {
  my $self = shift;
  my $str  = shift;
  $self->error_code('string') if $str =~ tr/01//c;
  my $bits = shift || length($str);
  $self->write_open;

  $self->_str( $str );
  $self->_setlen( $bits );

  $self->rewind_for_read;
}

sub to_raw {
  my $self = shift;
  $self->write_close;
  return pack("B*", $self->_str);
}
sub put_raw {
  my $self = shift;
  $self->error_stream_mode('write') unless $self->writing;
  my $vec  = shift;
  my $bits = shift || int((length($vec)+7)/8);

  my $str = unpack("B$bits", $vec);
  my $strlen = length($str);
  $self->error_code('assert', "string length") if $strlen > $bits;
  if ($strlen < $bits) {
    $str .= "0" x ($bits - $strlen);
  }

  my $rstr = $self->_strref;
  $$rstr .= $str;
  $self->_setlen( $self->len + $bits );
  1;
}

# Using default from_raw
# Using default to_store, from_store

# An example.  We have a custom put_string so this isn't much faster.
#sub put_stream {
#  my $self = shift;
#  die "put while reading" unless $self->writing;
#  my $source = shift;
#  return 0 unless defined $source && $source->can('to_string');
#
#  if (ref $source eq __PACKAGE__) {
#    my $rstr = $self->_strref;
#    my $sstr = $source->_strref;
#    $$rstr .= $$sstr;
#    $self->_setlen( $self->len + $source->len );
#  } else {
#    $self->put_string($source->to_string);
#  }
#  1;
#}

__PACKAGE__->meta->make_immutable;
no Moo;
1;

# ABSTRACT: A String implementation of Data::BitStream

=pod

=head1 NAME

Data::BitStream::String - A String implementation of Data::BitStream

=head1 SYNOPSIS

  use Data::BitStream::String;
  my $stream = Data::BitStream::String->new;
  $stream->put_gamma($_) for (1 .. 20);
  $stream->rewind_for_read;
  my @values = $stream->get_gamma(-1);

=head1 DESCRIPTION

An implementation of L<Data::BitStream>.  See the documentation for that
module for many more examples, and L<Data::BitStream::Base> for the API.
This document only describes the unique features of this implementation,
which is of limited value to people purely using L<Data::BitStream>.

This implementation is very memory inefficient, as it uses a binary string
to hold the data, hence uses one byte internally per bit of data.  However
it is a useful reference implementation, and since most operations use Perl
operations it is quite fast.

=head2 DATA

=over 4

=item B< _str >

A private string holding the data in binary string form.

=back

=head2 CLASS METHODS

=over 4

=item B< _strref >

Retrieves a reference to the private string.

=item I<after> B< erase >

Sets the private string to the empty string C<''>.

=item B< read >

=item B< write >

=item B< put_unary >

=item B< get_unary >

=item B< put_unary1 >

=item B< get_unary1 >

=item B< put_gamma >

=item B< get_gamma >

=item B< put_string >

=item B< read_string >

=item B< to_string >

=item B< from_string >

=item B< to_raw >

=item B< put_raw >

These methods have custom implementations.

=back

=head2 ROLES

The following roles are included.  Note that Gamma has an inline
implementation.

=over 4

=item L<Data::BitStream::Code::Base>

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
