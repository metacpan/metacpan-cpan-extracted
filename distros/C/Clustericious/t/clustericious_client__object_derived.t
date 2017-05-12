use strict;
use warnings;
use Test::More tests => 11;

#----------------------------------------------------------------------
package Foo::Object;

use base 'Clustericious::Client::Object';

sub m { 'return from m' };

#----------------------------------------------------------------------
package Foo::OtherObject;

use base 'Clustericious::Client::Object';

our %classes =
(
    a => 'Foo::Object'
);

sub n { 'return from n' };

#----------------------------------------------------------------------
package main;

use_ok('Clustericious::Client::Object');

my $obj = new_ok('Foo::Object', [ { some => 'stuff' } ]);

is($obj->some, 'stuff', 'access stuff');
is($obj->m, 'return from m', 'call derived class method');

#----------------------------------------------------------------------

$obj = new_ok('Foo::OtherObject', 
              [ { a => { some => 'stuff' },
                  b => { this => 'that' } } ]);

isa_ok($obj, 'Foo::OtherObject');
isa_ok($obj->{a}, 'Foo::Object');
isa_ok($obj->a, 'Foo::Object');

is($obj->n, 'return from n', 'call derived class method');
is($obj->a->m, 'return from m', 'call nested derived class method');
is($obj->b->this, 'that', 'nested object accessor');

