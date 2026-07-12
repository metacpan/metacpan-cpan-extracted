use strict;
use warnings;
use Test::More;

# Verify that schemas and result classes can be defined with 'use DBIO' syntax.
# ISA checks run without a DB. Live tests require DBIO_TEST_MYSQL_DSN.

# The storage component must match the DBD named in the DSN: DBD::MariaDB
# (dbi:MariaDB:) needs the MariaDB storage (mariadb_* DBD attributes), while
# DBD::mysql (dbi:mysql:) needs the plain MySQL storage (mysql_* attributes).
# Loading the wrong one pins a storage that FETCHes attributes the connected
# DBD does not implement (e.g. mysql_insertid on a DBD::MariaDB handle).
my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_MYSQL_$_" } qw(DSN USER PASS)};
my $mysql_component = ($dsn && $dsn =~ /^dbi:MariaDB:/i)
    ? 'MySQL::MariaDB'
    : 'MySQL';

{
    package MyTest::MySQLSchema;
    use DBIO 'Schema';
    __PACKAGE__->load_components($mysql_component);
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
}

# Hygiene: leave no live-DB residue so t/53's round-trip and other live tests
# start from a clean slate. Done in END with a dedicated dbh (matching the
# PostgreSQL t/05 pattern) so cleanup still runs if the test dies mid-way --
# the native Deploy path does not honour add_drop_table, so a leftover table
# would otherwise make the next run's deploy fail with "table already exists".
# Drop cd before artist to satisfy the foreign key.
END {
    return unless $dsn;
    require DBI;
    my $h = eval { DBI->connect($dsn, $user, $pass, { RaiseError => 0, PrintError => 0 }) };
    return unless $h;
    eval {
        $h->do('DROP TABLE IF EXISTS cd');
        $h->do('DROP TABLE IF EXISTS artist');
    };
    $h->disconnect;
}

done_testing;
