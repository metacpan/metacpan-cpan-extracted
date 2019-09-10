#!/usr/bin/env perl
use strictures 2;
use Test2::V0;

package CC;
    use Curio;
    add_key 'baz';
    add_key 'bar';
    alias_key 'foo' => 'bar';
    key_argument 'actual_key';
    has actual_key => ( is=>'ro' );
package main;

is(
    CC->fetch('foo')->actual_key(),
    'bar',
    'key alias was used',
);

is(
    CC->fetch('bar')->actual_key(),
    'bar',
    'key alias was not used',
);

is(
    CC->fetch('baz')->actual_key(),
    'baz',
    'key alias was not used',
);

done_testing;
