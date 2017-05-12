#!/usr/bin/perl

package X;

use Class::MakeMethods::Template::Hash (
  'new --copy' => 'copy',
  'scalar'    => [qw/ a b /],
);

sub new { bless {}, shift; }

package main;
use Test;
BEGIN { plan tests => 8 }

my $o = new X;

ok( 1 ); #1
ok( $o->a ('foo') eq 'foo' ); #2
ok( $c = $o->copy ); #3
ok( $c->a eq 'foo' ); #4
ok( $c->a ('bar') eq 'bar' ); #5
ok( $o->a eq 'foo' ); #6
ok( $o->a ('baz') eq 'baz' ); #7
ok( $c->a eq 'bar' ); #8

exit 0;

