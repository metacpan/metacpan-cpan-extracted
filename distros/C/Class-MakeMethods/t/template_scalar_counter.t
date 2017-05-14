#!/usr/local/bin/perl

use Test;
BEGIN { plan tests => 9 }

package X;

use Class::MakeMethods::Template::Scalar ( 
  'new' => 'new',
  'number --counter' => [ qw / a b / ]
);

package main;

my $o = X->new;

# Note that Scalar refs only have a single value, so a and b affect 
# the same underlying data.

ok( 1 ); #1
ok( $o->a == 0 ); #2
ok( $o->a == 0 ); #3
ok( $o->a_incr == 1 ); #4
ok( $o->a_incr == 2 ); #5
ok( $o->a == 2 ); #6
ok( $o->b == 2 ); #7
ok( $o->b_incr == 3 ); #8
ok( $o->a == 3 ); #9

exit 0;
