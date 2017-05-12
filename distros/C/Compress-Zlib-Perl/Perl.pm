package Compress::Zlib::Perl;

use 5.004;

# use if $] > 5.006, 'warnings';
# use warnings;
use strict;

require Exporter;

use vars qw($VERSION @ISA @EXPORT);
@ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

use constant Z_OK => 0;
use constant Z_STREAM_END => 1;
use constant MAX_WBITS => 16;

@EXPORT = qw(
	     Z_OK Z_STREAM_END MAX_WBITS crc32
);

$VERSION = '0.02';

{
  my @crc32;

  sub _init_crc32 {
    # I'm not sure why Ton wanted to reverse the order of the bits in this
    # constant, rather than using the bit-reversed constant
    # my $p=oct reverse sprintf"%032bb0", 0x04C11DB7;
    # But the only 5.005 friendly way I can find is this:
    my $p
      = unpack "I", pack "b*", scalar reverse unpack "b*", pack "I", 0x04C11DB7;
    @crc32 = map{for my$s(0..7) {$_ = $_>>1 ^ ($_&1 && $p)} $_} 0..255;
  }

  # Calculate gzip header 16 bit CRCs
  sub _crc16 {
    my $crc16 = shift;
    _init_crc32() unless @crc32;
    foreach my $input (@_) {
      # I have no way to test this, as nothing that I can find generates
      # gzip files with the header CRC.
      # Ton's code is this:
      $crc16 = $crc16>>8^$crc32[$crc16&0xff^ord(substr $input,$_,1)]
	for 0..length($input)-1;
      # I believe that the following is functionally equivalent, but should
      # be faster:
      # while ($input =~ /(.)/gs) {
      #   $crc16 = $crc16 >> 8 ^ $crc32[$crc16 & 0xff ^ ord $1];
      # }
      return $crc16;
    }
  }

  # Public interface starts here:

  # Calculate 32 bit CRCs
  sub crc32 {
    _init_crc32() unless @crc32;
    my ($buffer, $crc32) = @_;
    $crc32 ||= 0;
    $crc32 ^= 0xffffffff;
    my $pos = -length $buffer;
    $crc32 = $crc32>>8 ^ $crc32[$crc32&0xff^ord(substr($buffer, $pos++, 1))]
      while $pos;
    $crc32 ^ 0xffffffff;
  }
}

sub inflateInit {
  my %args = @_;
  die "Please specify negative window size"
    unless $args{-WindowBits} && $args{-WindowBits} < 0;
  my $self = bless {isize=>0,
		    osize=>0,
		    result=>"",
		    huffman=>"",
		    type0length=>"",
		    state=>\&stateReadFinal
		   };
  $self->_reset_bits_have;
  wantarray ? ($self, Z_OK) : $self;
}

sub total_in {
  $_[0]->{isize};
}

sub total_out {
  $_[0]->{osize};
}

sub inflate {
  $_[0]->{input} = \$_[1];
  my ($return, $status);
  $_[0]->{izize} += length $_[1];
  if (&{$_[0]->{state}}) {
    # Finished, so flush everything
    $return = length $_[0]->{result};
    $status = Z_STREAM_END;
  } else {
    die length ($_[1]) . " input remaining" if length $_[1];
    $return = length ($_[0]->{result}) - 0x8000;
    $return = 0 if $return < 0;
    $status = Z_OK;
  }
  $_[0]->{izize} -= length $_[1];
  $_[0]->{osize} += $return;
  wantarray ? (substr ($_[0]->{result}, 0, $return, ""), $status)
    : substr ($_[0]->{result}, 0, $return, "");
}

# Public interface ends here

sub _reset_bits_have {
  my $self = shift;
  $self->{val} = $self->{have} = 0;
}


# get arg bits (little endian)
sub _get_bits {
  my ($self, $want) = @_;
  my ($bits_val, $bits_have) = @{$self}{qw(val have)};
  while ($want > $bits_have) {
    # inlined input read
    my $byte = substr ${$_[0]->{input}}, 0, 1, "";
    if (!length $byte) {
      @{$self}{qw(val have)} = ($bits_val, $bits_have);
      return;
    }
    $bits_val |= ord($byte) << $bits_have;
    $bits_have += 8;
  }
  my $result = $bits_val & (1 << $want)-1;
  $bits_val >>= $want;
  $bits_have -= $want;
  @{$self}{qw(val have)} = ($bits_val, $bits_have);
  return $result;
}

