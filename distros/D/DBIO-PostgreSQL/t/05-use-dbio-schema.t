use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require DBI; 1 }
      or plan skip_all => 'DBI not installed';
}

# Verify 'use DBIO' and 'use DBIO -pg' schema definition for PostgreSQL.
# ISA checks run without a DB. Live tests require DBIO_TEST_PG_DSN.

{
    package MyTest::PgSchema;
    use DBIO 'Schema';
    __PACKAGE__->load_components('PostgreSQL');
}

# Plain result class — no PostgreSQL-specific features
{
    package MyTest::PgSchema::Result::Artist;
    use DBIO;

    __PACKAGE__->table('artist');
    __PACKAGE__->add_columns(
        id   => { data_type => 'integer', is_auto_increment => 1 },
        name => { data_type => 'varchar', size => 100 },
    );
    __PACKAGE__->set_primary_key('id');
    __PACKAGE__->has_many(cds => 'MyTest::PgSchema::Result::CD', 'artist_id');
}

# Result class using -pg shortcut — loads DBIO::PostgreSQL::Result
{
    package MyTest::PgSchema::Result::CD;
    use DBIO -pg;

    __PACKAGE__->pg_schema('public');
    __PACKAGE__->table('cd_dbio_test');
    __PACKAGE__->add_columns(
        id        => { data_type => 'integer', is_auto_increment => 1 },
        artist_id => { data_type => 'integer' },
        title     => { data_type => 'varchar', size => 200 },
    );
    __PACKAGE__->set_primary_key('id');
    __PACKAGE__->belongs_to(artist => 'MyTest::PgSchema::Result::Artist', 'artist_id');
    __PACKAGE__->pg_index('idx_cd_dbio_test_title' => { columns => ['title'] });
}

MyTest::PgSchema->register_class(Artist => 'MyTest::PgSchema::Result::Artist');
MyTest::PgSchema->register_class(CD     => 'MyTest::PgSchema::Result::CD');

# --- ISA checks (no database required) ---

ok 'MyTest::PgSchema::Result::Artist'->isa('DBIO::Core'),
    'use DBIO sets up DBIO::Core inheritance';

ok 'MyTest::PgSchema::Result::CD'->isa('DBIO::Core'),
    'use DBIO -pg also sets up DBIO::Core inheritance';

ok 'MyTest::PgSchema::Result::CD'->isa('DBIO::PostgreSQL::Result'),
    'use DBIO -pg loads DBIO::PostgreSQL::Result component';

is 'MyTest::PgSchema::Result::CD'->pg_schema, 'public',
    'pg_schema set correctly via -pg result class';

ok 'MyTest::PgSchema::Result::CD'->pg_indexes->{'idx_cd_dbio_test_title'},
    'pg_index registered on result class';

# --- Live tests (require DBIO_TEST_PG_DSN) ---

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_PG_$_" } qw(DSN USER PASS)};

SKIP: {
    skip 'Set DBIO_TEST_PG_DSN, _USER and _PASS to run live tests'
        . ' (NOTE: creates and drops tables artist, cd_dbio_test)', 5
        unless $dsn;

    my $schema = MyTest::PgSchema->connect($dsn, $user, $pass);
    isa_ok $schema->storage, 'DBIO::PostgreSQL::Storage',
        'PostgreSQL storage loaded via load_components';

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
}

# Drop test artefacts so they do not leak into later tests' Deploy->diff
# snapshots. A connected dbh in END is required because the schema's
# own dbh may already be disconnected at process exit.
END {
    return unless $dsn;
    my $h = eval { DBI->connect($dsn, $user, $pass, { RaiseError => 0, PrintError => 0 }) };
    return unless $h;
    eval {
        $h->do('DROP TABLE IF EXISTS cd_dbio_test CASCADE');
        $h->do('DROP TABLE IF EXISTS artist CASCADE');
    };
    $h->disconnect;
}

done_testing;
