#!/usr/bin/perl

use Test;
BEGIN { plan tests => 11 }

package X;

use Class::MakeMethods::Template::Hash (
  new     => 'new',
  number  => [ 'c', { 'interface' => { 
    -base => 'counter', '*_incr_func' => '-self_closure incr'
  } } ],
);

package main;

ok( 1 ); #1

my $o = X->new();

my $single_incr = $o->c_incr_func();
my $double_incr = $o->c_incr_func(2);

ok( ref( $single_incr and $double_incr ) ); #2

ok( $o->c() == 0 ); #3
ok( $o->c(123) ); #4
ok( $o->c() == 123 ); #5

ok( &$single_incr() == 124 ); #6
ok( $o->c() == 124 ); #7
ok( &$single_incr() == 125 ); #8
ok( &$double_incr() == 127 ); #9
ok( &$double_incr() == 129 ); #10
ok( $o->c() == 129 ); #11

exit 0;

