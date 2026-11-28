# Test origin: AI
# This test runs copies of the code examples in lib/DBIx/QuickORM/Manual/BulkInsert.pm. Whenever an
# example there changes, change its copy here to match: t/acceptance/Examples.t fails while any
# example has no copy in an example test.
use Test2::V0;
use lib 't/lib';

use DBIx::QuickORM;
use DBIx::QuickORM::Test qw/do_for_all_dbs/;
use DBIx::QuickORM::Test::Examples;

do_for_pg {
    my ($db) = @_;
    $db->connect->do($SCHEMA);
    my $orm = DBIx::QuickORM->new(connect => sub { $db->connect });
    my $dbh = $orm->connection->dbh;

    # INSERTING MANY ROWS
    my $users = $orm->insert_many(users => [{name => 'Ann'}, {name => 'Bob'}]);    # an arrayref of rows
    my $id    = $users->[0]->field('id');                                          # whole rows, canonical

    # the same, on a table handle
    my $more = $orm->handle('users')->insert_many([{name => 'Cy'}, {name => 'Di'}]);

    my $data = $orm->insert_many(
        users => [{name => 'Gus'}],
        data  => 1,                   # hashrefs instead of row objects
    );

    is([map { $_->field('name') } @$users], ['Ann', 'Bob'], "insert_many returns an arrayref of the new rows");
    ok($id,                   "with the keys the database generated");
    ok($users->[0]->is_canon, "canonical");
    is([sort keys %{$users->[0]->row_data}],                           [qw/created email id name prefs referred_by/], "with every field of the table, defaults included");
    is([map { $_->field('name') } @$more],                             ['Cy', 'Di'],                                  "through a table handle too");
    is(ref($data->[0]),                                                'HASH',                                        "data gives hashrefs");
    is($data->[0]->{name},                                             'Gus',                                         "of the new rows");
    is($dbh->selectcol_arrayref("SELECT name FROM users ORDER BY id"), ['Ann', 'Bob', 'Cy', 'Di', 'Gus'],             "the rows are in");

    $orm->insert_many(users => [{name => 'Hal'}, {name => 'Ida'}]);    # void: inserts only
    is($dbh->selectcol_arrayref("SELECT name FROM users WHERE name IN ('Hal', 'Ida') ORDER BY id"), ['Hal', 'Ida'], "void context only inserts");
    $dbh->do("DELETE FROM users WHERE name = 'Ida'");
    like(dies { $orm->insert_many(users => [{name => 'x'}, {name => 'y', email => 'y@example.com'}]) }, qr/needs the same fields in every row/, "rows with different fields croak");

    # JUST THE COUNT
    my $count = $orm->insert_many(
        users => [{name => 'Eve'}, {name => 'Fay'}],
        count => 1,
    );                                                                 # 2

    is($count, 2, "count gives how many rows went in");
    my ($eve) = $dbh->selectrow_array("SELECT id FROM users WHERE name = 'Eve'");
    my ($hal) = $dbh->selectrow_array("SELECT id FROM users WHERE name = 'Hal'");
    is($orm->refresh_row(users => {id => $eve}, db => 0), undef, "nothing is canonical with count");
    is($orm->refresh_row(users => {id => $hal}, db => 0), undef, "or in void context");

    # ALL OR NOTHING
    my $before     = $orm->handle('users')->count;
    my $statements = 0;
    local $dbh->{Callbacks} = {prepare => sub { $statements++ if $_[1] =~ m/^INSERT/; return }};

    # more binds than one statement may hold: two statements
    my @many = map { {
        name  => "User $_",
        email => "user$_\@example.com",
    } } 1 .. 40_000;

    $many[-1]->{email} = 'user1@example.com';    # a duplicate, in the last row

    # fails, and no row went in, not even the first statement's
    my $ok = eval { $orm->insert_many(users => \@many); 1 };

    ok(!$ok, "the duplicate makes insert_many fail");
    is($@->kind,                              'unique_violation', "with the database's error");
    is($statements,                           2,                  "the first statement had already run");
    is($orm->handle('users')->count,          $before,            "but its rows are rolled back with the second");
    is($orm->connection->dialect->bind_limit, 65535,              "PostgreSQL takes 65535 binds per statement");

    $many[-1]->{email} = 'user40000@example.com';
    $statements = 0;
    is($orm->insert_many(users => \@many, count => 1), 40_000, "without the duplicate every row goes in");
    is($statements,                                    2,      "in two statements");
    delete $dbh->{Callbacks};

    $orm->txn(sub {
        my $kept = $orm->insert(users => {name => 'Kept'});
        $many[-1]->{email} = 'user1@example.com';
        ok(!eval { $orm->insert_many(users => \@many); 1 },                                          "inside a transaction the failure");
        ok($orm->handle('users')->where({name => 'Kept'})->only,                                     "leaves the transaction usable: its savepoint rolled back");
        ok(!eval { $orm->insert_many(users => [{name => 'One', email => 'user1@example.com'}]); 1 }, "a single-statement insert_many fails the same way");
        ok($orm->handle('users')->where({name => 'Kept'})->only,                                     "and took a savepoint too, so the transaction is still usable");
        $_[0]->rollback;
    });
};

