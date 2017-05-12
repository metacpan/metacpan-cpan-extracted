use strict;
use warnings;
use Test::More tests => 3;

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

my $data =
{
    a => [ { a => 'b' }, { c => 'd' } ]
};

my $obj = new_ok('Foo::OtherObject', [ $data ]);

isa_ok($obj->a->[0], 'Foo::Object');

