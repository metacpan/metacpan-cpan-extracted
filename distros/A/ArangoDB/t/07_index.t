use strict;
use Test::More;
use Test::Fatal qw(lives_ok dies_ok exception);
use Test::Mock::Guard;
use ArangoDB;

if ( !$ENV{TEST_ARANGODB_PORT} ) {
    plan skip_all => 'Can"t find port of arangod';
}

my $port   = $ENV{TEST_ARANGODB_PORT};
my $config = {
    host       => 'localhost',
    port       => $port,
    keep_alive => 1,
};

init();

sub init {
    my $db = ArangoDB->new($config);
    map { $_->drop } @{ $db->collections };
}

subtest 'hash index' => sub {
    my $db   = ArangoDB->new($config);
    my $coll = $db->create('index_test1');
    $coll->save( { foo => 1, bar => { a => 1, b => 1 } } );
    $coll->save( { foo => 2, bar => { a => 5, b => 1 } } );
    $coll->save( { foo => 3, bar => { a => 1, b => 10 } } );

    my $index1 = $coll->ensure_hash_index( [qw/bar.a/] );
    isa_ok $index1, 'ArangoDB::Index::Hash';
    is $index1->type, 'hash';
    is_deeply $index1->fields, [qw/bar.a/];
    is $index1->collection_id, $coll->id;

    like exception {
        $coll->ensure_hash_index( [] );
    }, qr/^Failed to create hash index on the collection/;
};

subtest 'unique hash index' => sub {
    my $db   = ArangoDB->new($config);
    my $coll = $db->create('index_test2');
    $coll->save( { foo => 1, bar => { a => 1, b => 1 } } );
    $coll->save( { foo => 2, bar => { a => 5, b => 1 } } );
    $coll->save( { foo => 3, bar => { a => 1, b => 10 } } );

    my $index1 = $coll->ensure_unique_constraint( [qw/foo/] );
    isa_ok $index1, 'ArangoDB::Index::Hash';
    is $index1->type, 'hash';
    is_deeply $index1->fields, [qw/foo/];

    like exception { $coll->save( { foo => 1 } ) }, qr/unique constraint violated/;

    like exception {
        $coll->ensure_unique_constraint( [qw/bar.a/] );
    }, qr/^Failed to create unique hash index on the collection/;
};

subtest 'skiplist index' => sub {
    my $db   = ArangoDB->new($config);
    my $coll = $db->create('index_test3');
    $coll->save( { foo => 1, } );
    $coll->save( { foo => 2, } );
    $coll->save( { foo => 3, } );
    $coll->save( { foo => 10, } );

    my $index1 = $coll->ensure_skiplist( [qw/foo/] );
    isa_ok $index1, 'ArangoDB::Index::SkipList';
    is $index1->type, 'skiplist';
    is_deeply $index1->fields, [qw/foo/];
    ok !$index1->unique;

    like exception {
        $coll->ensure_skiplist( [] );
    }, qr/^Failed to create skiplist index on the collection/;
};

subtest 'unique skiplist index' => sub {
    my $db   = ArangoDB->new($config);
    my $coll = $db->create('index_test4');
    $coll->save( { foo => 1, } );
    $coll->save( { foo => 2, } );
    $coll->save( { foo => 3, } );
    $coll->save( { foo => 10, } );

    my $index1 = $coll->ensure_unique_skiplist( [qw/foo/] );
    isa_ok $index1, 'ArangoDB::Index::SkipList';
    is $index1->type, 'skiplist';
    is_deeply $index1->fields, [qw/foo/];
    ok $index1->unique;

    like exception { $coll->save( { foo => 1 } ) }, qr/unique constraint violated/;

    like exception {
        $coll->ensure_unique_skiplist( [] );
    }, qr/^Failed to create unique skiplist index on the collection/;
};

subtest 'geo index' => sub {
    my $db   = ArangoDB->new($config);
    my $coll = $db->collection('index_test5');
    my $id   = 0;
    $coll->save( { id => $id++, loc => [ 0,  0 ] } );
    $coll->save( { id => $id++, loc => [ 20, 20 ] } );
    $coll->save( { id => $id++, loc => [ 1,  -5 ] } );
    $coll->save( { id => $id++, loc => [ 10, 10 ] } );
    $coll->save( { id => $id++, loc => [ 20, 10 ] } );

    my $index = $coll->ensure_geo_index( [qw/loc/] );
    isa_ok $index, 'ArangoDB::Index::Geo';
    is $index->type, 'geo1';
    is_deeply $index->fields, [qw/loc/];

    like exception {
        $coll->ensure_geo_index( [], 1 );
    }, qr/^Failed to create geo index on the collection/;

    $coll->save( { lat => 0, lon => 0 } );
    $coll->save( { lat => 0, lon => 1 } );
    $index = $coll->ensure_geo_index( [qw/lat lon/] );
    isa_ok $index, 'ArangoDB::Index::Geo';
    is $index->type, 'geo2';
    is_deeply $index->fields, [qw/lat lon/];

};