# Get one huffman code
sub _get_huffman {
  my ($self, $code) = @_;
  $code = $self->{$code};
  my ($bits_val, $bits_have, $str) = @{$self}{qw(val have huffman)};
  do {
      if (--$bits_have < 0) {
	# inlined input read
	my $byte = substr ${$_[0]->{input}}, 0, 1, "";
	if (!length $byte) {
	  # bits_have is -1, but really should be zero, so fix in save
	  @{$self}{qw(val have huffman)} = ($bits_val, 0, $str);
	  return;
	}
	$bits_val = ord $byte;
	$bits_have = 7;
      }
      $str .= $bits_val & 1;
      $bits_val >>= 1;
    } until exists $code->{$str};
  defined($code->{$str}) || die "Bad code $str";
  @{$self}{qw(val have huffman)} = ($bits_val, $bits_have, "");
  return $code->{$str};
}

# construct huffman code
sub make_huffman {
  my $counts = shift;
  my (%code, @counts);
  push @{$counts[$counts->[$_]]}, $_ for 0..$#$counts;
  my $value = 0;
  my $bits = -1;
  for (@counts) {
    $value *= 2;
    next unless ++$bits && $_;
    # Ton used sprintf"%0${bits}b", $value;
    $code{reverse unpack "b$bits", pack "V", $value++} = $_ for @$_;
  }
  # Close the code to avoid infinite loops (and out of memory)
  $code{reverse unpack "b$bits", pack "V", $value++} = undef for
    $value .. (1 << $bits)-1;
  @code{0, 1} = () unless %code;
  return \%code;
}

