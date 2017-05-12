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
  plan tests => 119;
}

$SIG{__WARN__} = sub { push @warn, $_[0] };

eval {
  $c = new Convert::Binary::C;
};
ok($@,'',"failed to create Convert::Binary::C object");

@tests = (
  ['foo'                      => undef  ],
  ['int'                      => 'basic'],
  [' unsigned long long int ' => 'basic'],
);

run_tests( $c, @tests );

ok( scalar @warn, 0 );

@warn = ();

$c->parse( <<ENDC );

typedef int __int;
typedef int __array[10], *__ptr;

typedef struct test { int foo; } test, test2;
typedef struct undef undef, *undef2;
typedef union { int foo; } uni;
typedef enum noenu noenu;
typedef enum enu enu;

enum enu { ENU };

struct su { union uni *ptr; int flex[]; };
union uni2 { int foo[3][4]; };
enum  enu2 { FOO };

ENDC

@tests = (
  ['foo'             => undef    ],
  ['int'             => 'basic'  ],
  [' long double'    => 'basic'  ],
  ['__int'           => 'typedef'],
  ['__array'         => 'typedef'],
  ['__ptr'           => 'typedef'],
  ['__ptr.foo'       => ''       ],
  ['__ptr [10]'      => ''       ],
  ['__ptr !&'        => ''       ],
  ['test'            => 'typedef'],
  ['struct test'     => 'struct' ],
  ['test2'           => 'typedef'],
  ['undef'           => ''       ],
  ['undef2'          => 'typedef'],
  ['struct undef'    => ''       ],
  ['uni'             => 'typedef'],
  ['noenu'           => ''       ],
  ['enum enu'        => 'enum'   ],
  ['enu'             => 'typedef'],
  ['su'              => 'struct' ],
  ['union uni'       => ''       ],
  ['struct bar'      => undef    ],
  ['uni2'            => 'union'  ],
  ['enu2'            => 'enum'   ],
  ['test.foo'        => 'member' ],
  ['test.bar'        => ''       ],
  ['test2.foo'       => 'member' ],
  ['test2[3]'        => ''       ],
  ['test2.foo.x'     => ''       ],
  ['test2.foo[1]'    => ''       ],
  ['uni2.foo[1]'     => 'member' ],
  ['uni2.foo[2][3]'  => 'member' ],
  ['uni2.foo[-1]'    => 'member' ],
  ['uni2.foo[2][-1]' => 'member' ],
  ['uni2.foo[3]'     => 'member' ],
  ['uni2.foo[2][4]'  => 'member' ],
  ['undef.x'         => ''       ],
  ['__array[9]'      => 'member' ],
  ['__array[10]'     => 'member' ],
  ['__array.xxx'     => ''       ],
  ['enu.xxx'         => ''       ],
  ['enu???'          => ''       ],
  ['enu[0]'          => ''       ],
  ['noenu.xxx'       => ''       ],
  ['noenu???'        => ''       ],
  ['noenu[0]'        => ''       ],
  ['.xxx'            => undef    ],
  ['???'             => undef    ],
  ['[0]'             => undef    ],
  ['foo.xxx'         => undef    ],
  ['foo???'          => undef    ],
  ['foo[0]'          => undef    ],
  ['short int .xxx'  => undef    ],
  ['short int ???'   => undef    ],
  ['short int [0]'   => undef    ],
);

run_tests( $c, @tests );

ok( scalar @warn, 0 );

sub run_tests
{
  my $c = shift;
  for( @_ ) {
    my $rv = eval { $c->def($_->[0]) };
    ok( $@, '' );
    unless( defined $rv and defined $_->[1] ) {
      ok( defined $rv, defined $_->[1] );
    }
    else {
      ok( $rv, $_->[1], "wrong result for '$_->[0]'" );
    }
  }
}
