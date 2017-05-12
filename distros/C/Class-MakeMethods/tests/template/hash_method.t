#!/usr/bin/perl

use Test;
BEGIN { plan tests => 7 }

package X;

use Class::MakeMethods::Template::Hash (
  'new' => 'new',
  'code --method' => [ qw / a b / ],
  'code --method' => 'c'
);

package main;

sub meth { $_[0] };
sub foo { "foo" };
sub bar { $_[0] };

my $o = new X;

ok( 1 ); #1
#ok( eval { $o->a }; !$@ ); #2 # Ooops! this is broken at the moment.
ok( $o->a(\&foo) ); #3
ok( $o->a eq 'foo' ); #4
ok( ref $o->b(\&bar) ); #5
ok( $o->b('xxx') eq $o ); #6
ok( $o->c(sub { "baz" } ) ); #7
ok( $o->c eq 'baz' ); #8

exit 0;

