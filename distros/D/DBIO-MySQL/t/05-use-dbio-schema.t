use strict;
use warnings;
use Test::More;

# Verify that schemas and result classes can be defined with 'use DBIO' syntax.
# ISA checks run without a DB. Live tests require DBIO_TEST_MYSQL_DSN.

# load_components('MySQL') is the component for a MySQL server, whichever DBD
# the DSN names. The live half runs it against the DSN it is given, dbi:mysql:
# and dbi:MariaDB: alike.
#
# This file used to claim the opposite (karr k59). It switched to
# 'MySQL::MariaDB' for a dbi:MariaDB: DSN and said the storage component must
# match the DBD, because the pinned DBIO::MySQL::Storage would FETCH mysql_*
# attributes that DBD::MariaDB does not implement. So it steered around the
# combination instead of testing it. The claim was wrong. The component picks a
# storage class and the DSN picks the DBD, and nothing in DBIO::MySQL's contract
# ties the one to the other. DBD::MariaDB is this dist's recommended DBD and
# reaches MySQL servers, and dbio-mysql-ev connects with exactly
# load_components('MySQL', 'MySQL::EV') over dbi:MariaDB:. The FETCH it
# described was a bug in the storage, spelling DBD-private attributes by class.
# Since k57 it killed every such connect. The storage now names them by the DBD
# on the handle, and this file pins the combination live.
my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_MYSQL_$_" } qw(DSN USER PASS)};

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

SKIP: {
    skip 'Set DBIO_TEST_MYSQL_DSN, _USER and _PASS to run live tests'
        . ' (NOTE: creates and drops tables artist, cd)', 9
        unless $dsn;

    # Each DBD's own name for its auto-reconnect attribute, spelled here rather
    # than asked of the storage under test.
    my %ar_attr = (
        mysql   => 'mysql_auto_reconnect',
        MariaDB => 'mariadb_auto_reconnect',
    );

    # DBD::mysql switches auto-reconnect ON by itself when either variable is
    # set at connect. DBD::MariaDB 1.24 does not. Set both for both DSNs, so the
    # DBD::mysql run tests the reset and the DBD::MariaDB run tests the same
    # connect.
    my $schema = MyTest::MySQLSchema->connect($dsn, $user, $pass);
    my $dbh = do {
        local $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
        local $ENV{MOD_PERL}          = 'mod_perl/2.0.13';
        $schema->storage->dbh;
    };
    my $driver = $dbh->{Driver}{Name};

    isa_ok $schema->storage, 'DBIO::MySQL::Storage',
        'MySQL storage loaded via load_components';
    is ref($schema->storage), 'DBIO::MySQL::Storage',
        "... the pinned class itself, over DBD::$driver";
    ok !$dbh->{ $ar_attr{$driver} },
        "... $ar_attr{$driver} off on the fresh handle, under GATEWAY_INTERFACE and MOD_PERL";

    $schema->deploy({ add_drop_table => 1 });

    my $artist = $schema->resultset('Artist')->create({ name => 'Test Artist' });
    ok $artist->id, 'auto-increment id assigned';
    is $artist->id,
        scalar $dbh->selectrow_array(
            'SELECT id FROM artist WHERE name = ?', undef, 'Test Artist'),
        '... and it is the id of the row that was written';
    is $artist->name, 'Test Artist', 'name column correct';

    my $cd = $schema->resultset('CD')->create({
        artist_id => $artist->id,
        title     => 'First Album',
    });
    is $cd->artist->name, 'Test Artist', 'belongs_to traversal works';
    is $artist->cds->count, 1, 'has_many count correct';

    # An explicit value is the caller's choice and survives the reset (ADR
    # 0005), under this DBD's name.
    my $explicit = MyTest::MySQLSchema->connect($dsn, $user, $pass,
        { $ar_attr{$driver} => 1 });
    ok $explicit->storage->dbh->{ $ar_attr{$driver} },
        "an explicit $ar_attr{$driver} => 1 survives the reset";
    $explicit->storage->disconnect;
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
