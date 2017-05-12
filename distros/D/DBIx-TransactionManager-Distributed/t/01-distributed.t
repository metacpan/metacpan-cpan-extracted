#!perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Test::Warnings qw(warning warnings);
use Test::Deep;
use DBI;
use DBD::Mock;
use DBIx::TransactionManager::Distributed qw(register_dbh release_dbh dbh_is_registered txn register_cached_dbh);
use Scalar::Util qw(refaddr);
use Test::Refcount;

subtest register_dbh => sub {
    my $dbh;
    is(exception { $dbh = DBI->connect('DBI:Mock:', '', '', {RaiseError => 1}) }, undef, "create dbh");
    is(register_dbh('category1', $dbh), $dbh, 'register successfully');
    is_oneref($dbh, 'refcount is not increased');
    my $result;
    like(
        warning { $result = register_dbh('category1', $dbh) },
        qr/already registered this database handle at/,
        'register again to same category will failed'
    );
    ok(!$result, 'register failed');
    my $history = $dbh->{mock_all_history};
    is(scalar(@$history), 0, 'no statement executed');
    is_deeply(warning { $result = register_cached_dbh('category1', $dbh) }, [], 'but register again with cached_dbh  will success');
    ok($result, 'register success');
    is(release_dbh('category1', $dbh), $dbh, 'release successfully');
    is_deeply(warning { register_dbh('category1', $dbh) },
        [], 'register 3rd time to same category will not failed because previous register already released');
    is(release_dbh('category1', $dbh), $dbh, 'clear regsiter for later tests');

    local $DBIx::TransactionManager::Distributed::IN_TRANSACTION = 1;
    is(register_dbh('category1', $dbh), $dbh, 'register successfully');
    $history = $dbh->{mock_all_history};
    is(scalar(@$history),        1,            'has 1 statement executed');
    is($history->[0]->statement, 'BEGIN WORK', 'begin_work statement when registered during IN_TRANSACTION');
    is_deeply(warning { $result = register_dbh('category2', $dbh) }, [], 'no warnings emit');    # that means begin-work is not called again
    is($result, $dbh, 'register twice successfully');
    $result = undef;
    is_oneref($dbh, 'dbh refcount is not increased');
    $history = $dbh->{mock_all_history};
    is(scalar(@$history),        1,            'still has only 1 statement executed, that means begin-work only run once');
    is($history->[0]->statement, 'BEGIN WORK', 'begin_work statement when registered during IN_TRANSACTION');
    is(release_dbh('category1', $dbh), $dbh, 'release it from category1');
    ok(!dbh_is_registered('category1', $dbh), 'dbh should not be in category2 now');
    ok(dbh_is_registered('category2', $dbh), 'the dbh should still be in category2');
    like(
        warning { release_dbh('category1', $dbh) },
        qr/releasing unregistered dbh (\S+) for category category1 \(but found it in these categories instead: category2/,
        'has warnings because dbh already released before'
    );
    ok(!dbh_is_registered('category2', $dbh), 'dbh should not be in category2 now');
    done_testing();
};

subtest register_fork => sub {
    my $dbh1 = DBI->connect('DBI:Mock:', '', '');
    my $dbh2 = DBI->connect('DBI:Mock:', '', '');
    is(register_dbh('category1', $dbh1), $dbh1, 'register dbh1');
    is(register_dbh('category2', $dbh2), $dbh2, 'register dbh2');
    ok(dbh_is_registered('category1', $dbh1), 'the dbh1 is registered in category1');
    ok(dbh_is_registered('category2', $dbh2), 'the dbh2 is registered in category2');
    local $$ = fake_pid();
    my $dbh3 = DBI->connect('DBI:Mock:', '', '');
    is(register_dbh('category3', $dbh3), $dbh3, 'register dbh3');
    ok(!dbh_is_registered('category1', $dbh1), 'the dbh1 is dropped because pid changed');
    ok(!dbh_is_registered('category2', $dbh2), 'the dbh2 is dropped because pid changed');
    ok(dbh_is_registered('category3', $dbh3), 'dbh3 is still there');
    ok(release_dbh('category3', $dbh3), 'clear dbh');
    done_testing();
};

subtest txn => sub {
    # test warn
    my ($dbh1_1, $dbh1_2, $dbh2_1) = init_dbh_for_txn_test();
    my $code = sub {
        return qw(1_1 1_2 2_1);
    };
    $dbh1_1 = undef;
    cmp_deeply([
            warnings {
                txn(sub { $code->() }, 'category1');
            }
        ],
        [re(qr/Had 1 database handles/), re(qr/unreleased dbh in/)],
        "will emit warning if some dbhs are invalid now"
    );

    #test normal case
    clear_dbh_for_txn_test();
    ($dbh1_1, $dbh1_2, $dbh2_1) = init_dbh_for_txn_test();
    $code = sub {
        my ($dbh1_1, $dbh1_2, $dbh_2_1) = @_;
        $dbh1_1->do('select 1_1');
        $dbh1_2->do('select 1_2');
        $dbh2_1->do('select 2_1');
        return wantarray ? qw(1_1 1_2 2_1) : "1";
    };
    my $result;
    is_deeply(
        warning {
            $result = txn(sub { $code->($dbh1_1, $dbh1_2, $dbh2_1) }, 'category1');
        },
        [],
        'no warning for normal case'
    );
    is($result, '1', 'want scalar will get 1');
    my $history = $dbh1_1->{mock_all_history};
    is(scalar @$history, 3, "3 statement");
    is($history->[0]->statement, 'BEGIN WORK');
    is($history->[1]->statement, 'select 1_1');
    is($history->[2]->statement, 'COMMIT');
    $history = $dbh1_2->{mock_all_history};
    is(scalar @$history, 3, "3 statement");
    is($history->[0]->statement, 'BEGIN WORK');
    is($history->[1]->statement, 'select 1_2');
    is($history->[2]->statement, 'COMMIT');
    $history = $dbh2_1->{mock_all_history};
    is(scalar @$history,         1,            "dbh2_1 is not in category1, so only one statement");
    is($history->[0]->statement, 'select 2_1', 'dbh2_1 no begin_work and commit');

    for my $dbh ($dbh1_1, $dbh1_2, $dbh2_1) {
        $dbh->{mock_clear_history} = 1;
        $dbh->{AutoCommit}         = 1;    # DBD::Mock has an bug. the second dbh cannot reset autocommit after commit. so we reset it by hand
    }

    my @result = txn(sub { $code->($dbh1_1, $dbh1_2, $dbh2_1) }, 'category1');
    is_deeply(\@result, [qw(1_1 1_2 2_1)], 'wantarray will get a list');

    for my $dbh ($dbh1_1, $dbh1_2, $dbh2_1) {
        $dbh->{mock_clear_history} = 1;
        $dbh->{AutoCommit}         = 1;    # DBD::Mock has an bug. the second dbh cannot reset autocommit after commit. so we reset it by hand
    }

    $dbh1_2->{mock_add_parser} = sub {
        my $sql = shift;
        die "simulate parse error"    if $sql =~ /select/;
        die "simulate rollback error" if $sql =~ /rollback/i;
    };
    cmp_deeply([
            warnings {
                like(
                    exception {
                        txn(sub { $code->($dbh1_1, $dbh1_2, $dbh2_1) }, 'category1');
                    },
                    qr/simulate parse error/,
                    "will die if error"
                );
            }
        ],
        [re(qr/simulate parse error/), re(qr/Error in transaction/), re(qr/simulate rollback error/), re(qr/^after/is)],
        "have warnings"
    );
    $history = $dbh1_1->{mock_all_history};
    is($history->[-1]->statement, 'ROLLBACK', 'dbh1_1 rollbacked');

    # test fork
    clear_dbh_for_txn_test();
    ($dbh1_1, $dbh1_2, $dbh2_1) = init_dbh_for_txn_test();
    local $$ = fake_pid();    # change $$ to simulate fork
    is(
        exception {
            txn(sub { $code->($dbh1_1, $dbh1_2, $dbh2_1) }, 'category1');
        },
        undef
    );
    $history = $dbh1_1->{mock_all_history};
    is(scalar @$history,          1,            'no begin_work and rollback because fork will clear all registered dbh');
    is($history->[-1]->statement, 'select 1_1', 'only select statement');

    clear_dbh_for_txn_test();
    ($dbh1_1, $dbh1_2, $dbh2_1) = init_dbh_for_txn_test();
    $code = sub {
        my ($dbh1_1, $dbh1_2, $dbh_2_1) = @_;
        $$ = fake_pid();    # change $$ to simulate fork
        $dbh1_1->do('select 1_1');
        $dbh1_2->do('select 1_2');
        $dbh2_1->do('select 2_1');
        return wantarray ? qw(1_1 1_2 2_1) : "1";
    };
    is(
        exception {
            txn(sub { $code->($dbh1_1, $dbh1_2, $dbh2_1) }, 'category1');
        },
        undef
    );
    $history = $dbh1_1->{mock_all_history};
    is(scalar @$history,         2,            'no commit because fork will clear all registered dbh');
    is($history->[0]->statement, 'BEGIN WORK', 'has begin work');
    is($history->[1]->statement, 'select 1_1', 'has select');
    done_testing();
};

sub init_dbh_for_txn_test {
    my $dbh1_1 = DBI->connect('DBI:Mock:', '', '', {RaiseError => 1});
    my $dbh1_2 = DBI->connect('DBI:Mock:', '', '', {RaiseError => 1});
    my $dbh2_1 = DBI->connect('DBI:Mock:', '', '', {RaiseError => 1});
    ok(register_dbh('category1', $dbh1_1));
    ok(register_dbh('category1', $dbh1_2));
    ok(register_dbh('category2', $dbh2_1));
    return ($dbh1_1, $dbh1_2, $dbh2_1);
}

sub clear_dbh_for_txn_test {
    local $$ = fake_pid();
    DBIx::TransactionManager::Distributed::_check_fork();
}

{
    my $pid = 1;

    sub fake_pid {
        return $pid++;
    }

}
done_testing;

