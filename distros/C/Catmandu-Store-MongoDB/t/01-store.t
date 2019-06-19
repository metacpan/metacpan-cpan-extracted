use strict;
use warnings;

use lib "t/lib";

use Test::More;
use Test::Exception;

use Catmandu::Store::MongoDB;

use MongoDBTest '$conn';

ok $conn;

my $db = $conn->get_database('test_database');

my $store = Catmandu::Store::MongoDB->new( database_name => 'test_database' );

ok $store;

my $obj1 = $store->bag->add( { _id => '123', name => 'Patrick' } );

ok $obj1;

is $obj1->{_id}, 123;

my $obj2 = $store->bag->get('123');

ok $obj2;

is_deeply $obj2 , { _id => '123', name => 'Patrick' };

$store->bag->add( { _id => '456', name => 'Nicolas' } );

is $store->bag->count, 2;

is $store->bag->search( query => '{"name":"Nicolas"}' )->total, 1;

# MongoDB sort specification as JSON
is $store->bag->search( sort => '{"name":-1}' )->first->{name}, 'Patrick';

# MongoDB sort specification as hash ref
is $store->bag->search( sort => { name => 1 } )->first->{name}, 'Nicolas';

$store->bag->delete('123');

is $store->bag->count, 1;

$store->bag->delete_all;

is $store->bag->count, 0;

my $obj3 = $store->bag->add( { _id => '789', char => 'ABC', num => '123' } );

is_deeply $store->bag->searcher(
    query  => { char => "ABC" },
    fields => { num  => 1, _id => 0 }
)->first, { num => '123' };

is_deeply $store->bag->search( query => { char => "ABC" },
    fields => { _id => 1 } )->first, { _id => '789' };

END {
    if ($db) {
        $db->drop;
    }
}

done_testing;
