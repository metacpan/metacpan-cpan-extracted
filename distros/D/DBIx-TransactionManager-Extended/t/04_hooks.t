use strict;
use warnings;

use Test::More 0.98;
use t::Util;

use DBIx::TransactionManager::Extended;

subtest 'cannot call out of the transaction' => sub {
    my $dbh = create_mock_dbh();
    my $manager = DBIx::TransactionManager::Extended->new($dbh);
    for my $method (qw/add_hook_after_commit add_hook_before_commit remove_hook_after_commit remove_hook_before_commit/) {
        eval { $manager->$method(sub {}) };
        like $@, qr/^\QCANNOT call $method out of the transaction/, $method;
    }
};

subtest 'add/remove hooks' => sub {
    my $dbh = create_mock_dbh();
    my $manager = DBIx::TransactionManager::Extended->new($dbh);

    my @result;
    $manager->txn_begin();
    $manager->add_hook_before_commit(sub { push @result => 1; is $dbh->called_count('commit'), 0, 'before commit (1)'; });
    $manager->add_hook_after_commit(sub { push @result => 3; is $dbh->called_count('commit'), 1, 'after commit (3)'; });
    $manager->add_hook_before_commit(sub { push @result => 2; is $dbh->called_count('commit'), 0, 'before commit (2)'; });
    $manager->add_hook_after_commit(sub { push @result => 4; is $dbh->called_count('commit'), 1, 'after commit (4)'; });
    is_deeply \@result, [], 'not yet run hooks here';
    $manager->txn_commit();
    is_deeply \@result, [1, 2, 3, 4], 'should run hooks';

    $manager->txn_begin(); $manager->txn_commit();
    is_deeply \@result, [1, 2, 3, 4], 'hooks are removed after commit';

    $manager->txn_begin();
    $manager->add_hook_after_commit(sub { push @result => 99999 });
    $manager->add_hook_before_commit(sub { push @result => 99999 });
    $manager->txn_rollback();
    is_deeply \@result, [1, 2, 3, 4], 'should not run hooks at rollback';

    $manager->txn_begin(); $manager->txn_commit();
    is_deeply \@result, [1, 2, 3, 4], 'hooks are removed after rollback';

    $manager->txn_begin();
    $manager->txn_begin();
    my $context_data = $manager->context_data();
    $manager->add_hook_after_commit(sub { push @result => 6; is $_[0], $context_data, 'context data is passed to before hook' });
    $manager->add_hook_before_commit(sub { push @result => 5; is $_[0], $context_data, 'context data is passed to before hook' });
    $manager->txn_commit();
    is_deeply \@result, [1, 2, 3, 4], 'should not run hooks at commit on nested transaction';
    $manager->txn_commit();
    is_deeply \@result, [1, 2, 3, 4, 5, 6], 'should run hooks at commit all transaction';

    $manager->txn_begin();
    $manager->add_hook_after_commit(sub { push @result => 9 });
    $manager->add_hook_before_commit(sub { push @result => 7 });
    my $after = $manager->add_hook_after_commit(sub { push @result => 99999 });
    my $before = $manager->add_hook_before_commit(sub { push @result => 99999 });
    $manager->add_hook_after_commit(sub { push @result => 10 });
    $manager->add_hook_before_commit(sub { push @result => 8 });
    is $manager->remove_hook_after_commit($after), $after, 'returns removed hook (after)';
    is $manager->remove_hook_before_commit($before), $before, 'returns removed hook (before)';
    is $manager->remove_hook_after_commit($after), undef, 'returns undef if not removed';
    is $manager->remove_hook_before_commit($before), undef, 'returns undef if not removed';
    $manager->txn_commit();
    is_deeply \@result, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10], 'should removed specified hooks'
        or diag explain \@result;
};

subtest 'failed to commit' => sub {
    my $dbh = create_mock_dbh();
    $dbh->set_method(commit => sub { die 'something wrong' });

    my $manager = DBIx::TransactionManager::Extended->new($dbh);

    my @result;
    $manager->txn_begin();
    $manager->add_hook_before_commit(sub { push @result => 1 });
    $manager->add_hook_after_commit(sub { push @result => 3 });
    $manager->add_hook_before_commit(sub { push @result => 2 });
    $manager->add_hook_after_commit(sub { push @result => 4 });
    eval {
        $manager->txn_commit();
    };
    like $@, qr/^something wrong/, 'dead';
    is_deeply \@result, [1, 2], 'should not run after hooks'
        or diag explain \@result;

    $dbh->set_method(commit => sub { 1 });
    $manager->txn_begin(); $manager->txn_commit();
    is_deeply \@result, [1, 2], 'hooks are removed after commit'
        or diag explain \@result;
};

subtest 'dead at before commit hook' => sub {
    my $dbh = create_mock_dbh();
    my $manager = DBIx::TransactionManager::Extended->new($dbh);

    $manager->txn_begin();
    $manager->add_hook_before_commit(sub { die 'something wrong' });
    eval {
        $manager->txn_commit();
    };
    like $@, qr/^something wrong/, 'dead';
    is $dbh->called_count('commit'),   0, 'not commited';
    is $dbh->called_count('rollback'), 1, 'rollbacked';

    $manager->txn_begin();
    eval {
        $manager->txn_commit();
    };
    is $@, '', 'hooks are removed after commit';
};

subtest 'dead at after commit hook' => sub {
    my $dbh = create_mock_dbh();
    my $manager = DBIx::TransactionManager::Extended->new($dbh);

    $manager->txn_begin();
    $manager->add_hook_after_commit(sub { die 'something wrong' });
    eval {
        $manager->txn_commit();
    };
    like $@, qr/^something wrong/, 'dead';
    is $dbh->called_count('commit'),   1, 'commited';
    is $dbh->called_count('rollback'), 0, 'not rollbacked';

    $manager->txn_begin();
    eval {
        $manager->txn_commit();
    };
    is $@, '', 'hooks are removed after commit';
};

subtest 'cycle calls' => sub {
    my $dbh = create_mock_dbh();
    my $manager = DBIx::TransactionManager::Extended->new($dbh);

    for my $type1 (qw/before after/) {
        my $method1 = "add_hook_${type1}_commit";
        for my $type2 (qw/before after/) {
            my $method2 = "add_hook_${type2}_commit";

            my $i = 1;
            my $called = 0;
            my $code; $code = sub {
                $manager->txn_begin();
                $manager->$method1(sub {
                    $called++;
                    $manager->txn_begin();
                    $manager->$method2(sub {
                        $called++;
                        $code->() if $i++ < 4;
                    });
                    $manager->txn_commit();
                });
                $manager->txn_commit();
            };
            $code->();
            undef $code;

            is $called, 8, "should run $type1->$type2->$type1->... hooks"
        }
    }
};

done_testing;
