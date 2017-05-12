package CORBA::IOP::Util;

require Exporter;

use strict;
use vars qw(@ISA @EXPORT $IOR_MAGIC $TAG_INTERNET_IOP);

@ISA = qw(Exporter);
@EXPORT = qw(decode_number decode_string decode_encapsulation $IOR_MAGIC $TAG_INTERNET_IOP
	     encode_number encode_string encode_encapsulation);


$IOR_MAGIC = "IOR:";
$TAG_INTERNET_IOP = 0;


sub quantise {
  my ($index, $quantum) = @_;
  my ($offset);

  $offset = $index % $quantum;

  return $offset != 0 ? $index + $quantum - $offset : $index;
}


#
# decode hex string
#
sub decode_hex {
  my ($what, $index, $size) = @_;
  my (@array, $where, $i);

  for ($i = 0; $i < $size; $i++) {
    $where = ($index + $i) * 2;  # every 2 characters is 1 hex digit
    $array[$i] = hex(unpack("x$where a2", $what));
  }
  return (pack("c$size", @array), $index + $size);
}


#
# decode an unsigned number
#
sub decode_number {
  my ($what, $index, $size, $little_endian) = @_;
  my (@array, $where, $i);

  $index = quantise($index, $size);

  # every 2 characters is 1 hex digit
  for ($i = 0; $i < $size; $i++) {
    $where = ($index + $i) * 2;
    $array[$i] = unpack("x$where a2", $what);
  }

  return (hex(join("", $little_endian ? reverse(@array) : @array)), $index + $size);
}


#
# decode a string (length + chars + null)
#
sub decode_string {
  my ($what, $index, $little_endian) = @_;
  my ($size, $string);

  # first decode the length (ulong)
  ($size, $index) = decode_number($what, $index, 4, $little_endian); 

  # decode the rest, ignoring null termination character
  ($string, $index) = decode_hex($what, $index, $size - 1);

  return $string, $index + 1;
}


#
# decode an encapsulation (length + octets)
#
sub decode_encapsulation {
  my ($what, $index, $little_endian) = @_;
  my $size;

  # first decode the length (ulong)
  ($size, $index) = decode_number($what, $index, 4, $little_endian);

  # decode the rest
  return decode_hex($what, $index, $size);
}


sub encode_number {
  my ($length, $size, $little_endian, $value) = @_;

  my ($result, @array, $i);

  # String length is twice the byte position.
  $result = "00" x (quantise($length/2, $size) - $length/2);

  for ($i=0; $i<$size; $i++){
    $array[$i] = sprintf("%.2x", $value % 0x100);
    $value = int($value / 0x100);
  }

  $result .= join("", !$little_endian ? reverse(@array) : @array);

  return $result;
}


sub encode_string {
  my ($length, $little_endian, $string) = @_;

  return encode_number($length, 4, $little_endian, length($string) + 1) # Length
    . unpack("H*", $string) . "00"; # Encoded string and terminator.
}


sub encode_encapsulation {
  my ($length, $little_endian, $string) = @_;

  return encode_number($length, 4, $little_endian, length($string)) # Length
    . unpack("H*", $string); # Octet stream.
}


1;
