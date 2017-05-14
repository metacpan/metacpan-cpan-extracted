#!/usr/bin/perl

use Test;
BEGIN { plan tests => 9 }

package X;

use Class::MakeMethods;

Class::MakeMethods->import( 'Template::Hash:new --with_values' => 'new' );

Class::MakeMethods->import( 'Template::Hash:scalar' => 'b' );
Class::MakeMethods->import( '::Class::MakeMethods::Template::Hash:scalar' => 'b2' );
Class::MakeMethods->import( -MakerClass=>'Template::Hash', 'scalar' => 'c' );
Class::MakeMethods::Template::Hash->import( 'scalar' => 'd' );

Class::MakeMethods->import( 'Template::Hash:scalar' => 'e' );
Class::MakeMethods->import( 'Template::Hash:scalar' => [ 'f' ] );
Class::MakeMethods->import( 'Template::Hash:scalar' => { 'name' => 'g' } );
Class::MakeMethods->import( 'Template::Hash:scalar' => [ { 'name' => 'h' } ] );
Class::MakeMethods->import( 'Template::Hash:scalar' => [ 'i', { 'info'=>"foo" } ] );

package main;

ok( 1 ); #1

my $o = X->new;

ok( $o->b(1) ); #2
ok( $o->c(1) ); #3
ok( $o->d(1) ); #4

ok( $o->e(1) ); #5
ok( $o->f(1) ); #6
ok( $o->g(1) ); #7
ok( $o->h(1) ); #8
ok( $o->i(1) ); #9

