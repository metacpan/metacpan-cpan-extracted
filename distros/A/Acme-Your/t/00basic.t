#!perl -w
#use strict;
use Test::More tests => 4;

BEGIN { require_ok( 'Acme::Your' ) };

package Bar;

use vars '$foo';
$foo = 'from_bar';
sub foo_value {
    return $foo;
}

package main;
use Acme::Your 'Bar';
is( Bar::foo_value, 'from_bar', 'out of scope');
{
    your $foo;
    $foo = 'test';
    is( Bar::foo_value, 'test', 'in scope');
}

is( Bar::foo_value, 'from_bar', 'back out again');