# Inflate state machine.
{
  my ($static_lit_code, $static_dist_code, @lit_base, @dist_base);

  my @lit_extra = (-1,
		   0,0,0,0,0,0,0,0,1,1,1,1,2,2,2,2,
		   3,3,3,3,4,4,4,4,5,5,5,5,0,-2,-2);
  my @dist_extra = (0,0,0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,
		    9,9,10,10,11,11,12,12,13,13,-1,-1);
  my @alpha_map = (16, 17, 18, 0, 8, 7, 9, 6, 10,
		   5, 11, 4, 12, 3, 13, 2, 14, 1, 15);
  sub prepare_tables {
    my $length = 3;
    for (@lit_extra) {
      push @lit_base, $length;
      $length += 1 << $_ if $_ >= 0;
    }
    # Exceptional case
    splice(@lit_base, -3, 3, 258);

    my $dist = 1;
    for (@dist_extra) {
      push @dist_base, $dist;
      $dist += 1 << $_ if $_ >= 0;
    }
    splice(@dist_base, -2, 2);
  }

  sub stateReadFinal {
    my $bit = _get_bits($_[0], 1);
    if (!defined $bit) {
      # STALL
      return;
    }
    $_[0]->{final} = $bit;
    goto &{$_[0]->{state} = \&stateReadType};
  }
  sub stateReadType {
    my $type = _get_bits($_[0], 2);
    if (!defined $type) {
      # STALL
      return;
    }
    $_[0]->{type} = $type;
    if ($type) {
      prepare_tables() unless @lit_base;
      if ($type == 1) {
	$_[0]->{lit}  = $static_lit_code  ||=
	  make_huffman([(8)x144,(9)x112, (7)x24, (8)x8]);
	$_[0]->{dist} = $static_dist_code ||=
	  make_huffman([(5)x32]);
	# This is the main inflation loop.
	goto &{$_[0]->{state} = \&stateReadLit};
      } elsif ($type == 2) {
	goto &{$_[0]->{state} = \&stateReadHLit};
      } else {
	die "deflate subtype $type not supported\n";
      }
    }
    goto &{$_[0]->{state} = \&stateReadUncompressedLen};
  }

  sub stateReadUncompressedLen {
    # Not compressed;
    $_[0]->_reset_bits_have;
    # inlined input read
    $_[0]->{type0length}
      .= substr ${$_[0]->{input}}, 0, 4 - length $_[0]->{type0length}, "";
    if (length $_[0]->{type0length} < 4) {
      # STALL
      return;
    }
    my ($len, $nlen) = unpack("vv", $_[0]->{type0length});
    $_[0]->{type0length} = "";
    $len == (~$nlen & 0xffff) ||
      die "$len is not the 1-complement of $nlen";
    $_[0]->{type0left} = $len;
    goto &{$_[0]->{state} = \&stateReadUncompressed};
  }

  sub stateReadUncompressed {
    # inlined input read
    my $got = substr ${$_[0]->{input}}, 0, $_[0]->{type0left}, "";
    $_[0]->{result} .= $got;
    if ($_[0]->{type0left} -= length $got) {
      # Still need more.
      # STALL
      return;
    }
    if ($_[0]->{final}) {
      # Finished.
      return 1;
    }
    # Begin the next block
    goto &{$_[0]->{state} = \&stateReadFinal};
  }

  sub stateReadHLit {
    my $hlit = _get_bits($_[0], 5);
    if (!defined $hlit) {
      # STALL
      return;
    }
    $_[0]->{hlit} = $hlit + 257;
    goto &{$_[0]->{state} = \&stateReadHDist};
  }
  sub stateReadHDist {
    my $hdist = _get_bits($_[0], 5);
    if (!defined $hdist) {
      # STALL
      return;
    }
    $_[0]->{hdist} = $hdist + 1;
    goto &{$_[0]->{state} = \&stateReadHCLen};
  }
  sub stateReadHCLen {
    my $hclen = _get_bits($_[0], 4);
    if (!defined $hclen) {
      # STALL
      return;
    }
    $_[0]->{alphaleft} = $_[0]->{hclen} = $hclen + 4;
    # Determine the code length huffman code
    $_[0]->{alpha_raw} = [(0) x @alpha_map];

    goto &{$_[0]->{state} = \&stateReadAlphaCode};
  }
  sub stateReadAlphaCode {
    my $alpha_code = $_[0]->{alpha_raw};
    while ($_[0]->{alphaleft}) {
      my $code = _get_bits($_[0], 3);
      if (!defined $code) {
	# STALL
	return;
      }
      # my $where = $_[0]->{hclen} - $_[0]->{alphaleft};
      $alpha_code->[$alpha_map[$_[0]->{hclen} - $_[0]->{alphaleft}--]] = $code;
    }
    $_[0]->{alpha} = make_huffman($alpha_code);
    delete $_[0]->{alpha_raw};

    # Get lit/length and distance tables
    $_[0]->{code_len} = [];
    goto &{$_[0]->{state} = \&stateBuildAlphaCode};
  }

  sub stateBuildAlphaCode {
    my $code_len = $_[0]->{code_len};
    while (@$code_len < $_[0]->{hlit}+$_[0]->{hdist}) {
      my $alpha = _get_huffman($_[0], 'alpha');
      if (!defined $alpha) {
	# STALL
	return;
      }
      if ($alpha < 16) {
	push @$code_len, $alpha;
      } elsif ($alpha == 16) {
	goto &{$_[0]->{state} = \&stateReadAlphaCode16};
      } elsif ($alpha == 17) {
	goto &{$_[0]->{state} = \&stateReadAlphaCode17};
      } else {
	goto &{$_[0]->{state} = \&stateReadAlphaCodeOther};
      }
    }
    @$code_len == $_[0]->{hlit}+$_[0]->{hdist} || die "too many codes";
    my @lit_len = splice(@$code_len, 0, $_[0]->{hlit});
    $_[0]->{lit}  = make_huffman(\@lit_len);
    $_[0]->{dist} = make_huffman($code_len);
    delete $_[0]->{code_len};
    goto &{$_[0]->{state} = \&stateReadLit};
  }

  sub stateReadAlphaCode16 {
    my $code_len = $_[0]->{code_len};
    my $bits = _get_bits($_[0], 2);
    if (!defined $bits) {
      # STALL
      return;
    }
    push @$code_len, ($code_len->[-1]) x (3+$bits);
    goto &{$_[0]->{state} = \&stateBuildAlphaCode};
  }

  sub stateReadAlphaCode17 {
    my $code_len = $_[0]->{code_len};
    my $bits = _get_bits($_[0], 3);
    if (!defined $bits) {
      # STALL
      return;
    }
    push @$code_len, (0) x (3+$bits);
    goto &{$_[0]->{state} = \&stateBuildAlphaCode};
  }

  sub stateReadAlphaCodeOther {
    my $code_len = $_[0]->{code_len};
    my $bits = _get_bits($_[0], 7);
    if (!defined $bits) {
      # STALL
      return;
    }
    push @$code_len, (0) x (11+$bits);
    goto &{$_[0]->{state} = \&stateBuildAlphaCode};
  }

  sub stateReadLit {
    while (1) {
      my $lit = _get_huffman($_[0], 'lit');
      if (!defined $lit) {
	# STALL
	return;
      }
    if ($lit >= 256) {
      if ($lit_extra[$lit -= 256] < 0) {
	die "Invalid literal code" if $lit;

	if ($_[0]->{final}) {
	  # Finished.
	  return 1;
	}
	# Begin the next block
	goto &{$_[0]->{state} = \&stateReadFinal};
      }
      $_[0]->{litcode} = $lit;
      # BREAK
      goto &{$_[0]->{state} = \&stateGetLength};
    }

      $_[0]->{result} .= chr $lit;
      # Back to the main inflation loop
      # goto &stateReadLit;
      # ie loop
    }
  }

  sub stateGetLength {
    my $lit = $_[0]->{litcode};
    my $bits = _get_bits($_[0], $lit_extra[$lit]);
    if (!defined $bits) {
      # STALL
      return;
    }
    $_[0]->{length} = $lit_base[$lit] + ($lit_extra[$lit] && $bits);
    goto &{$_[0]->{state} = \&stateGetDCode};
  }

  sub stateGetDCode {
    my $d = _get_huffman($_[0], 'dist');
    if (!defined $d) {
      # STALL
      return;
    }
    $_[0]->{dcode} = $d;
    goto &{$_[0]->{state} = \&stateGetDistDecompress};
  }

  sub stateGetDistDecompress {
    my $d = $_[0]->{dcode};
    die "Invalid distance code" if $d >= 30;
    my $bits = _get_bits($_[0], $dist_extra[$d]);
    if (!defined $bits) {
      # STALL
      return;
    }
    my $dist = $dist_base[$d] + ($dist_extra[$d] && $bits);

    # Go for it
    my $length = $_[0]->{length};
    if ($dist >= $length) {
      my $section = substr ($_[0]->{result}, -$dist, $length);
      $_[0]->{result} .= $section;
    } else {
      my $remaining = $length;
      while ($remaining) {
	my $take
	  = $dist >= $remaining ? $remaining : $dist;
	$_[0]->{result} .= substr($_[0]->{result}, -$dist, $take);
	$remaining -= $take;
      }
    }
    # Back to the main inflation loop
    goto &{$_[0]->{state} = \&stateReadLit};
  }
}

