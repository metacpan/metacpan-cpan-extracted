################################################################################
#
# Copyright (c) 2002-2015 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
################################################################################

use Test;
use Convert::Binary::C @ARGV;

$^W = 1;

BEGIN { plan tests => 182 }

eval {
  $p = new Convert::Binary::C ByteOrder => 'BigEndian',
                              EnumSize  => 4,
                              EnumType  => 'Integer';
};
ok($@,'',"failed to create Convert::Binary::C object");

eval {
$p->parse(<<'EOF');
enum ubyte_u {
  ZERO, ONE, TWO, THREE,
  ANOTHER_ONE = 1,
  BIGGEST = 255
};

enum sbyte_u {
  MINUS_TWO = -2, MINUS_ONE, Z_E_R_O, PLUS_ONE,
  NEG = -1, NOTHING, POS,
  MIN = -128, MAX = 127
};

enum uword_u { W_BIGGEST = 65535 };
enum sword_u { W_MIN = -32768, W_MAX = 32767 };

enum ulong_u { WHATEVER =  65536 };
enum slong_u { NEGATIVE = -32769 };

enum sword_s { SWS = -129 };
enum uword_s { UWS = 128 };

enum slong_s { SLS = -32769 };
enum ulong_s { ULS =  32768 };

EOF
};
ok($@,'',"parse() failed");

# catch all warnings for further checks

$SIG{__WARN__} = sub { push @warn, $_[0] };
sub chkwarn {
  ok( scalar @warn, scalar @_, "wrong number of warnings" );
  ok( shift @warn, $_ ) for @_;
  @warn = ();
}

#-----------------------------------------------------
# check sizeof()
#-----------------------------------------------------

ok($p->sizeof('ubyte_u'),4,"ubyte_u size");
ok($p->sizeof('sbyte_u'),4,"sbyte_u size");
ok($p->sizeof('uword_u'),4,"uword_u size");
ok($p->sizeof('sword_u'),4,"sword_u size");
ok($p->sizeof('ulong_u'),4,"ulong_u size");
ok($p->sizeof('slong_u'),4,"slong_u size");

eval { $p->EnumSize( -1 ) };
ok($@,'',"failed in configure"); chkwarn;

ok($p->sizeof('ubyte_u'),2,"ubyte_u size");
ok($p->sizeof('sbyte_u'),1,"sbyte_u size");
ok($p->sizeof('uword_u'),4,"uword_u size");
ok($p->sizeof('sword_u'),2,"sword_u size");
ok($p->sizeof('ulong_u'),4,"ulong_u size");
ok($p->sizeof('slong_u'),4,"slong_u size");

ok($p->sizeof('uword_s'),2,"uword_u size");
ok($p->sizeof('sword_s'),2,"sword_u size");
ok($p->sizeof('ulong_s'),4,"ulong_u size");
ok($p->sizeof('slong_s'),4,"slong_u size");

eval { $p->EnumSize( 0 ) };
ok($@,'',"failed in configure"); chkwarn;

ok($p->sizeof('ubyte_u'),1,"ubyte_u size");
ok($p->sizeof('sbyte_u'),1,"sbyte_u size");
ok($p->sizeof('uword_u'),2,"uword_u size");
ok($p->sizeof('sword_u'),2,"sword_u size");
ok($p->sizeof('ulong_u'),4,"ulong_u size");
ok($p->sizeof('slong_u'),4,"slong_u size");

#-----------------------------------------------------
# check enum types
#-----------------------------------------------------

@ubyte = (
  [  0, 'ZERO'     ],
  [  1, 'ONE'      ],
  [  2, 'TWO'      ],
  [  3, 'THREE'    ],
  [ 42, '<ENUM:42>'],
  [255, 'BIGGEST'  ],
);

for( @ubyte ) {
  eval { $pk = $p->unpack( 'ubyte_u', pack('C', $_->[0]) ) };
  ok($@,'',"failed for (@$_)"); chkwarn;
  ok($_->[0] == $pk); chkwarn;
  ok($_->[1] ne $pk); chkwarn;
}

eval { $p->EnumType( 'String' ) };
ok($@,'',"failed in configure"); chkwarn;

for( @ubyte ) {
  eval { $pk = $p->unpack( 'ubyte_u', pack('C', $_->[0]) ) };
  ok($@,'',"failed for (@$_)"); chkwarn;
  ok($_->[0] != $pk ? 1 : $_->[0] == 0);
  chkwarn( qr/Argument "$pk" isn't numeric/ );
  ok($_->[1] eq $pk); chkwarn;
}

eval { $p->EnumType( 'Both' ) };
ok($@,'',"failed in configure"); chkwarn;

for( @ubyte ) {
  eval { $pk = $p->unpack( 'ubyte_u', pack('C', $_->[0]) ) };
  ok($@,'',"failed for (@$_)"); chkwarn;
  ok($_->[0] == $pk); chkwarn;
  ok($_->[1] eq $pk); chkwarn;
}

#-----------------------------------------------------
# check pack/unpack
# (some of these may issue warnings in the future)
#-----------------------------------------------------

@sbyte = (
  ['ZERO',     0, 'Z_E_R_O'  ],
  ['NOTHING',  0, 'Z_E_R_O'  ],
  [-2,        -2, 'MINUS_TWO'],
  ['-2',      -2, 'MINUS_TWO'],
  ['POS',      1, 'PLUS_ONE' ],
  ['THREE',    3, '<ENUM:3>' ],
);

for( @sbyte ) {
  eval { $pk = $p->unpack( 'sbyte_u', $p->pack( 'sbyte_u', $_->[0] ) ) };
  ok($@,'',"failed for (@$_)"); chkwarn;
  ok($_->[1] == $pk); chkwarn;
  ok($_->[2] eq $pk); chkwarn;
}
