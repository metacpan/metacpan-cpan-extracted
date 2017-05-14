#!/usr/bin/perl

package X;

use Test;
BEGIN { plan tests => 13 }

use Class::MakeMethods::Template::Hash (
  'string --get_concat' => 'x',
  'string --get_concat' => {'name' => 'y', 'join' => "\t"},
);

sub new { bless {}, shift; }

my $o = new X;

ok( 1 ); #1
ok( $o->x eq "" ); #2
ok( $o->x('foo') ); #3
ok( $o->x eq 'foo' ); #4
ok( $o->x('bar') ); #5
ok( $o->x eq 'foobar' ); #6
ok( ! defined $o->clear_x ); #7
ok( $o->x eq "" ); #8

ok( $o->y eq "" ); #9
ok( $o->y ('one') ); #10
ok( $o->y eq 'one' ); #11
ok( $o->y ('two') ); #12
ok( $o->y eq "one\ttwo" ); #13

exit 0;

