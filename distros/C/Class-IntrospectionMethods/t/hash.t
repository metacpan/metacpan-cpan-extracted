#!/usr/local/bin/perl
use warnings FATAL => qw(all);

package X;

use lib qw ( ./t );
use Test::More tests => 19 ;

use Class::IntrospectionMethods  qw/make_methods set_obsolete_behavior/;
set_obsolete_behavior('skip',1) ;

make_methods
  (
   hash => [ qw / a b / ],
   hash => 'c'
  );

sub new { bless {}, shift; }
my $o = new X;

ok( 1 ,"start");
ok( ! scalar keys %{$o->a} );
ok( ! defined $o->a('foo') );
is( $o->a('foo', 'baz'),'baz' );
is( $o->a('foo') , 'baz' );
ok( $o->a('bar', 'baz2') );

ok( $o->a_set(qw / a b c d / ),"test set" );

is_deeply([sort keys %{$o->a}],
	   [qw/a c/],"set result");
is_deeply([sort $o->a_keys],
	  [qw/a c/],"x_keys");

is_deeply([sort $o->a_values],
	  [qw/b d/],"x_values");

ok( $o->c('foo', 'bar') );
is( $o->c('foo') , 'bar' );

$o->c_delete('foo');
ok( ! defined $o->c('foo') ,"x_delete");

ok( $o->c ,"get h ref");

ok($o->c_set(qw / a b c d e f /),"c set");
is_deeply( scalar $o->c, {qw / a b c d e f /});

$o->c_delete(qw / a c /);
my %h = $o->c;
is($h{'e'} , 'f');

$o->a_clear;
is (scalar $o->a_keys, 0 , "test clear");

$o->a ('a' => 1);
is_deeply([keys %{$o->a}],['a']);

