# Test origin: AI
use Test2::V0;
use lib 't/lib';

use DBIx::QuickORM;
use DBIx::QuickORM::Test;
use DBIx::QuickORM::Source::Table;

my $TEXT = "caf\x{e9} \x{263a} \x{1F600}";

my %BLOB = (PostgreSQL => 'BYTEA', MySQL => 'VARBINARY(20)', MariaDB => 'VARBINARY(20)', SQLite => 'BLOB', DuckDB => 'BLOB');

my %OFFSET_SQL = (
    PostgreSQL => 'SELECT EXTRACT(TIMEZONE FROM CURRENT_TIMESTAMP)',
    DuckDB     => 'SELECT EXTRACT(TIMEZONE FROM CURRENT_TIMESTAMP)',
    MySQL      => 'SELECT TIME_TO_SEC(TIMEDIFF(NOW(), UTC_TIMESTAMP()))',
    MariaDB    => 'SELECT TIME_TO_SEC(TIMEDIFF(NOW(), UTC_TIMESTAMP()))',
);

do_for_all_dbs {
    my ($db, $set) = @_;
    my $family = $set->{family};

    subtest utf8_handle => sub {
        skip_all "DBD::DuckDB exchanges bytes; the ORM converts text itself (see utf8_orm)" if $family eq 'DuckDB';

        my $dbh     = DBIx::QuickORM->new(connect => sub { $db->connect })->connection->dbh;
        my $charset = $family =~ m/^(?:MySQL|MariaDB)$/ ? ' CHARACTER SET utf8mb4' : '';
        $dbh->do("CREATE TABLE qorm_utf8 (v VARCHAR(50)$charset)");

        is(scalar($dbh->selectrow_array("SELECT '$TEXT'")), $TEXT, "A string in the SQL text comes back as characters");

        my @values = ($TEXT, "caf\x{e9}");
        $dbh->do('INSERT INTO qorm_utf8 (v) VALUES (?)', undef, $_) for @values;
        is([sort @{$dbh->selectcol_arrayref('SELECT v FROM qorm_utf8')}], [sort @values], "Bound strings, including a Latin-1 one, are stored and read back as characters");
    };

    subtest utf8_orm => sub {
        my $dbh     = $db->connect;
        my $charset = $family =~ m/^(?:MySQL|MariaDB)$/ ? ' CHARACTER SET utf8mb4' : '';
        my $q       = $family =~ m/^(?:MySQL|MariaDB)$/ ? '`'                      : '"';
        $dbh->do("CREATE TABLE ${q}caf\x{e9}_\x{263a}${q} (id INTEGER PRIMARY KEY, ${q}v\x{e9}${q} VARCHAR(50)$charset, b $BLOB{$family})");

        my $orm   = DBIx::QuickORM->new(dbh => $dbh, row_class => undef);
        my $table = "caf\x{e9}_\x{263a}";
        my $field = "v\x{e9}";
        my $latin = "caf\x{e9}";
        utf8::downgrade($latin);
        my $bytes = "\xc3\xa9\xff";

        $orm->insert($table => {id => 1, $field => $TEXT, b => $bytes});
        $orm->insert($table => {id => 2, $field => $latin});
        $orm->clear_cache;

        is($orm->refresh_row($table, {id => 1})->{$field}, $TEXT,  "Text goes in and comes back as characters, names included");
        is($orm->refresh_row($table, {id => 2})->{$field}, $latin, "A Latin-1 string that was never upgraded too");
        is($orm->refresh_row($table, {id => 1})->{b},      $bytes, "Binary fields stay bytes both ways");
        ok($orm->update_row($table, {id => 2, $field => $latin}, {$field => $TEXT}, cas => [$field], enforce_canon => 0), "Text compares as characters");

        my $source = DBIx::QuickORM::Source::Table->new(table => $table, db_map => $orm->db_map);
        my ($row) = @{$orm->connection->select($source, "SELECT id, ${q}v\x{e9}${q} FROM ${q}caf\x{e9}_\x{263a}${q} WHERE ${q}v\x{e9}${q} = ?", [[$field => $TEXT]])};
        is($row->{$field}, $TEXT, "and the query primitive converts its SQL, binds, and results");
    };

    subtest time_zone => sub {
        my $sql    = $OFFSET_SQL{$family} or skip_all "$family has no session time zone";
        my $offset = sub {
            DBIx::QuickORM->new(connect => sub { $db->connect }, @_)->connection->dbh->selectrow_array($sql);
        };

        is($offset->() + 0, 0, "The session time zone is UTC by default");

        return if $family =~ m/^(?:MySQL|MariaDB)$/;    # zone names need time zone tables loaded on the server
        is($offset->(time_zone => 'Asia/Tokyo') + 0, 32400, "A zone name sets it");
    };
};

done_testing;
