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

BEGIN { plan tests => 207 }

#===================================================================
# perform some average stuff
#===================================================================

eval {
  $p = Convert::Binary::C->new(
    PointerSize => 4,
    EnumSize    => 4,
    IntSize     => 4,
    LongSize    => 4,
    Alignment   => 2,
    ByteOrder   => 'BigEndian',
    EnumType    => 'String'
  );
  $q = Convert::Binary::C->new;
};
ok($@,'');

#-----------------------------------
# create some average ( ?? :-) code
#-----------------------------------

$code = <<'CCODE';
#define ONLY_ONE 1

typedef struct abc abc_type;

typedef struct never ever;

struct abc {
  abc_type *p1;
#if ONLY_ONE > 1
  abc_type *p2;
#endif
};

typedef unsigned long u32;

#define Day( which )  \
        which ## DAY

typedef enum {
  Day( MON ),
  Day( TUES ),
  Day( WEDNES ),
} day;

# \
  define  __SIX__ \
  ( sizeof( unsigned char * ) + sizeof( short ) )

   # define SIXTEEN \
     (sizeof "Hello\"\xfworld\069!")

typedef union zap {
  signed long  za[__SIX__];
  short        zb[SIXTEEN];
  char         zc[sizeof(struct never (*[2][3])[4])];
  ever        *zd[sizeof( abc_type )];
} ZAP;

CCODE

#-----------------------
# try to parse the code
#-----------------------

eval {
  $p->parse( $code );
  $q->parse( $code );
};
ok($@,'');

#------------------------
# reconfigure the parser
#------------------------

eval {
  $p->configure( Alignment => 8, EnumSize => 0 );
};
ok($@,'');

#--------------------------------
# and parse some additional code
#--------------------------------

$code = <<'CCODE';
typedef struct {
  abc_type xxx;
  u32 dusel, *fusel;
  int musel[((1<<1)+4)&0x00000002];
  union {
    char bytes[(12/2)%4][(0x10|010)>>3];
    day  today;
    long value;
  } test;
  struct ints fubar;
  union zap hello;
} husel;

#pragma pack( push, 1 )

struct packer {
  char  i;
  short am;
  char  really;
  long  packed;
};

#pragma pack( pop )

struct nopack {
  char  i;
  short am;
  char  not;
  long  packed;
};

CCODE

$c99_code = <<'CCODE' . $code;
#define \
MYINTS( ... \
) { int __VA_ARGS__; }

struct ints MYINTS( a, b, c );

CCODE

#-----------------------
# try to parse the code
#-----------------------

eval {
  $q->HasMacroVAARGS( 0 );
  $q->parse( $c99_code );
};
ok($@,qr/invalid macro argument/);

eval { $p->parse( $c99_code ) };
ok($@,'');

#------------------------
# reconfigure the parser
#------------------------

eval { $p->Alignment( 4 ) };
ok($@,'');

#-------------------
# test some offsets
#-------------------

ok($p->offsetof('packer', 'i'), 0);
ok($p->offsetof('packer', 'am'), 1);
ok($p->offsetof('packer', 'really'), 3);
ok($p->offsetof('packer', 'packed'), 4);

ok($p->offsetof('nopack', 'i'), 0);
ok($p->offsetof('nopack', 'am'), 2);
ok($p->offsetof('nopack', 'not'), 4);
ok($p->offsetof('nopack', 'packed'), 8);

#------------------------
# now try some unpacking
#------------------------

# on a pack()ed struct

$data = pack( 'cnCN', -47, 0x1234, 0x55, 2000000000 );

eval { $result = $p->unpack( 'packer', $data ) };
ok($@,'');

$refres = {
  i      => -47,
  am     => 0x1234,
  really => 0x55,
  packed => 2000000000,
};

reccmp( $refres, $result );

# on a 'normal' struct

$data = pack( 'cxnCx3N', -47, 0x1234, 0x55, 2000000000 );

eval { $result = $p->unpack( 'nopack', $data ) };
ok($@,'');

$refres = {
  i      => -47,
  am     => 0x1234,
  not    => 0x55,
  packed => 2000000000,
};

reccmp( $refres, $result );

#-----------------------
# test something bigger
#-----------------------

$data = pack( "N5c8N3C48", 123, 4711, 0xDEADBEEF,
              -42, 42, 1, 0, 0, 0, -2, 3, 0, 0,
              -10000, 5000, 8000, 1..48 );

eval { $result = $p->unpack( 'husel', $data ) };
ok($@,'');

eval { undef $p };
ok($@,'');


