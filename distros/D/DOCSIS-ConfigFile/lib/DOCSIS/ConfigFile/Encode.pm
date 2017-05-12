package DOCSIS::ConfigFile::Encode;

=head1 NAME

DOCSIS::ConfigFile::Encode - Encode functions for a DOCSIS config-file.

=head1 SYNOPSIS

    @uchar = snmp_object({
                 value => { oid => $str, type => $str, value => $str },
             });
    @uchar = bigint({ value => $bigint });
    @uchar = int({ value => $int });
    @uchar = uint({ value => $uint });
    @uchar = ushort({ value => $ushort });
    @uchar = uchar({ value => $char });
    @uchar = vendorspec({
                 value  => '0x001337', # vendors ID
                 nested => [
                     {
                         type => $int, # vendor specific type
                         value => $int, # vendor specific value
                     },
                 ],
             });
    @uchar = ip({ value => '1.2.3.4' });
    @uchar = ether({ value => '0x0123456789abcdef' });
    @uchar = ether({ value => $uint });
    @uchar = string({ value => '0x0123456789abcdef' });
    @uchar = string({ value => 'string containing percent: %25' });
    @uchar = hexstr({ value => '0x0123456789abcdef' });
    () = mic({ value => $any });

=head1 DESCRIPTION

This module has functions which is used to encode "human" data
into list of unsigned characters (0-255) (refered to as "bytes")
later in the pod. This list can then be encoded into binary data
using:

    $bytestr = pack 'C*', @uchar;

=cut

use strict;
use warnings;
use bytes;
use Carp 'confess';
use DOCSIS::ConfigFile::Syminfo;
use Math::BigInt;
use Socket;

our %SNMP_TYPE = (
  INTEGER   => [0x02, \&int],
  STRING    => [0x04, \&string],
  NULLOBJ   => [0x05, sub { }],
  OBJECTID  => [0x06, \&objectid],
  IPADDRESS => [0x40, \&ip],
  COUNTER   => [0x41, \&uint],
  UNSIGNED  => [0x42, \&uint],
  TIMETICKS => [0x43, \&uint],
  OPAQUE    => [0x44, \&uint],
  COUNTER64 => [0x46, \&bigint],
);

=head1 FUNCTIONS

=head2 snmp_object

This function encodes a human-readable SNMP oid into a list of bytes:

    @bytes = (
      #-type---length---------value-----type---
        0x30,  $total_length,         # object
        0x06,  int(@oid),     @oid,   # oid
        $type, int(@value),   @value, # value
    );

=cut

sub snmp_object {
  my $obj = _test_value(snmp_object => $_[0]);
  my $type = $SNMP_TYPE{uc($obj->{type})} or confess "Unknown SNMP type: @{[$obj->{type}||'']}";
  my @value = $type->[1]->({value => $obj->{value}, snmp => 1});
  my @oid = _snmp_oid($obj->{oid});

  unless (@value) {
    confess 'Failed to decode SNMP value: ' . $obj->{value};
  }

  my @oid_length   = _snmp_length(0 + @oid);
  my @value_length = _snmp_length(0 + @value);
  my @total_length = _snmp_length(3 + @value + @oid + @value_length);

  return (
    #-type--------length----------value-----type---
    0x30, @total_length,        # object
    0x06, @oid_length, @oid,    # oid
    $type->[0], @value_length, @value,    # value
  );
}

sub _snmp_length {
  my $length = $_[0];
  my @bytes;

  if ($length < 0x80) {
    return $length;
  }
  elsif ($length < 0xff) {
    return 0x81, $length;
  }
  elsif ($length < 0xffff) {
    while ($length) {
      unshift @bytes, $length & 0xff;
      $length >>= 8;
    }
    return 0x82, @bytes;
  }

  confess "Too long snmp length: ($length)";
}

