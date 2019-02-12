use strict;
use warnings;

package MyClass;
use Class::Tiny::Immutable 'foo', {bar => 42, baz => undef}, 'wibble';

sub BUILD { shift->{wibble}++ }

package MyClass::Child;
our @ISA = 'MyClass';
use Class::Tiny 'child_attr';

package main;

use Test::More;

my $obj;
ok !eval { $obj = MyClass->new; 1 }, 'constructor dies without required attribute';
ok !eval { $obj = MyClass->new(foo => 'abc'); 1}, 'required attribute cannot be set by BUILD';
ok(eval { $obj = MyClass->new(foo => 'abc', wibble => 2); 1}, 'constructor succeeds with required attributes') or diag $@;
is $obj->foo, 'abc', 'foo has right value';
ok !eval { $obj->foo('xyz'); 1 }, 'setter for readonly attribute dies';
is $obj->bar, 42, 'bar has right value';
ok !eval { $obj->bar(21); 1 }, 'setter for lazy attribute dies';
is $obj->baz, undef, 'baz has right value';
ok !eval { $obj->baz(0); 1 }, 'setter for lazy attribute dies';
is $obj->wibble, 3, 'wibble has right value';
ok !eval { $obj->wibble(undef); 1 }, 'setter for readonly attribute dies';

my @required = Class::Tiny::Immutable->get_all_required_attributes_for('MyClass');
is_deeply [sort @required], [qw(foo wibble)], 'list required attributes';
@required = Class::Tiny::Immutable->get_all_required_attributes_for('MyClass::Child');
is_deeply [sort @required], [qw(foo wibble)], 'same required attributes';

done_testing;
