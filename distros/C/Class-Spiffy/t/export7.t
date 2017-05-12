use Test::More;

plan tests => 4;

package B;
use Class::Spiffy -base, -XXX;

package A;
use Class::Spiffy -base;

package main;

ok(not defined &A::XXX);
ok(defined &A::field);

ok(defined &B::XXX);
ok(defined &B::field);
