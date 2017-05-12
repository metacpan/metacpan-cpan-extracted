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

BEGIN { plan tests => 18 }

my $c = eval { new Convert::Binary::C };
ok($@,'',"failed to create Convert::Binary::C object");

$c->PointerSize(4)->IntSize(2)->CharSize(1);

@test = (
  [ 'const volatile' => $c->IntSize ],
  [ 'volatile [3]'   => 3 * $c->IntSize ],
  [ 'restrict *'     => $c->PointerSize ],
);

for my $t (@test) {
  eval { $c->clean->parse("typedef char array[sizeof($t->[0])];") };
  ok($@, '');
  ok($c->sizeof('array'), $t->[1]);
}

# bitfield size tests

@test = (
  [ 'int :-1'   => qr/negative width for bit-field/ ],
  [ 'int :0'    => '' ],
  [ 'int :1'    => '' ],
  [ 'int bf:-1' => qr/negative width for bit-field 'bf'/ ],
  [ 'int bf:0'  => qr/zero width for bit-field 'bf'/ ],
  [ 'int bf:1'  => '' ],
);

for my $t (@test) {
  eval { $c->clean->parse("struct bitfield { $t->[0]; };") };
  ok($@, $t->[1]);
}

# short-circuiting test
# XXX: this doesn't mean we're really short-circuiting, only
#      that we're cheating good enough ;-)

@test = (
  [ '1 || (1 / 0) ? 2 : 3' => 2 ],
  [ '0 && (1 / 0) ? 2 : 3' => 3 ],
);

for my $t (@test) {
  eval { $c->clean->parse("typedef char array[$t->[0]];") };
  ok($@, '');
  ok($c->sizeof('array'), $t->[1]);
}

# TODO: operator precedence tests

# TODO: array size tests



# test typedef behaviour

eval { $c->clean->parse(<<ENDC) };

typedef int T;

typedef struct T
{
  T T[sizeof(T)];
  T x : 10;
  T   :  1;
  T y :  1;
  T   :  0;
  int z;
} TT;

ENDC

ok($@, '');
