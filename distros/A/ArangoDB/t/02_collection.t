use strict;
use Test::More;
use Test::Fatal qw(lives_ok dies_ok exception);
use Test::Mock::Guard;
use ArangoDB;
use JSON;

if ( !$ENV{TEST_ARANGODB_PORT} ) {
    plan skip_all => 'Can"t find port of arangod';
}

my $port   = $ENV{TEST_ARANGODB_PORT};
my $config = {
    host       => 'localhost',
    port       => $port,
    keep_alive => 1,
};

sub init {
    my $db = ArangoDB->new($config);
    map { $_->drop } @{ $db->collections };
}

subtest 'create collection' => sub {
    init();
    my $db = ArangoDB->new($config);
    my $coll;
    lives_ok { $coll = $db->create("foo"); } 'Create new collection';
    isa_ok $coll, 'ArangoDB::Collection';
    is $coll->name, 'foo';
    ok $coll->is_loaded;
    ok !$coll->is_newborn;
    ok !$coll->is_unloaded;
    ok !$coll->is_being_unloaded;
    ok !$coll->is_deleted;
    ok !$coll->is_corrupted;

    like exception {
        my $guard = mock_guard( 'ArangoDB::Connection' => { http_post => sub {die}, } );
        $db->create('bar');
    }, qr/^Failed to create collection/;

    like exception {
        $db->create('foo');
    }, qr/^Failed to create collection/;

    $db->collection('baz');
};

subtest 'get collection' => sub {
    init();
    my $db = ArangoDB->new($config);

    $db->('foo');
    $db->('baz');

    my $coll = $db->find('bar');
    is $coll, undef, 'Returns undef if the collection does not exist.';

    $coll = $db->find('foo');
    isa_ok $coll, 'ArangoDB::Collection';

    like exception {
        my $guard = mock_guard(
            'ArangoDB::Connection' => {
                http_get => sub {
                    die ArangoDB::ServerException->new(
                        {   code   => 500,
                            status => 500,
                            detail => {},
                        }
                    );
                },
            }
        );
        $db->find('qux');
    }, qr/Failed to get collection/;

};

subtest 'get all collections' => sub {
    init();
    my $db = ArangoDB->new($config);

    $db->('foo');
    $db->('baz');
    my $colls = $db->collections;
    is scalar @$colls, 2;
    like exception {
        my $guard = mock_guard( 'ArangoDB::Connection', { http_get => sub {die}, } );
        $db->collections();
    }, qr/^Failed to get collections/;
};

subtest 'drop collection' => sub {
    my $db = ArangoDB->new($config);
    lives_ok {
        $db->('baz')->drop;
    };

    like exception {
        my $guard = mock_guard( 'ArangoDB::Connection', { http_delete => sub {die}, } );
        $db->('baz')->drop;
    }, qr/^Failed to drop the collection/;
};

subtest 'collection name confliction' => sub {
    my $db = ArangoDB->new($config);
    dies_ok { $db->create("foo") } 'Attempt to create collection that already exist name';
    lives_ok { $db->('foo')->drop } 'Drop collection';
    lives_ok { $db->create( 'foo', { waitForSync => 1, } ); } 'Create collection with name that dropped collection';
};

subtest 'rename collection' => sub {
    my $db   = ArangoDB->new($config);
    my $coll = $db->collection('foo');
    is $coll->name, 'foo';
    $coll->name('bar');
    is $coll->name, 'bar';
    my $coll2 = $db->collection('bar');
    is $coll->id,    $coll2->id;
    is $coll2->name, 'bar';
};

subtest 'wait for sync' => sub {
    my $db   = ArangoDB->new($config);
    my $coll = $db->collection('bar');
    is $coll->wait_for_sync, 0;
    $coll->wait_for_sync(1);
    is $coll->wait_for_sync, 1;
    $coll->wait_for_sync(0);
    is $coll->wait_for_sync, 0;
};

subtest 'unload and load collection' => sub {
    my $db   = ArangoDB->new($config);
    my $coll = $db->collection('bar');
    ok $coll->is_loaded;
    $coll->unload;
    ok $coll->is_being_unloaded;
    $coll->load;
    ok $coll->is_loaded;
};

subtest 'count documents in collection' => sub {
    my $db   = ArangoDB->new($config);
    my $coll = $db->collection('bar');
    is $coll->count, 0;
    my $doc = $coll->save( { baz => 1 } );
    isa_ok $doc, 'ArangoDB::Document';
    is $coll->count, 1;
    $doc = $coll->save( { qux => 1 } );
    is $coll->count, 2;

    like exception {
        my $guard = mock_guard(
            'ArangoDB::Connection' => {
                http_get => sub {die}
            }
        );
        $coll->count;
    }, qr/^Failed to get the property/;

};

subtest 'figures' => sub {
    my $db    = ArangoDB->new($config);
    my $coll  = $db->collection('bar');
    my $stats = $coll->figure();
    is ref($stats), 'HASH';
    is $stats->{alive}{count}, $coll->figure('alive-count');
    is $stats->{alive}{size},  $coll->figure('alive-size');
    is ref( $coll->figure('alive') ), 'HASH';
    is $coll->figure('count'), 2;
    ok $coll->figure('journalSize');
    ok !defined $coll->figure('foo');
};

subtest 'drop collection by name' => sub {
    my $db   = ArangoDB->new($config);
    my $coll = $db->create('qux');
    ok $coll;
    $db->('qux')->drop;
    $coll = $db->find('qux');
    ok !defined $coll;
};

subtest 'fail drop collection' => sub {
    my $db   = ArangoDB->new($config);
    my $coll = $db->collection('bar');
    $coll->drop();
    my $e = exception { $coll->drop() };
    like $e, qr/^Failed to drop the collection\(bar\)/;
};

subtest 'truncate collection' => sub {
    my $db   = ArangoDB->new($config);
    my $coll = $db->create('foo');
    my $id   = $coll->id;
    $coll->save( { foo => 1 } );
    is $coll->count, 1;
    lives_ok { $coll->truncate() };
    $coll = $db->collection('foo');
    is $coll->id,    $id;
    is $coll->count, 0;
    $coll->save( { save => 2 } );
    is $coll->count, 1;
    lives_ok { $db->('foo')->truncate };
    is $coll->count, 0;
};

subtest 'fail truncate collection' => sub {
    my $guard = mock_guard( 'ArangoDB::Connection' =>
            { http_put => sub { die ArangoDB::ServerException->new( code => 500, status => 500, detail => {} ) }, } );
    my $db   = ArangoDB->new($config);
    my $coll = $db->collection('foo');
    like exception { $coll->truncate() }, qr/^Failed to truncate the collection\(foo\)/;
};

done_testing;