sub _snmp_oid {
  my $oid = $_[0];
  my (@encoded_oid, @input_oid);
  my $subid = 0;

  if ($_[0] =~ /[A-Za-z]/) {
    die "[DOCSIS] Need to install SNMP.pm http://www.net-snmp.org/ to encode non-numberic OID $oid"
      unless DOCSIS::ConfigFile::Syminfo::CAN_TRANSLATE_OID;
    $oid = SNMP::translateObj($oid) or confess "Could not translate OID '$_[0]'";
  }

  @input_oid = split /\./, $oid;
  shift @input_oid unless length $input_oid[0];

  # the first two sub-id are in the first id
  {
    my $first  = shift @input_oid;
    my $second = shift @input_oid;
    push @encoded_oid, $first * 40 + $second;
  }

SUB_OID:
  for my $id (@input_oid) {
    if ($id <= 0x7f) {
      push @encoded_oid, $id;
    }
    else {
      my @suboid;

      while ($id) {
        unshift @suboid, 0x80 | ($id & 0x7f);
        $id >>= 7;
      }

      $suboid[-1] &= 0x7f;
      push @encoded_oid, @suboid;
    }
  }

  return @encoded_oid;
}

=head2 bigint

Returns a list of bytes representing the C<$bigint>. This can be any
number (negative or positive) which can be representing using 64 bits.

=cut

sub bigint {
  my $value = _test_value(bigint => $_[0]);
  my $int64 = Math::BigInt->new($value);

  $int64->is_nan and confess "$value is not a number";

  my $negative = $int64 < 0;
  my @bytes = $negative ? (0x80) : ();

  while ($int64) {
    my $value = $int64 & 0xff;
    $int64 >>= 8;
    $value ^= 0xff if ($negative);
    unshift @bytes, $value;
  }

  return @bytes ? @bytes : (0);    # 0 is also a number ;-)
}

=head2 int

Returns a list of bytes representing the C<$int>. This can be any
number (negative or positive) which can be representing using 32 bits.

=cut

sub int {
  my $obj      = $_[0];
  my $int      = _test_value(int => $obj, qr{^[+-]?\d{1,10}$});
  my $negative = $int < 0;
  my @bytes;

  # make sure we're working on 32bit
  $int &= 0xffffffff;

  while ($int) {
    my $value = $int & 0xff;
    $int >>= 8;
    $value ^= 0xff if ($negative);
    unshift @bytes, $value;
  }

  if (!$obj->{snmp}) {
    $bytes[0] |= 0x80 if ($negative);
    unshift @bytes, 0 for (1 .. 4 - @bytes);
  }
  if (@bytes == 0) {
    @bytes = (0);
  }
  if ($obj->{snmp}) {
    unshift @bytes, 0 if (!$negative and $bytes[0] > 0x79);
  }

  return @bytes;
}

=head2 uint

Returns a list of bytes representing the C<$uint>. This can be any
positive number which can be representing using 32 bits.

=cut

sub uint {
  my $obj = $_[0];
  my $uint = _test_value(uint => $obj, qr{^\+?\d{1,10}$});
  my @bytes;

  while ($uint) {
    my $value = $uint & 0xff;
    $uint >>= 8;
    unshift @bytes, $value;
  }

  if (!$obj->{snmp}) {
    unshift @bytes, 0 for (1 .. 4 - @bytes);
  }
  if (@bytes == 0) {
    @bytes = (0);
  }
  if ($obj->{snmp}) {
    unshift @bytes, 0 if ($bytes[0] > 0x79);
  }

  return @bytes;
}

=head2 ushort

Returns a list of bytes representing the C<$ushort>. This can be any
positive number which can be representing using 16 bits.

=cut

sub ushort {
  my $obj = $_[0];
  my $ushort = _test_value(ushort => $obj, qr{^\+?\d{1,5}$});
  my @bytes;

  if ($obj->{snmp}) {
    unshift @bytes, 0 if ($ushort > 0x79);
  }

  while ($ushort) {
    my $value = $ushort & 0xff;
    $ushort >>= 8;
    unshift @bytes, $value;
  }

  if (!$obj->{snmp}) {
    unshift @bytes, 0 for (1 .. 2 - @bytes);
  }
  if (@bytes == 0) {
    @bytes = (0);
  }

  return @bytes;
}

=head2 uchar

Returns a list with one byte representing the C<$uchar>. This can be any
positive number which can be representing using 8 bits.

=cut

sub uchar {
  return _test_value(uchar => $_[0], qr/\+?\d{1,3}$/);
}

=head2 vendorspec

Will byte-encode a complex vendorspec datastructure.

=cut

