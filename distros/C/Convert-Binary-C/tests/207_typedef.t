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

BEGIN { plan tests => 30 }

eval { $c = Convert::Binary::C->new; };
ok($@,'',"failed to create Convert::Binary::C object");

eval {
$c->parse(<<'EOF');
/* just some C stuff */
typedef struct car truck, mobile[3], *vehicle;
typedef enum { MONDAY, JANUARY, Y2K } day, month[4][5], *year;
struct car {
  int wheel;
  int gear;
};
/* the only way to execute the default_declaring_list */
/* rule is some strange construct like this...        */
typedef const foo, *bar, baz[2][3];
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
# check what has been parsed...
#-----------------------------------------------------

@names   = eval { $c->typedef_names };
ok( $@, '' );
$n_names = eval { $c->typedef_names };
ok( $@, '' );

@defs    = eval { $c->typedef };
ok( $@, '' );
$n_defs  = eval { $c->typedef };
ok( $@, '' );

ok( $n_names, 9, "wrong number of typedefs has been parsed" );
ok( $n_names, $n_defs, "typedef_names/typedef mismatch" );
ok( scalar @names, $n_names, "typedef_names array/scalar mismatch" );
ok( scalar @defs,  $n_defs,  "typedef array/scalar mismatch" );

#-----------------------------------------------------
# some heavy typedefing ;-)
#-----------------------------------------------------

eval {
  $c->clean->IntSize(4)->parse(<<ENDC);
typedef int a;                            //   4
typedef a b;                              //   4
typedef b c[5];                           //  20
typedef c d;                              //  20
typedef d e[10];                          // 200
typedef e f;                              // 200
typedef struct { struct { f x; }; } g[2]; // 400
ENDC
};
ok( $@, '', 'parse() failed' );

$r = eval { $c->def('f') };
ok( $@, '' );
ok( $r,'typedef');

$r = eval { $c->offsetof('f', '[1][2]+1') };
ok( $@, '' );
ok( $r, 29 );

$r = eval { $c->offsetof('f[9]', '[1]+2') };
ok( $@, '' );
ok( $r, 6 );

$r = eval { $c->sizeof('f[9]') };
ok( $@, '' );
ok( $r, 20 );

$r = eval { $c->sizeof('g') };
ok( $@, '' );
ok( $r, 400 );

$r = eval { $c->typeof('f[9]') };
ok( $@, '' );
ok( $r, 'd' );

$r = eval { $c->member('f', 29) };
ok( $@, '' );
ok( $r, '[1][2]+1' );

$r = eval { $c->member('f[9]', 6) };
ok( $@, '' );
ok( $r, '[1]+2' );

$r = eval { $c->member('g', 256) };
ok( $@, '' );
ok( $r, '[1].x[2][4]' );

ok( scalar @warn, 0, "unexpected warnings" );
print "# $_" for @warn;
