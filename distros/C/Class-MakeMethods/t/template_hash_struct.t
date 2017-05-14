#!/usr/local/bin/perl

package X;

use Test;
BEGIN { plan tests => 16 }

use Class::MakeMethods::Template::Hash
  struct => [ qw / a b c d / ],
  struct => 'e';

sub new { bless {}, shift; }
my $o = new X;

ok( 1 ); #1

ok( eval { $o->a; 1; } and ! $@ ); #2
ok( ! $o->a ); #3
ok( ! $o->b ); #4
ok( ! $o->c ); #5
ok( ! $o->d ); #6
ok( ! $o->e ); #7

my @f;
ok do { @f = $o->struct_fields; print "@f\n" }; #8
ok do {
  $f[0] eq 'a' and 
  $f[1] eq 'b' and 
  $f[2] eq 'c' and 
  $f[3] eq 'd' and 
  $f[4] eq 'e'
};

ok( $o->struct(0,1,2,3,4) ); #9

my %h;
ok( %h = $o->struct_dump ); #10
ok do {
  $h{'a'} == 0 and 
  $h{'b'} == 1 and 
  $h{'c'} == 2 and 
  $h{'d'} == 3 and 
  $h{'e'} == 4
};

ok( $o->a('foo') ); #11
ok( $o->a eq 'foo' ); #12

ok( ! defined $o->clear_a ); #13
ok( ! defined $o->a ); #14

exit 0;

