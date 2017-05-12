package Data::BitStream::Code::Varint;
use strict;
use warnings;
BEGIN {
  $Data::BitStream::Code::Varint::AUTHORITY = 'cpan:DANAJ';
  $Data::BitStream::Code::Varint::VERSION   = '0.08';
}

our $CODEINFO = { package   => __PACKAGE__,
                  name      => 'Varint',
                  universal => 1,
                  params    => 0,
                  encodesub => sub {shift->put_varint(@_)},
                  decodesub => sub {shift->get_varint(@_)}, };

use Moo::Role;
requires qw(maxbits read write);

# base-128 encoding, LSB first.
# This is the Unsigned LEB128 format used in DWARF and numerous other places.
# It is called Varint or Varint-128 by Google.
# It is an endian reverse of the ASN.1 BER format.
# The Perl Sereal module uses this format.

# Very fast to parse (especially in C), but lousy space usage compared to
# most other VLCs.  It has advantages in being byte aligned and
# restart-friendly.  Fibonacci codes have the latter property but not the
# first.  UTF-8 is an example of variable length coding that uses both
# properties to advantage.
#
# Since it is byte-aligned, the results should be amenable to compression
# with byte compressors such as Snappy, ZLIB, BZIP, 7ZIP, etc.

sub put_varint {
  my $self = shift;
  $self->error_stream_mode('write') unless $self->writing;

  foreach my $val (@_) {
    $self->error_code('zeroval') unless defined $val and $val >= 0;
    # Coalesce calls to write for small numbers.
    if ($val <= 127) {
      $self->write(8, $val);
    } elsif ($val <= 16383) {
      $self->write(16,   0x00008000
                       | (($val & 0x7F) << 8)
                       | ($val >> 7) );
    } elsif ($val <= 2097151) {
      $self->write(24,   0x00808000
                       | (($val & 0x7F) << 16)
                       | ((($val >> 7) & 0x7F) << 8)
                       | ($val >> 14) );
    } else {
      my $v = $val;
      while ($v > 127) {
        $self->write(8, ($v & 0x7F) | 0x80);
        $v >>= 7;
      }
      $self->write(8, $v);
    }
  }
  1;
}

sub get_varint {
  my $self = shift;
  $self->error_stream_mode('read') if $self->writing;
  my $count = shift;
  if    (!defined $count) { $count = 1;  }
  elsif ($count  < 0)     { $count = ~0; }   # Get everything
  elsif ($count == 0)     { return;      }

  my @vals;
  my $maxbits = $self->maxbits;
  $self->code_pos_start('varint');
  while ($count-- > 0) {
    $self->code_pos_set;
    my $byte = $self->read(8);
    last unless defined $byte;
    my $val = $byte & 0x7F;
    my $shift = 7;
    while ($byte > 127) {
      $byte = $self->read(8);
      $self->error_off_stream unless defined $byte;
      $self->error_code('overflow') if $shift > $maxbits;
      $val |= ($byte & 0x7F) << $shift;
      $shift += 7;
    }
    push @vals, $val;
  }
  $self->code_pos_end;
  wantarray ? @vals : $vals[-1];
}
no Moo::Role;
1;