1;
__END__

=head1 NAME

Compress::Zlib::Perl - (Partial) Pure perl implementation of Compress::Zlib

=head1 SYNOPSIS

    use Compress::Zlib::Perl;
    ($i, $status) = inflateInit(-WindowBits => -MAX_WBITS);
    ($out, $status) = $i->inflate($buffer);

=head1 DESCRIPTION

This a pure perl implementation of Compress::Zlib's inflate API.

=head2 Inflating deflated data

Currently the only thing Compress::Zlib::Perl can do is inflate compressed
data. A constructor and 3 methods from Compress::Zlib's interface are
replicated:

=over 4

=item inflateInit -WindowBits => -MAX_WBITS

Argument list specifies options. Expects that the option -WindowBits is set
to a negative value. In scalar context returns an C<inflater> object; in list
context returns this object and a status (usually C<Z_OK>)

=item inflate INPUT

Inflates this section of deflate compressed data stream. In scalar context
returns some inflated data; in list context returns this data and an output
status. The status is C<Z_OK> if the input stream is not yet finished,
C<Z_STREAM_END> if all the input data is consumed and this output is the
final output.

C<inflate> modifies the input parameter; at the end of the compressed stream
any data beyond its end remains in I<INPUT>. Before the end of stream all
input data is consumed during the C<inflate> call.

This implementation of C<inflate> may not be as prompt at returning data as
Compress::Zlib's; this implementation currently buffers the last 32768 bytes
of output data until the end of the input stream, rather than attempting to
return as much data as possible during inflation.

=item total_in

Returns the total input (compressed) data so far

=item total_out

Returns the total output (uncompressed) data so far

=back

=head2 EXPORT

=over 4

=item crc32 BUFFER[, CRC32]

Calculate and return a 32 bit checksum for buffer. CRC32 is suitably
initialised if C<undef> is passed in.

=item Z_OK

Constant for returning normal status

=item Z_STREAM_END

Constant for returning end of stream

=item MAX_WBITS

Constant to pass to inflateInit (for compatibility with Compress::Zlib)

=back

=head1 TODO

=over

=item *

Test and if necessary fix on big endian systems

=item *

Backport to at least 5.005_03

=item *

Fill in all the other missing Comress::Zlib APIs

=back

=head1 BUGS

=over 4

=item *

Doesn't implement all of Compress::Zlib

=item *

Doesn't emulate Compress::Zlib's error return values - instead uses C<die>

=item *

Slow. Well, what did you expect?

=back

=head1 SEE ALSO

Compress::Zlib

=head1 AUTHOR

Ton Hospel wrote a pure perl gunzip program.
Nicholas Clark, E<lt>nick@talking.bollo.cx<gt> turned it into a state machine
and reworked the decompression core to fit Compress::Zlib's interface.

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Ton Hospel, Nicholas Clark

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