$refres = {
  xxx   => { p1 => 123 },
  dusel => 4711,
  fusel => 0xDEADBEEF,
  musel => [ -42, 42 ],
  test  => {
             bytes => [ [ 1, 0, 0 ], [ 0, -2, 3 ] ],
             today => 'TUESDAY',
             value => 16777216,
           },
  fubar => {
             a => -10000,
             b =>   5000,
             c =>   8000,
           },
  hello => {
             za => [16909060, 84281096, 151653132, 219025168, 286397204, 353769240],
             zb => [258, 772, 1286, 1800, 2314, 2828, 3342, 3856,
                    4370, 4884, 5398, 5912, 6426, 6940, 7454, 7968],
             zc => [1..24],
             zd => [16909060, 84281096, 151653132, 219025168],
           },
};

reccmp( $refres, $result );

#------------------------------------------------
# test pack/unpack/sizeof/typeof for basic types
#------------------------------------------------

$p = Convert::Binary::C->new;

@tests = (
  ['char',        $p->CharSize      ],
  ['short',       $p->ShortSize     ],
  ['int',         $p->IntSize       ],
  ['long',        $p->LongSize      ],
  ['long long',   $p->LongLongSize  ],
  ['float',       $p->FloatSize     ],
  ['double',      $p->DoubleSize    ],
  ['long double', $p->LongDoubleSize],
);

for( @tests ) {
  my $size = eval { $p->sizeof( $_->[0] ) };
  ok( $@, '' );
  ok( $size, $_->[1] );
}

check_basic( $p );

# must work without parse data, too
$p->clean;
check_basic( $p );

#--------------------------------
# test offsetof in strange cases
#--------------------------------

eval {
  $p->configure( IntSize     => 4
               , LongSize    => 4
               , PointerSize => 4
               , EnumSize    => 4
               , Alignment   => 4
               )->parse(<<ENDC);
struct foo {
  int a;
  struct bar {
    int x, y;
  } ary[5];
  struct bar {
    int x, y;
  } aryary[5][5];
};
typedef int a[10];
typedef struct {
  char abc;
  long day;
  int *ptr;
} week;
struct test {
  week zap[8];
};
ENDC
};

@tests = (
  ['foo',           '.ary',           4],
  ['foo.ary[2]',    '.x',             0],
  ['foo.ary[2]',    '.y',             4],
  ['foo.ary[2]',    '',               0],
  ['foo.ary',       '[2].y',         20],
  ['foo.aryary[2]', '[2].y',         20],
  ['a',             '[9]',           36],
  ['test',          '.zap[5].day',   64],
  ['test.zap[2]',   '.day',           4],
  ['test',          '.zap[5].day+1', 65],
);

$SIG{__WARN__} = sub { push @warn, $_[0] };
ok( $@, '' );
for( @tests ) {
  my $off = eval { $p->offsetof( $_->[0], $_->[1] ) };
  ok( $@, '' );
  ok( $off, $_->[2] );
}
ok( scalar @warn, 1 );
ok( $warn[0], qr/^Empty string passed as member expression/ );

#------------------------------
# some simple tests for member
#------------------------------

@tests = (
  ['foo',           '.ary[0].x',      4],
  ['foo.ary[2]',    '.x',             0],
  ['foo.ary[2]',    '.y',             4],
  ['foo.ary',       '[2].y',         20],
  ['foo.aryary[2]', '[2].y',         20],
  ['a',             '[9]',           36],
  ['test',          '.zap[5].day',   64],
  ['test.zap[2]',   '.day',           4],
  ['test',          '.zap[5].day+1', 65],
);

@warn = ();
ok( $@, '' );
for( @tests ) {
  my @m = eval { $p->member( $_->[0], $_->[2] ) };
  ok( $@, '' );
  ok( scalar @m, 1 );
  ok( $m[0], $_->[1] );
}
ok( scalar @warn, 0 );

#------------------------------
# test 64-bit negative numbers
#------------------------------

$p->clean->parse(<<ENDC);

typedef signed long long i_64;

ENDC

$p->LongLongSize(8);

for my $bo (qw( BigEndian LittleEndian )) {
  $p->ByteOrder($bo);
  my $x = $p->pack('i_64', -1);
  ok($x, pack('C*', (255)x8));
}


sub check_basic
{
  my $c = shift;

  for my $t ( 'signed char'
            , 'unsigned short int'
            , 'long int'
            , 'signed int'
            , 'long long'
            )
  {
    ok( eval { $c->typeof( $t ) }, $t );
    ok( eval { $c->sizeof( $t ) } > 0 );
    ok( eval { $c->unpack( $t, $c->pack($t, 42) ) }, 42 );
  }
}

sub reccmp
{
  my($ref, $val) = @_;

  my $id = ref $ref;

  unless( $id ) {
    ok( $ref, $val );
    return;
  }

  if( $id eq 'ARRAY' ) {
    ok( @$ref == @$val );
    for( 0..$#$ref ) {
      reccmp( $ref->[$_], $val->[$_] );
    }
  }
  elsif( $id eq 'HASH' ) {
    ok( @{[keys %$ref]} == @{[keys %$val]} );
    for( keys %$ref ) {
      reccmp( $ref->{$_}, $val->{$_} );
    }
  }
}
