################################################################################
#
# Copyright (c) 2002-2020 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
################################################################################

use Test;
use Convert::Binary::C @ARGV;

$^W = 1;

BEGIN {
  plan tests => 50;
}

$reason = Convert::Binary::C::feature('ieeefp') ? '' : 'no IEEE floating point';

$SIG{__WARN__} = sub { push @warn, $_[0] };

my $c = eval { Convert::Binary::C->new };
skip($reason,$@,'');

# check with reference data
while( <DATA> ) {

  s/^\s*//; s/\s*$//; s/#.*//;
  /\S/ or next;
  my($value, $double, $single) = split /\s*\|\s*/;
  my $sb = hex2str( $single );
  my $db = hex2str( $double );
  my $sl = reverse $sb;
  my $dl = reverse $db;
  my($u,$p);

  print "# checking $value\n";

  # Single Precision, BigEndian
  $c->FloatSize( length $sb )->ByteOrder( 'BigEndian' );

  $p = $c->pack('float', $value);
  printf "# pack(\$value) => %s\n", hexdump($p);
  skip( $reason, $p, $sb );

  $u = $c->unpack('float', $sb);
  print "# unpack(\$sb) => $u\n";
  skip( $reason, delta_ok( $value, $u, 1e-7 ) );

  # Double Precision, BigEndian
  $c->FloatSize( length $db )->ByteOrder( 'BigEndian' );

  $p = $c->pack('float', $value);
  printf "# pack(\$value) => %s\n", hexdump($p);
  skip( $reason, $p, $db );

  $u = $c->unpack('float', $db);
  print "# unpack(\$db) => $u\n";
  skip( $reason, delta_ok( $value, $u, 1e-15 ) );

  # Single Precision, LittleEndian
  $c->FloatSize( length $sl )->ByteOrder( 'LittleEndian' );

  $p = $c->pack('float', $value);
  printf "# pack(\$value) => %s\n", hexdump($p);
  skip( $reason, $p, $sl );

  $u = $c->unpack('float', $sl);
  print "# unpack(\$sl) => $u\n";
  skip( $reason, delta_ok( $value, $u, 1e-7 ) );

  # Double Precision, LittleEndian
  $c->FloatSize( length $dl )->ByteOrder( 'LittleEndian' );

  $p = $c->pack('float', $value);
  printf "# pack(\$value) => %s\n", hexdump($p);
  skip( $reason, $p, $dl );

  $u = $c->unpack('float', $dl);
  print "# unpack(\$dl) => $u\n";
  skip( $reason, delta_ok( $value, $u, 1e-15 ) );

}

skip( $reason, scalar @warn, 0, "unexpected warnings" );


sub delta_ok
{
  my($ref, $val, $delta) = @_;

  abs($val-$ref) <= $delta * abs($ref) and return 1;

  # catch the different cases of 'infinity'
  $ref > 1e10 and $val !~ /^[+-]?\d*(?:\.\d*)(?:[eE][+-]?\d+)?$/ and return 1;

  return 0;
}

sub hex2str { pack 'C*', map hex, split ' ', $_[0] }
sub hexdump { join ' ', map { sprintf '%02X', $_ } unpack 'C*', $_[0] }

__DATA__

-1.0            | BF F0 00 00 00 00 00 00 | BF 80 00 00
 0.0            | 00 00 00 00 00 00 00 00 | 00 00 00 00
 0.4            | 3F D9 99 99 99 99 99 9A | 3E CC CC CD
 1.0            | 3F F0 00 00 00 00 00 00 | 3F 80 00 00
 3.1415926535   | 40 09 21 FB 54 41 17 44 | 40 49 0F DB
 1.220703125e-4 | 3F 20 00 00 00 00 00 00 | 39 00 00 00