# WITHOUT RETURNING (MySQL), on every database, with the id and name fields of the Quickstart's users table
my %AUTO_PK = (
    PostgreSQL => 'SERIAL PRIMARY KEY',
    MySQL      => 'INTEGER AUTO_INCREMENT PRIMARY KEY',
    MariaDB    => 'INTEGER AUTO_INCREMENT PRIMARY KEY',
    SQLite     => 'INTEGER PRIMARY KEY AUTOINCREMENT',
    DuckDB     => "INTEGER PRIMARY KEY DEFAULT nextval('users_seq')",
);

do_for_all_dbs {
    my ($db, $set) = @_;
    my $family = $set->{family};

    # DuckDB sees only its own connection's writes, so the setup connection is closed before the ORM opens.
    my $setup = $db->connect;
    $setup->do("CREATE SEQUENCE users_seq") if $family eq 'DuckDB';
    $setup->do("CREATE TABLE users (id $AUTO_PK{$family}, name VARCHAR(20) NOT NULL)");
    $setup->disconnect;
    my $orm = DBIx::QuickORM->new(connect => sub { $db->connect });

    # on MySQL every row must carry its whole primary key
    my $rows = $orm->insert_many(
        users => [
            {
                id   => 1,
                name => 'A',
            },
            {
                id   => 2,
                name => 'B',
            },
        ],
    );

    # on MySQL the row holds only its key, and fetches the rest when read
    my $name = $rows->[0]->field('name');

    is([map { [$_->field('id'), $_->field('name')] } @$rows], [[1, 'A'], [2, 'B']], "insert_many gives both rows with their keys");
    is($name,                                                 'A',                  "and their fields read back");

    if ($orm->connection->dialect->supports_returning_insert) {
        isnt($family, 'MySQL', "every database but MySQL returns inserted rows");
        is([map { $_->row_data } @$rows], [{id => 1, name => 'A'}, {id => 2, name => 'B'}], "the rows came back whole");
    }
    else {
        is($family, 'MySQL', "only MySQL has no RETURNING");
        my $more = $orm->insert_many(users => [{id => 3, name => 'C'}]);
        is([map { $_->row_data } @$more], [{id => 3}], "the rows hold only their keys");
        is($more->[0]->field('name'),     'C',         "a field read later is fetched");
        like(dies { my $r = $orm->insert_many(users => [{name => 'D'}]) }, qr/cannot return rows unless every row carries its whole primary key.*count => 1/, "without the keys it croaks, pointing at count");
        is($orm->insert_many(users => [{name => 'D'}], count => 1), 1, "count inserts them");
    }
};

done_testing;
