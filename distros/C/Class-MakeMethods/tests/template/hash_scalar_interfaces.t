#!/usr/bin/perl

use Test;
BEGIN { plan tests => 12 }

package X;

use Class::MakeMethods::Template::Hash (
  new => 'new',
  'scalar' => [
    -interface =>{ 'get_*' => 'get', 'set_*' => 'set_return' }, qw/ d e /,
    -interface => 'eiffel'        => 'g',
    -interface => 'java'          => 'h',
    -interface => 'with_clear'    => 'i',
    -interface => 'noclear'       => 'f',
  ]
);

package main;

my $o = new X;

ok( 1 ); #1

ok( ! $o->can ('d') ); #2			# 12
ok( ! $o->can ('clear_e') ); #3			# 13
ok( ! defined $o->get_d ); #4			# 14
ok( ! defined $o->set_d ('foo') ); #5		# 15
ok( $o->get_d eq 'foo' ); #6			# 16
ok( ! defined $o->set_d (undef) ); #7		# 17
ok( ! defined $o->get_d ); #8			# 18

ok sub { $o->can ('f') and ! $o->can ('clear_f') and
	 ! $o->can ('set_f') and ! $o->can ('get_f') };

ok sub { $o->can ('g') and ! $o->can ('clear_g') and
	 $o->can ('set_g') and ! $o->can ('get_g') };
ok sub { ! $o->can ('h') and ! $o->can ('clear_h') and
	 $o->can ('seth') and $o->can ('geth') };
ok sub { $o->can ('i') and $o->can ('clear_i') and
	 ! $o->can ('set_i') and ! $o->can ('get_i') };

exit 0;

