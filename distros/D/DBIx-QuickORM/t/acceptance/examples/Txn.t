# Test origin: AI
# This test runs copies of the code examples in lib/DBIx/QuickORM/Txn.pm. Whenever an example
# there changes, change its copy here to match: t/acceptance/Examples.t fails while any example has
# no copy in an example test.
use Test2::V0;
use lib 't/lib';

use DBIx::QuickORM;
use DBIx::QuickORM::Test::Examples;

do_for_pg {
    my ($db) = @_;
    $db->connect->do($SCHEMA);
    my $orm   = DBIx::QuickORM->new(connect => sub { $db->connect });
    my $named = sub { $orm->handle('users')->where({name => $_[0]})->count };

    # Block form
    # Commits when the block returns. An exception rolls back and is rethrown.
    $orm->txn(sub {
        my $bob = $orm->insert(users => {name => 'Bob'});
        $orm->insert(
            posts => {
                user_id => $bob->field('id'),
                title   => 'Hello',
            },
        );
    });

    # Commit or roll back early through the transaction the block is given.
    $orm->txn(sub {
        my $txn = shift;
        $orm->insert(users => {name => 'Temp'});
        $txn->rollback;
    });

    is($named->('Bob'),              1, "the block committed");
    is($orm->handle('posts')->count, 1, "everything in it");
    is($named->('Temp'),             0, "a block can roll back");

    like(
        dies {
            $orm->txn(sub { $orm->insert(users => {name => 'Oops'}); die "boom\n" })
        },
        qr/^boom$/,
        "an exception in the block is rethrown",
    );
    is($named->('Oops'), 0, "after rolling the block back");

    # Object form
    my $txn = $orm->txn;
    $orm->insert(users => {name => 'Carol'});
    $txn->commit;

    my $undo = $orm->txn;
    $orm->insert(users => {name => 'Nobody'});
    $undo->rollback;

    is($named->('Carol'),  1, "commit");
    is($named->('Nobody'), 0, "rollback");
};

done_testing;
