
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestDB;
use TestSchema;
use DBIx::Class::Async;

# Helper to handle both Sync and Async results in tests
sub await {
    my $val = shift;
    return (ref($val) && $val->can('get')) ? $val->get : $val;
}

subtest 'Real Integration: Optimized Delete' => sub {
    my $db_file = setup_test_db();
    my $schema  = TestSchema->connect("dbi:SQLite:dbname=$db_file");
    my $async_bridge = DBIx::Class::Async->new(
        schema_class => 'TestSchema',
        connect_info => ["dbi:SQLite:dbname=$db_file"],
    );

    my $rs_all = $schema->resultset('User');
    my $active_rs = $rs_all->search(
        { active => 1 },
        { async_db => $async_bridge } # This triggers your Async ResultSet logic!
    );
    #my $active_rs = $rs_all->search({ active => 1 });

    # 1. Check count (Handle sync/async)
    is(await($active_rs->count), 3, "Found 3 active users");

    # 2. Execute Delete (This is the async part we are testing)
    my $f = $active_rs->delete;

    # If your ResultSet.pm logic returns a Future, this works:
    my $deleted_count = await($f);

    # 3. Verifications
    is($deleted_count, 3, "Bulk delete reported 3 rows deleted");


    # Use standard DBIC 'first' because $rs_all is synchronous
    my $remaining_user = $rs_all->first;

    ok($remaining_user, "Found the remaining user");
    is($remaining_user->name, 'Charlie', "The survivor is indeed Charlie");

    done_testing(); # Ensure this is at the end of the script
};

subtest 'Real Integration: Optimized Delete' => sub {
    my $db_file = setup_test_db();
    my $schema  = TestSchema->connect("dbi:SQLite:dbname=$db_file");
    my $async_bridge = DBIx::Class::Async->new(
        schema_class => 'TestSchema',
        connect_info => ["dbi:SQLite:dbname=$db_file"],
    );

    # 1. SETUP: TestDB starts with 4 users (Alice, Bob, Charlie, Diana)
    # Alice, Bob, Diana are active (3 total)
    #my $rs = $schema->resultset('User')->search({ active => 1 });
    my $rs = $schema->resultset('User')->search(
        { active => 1 },
        { async_db => $async_bridge } # This triggers your Async ResultSet logic!
    );

    # 2. EXECUTE: This calls your real delete() -> delete_all() logic
    # No mocks. No patches. Just the real bridge and worker.
    my $f = $rs->delete;

    # 3. VERIFY: Ensure we got a Future back and it resolved to 3
    my $deleted_count = await ($f);
    is($deleted_count, 3, "Bulk delete reported 3 rows deleted");

    # 4. FINAL CHECK: Query the real SQLite file to see what happened
    my $remaining_count = $schema->resultset('User')->count;
    is($remaining_count, 1, "Only 1 user remains in the database");

    my $survivor = $schema->resultset('User')->first;
    is($survivor->name, 'Charlie', "The survivor is Charlie (the inactive one)");
};

done_testing();
