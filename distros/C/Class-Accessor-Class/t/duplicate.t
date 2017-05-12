use Test::More tests => 9;

use strict;
use warnings;

BEGIN { use_ok('Class::Accessor::Class'); }

package Foo;
	@Foo::ISA = qw(Class::Accessor::Class);
package main;

package Bar;
	@Bar::ISA = qw(Class::Accessor::Class);
package main;

my $foo_1 = Foo->make_class_accessor('foo');
my $foo_2 = Foo->make_class_accessor('foo');
my $bar_1 = Bar->make_class_accessor('foo');

isa_ok($foo_1, 'CODE');
isa_ok($foo_2, 'CODE');
isa_ok($bar_1, 'CODE');

$foo_1->('self', 1);

is($foo_1->('self'), 1, "first accessor works");
is($foo_2->('self'), 1, "second accessor gets first's data");
is($bar_1->(),   undef, "Bar:: accessor gets undef");

$foo_2->('self', 2);

is($foo_2->('self'), 2, "second accessor works");
is($foo_1->('self'), 2, "first accessor gets second's data");
