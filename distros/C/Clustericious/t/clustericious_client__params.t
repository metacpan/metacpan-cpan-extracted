use strict;
use warnings;
use Test::More 'no_plan';

use_ok('Clustericious::Client::Object::Params');

my $data = 
[
    { name => 'foo', value => 'foovalue' },
    { name => 'bar', value => 'barvalue' }
];

my $obj = new_ok('Clustericious::Client::Object::Params', [ $data ]);

is($obj->foo, 'foovalue', 'accessor method');

is_deeply($obj, { foo => 'foovalue', bar => 'barvalue' }, 'check hash');

