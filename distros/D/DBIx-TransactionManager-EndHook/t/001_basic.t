use strict;
use warnings;
use utf8;

use Test::Exception;
use Test::More;
use DBD::SQLite;
use DBI;

use DBIx::TransactionManager;
use DBIx::TransactionManager::EndHook;

sub new_txn_manager {
    my $dbh = DBI->connect("dbi:SQLite::memory:", "", "", {
        sqlite_use_immediate_transaction => 1,
    });
    DBIx::TransactionManager->new( $dbh );
}

local $SIG{ __WARN__ } = sub {};

subtest 'no nest transaction' => sub {
    my $txn_manager = new_txn_manager();
    my $txn = $txn_manager->txn_scope;

    my $call_count = 0;


    $txn_manager->add_end_hook(sub {
        $call_count++;
    });
    $txn_manager->add_end_hook(sub {
        $call_count++;
    });

    $txn->commit;

    # call twice
    is $call_count, 2;

    # hooks should be empty
    is_deeply $txn_manager->{_end_hooks}, [];
};

subtest 'die in twice hook' => sub {
    my $txn_manager = new_txn_manager();
    my $txn = $txn_manager->txn_scope;

    my $call_count = 0;

    $txn_manager->add_end_hook(sub {
        $call_count++;
    });
    $txn_manager->add_end_hook(sub {
        die "dieeeeeeeee";
        $call_count++;
    });
    $txn_manager->add_end_hook(sub {
        $call_count++;
    });

    throws_ok {
        $txn->commit;
    } qr/^dieeeeeeeee/;


    # call once
    is $call_count, 1;

    # hooks should be empty.
    # add_end_hook does not handle exception.
    is_deeply $txn_manager->{_end_hooks}, [];
};

subtest 'nest transaction' => sub {
    my $txn_manager = new_txn_manager();
    my $txn1 = $txn_manager->txn_scope;

    my $call_count = 0;

    my $txn2 = $txn_manager->txn_scope;

    $txn_manager->add_end_hook(sub {
        $call_count++;
    });
    $txn_manager->add_end_hook(sub {
        $call_count++;
    });

    $txn2->commit;

    # hook are not executed when nested transaction are commited
    is $call_count, 0;

    # so, hook are not empty
    is @{ $txn_manager->{_end_hooks} }, 2;

    $txn1->commit;

    # call count should be twice
    is $call_count, 2;

    # hook are emtpy
    is_deeply $txn_manager->{_end_hooks}, [];
};

subtest 'fail in nested transaction' => sub {
    my $call_count = 0;

    my $txn_manager = new_txn_manager();

    my $txn1 = $txn_manager->txn_scope;

    $txn_manager->add_end_hook(sub {
        $call_count++;
    });

    {
        my $txn2 = $txn_manager->txn_scope;
        undef $txn2;
    }

    throws_ok {
        $txn1->commit;
    } qr/^tried to commit but already rollbacked in nested transaction/;

    is $call_count, 0;
};

subtest 'can call add_end_hook only in transactions' => sub {
    my $txn_manager = new_txn_manager();

    throws_ok {
        $txn_manager->add_end_hook(sub{});
    } qr/^only can call add_end_hook in transaction/;
};

subtest 'clear hook on rollback' => sub {
    my $txn_manager = new_txn_manager();

    my $should_be_1_after_commit = 0;
    {
        my $scope = $txn_manager->txn_scope;
        $txn_manager->add_end_hook( sub {
            $should_be_1_after_commit = 1;
        });
        # end of scope
    }

    is $should_be_1_after_commit, 0;

    {
        my $scope = $txn_manager->txn_scope;
        $scope->commit;
    }

    is $should_be_1_after_commit, 0;
};

done_testing;
