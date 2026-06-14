use Test2::V0;
use DBI;
use File::Temp qw/tempdir/;

# SQLite identity detection: a plain INTEGER PRIMARY KEY column aliases the
# rowid and auto-assigns on insert, so it must be marked identity just like
# AUTOINCREMENT columns (and like Pg/MySQL identity columns). AUTOINCREMENT
# detection must parse the table's own CREATE TABLE DDL, not match the bare
# word anywhere in sqlite_master (triggers, comments).

BEGIN {
    skip_all "DBD::SQLite is required for these tests"
        unless eval { require DBD::SQLite; 1 };
}

require DBIx::QuickORM;

my $dir = tempdir(CLEANUP => 1);
my $dsn = "dbi:SQLite:dbname=$dir/identity.sqlite";

{
    my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});

    $dbh->do('CREATE TABLE plain_pk   (id INTEGER PRIMARY KEY, name TEXT)');
    $dbh->do('CREATE TABLE auto_pk    (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT)');
    $dbh->do('CREATE TABLE text_pk    (id TEXT PRIMARY KEY, name TEXT)');
    $dbh->do('CREATE TABLE int_pk     (id INT PRIMARY KEY, name TEXT)');
    $dbh->do('CREATE TABLE no_rowid   (id INTEGER PRIMARY KEY, name TEXT) WITHOUT ROWID');
    $dbh->do('CREATE TABLE multi_pk   (a INTEGER, b INTEGER, PRIMARY KEY (a, b))');
    $dbh->do('CREATE TABLE with_trig  (id TEXT PRIMARY KEY, note TEXT)');

    # A trigger row in sqlite_master for with_trig that contains the word
    # AUTOINCREMENT; it must not flag the table.
    $dbh->do(<<'    EOT');
        CREATE TRIGGER with_trig_autoincrement AFTER INSERT ON with_trig
        BEGIN
            UPDATE with_trig SET note = 'AUTOINCREMENT mentioned here' WHERE id = NEW.id;
        END
    EOT

    $dbh->disconnect;
}

my $con     = DBIx::QuickORM->quick(credentials => {dsn => $dsn});
my $schema  = $con->schema;
my $dialect = $con->dialect;

subtest rowid_alias_identity => sub {
    ok($schema->table('plain_pk')->column('id')->identity, "plain INTEGER PRIMARY KEY (rowid alias) is identity");
    ok($schema->table('auto_pk')->column('id')->identity, "INTEGER PRIMARY KEY AUTOINCREMENT is identity");

    ok(!$schema->table('text_pk')->column('id')->identity, "TEXT PRIMARY KEY is not identity");
    ok(!$schema->table('int_pk')->column('id')->identity, "INT (not INTEGER) PRIMARY KEY does not alias rowid, not identity");
    ok(!$schema->table('no_rowid')->column('id')->identity, "INTEGER PRIMARY KEY in a WITHOUT ROWID table is not identity");
    ok(!$schema->table('multi_pk')->column('a')->identity, "multi-column primary key columns are not identity");
    ok(!$schema->table('multi_pk')->column('b')->identity, "multi-column primary key columns are not identity");
};

subtest autoinc_detection => sub {
    ok($dialect->table_has_autoinc('auto_pk'), "AUTOINCREMENT in the column definition is detected");
    ok(!$dialect->table_has_autoinc('plain_pk'), "no AUTOINCREMENT clause, none detected");
    ok(!$dialect->table_has_autoinc('with_trig'), "AUTOINCREMENT inside a trigger does not flag the table");
    ok(!$schema->table('with_trig')->column('id')->identity, "trigger mention of AUTOINCREMENT does not mark the TEXT pk as identity");
};

subtest identity_auto_assigns => sub {
    my $row = $con->insert(plain_pk => {name => 'auto'});
    ok($row->field('id'), "insert without id auto-assigned one (rowid alias)");
};

done_testing;
