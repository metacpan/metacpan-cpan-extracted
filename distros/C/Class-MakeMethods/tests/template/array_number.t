#!/usr/bin/perl

use Test;
BEGIN { plan tests => 11 }

package X;

use Class::MakeMethods::Template::Array (
  new     => 'new',
  number  => [ qw/ a b c /]
);

package main;

my $o = X->new();

ok( 1 );
ok( $o->a == 0 );
ok( $o->a(123) );
ok( $o->a == 123 );
ok( $o->a(undef) == 0 );
ok( $o->a == 0 );
ok( $o->a("456") );
ok( $o->a == 456 );
ok( $o->a(undef) == 0 );
ok( $o->a == 0 );
ok( ! eval { $o->a("Foo"); 1 } );

exit 0;

