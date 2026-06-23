use strict;
use warnings;
use Test::More;

# Verify that schemas and result classes can be defined with 'use DBIO' syntax.
# ISA checks run without a DB. Live tests require DBIO_TEST_MYSQL_DSN.

{
    package MyTest::MySQLSchema;
    use DBIO 'Schema';
    __PACKAGE__->load_components('MySQL');
}

{
    package MyTest::MySQLSchema::Result::Artist;
    use DBIO;

    __PACKAGE__->table('artist');
    __PACKAGE__->add_columns(
        id   => { data_type => 'integer', is_auto_increment => 1 },
        name => { data_type => 'varchar', size => 100 },
    );
    __PACKAGE__->set_primary_key('id');
    __PACKAGE__->has_many(cds => 'MyTest::MySQLSchema::Result::CD', 'artist_id');
}

{
    package MyTest::MySQLSchema::Result::CD;
    use DBIO;

    __PACKAGE__->table('cd');
    __PACKAGE__->add_columns(
        id        => { data_type => 'integer', is_auto_increment => 1 },
        artist_id => { data_type => 'integer' },
        title     => { data_type => 'varchar', size => 200 },
    );
    __PACKAGE__->set_primary_key('id');
    __PACKAGE__->belongs_to(artist => 'MyTest::MySQLSchema::Result::Artist', 'artist_id');
}

MyTest::MySQLSchema->register_class(Artist => 'MyTest::MySQLSchema::Result::Artist');
MyTest::MySQLSchema->register_class(CD     => 'MyTest::MySQLSchema::Result::CD');

# --- ISA checks (no database required) ---

ok 'MyTest::MySQLSchema::Result::Artist'->isa('DBIO::Core'),
    'use DBIO sets up DBIO::Core inheritance';

ok 'MyTest::MySQLSchema::Result::CD'->isa('DBIO::Core'),
    'second result class also inherits DBIO::Core';

# --- Live tests (require DBIO_TEST_MYSQL_DSN) ---

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_MYSQL_$_" } qw(DSN USER PASS)};

SKIP: {
    skip 'Set DBIO_TEST_MYSQL_DSN, _USER and _PASS to run live tests'
        . ' (NOTE: creates and drops tables artist, cd)', 5
        unless $dsn;

    my $schema = MyTest::MySQLSchema->connect($dsn, $user, $pass);
    isa_ok $schema->storage, 'DBIO::MySQL::Storage',
        'MySQL storage loaded via load_components';

    $schema->deploy({ add_drop_table => 1 });

    my $artist = $schema->resultset('Artist')->create({ name => 'Test Artist' });
    ok $artist->id, 'auto-increment id assigned';
    is $artist->name, 'Test Artist', 'name column correct';

    my $cd = $schema->resultset('CD')->create({
        artist_id => $artist->id,
        title     => 'First Album',
    });
    is $cd->artist->name, 'Test Artist', 'belongs_to traversal works';
    is $artist->cds->count, 1, 'has_many count correct';

    # Hygiene: leave no live-DB residue so t/53 round-trip and other live
    # tests start from a clean slate. add_drop_table already drops CD
    # before dropping artist, but only if the test reaches the end of
    # the schema deploy -- be explicit in case we never get there.
    eval {
        $schema->storage->dbh->do('DROP TABLE IF EXISTS cd');
        $schema->storage->dbh->do('DROP TABLE IF EXISTS artist');
    };
}

done_testing;
