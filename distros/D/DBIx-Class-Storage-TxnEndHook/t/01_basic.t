use strict;
use warnings;
use Test::More;
use lib qw(t/lib);
use MyApp::Schema;
use Test::Fatal;

sub gen_schema {
    my $schema = MyApp::Schema->connect("dbi:SQLite::memory:", "", "", {
        sqlite_use_immediate_transaction => 1,
    });
}

subtest 'add_txn_end_hook should call in transaction' => sub {
    my $schema = gen_schema();

    like(
        exception {
            $schema->storage->add_txn_end_hook(sub {});
        },
        qr/only can call add_txn_end_hook in transaction/,
        "die if called add_txn_end_hook method without transaction",
    );
};

subtest 'DBIx::Schema->txn_do style' => sub {
    my $schema = gen_schema();
    my $call_count = 0;

    $schema->txn_do(sub{
            $schema->storage->add_txn_end_hook(sub {
                    $call_count++;
                });
            is $call_count, 0, "not yet call";
            is @{ $schema->storage->_hooks }, 1, "hooks count is 1";
        });

    is $call_count, 1, "add_txn_end_hook is called";
    is @{ $schema->storage->_hooks }, 0, "all hooks is executed";
};

subtest 'DBIx::Schema->txn_begin and txn_commit style' => sub {
    my $schema = gen_schema();
    my $call_count = 0;

    $schema->txn_begin;
    $schema->storage->add_txn_end_hook(sub {
        $call_count++;
    });
    is $call_count, 0, "not yet call";
    is @{ $schema->storage->_hooks }, 1, "hooks count is 1";

    $schema->txn_commit;

    is $call_count, 1, "called";
    is @{ $schema->storage->_hooks }, 0, "all hooks is executed";
};

subtest 'DBIx::Schema->storage->txn_begin and txn_commit style' => sub {
    my $schema = gen_schema();
    my $call_count = 0;

    $schema->storage->txn_begin;
    $schema->storage->add_txn_end_hook(sub {
        $call_count++;
    });
    $schema->storage->add_txn_end_hook(sub {
        $call_count++;
    });
    is $call_count, 0;
    is @{ $schema->storage->_hooks }, 2;
    $schema->storage->txn_commit;

    is $call_count, 2;
    is @{ $schema->storage->_hooks }, 0;
};

subtest 'DBIx::Schema->txn_scope_guard style' => sub {
    my $schema = gen_schema();
    my $call_count = 0;

    my $guard = $schema->txn_scope_guard;
    $schema->storage->add_txn_end_hook(sub {
        $call_count++;
    });
    $schema->storage->add_txn_end_hook(sub {
        $call_count++;
    });
    is $call_count, 0;
    is @{ $schema->storage->_hooks }, 2;

    $guard->commit;

    is $call_count, 2;
    is @{ $schema->storage->_hooks }, 0;
};

subtest 'die in end hook subroutine' => sub {
    my $schema = gen_schema();
    my $call_count = 0;

    my $guard = $schema->txn_scope_guard;
    $schema->storage->add_txn_end_hook(sub {
        $call_count++;
    });
    $schema->storage->add_txn_end_hook(sub {
        die "die!die!die!";
        $call_count++;
    });
    $schema->storage->add_txn_end_hook(sub {
        $call_count++;
    });
    is $call_count, 0;
    is @{ $schema->storage->_hooks }, 3;

    is(
        exception {
            $guard->commit;
        },
        undef,
        "not died in commit",
    );

    is $call_count, 1;
    is @{ $schema->storage->_hooks }, 0, "all hooks is executed";

    is $guard->{inactivated}, 1, "guard should be inactivated";
};

subtest 'nest transaction' => sub {
    my $schema = gen_schema();
    my $call_count = 0;

    my $guard1 = $schema->txn_scope_guard;
    my $guard2 = $schema->txn_scope_guard;

    $schema->storage->add_txn_end_hook(sub {
        $call_count++;
    });
    $schema->storage->add_txn_end_hook(sub {
        $call_count++;
    });

    $guard2->commit;

    is $call_count, 0;
    is @{ $schema->storage->_hooks }, 2, "not yet called";

    $guard1->commit;

    is $call_count, 2;
    is @{ $schema->storage->_hooks }, 0;
};

subtest 'schema->add_txn_end_hook' => sub {
    my $schema = gen_schema();
    my $call_count = 0;

    $schema->txn_begin;
    $schema->add_txn_end_hook(sub {
        $call_count++;
    });
    $schema->add_txn_end_hook(sub {
        $call_count++;
    });
    is $call_count, 0;
    is @{ $schema->storage->_hooks }, 2;
    $schema->txn_commit;

    is $call_count, 2;
    is @{ $schema->storage->_hooks }, 0;
};

subtest 'clear hook on rollback' => sub {
    my $schema = gen_schema();
    my $call_count = 0;

    {
        my $guard = $schema->txn_scope_guard;
        $schema->storage->add_txn_end_hook(sub {
            $call_count++;
        });
        is @{ $schema->storage->_hooks }, 1, "not yet called";
        # end of scope
    }

    is $call_count, 0;
    is @{ $schema->storage->_hooks }, 0, "cleard hooks";
};

done_testing;
