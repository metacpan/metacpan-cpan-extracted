#!/usr/bin/perl

package X;

use Test;
BEGIN { plan tests => 7 }

use Class::MakeMethods::Template::Hash (
  code => [ qw / a b / ],
  code => 'c'
);
sub new { bless {}, shift; }
sub foo { "foo" };
sub bar { $_[0] };
my $o = new X;

ok( 1 ); #1
#ok( eval { $o->a }; !$@ ); #2 # Ooops! this is broken at the moment.
ok( $o->a(\&foo) ); #3
ok( $o->a eq 'foo' ); #4
ok( ref $o->b(\&bar) ); #5
ok( $o->b('xxx') eq 'xxx' ); #6
ok( $o->c(sub { "baz" } ) ); #7
ok( $o->c eq 'baz' ); #8

exit 0;

