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

BEGIN { plan tests => 43 }

eval {
  $c = new Convert::Binary::C;
};
ok($@,'',"failed to create Convert::Binary::C object");

#------------------------
# check the void keyword
#------------------------

eval {
  $c->clean->DisabledKeywords( [] );
  $c->parse( "typedef int void;" );
};
ok($@, qr/(parse|syntax) error/);

eval {
  $c->clean->DisabledKeywords( ['void'] );
  $c->parse( "typedef int void;" );
  @td = $c->typedef_names;
};
ok($@,'');
ok( scalar @td, 1 );
ok( $td[0], 'void' );

#------------------------
# check the C99 keywords
#------------------------

eval {
  $c->clean->DisabledKeywords( [] );
  $c->parse( "struct inline { int restrict; };" );
};
ok($@, qr/(parse|syntax) error/);

eval {
  $c->clean->DisabledKeywords( [qw( inline restrict )] );
  $c->parse( "struct inline { int restrict; };" );
  @st = $c->struct_names;
};
ok($@, '');
ok( scalar @st, 1 );
ok( $st[0], 'inline' );

my @c99decl = (
  'void funky(const int * const restrict foo[const restrict 8]);',
  'void funky(const int * const foo[const restrict 8]);',
  'void funky(const int * const foo[static const restrict 8]);',
  'void funky(const int * const foo[const restrict static 8]);',
  'void funky(const int * const foo[static 8]);',
  'void funky(restrict int * const foo[restrict 8]);',
);

$c->DisabledKeywords([]);

for my $c99 (@c99decl) {
  eval { $c->clean->parse($c99) };
  ok($@, '');
}

#--------------------
# check C++ comments
#--------------------

eval {
  $c->clean->DisabledKeywords( [] );
  $c->parse( "struct foo { int a[8//*comment*/4]; };\n" )
};
ok($@, qr/(parse|syntax) error/);

eval {
  $c->clean->HasCPPComments( 0 );
  $c->parse( "struct foo { char a[8//*comment*/4]; };\n" );
  $s = $c->sizeof('foo');
};
ok($@, '');
ok( $s, 2 );

#-----------------------------
# check (some) GNU extensions
#-----------------------------

eval {
  $c->clean->parse( "typedef __signed __extension__ long long _signed;" );
};
ok($@, qr/(parse|syntax) error/);

eval {
  $c->clean->Define( qw( __signed=signed __extension__= ) );
  $c->parse( "typedef __signed __extension__ long long _signed;" );
};
ok($@, '');

eval {
  $c->clean->parse( <<END );
#undef __signed
typedef __signed __extension__ long long _signed;
END
};
ok($@, qr/(parse|syntax) error/);

eval {
  $c->clean->KeywordMap( { __signed => 'signed', __extension__ => undef } );
  $c->parse( <<END );
#undef __signed
typedef __signed __extension__ long long _signed;
END
};
ok($@, '');

eval {
  $c->clean->Define( [] );
  $c->parse( <<END );
typedef __signed __extension__ long long _signed;
END
};
ok($@, '');

eval {
  $c->clean->parse( <<END );
typedef __signed __extension__ long long signed;
END
};
ok($@, qr/(parse|syntax) error/);

eval {
  $c->clean->DisabledKeywords( ['signed'] );
  $c->parse( <<END );
typedef __signed __extension__ long long signed;
END
};
ok($@, '');

#------------------------------
# check empty structs / unions
#------------------------------

for my $code (
               "struct test { };",
               "typedef struct { } test;",
               "union test { };",
               "typedef union { } test;",
               "struct test { } s = { };",
               "union test { } u = { };",
             )
{
  my $s = -1;
  my @m;
  eval {
    $c->clean->parse("$code\n");
    $s = $c->sizeof('test');
    @m = $c->member('test');
  };
  ok($@, '', $code);
  ok($s, 0);
  ok(scalar @m, 0);
}
