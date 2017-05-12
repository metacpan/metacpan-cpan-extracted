use strict;
use warnings;
use Test::More tests => 13;

use_ok('Clustericious::Client::Object');

my $obj = new_ok('Clustericious::Client::Object', [ {some => 'stuff'} ]);

is($obj->some, 'stuff', 'Access variable');

is($obj->some('foo'), 'foo', 'Set variable');

is($obj->some, 'foo', 'Retains value');

is($obj->missing, undef, 'Ok to access missing variable');

#----------------------------------------------------------------------

my $array = Clustericious::Client::Object->new([ { some => 'stuff' } ]);

isa_ok($array->[0], 'Clustericious::Client::Object');

is($array->[0]->some, 'stuff', 'Access variable from array');

#----------------------------------------------------------------------

$obj = new_ok('Clustericious::Client::Object',
              [ { some => 'stuff'}, 'client' ]);

is($obj->_client, 'client', 'Access cached client');

#----------------------------------------------------------------------

my $data = [ qw(a b c) ];

$obj = new_ok('Clustericious::Client::Object', [ { some => $data } ]);

is_deeply(scalar $obj->some, $data, 'Retrieve an array');

is_deeply([$obj->some], $data, 'Retrieve flattened array in list context');





