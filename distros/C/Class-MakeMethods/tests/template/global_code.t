#!/usr/bin/perl

package X;

use Test;
BEGIN { plan tests => 7 }

use Class::MakeMethods::Template::Global (
  'code' => [ qw / a b / ],
  'code' => 'c'
);

sub foo { "foo" };
sub bar { $_[0] };

ok( 1 ); #1
ok( X->a(\&foo) ); #2
ok( X->a eq 'foo' ); #3
ok( ref X->b(\&bar) ); #4
ok( X->b('xxx') eq 'xxx' ); #5
ok( X->c(sub { "baz" } ) ); #6
ok( X->c eq 'baz' ); #7

exit 0;

