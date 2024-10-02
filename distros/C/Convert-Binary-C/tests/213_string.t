################################################################################
#
# Copyright (c) 2002-2024 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
################################################################################

use Test;
use Convert::Binary::C @ARGV;

$^W = 1;

BEGIN { plan tests => 91 }

eval {
  $C{B} = Convert::Binary::C->new(
    LongSize     => 4,
    LongLongSize => 8,
    ByteOrder    => 'BigEndian'
  );
};
ok($@,'',"failed to create Convert::Binary::C object");

eval {
  $C{B}->parse( <<'ENDC' );
typedef signed long long int   i_64;
typedef unsigned long long int u_64;
typedef signed long int        i_32;
typedef unsigned long int      u_32;
ENDC
};
ok($@,'',"failed to parse code");

eval {
  $C{L} = $C{B}->clone->ByteOrder( 'LittleEndian' );
};
ok($@,'',"failed to clone LittleEndian object");

@bytes = ( 0xAB, 0x54, 0xA9, 0x8C, 0xEB, 0x1F, 0x0A, 0xD2 );
$str{B} = pack 'C*', @bytes;
$str{L} = pack 'C*', reverse @bytes;

%order = (
  B => 'BigEndian',
  L => 'LittleEndian',
);

@tests = (
  {
    type => 'u_64',
    B => "12345678901234567890",
    L => "12345678901234567890",
  },
  {
    type => 'i_64',
    B => "-6101065172474983726",
    L => "-6101065172474983726",
  },
  {
    type => 'u_32',
    B => "2874452364",
    L => "3944680146",
  },
  {
    type => 'i_32',
    B => "-1420514932",
    L => "-350287150",
  },
);

for my $test ( @tests ) {
  for my $bo ( qw( B L ) ) {
    print "# unpack $order{$bo} $test->{type}\n";
    eval { $val = $C{$bo}->unpack( $test->{type}, $str{$bo} ) };
    ok($@,'',"unpack failed");
    ok($val, $test->{$bo}, "wrong value");
  }
}

@tests = (
  {
    type => 'u_64',
    B => " + 12345678901234567890",
    L => "12345678901234567890",
  },
  {
    type => 'i_64',
    B => " -6101065172474983726",
    L => "-  6101065172474983726",
  },
  {
    type => 'u_32',
    B => " + 2874452364",
    L => "3944680146",
  },
  {
    type => 'i_32',
    B => "-  1420514932",
    L => " - 350287150",
  },
);

for my $test ( @tests ) {
  for my $bo ( qw( B L ) ) {
    print "# pack $order{$bo} $test->{type}\n";
    eval { $val = $C{$bo}->pack( $test->{type}, $test->{$bo} ) };
    ok($@,'',"pack failed for $order{$bo} $test->{type} test");
    ok(length($val), $C{$bo}->sizeof($test->{type}), "wrong string size" );
    ok($val, substr($str{$bo}, 0, length($val)), "wrong string");
  }
}

@tests = (
  {
    name => 'dec',
    type => 'u_64',
    str  => pack("C*", 0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0x0E),
    B => " 81985529216486670",
    L => "1066697293388129025",
  },
  {
    name => 'hex',
    type => 'u_64',
    str  => pack("C*", 0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0x0E),
    B => "0x0123456789aBCd0E",
    L => " 0x0ECdaB8967452301",
  },
  {
    name => 'oct',
    type => 'u_64',
    str  => pack("C*", 0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0x0E),
    B => "04432126361152746416",
    L => "  073155270454721221401",
  },
  {
    name => 'bin',
    type => 'u_64',
    str  => pack("C*", 0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0x0E),
    B => " 0b100100011010001010110011110001001101010111100110100001110  ",
    L => "0b111011001101101010111000100101100111010001010010001100000001  ",
  },
  {
    name => 'dec',
    type => 'u_32',
    str  => pack("C*", 0x00, 0xaf, 0xfe, 0x00),
    B => "   11533824 ",
    L => "  16690944",
  },
  {
    name => 'hex',
    type => 'u_32',
    str  => pack("C*", 0x00, 0xaf, 0xfe, 0x00),
    B => "  0x00AffE00",
    L => "0x00FeaF00  ",
  },
  {
    name => 'oct',
    type => 'u_32',
    str  => pack("C*", 0x00, 0xaf, 0xfe, 0x00),
    B => "  053777000",
    L => " 077527400  ",
  },
  {
    name => 'bin',
    type => 'u_32',
    str  => pack("C*", 0x00, 0xaf, 0xfe, 0x00),
    B => " 0b101011111111111000000000",
    L => "  0b111111101010111100000000",
  },
);

for my $test ( @tests ) {
  for my $bo ( qw( B L ) ) {
    print "# pack $test->{name} $order{$bo} $test->{type}\n";
    eval { $val = $C{$bo}->pack( $test->{type}, $test->{$bo} ) };
    ok($@,'',"pack failed for $order{$bo} $test->{type} test");
    ok(length($val), $C{$bo}->sizeof($test->{type}), "wrong string size" );
    ok($val, substr($test->{str}, 0, length($val)), "wrong string");
  }
}
