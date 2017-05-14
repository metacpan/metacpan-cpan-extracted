#!/usr/bin/perl

package Y;
my $count = 0;
sub new { bless { id => $count++ }, shift; }
sub id { shift->{id}; }

package X;

use Test;
BEGIN { plan tests => 8 }

use Class::MakeMethods::Template::Hash (
  array_of_objects  => [ '-class' => 'Y', { name => 'a', delegate => 'id' } ],
);

sub new { bless {}, shift; }
my $o = new X;

ok( 1 ); #1

ok( $o->push_a (Y->new) ); #2
ok( $o->push_a (Y->new) ); #3
ok( $o->pop_a->id == 1  ); #4
ok( $o->push_a (Y->new) ); #5
ok do { @b = $o->a; @b == 2 }; #6
ok( join (' ', $o->id) eq '0 2' ); #7
ok do { $a = 1; for ($o->a) { $a &&= ( ref ($_) eq 'Y' ) }; $a }; #8

exit 0;

