#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Bread::Board;

{
    package Foo;
    use Moose;
    has 'bar' => (is => 'ro', isa => 'Int', required => 1);
    has 'baz' => (is => 'ro', isa => 'Str', required => 1);
}

my $c = container 'MyApp' => as {

    service 'foo' => (
        lifecycle  => 'Session::WithParameters',
        class      => 'Foo',
        parameters => {
            bar => { isa => 'Int' },
            baz => { isa => 'Str' },
        }
    );

};

my $foo;
is(exception {
    $foo = $c->resolve( service => 'foo', parameters => { bar => 10, baz => 'BAZ' } );
}, undef, '... got the service correctly');
isa_ok($foo, 'Foo');
is($foo->bar, 10, '... got the right parameter value');
is($foo->baz, 'BAZ', '... got the right parameter value');

# this is the same instance ...
my $foo2;
is(exception {
    $foo2 = $c->resolve( service => 'foo', parameters => { bar => 10, baz => 'BAZ' } );
}, undef, '... got the service correctly');
isa_ok($foo2, 'Foo');
is($foo2->bar, 10, '... got the right parameter value');
is($foo2->baz, 'BAZ', '... got the right parameter value');

# this will be different instance ...
my $foo3;
is(exception {
    $foo3 = $c->resolve( service => 'foo', parameters => { bar => 20, baz => 'BAZ' } );
}, undef, '... got the service correctly');
isa_ok($foo3, 'Foo');
is($foo3->bar, 20, '... got the right parameter value');
is($foo3->baz, 'BAZ', '... got the right parameter value');

# confirm our assumptions ...

is($foo, $foo2, '... they are the same instances (same params)');
isnt($foo, $foo3, '... they are not the same instances (diff params)');

# flush them all away ...
$c->flush_session_instances;

my $foo4;
is(exception {
    $foo4 = $c->resolve( service => 'foo', parameters => { bar => 10, baz => 'BAZ' } );
}, undef, '... got the service correctly');
isa_ok($foo4, 'Foo');
is($foo4->bar, 10, '... got the right parameter value');
is($foo4->baz, 'BAZ', '... got the right parameter value');

isnt($foo, $foo4, '... they are not the same instances (same params, post-flush)');
isnt($foo2, $foo4, '... they are not the same instances (same params, post-flush)');
isnt($foo3, $foo4, '... they are not the same instances (diff params, post-flush)');

done_testing;
