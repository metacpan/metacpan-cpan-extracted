#!/usr/bin/perl
use strict; use warnings FATAL => 'all'; 
use Test::More;

use DTL::Fast::Context;
use Data::Dumper;

my $context = new DTL::Fast::Context();

isa_ok($context, 'DTL::Fast::Context');
$context->set('key1' => 'val1');
is( $context->get('key1'), 'val1', 'One item assignment');

$context = new DTL::Fast::Context({
    'key2' => 'val2'
});

is( $context->get('key2'), 'val2', 'Constructor assignment');
$context->push_scope();
is( $context->get('key2'), 'val2', 'Scoping');
$context->set('key2' => 'val3');
is( $context->get('key2'), 'val3', 'Shadowing');
$context->pop_scope();
is( $context->get('key2'), 'val2', 'Unshadowing');

$context->set('key1' => 'val10', 'key3' => 'val3');
is( $context->get('key1'), 'val10', 'Multiply assignment, var 1');
is( $context->get('key3'), 'val3', 'Multiply assignment, var 2');

eval{ $context->pop_scope();};
if( $@ ){
    ok( 1, 'Scope levels control');
} else
{
    ok( 0, 'Scope levels control');
}

eval{ $context->set('var1.var2.var3' => 'traversed value'); };
if( $@ ){
    ok( 1, 'Traversed set control');
} else
{
    ok( 0, 'Traversed set control');
}

$context->set('var1' => {});
isa_ok($context->get('var1'), 'HASH', 'Traversed set step 1, hash');

$context->set('var1.var2' => []);
isa_ok($context->get('var1.var2'), 'ARRAY', 'Traversed set level 2, array');

$context->set('var1.var2.7' => sub{ return 'Test string';} );
is($context->get('var1.var2.7'), 'Test string', 'Traversed set level 3, code');

is($context->get('var1.var2.8'), undef, 'Not existed value');

is($context->get([qw( var1 var2 7)]), 'Test string', 'Traversed getting by arrayref');

package Foo;

sub new
{
    return bless {}, shift;
}

sub supermethod
{
    return "Foo test";
}

package main;

$context->set('var1.var2.6' => new Foo());
isa_ok( $context->get( 'var1.var2.6' ), 'Foo');
is( $context->get( 'var1.var2.6.supermethod' ), 'Foo test', 'Object method getting');

#warn Dumper($context);

done_testing();
