use strict;
use warnings;
use Test::More;
use DBI;
use DBIx::FixtureLoader;
use Test::Requires 'DBD::SQLite';

my $dbh = DBI->connect("dbi:SQLite::memory:", '', '', {RaiseError => 1}) or die 'cannot connect to db';
$dbh->do(q{
    CREATE TABLE item (
        id   INTEGER PRIMARY KEY,
        name VARCHAR(255)
    );
});

my $m = DBIx::FixtureLoader->new(
    dbh => $dbh,
);

$m->load_fixture('t/data/item.csv');

my $result = $dbh->selectrow_arrayref('SELECT COUNT(*) FROM item');
is $result->[0], 2;

my $rows = $dbh->selectall_arrayref('SELECT * FROM item ORDER BY id;', {Slice => {}});
is scalar @$rows, 2;
is $rows->[0]{name}, 'エクスカリバー';

subtest "adding yaml" => sub {
    $m->load_fixture('t/data/item-2.yml');

    my $result = $dbh->selectrow_arrayref('SELECT COUNT(*) FROM item ORDER BY id;');
    is $result->[0], 4;

    my $rows = $dbh->selectall_arrayref('SELECT * FROM item;', {Slice => {}});
    is scalar @$rows, 4;
    is $rows->[3]{name}, '正宗';
};

subtest "adding json" => sub {
    $m->load_fixture('t/data/item-3.json');

    my $rows = $dbh->selectall_arrayref('SELECT * FROM item ORDER BY id;', {Slice => {}});
    is scalar @$rows, 5;
    is $rows->[4]{name}, 'グラディウス';
};


subtest "adding ar-ish yml" => sub {
    $m->load_fixture('t/data/item-4.yaml');

    my $rows = $dbh->selectall_arrayref('SELECT * FROM item;', {Slice => {}});
    is scalar @$rows, 7;
    is $rows->[6]{name}, 'ウィザードロッド';
};

subtest "adding Test::Fixtures::DBI" => sub {
    $m->load_fixture('t/data/item-5-fixture-dbi.txt', format => 'yaml');

    my $rows = $dbh->selectall_arrayref('SELECT * FROM item;', {Slice => {}});
    is scalar @$rows, 9;
    is $rows->[8]{name}, '賢者の杖';
};

subtest "can't set update option" => sub {
    my $m = DBIx::FixtureLoader->new(
        dbh => $dbh,
        update => 1,
    );

    local $@;
    eval {
        $m->load_fixture('t/data/item-3.json');
    };
    ok $@;
};

subtest 'delete' => sub {
    my $m = DBIx::FixtureLoader->new(
        dbh => $dbh,
    );
    $m->load_fixture('t/data/item-3.json', delete => 1);

    my $rows = $dbh->selectall_arrayref('SELECT * FROM item;', {Slice => {}});
    is scalar @$rows, 1;
};

subtest 'delete2' => sub {
    my $m = DBIx::FixtureLoader->new(
        dbh => $dbh,
        delete => 1,
    );
    $m->load_fixture('t/data/item-2.yml');

    my $rows = $dbh->selectall_arrayref('SELECT * FROM item;', {Slice => {}});
    is scalar @$rows, 2;
};

done_testing;
