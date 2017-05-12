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

BEGIN {
  plan tests => 10;
}

my $CCCFG = require 'tests/include/config.pl';

eval {
  $c = new Convert::Binary::C;
};
ok($@,'',"failed to create Convert::Binary::C::Cached object");

eval {
  $c->parse( <<'ENDC' );

enum Zoo {
  APE, BEAR
};

static int a = 23;

static int test( int abc )
{
  int x, y;

  y = abc;
  x = y * y;

  return x;
}

static void foo( void )
{
  enum Bar {
    FOO, BAR
  } xxx;

  typedef enum _foo foo;

  struct _bar {
    int test;
    struct _bar *xxx;
  };

  {
    enum Bar;
    struct _bar;
  }
}

typedef unsigned long u_32;

static void bar( void )
{
  enum Bar {
    BAR, FOO
  } xxx;

  typedef enum _foo foo;

  struct _bar {
    int test;
    struct _bar *xxx;
  };
}

struct _bar {
  int foo;
};

ENDC
};
ok($@,'',"failed to parse code");

# check that only global types have been parsed
eval {
  @enum = $c->enum;
  @comp = $c->compound;
  @type = $c->typedef;
};
ok($@,'',"failed to get types");

ok( scalar @enum, 1, "got more/less enums than expected" );
ok( scalar @comp, 1, "got more/less compounds than expected" );
ok( scalar @type, 1, "got more/less typedefs than expected" );

ok( $enum[0]{identifier}, "Zoo" );
ok( $comp[0]{identifier}, "_bar" );
ok( $type[0]{declarator}, "u_32" );

# this file has some local types, just check if it parses correctly
eval {
  $c->clean->configure(%$CCCFG)->parse_file('tests/include/util.c');
};
ok($@,'',"failed to parse file");
