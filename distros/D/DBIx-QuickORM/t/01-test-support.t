# Test origin: AI
use Test2::V0;
use lib 't/lib';
use DBIx::QuickORM::Test qw/do_for_all_dbs db_sets/;

subtest db_sets => sub {
    my @sets = db_sets();
    is([map { $_->{name} } @sets[0 .. 5]], [qw/sqlite duckdb postgresql mariadb mysqlcom percona/], "The \$PATH sets come first");
    ok(!(grep { !$_->{family} || !$_->{driver} } @sets), "Every set has a family and a QuickDB driver");

    local $ENV{QORM_TEST_SETS} = 'sqlite, MySQL';
    is([map { $_->{family} } db_sets()], bag { item 'SQLite'; item 'MySQL'; etc }, "QORM_TEST_SETS filters by name or family");
    ok(!(grep { $_->{family} !~ m/^(?:SQLite|MySQL)$/ } db_sets()), "and keeps nothing else");
};

subtest run => sub {
    local $ENV{QORM_TEST_SETS} = 'sqlite,duckdb';

    my $parent = $$;
    do_for_all_dbs {
        my ($db, $set) = @_;
        isnt($$, $parent, "$set->{name} runs in a child process");
        ok($db->connect->do('SELECT 1'), "$set->{name} connects");
    };

    ok(!$INC{'DBIx/QuickDB.pm'}, "The parent never loads DBIx::QuickDB");
};

done_testing;
