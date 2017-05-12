package Data::BitStream::Code::BER;
use strict;
use warnings;
BEGIN {
  $Data::BitStream::Code::BER::AUTHORITY = 'cpan:DANAJ';
  $Data::BitStream::Code::BER::VERSION   = '0.08';
}

our $CODEINFO = { package   => __PACKAGE__,
                  name      => 'BER',
                  universal => 1,
                  params    => 0,
                  encodesub => sub {shift->put_BER(@_)},
                  decodesub => sub {shift->get_BER(@_)}, };

use Moo::Role;
requires qw(maxbits read write);

# Big-endian base-128

sub put_BER {
  my $self = shift;
  $self->error_stream_mode('write') unless $self->writing;

  foreach my $val (@_) {
    $self->error_code('zeroval') unless defined $val and $val >= 0;

    if ($val <= 127) {
      $self->write(8, $val);
    } else {
      # Simple method using pack
      $self->put_string( unpack("B*", pack("w", $val)) );
      #my @bytes;
      #my $v = $val;
      #do {
      #  unshift @bytes, ($v & 0x7F) | 0x80;
      #  $v >>= 7;
      #} while ($v > 0);
      #$bytes[-1] &= 0x7F;   # clear mark on last byte
      #foreach my $byte (@bytes) {
      #  $self->write(8, $byte);
      #}
    }
  }
  1;
}

sub get_BER {
  my $self = shift;
  $self->error_stream_mode('read') if $self->writing;
  my $count = shift;
  if    (!defined $count) { $count = 1;  }
  elsif ($count  < 0)     { $count = ~0; }   # Get everything
  elsif ($count == 0)     { return;      }

  my @vals;
  $self->code_pos_start('BER');
  while ($count-- > 0) {
    $self->code_pos_set;
    my $byte = $self->read(8);
    last unless defined $byte;
    my $val = $byte & 0x7F;
    while ($byte > 127) {
      $byte = $self->read(8);
      $self->error_off_stream unless defined $byte;
      $self->error_code('overflow') if (($val << 7) >> 7) != $val;
      $val = ($val << 7) | ($byte & 0x7F);
    }
    push @vals, $val;
  }
  $self->code_pos_end;
  wantarray ? @vals : $vals[-1];
}
no Moo::Role;
1;
