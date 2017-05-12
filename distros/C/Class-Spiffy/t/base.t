use lib 't', 'lib';
use strict;
use warnings;

package XXX;
BEGIN {require Thing}
use base 'Thing';

package Foo;
use base 'Class::Spiffy';
BEGIN { @Foo::EXPORT=qw(xxx) }
sub xxx {}

package Bar;
use base 'Foo', 'Thing';

package Boo;
BEGIN { @Boo::EXPORT=qw(xxx) }
sub xxx {}

package Goo;
use base 'Boo';

package Something;
use base 'Class::Spiffy';
BEGIN { @Something::EXPORT = qw(qwerty) }
sub qwerty {}

package SomethingGood;
use base 'Something';

package main;
use Test::More tests => 24;

ok(Thing->isa('Class::Spiffy'));
ok(defined &XXX::thing);
ok(defined &XXX::field);
ok(defined &XXX::const);

ok(defined &Foo::field);
ok(defined &Foo::const);
ok(defined &Foo::xxx);

ok(Bar->isa('Class::Spiffy'));
ok(Bar->isa('Foo'));
ok(Bar->isa('Thing'));
ok(defined &Bar::field);
ok(defined &Bar::const);
ok(defined &Bar::xxx);
ok(defined &Bar::thing);

ok(not Boo->isa('Class::Spiffy'));
ok(defined &Boo::xxx);

ok(not Goo->isa('Class::Spiffy'));
ok(Goo->isa('Boo'));
ok(not defined &Goo::xxx);

ok(SomethingGood->isa('Something'));
ok(SomethingGood->isa('Class::Spiffy'));
ok(not SomethingGood->isa('Thing'));
ok(not defined &SomethingGood::thing);

ok(not @Class::Spiffy::ISA);