subtest 'geo constraint' => sub {
    my $db   = ArangoDB->new($config);
    my $coll = $db->collection('index_test6');
    my $id   = 0;
    $coll->save( { id => $id++, loc => [ 0,  0 ] } );
    $coll->save( { id => $id++, loc => [ 20, 20 ] } );
    $coll->save( { id => $id++, loc => [ 1,  -5 ] } );
    $coll->save( { id => $id++, loc => [ 10, 10 ] } );
    $coll->save( { id => $id++, loc => [ 20, 10 ] } );

    my $index = $coll->ensure_geo_constraint( [qw/loc/] );
    isa_ok $index, 'ArangoDB::Index::Geo';
    is $index->type, 'geo1';
    is_deeply $index->fields, [qw/loc/];

    my $index2 = $db->index($index);
    isa_ok $index2, 'ArangoDB::Index::Geo';

    like exception {
        $coll->ensure_geo_constraint( [], 1 );
    }, qr/^Failed to create geo constraint on the collection/;
};

subtest 'CAP constraint' => sub {
    my $db   = ArangoDB->new($config);
    my $coll = $db->collection('index_test7');
    my $cap  = $coll->ensure_cap_constraint(10);
    isa_ok $cap, 'ArangoDB::Index::CapConstraint';
    is $cap->size, 10;
    for my $id ( 0 .. 10 ) {
        $coll->save( { id => $id, foo => $id * 2 } );
    }
    is $coll->count, 10;

    my $cap2 = $db->index($cap);
    isa_ok $cap2, 'ArangoDB::Index::CapConstraint';

    like exception { $coll->ensure_cap_constraint('x') }, qr/^Failed to create cap constraint on the collection/;

};

subtest 'get indexes' => sub {
    my $db   = ArangoDB->new($config);
    my $coll = $db->collection('index_test8');

    $coll->ensure_hash_index( [qw/foo/] );
    $coll->ensure_skiplist(   [qw/bar/] );

    my $indexes = $coll->get_indexes();

    is scalar @$indexes, 3;    # primary + 2
    ok !grep { !$_->isa('ArangoDB::Index') } @$indexes;

    like exception {
        my $guard = mock_guard(
            'ArangoDB::Connection' => {
                http_get => sub {die}
            }
        );
        $coll->get_indexes();
    }, qr/^Failed to get the index/;

};

subtest 'get index' => sub {
    my $db   = ArangoDB->new($config);
    my $coll = $db->collection('index_test9');

    my $index = $db->index( $coll . '/0' );
    isa_ok $index, 'ArangoDB::Index::Primary';
    is $index->fields->[0], '_id';

    like exception { $db->index() }, qr/^Failed to get the index/;
};

subtest 'unknown index' => sub {
    my $db   = ArangoDB->new($config);
    my $coll = $db->collection('index_test10');

    like exception {
        my $guard = mock_guard(
            'ArangoDB::Connection' => {
                http_get => sub {
                    return { type => 'foo', };
                    }
            }
        );
        $db->index();
    }, qr/Unknown index type\(foo\)/;

    like exception {
        my $guard = mock_guard(
            'ArangoDB::Connection' => {
                http_get => sub {
                    return {};
                    }
            }
        );
        $db->index();
    }, qr/Unknown index type\(\)/;
};

subtest 'Drop index' => sub {
    my $db   = ArangoDB->new($config);
    my $coll = $db->collection('index_test11');

    my $index = $coll->ensure_hash_index( [qw/foo/] );
    $index->drop();

    ok exception { $db->index($index) };

    like exception { $index->drop() }, qr/^Failed to drop the index/;

    like exception {
        my $guard = mock_guard(
            'ArangoDB::Connection' => {
                http_delete => sub {die}
            }
        );
        $index->drop();
    }, qr/^Failed to drop the index/;

};

done_testing;
