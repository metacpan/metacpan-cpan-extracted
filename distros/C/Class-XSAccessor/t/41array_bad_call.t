use strict;
use warnings;

use Test::More tests => 13;

BEGIN { use_ok('Class::XSAccessor') };

package Array;

use Class::XSAccessor::Array {
    accessors => {
        foo => 0,
        bar => 1
    },
    constructor => 'new'
};

package main;

my $array = Array->new();

isa_ok $array, 'Array';
can_ok $array, 'foo', 'bar';

$array->foo('FOO');
$array->bar('BAR');

is $array->foo, 'FOO';
is $array->bar, 'BAR';

eval { Array->foo };

like $@, qr{Class::XSAccessor: invalid instance method invocant: no array ref supplied };

eval { Array->bar };

like $@, qr{Class::XSAccessor: invalid instance method invocant: no array ref supplied };

eval { Array::foo() };

# package name introduced in 5.10.1
like $@, qr{Usage: (Array::)?foo\(self, \.\.\.\) };

eval { Array::bar() };

like $@, qr{Usage: (Array::)?bar\(self, \.\.\.\) };

eval { Array::foo( {} ) };

like $@, qr{Class::XSAccessor: invalid instance method invocant: no array ref supplied };

eval { Array::bar( '' ) };

like $@, qr{Class::XSAccessor: invalid instance method invocant: no array ref supplied };

is Array::foo($array), 'FOO';
is Array::bar($array), 'BAR';