sub vendorspec {
  my $obj = $_[0];
  my (@vendor, @bytes);

  unless (ref $obj->{nested} eq 'ARRAY') {
    confess "vendor({ nested => ... }) is not an array ref";
  }

  @vendor = ether($obj);                       # will extract value=>$hexstr. might confess
  @bytes = (8, CORE::int(@vendor), @vendor);

  for my $tlv (@{$obj->{nested}}) {
    my @value = hexstr($tlv);                  # will extract value=>$hexstr. might confess
    push @bytes, uchar({value => $tlv->{type}});
    push @bytes, CORE::int(@value);
    push @bytes, @value;
  }

  return @bytes;
}

=head2 ip

Returns a list of four bytes representing the C<$ip>. The C<$ip> must
be in in the format "1.2.3.4".

=cut

sub ip {
  return split /\./, _test_value(ip => $_[0], qr{^(?:\d{1,3}\.){3}\d{1,3}$});
}

=head2 ether

This function use either L</uint> or L</hexstr> to encode the
input value. It will figure out the function to use by checking
the input for either integer value or a string looking like
a hex-string.

=cut

sub ether {
  my $string = _test_value(ether => $_[0]);

  if ($string =~ qr{^\+?[0-4294967295]$}) {    # numeric
    return uint({value => $string});
  }
  elsif ($string =~ /^(?:0x)?([0-9a-f]+)$/i) {    # hex
    return hexstr({value => $1});
  }

  confess "ether({ value => $string }) is invalid";
}

=head2 objectid

Encodes MIB number as value of C<OBJECTID>
can be in format: 1.2.3.4, .1.2.3.4

=cut

sub objectid {
  my $oid = _test_value(objectid => $_[0], qr{^\.?\d+(\.\d+)+$});
  $oid =~ s/^\.//;
  return _snmp_oid($oid);
}

=head2 string

Returns a list of bytes representing the C<$str>. Will use
L</hexstr> to decode it if it looks like a hex string (a
string starting with leading "0x"). In other cases, it will
decode it itself. The input string might also be encoded
with a simple uri-encode format: "%20" will be translated
to a space, and "%25" will be translated into "%", before
encoded using C<ord()>.

=cut

sub string {
  my $string = _test_value(string => $_[0]);

  if ($string =~ /^0x[a-f0-9]+$/i) {
    return hexstr(@_);
  }
  else {
    $string =~ s/%(\w\w)/{ chr hex $1 }/ge;
    return map { ord $_ } split //, $string;
  }
}

=head2 stringz

Returns a list of bytes representing the C<$str> with a zero
terminator at the end. The "\0" byte will be added unless
seen as the last element in the list.

Only ServiceClassName needs this, see L<DOCSIS::ConfigFile::Syminfo>
for more details.

=cut

sub stringz {
  my @bytes = string(@_);
  push @bytes, 0 if (@bytes == 0 or $bytes[-1] ne "\0");
  return @bytes;
}

=head2 hexstr

Will encode any hex encoded string into a list of bytes. The string
can have an optional leading "0x".

=cut

sub hexstr {
  my $string = _test_value(hexstr => $_[0], qr{(?:0x)?([a-f0-9]+)}i);
  my @bytes;

  $string =~ s/^(?:0x)//;

  while ($string =~ s/(\w{1,2})$//) {
    unshift @bytes, hex $1;
  }

  if ($string) {
    confess "hexstr({ value => ... }) is left with ($string) after decoding";
  }

  return @bytes;
}

=head2 mic

Cannot encode CM/CMTS mic without complete information about
the config file, so this function returns an empty list.

=cut

sub mic { }

=head2 no_value

This method will return an empty list. It is used by DOCSIS types, which
has zero length.

=cut

sub no_value { }

=head2 vendor

Will byte-encode a complex vendorspec datastructure.

=cut

sub vendor {
  my $options = $_[0]->{value}{options};
  my @vendor  = ether({value => $_[0]->{value}{id}});
  my @bytes   = (8, CORE::int(@vendor), @vendor);

  for (my $i = 0; $i < @$options; $i += 2) {
    my @value = hexstr({value => $options->[$i + 1]});
    push @bytes, uchar({value => $options->[$i]});
    push @bytes, CORE::int(@value);
    push @bytes, @value;
  }

  return @bytes;
}

sub _test_value {
  my ($name, $obj, $test) = @_;

  confess "$name({ value => ... }) received undefined value" unless defined $obj->{value};
  confess "$name({ value => " . $obj->{value} . " }) does not match $test" if $test and not $obj->{value} =~ $test;
  $obj->{value};
}

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut

1;
