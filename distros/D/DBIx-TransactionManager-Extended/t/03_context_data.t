use strict;
use warnings;

use Test::More 0.98;
use t::Util;

use DBIx::TransactionManager::Extended;

subtest 'cannot call out of the transaction' => sub {
    my $dbh = create_mock_dbh();
    my $manager = DBIx::TransactionManager::Extended->new($dbh);
    eval { $manager->context_data() };
    like $@, qr/^\QCANNOT call context_data out of the transaction/, 'dead';
};

subtest 'reset context data at commit/rollback' => sub {
    my $dbh = create_mock_dbh();
    my $manager = DBIx::TransactionManager::Extended->new($dbh);

    $manager->txn_begin();
    my $context_data = $manager->context_data;
    $context_data->{c}++;
    $manager->add_hook_before_commit(sub {
        my $context_data = shift;
        is_deeply $context_data, { c => 1 }, 'should not reset the context data at before commit hook is called';
    });
    $manager->add_hook_after_commit(sub {
        my $context_data = shift;
        is_deeply $context_data, { c => 1 }, 'should not reset the context data at after commit hook is called';
    });
    $manager->txn_commit();
    is_deeply $context_data, {}, 'should reset the context data at commit';

    $manager->txn_begin();
    $manager->context_data->{c}++;
    $manager->txn_rollback();
    is_deeply $context_data, {}, 'should reset the context data at rollback';

    $manager->txn_begin();
    $manager->txn_begin();
    $manager->context_data->{c}++;
    $manager->txn_commit();
    is_deeply $context_data, { c => 1 }, 'should not reset the context data at commit on nested transaction';
    $manager->txn_commit();
    is_deeply $context_data, {}, 'should reset the context data at commit all transactions';
};

subtest 'failed to commit' => sub {
    my $dbh = create_mock_dbh();
    $dbh->set_method(commit => sub { die 'something wrong' });

    my $manager = DBIx::TransactionManager::Extended->new($dbh);

    $manager->txn_begin();
    my $context_data = $manager->context_data;
    $context_data->{c}++;
    eval {
        $manager->txn_commit();
    };
    like $@, qr/^something wrong/, 'dead' or diag $@;
    is_deeply $context_data, {}, 'should reset the context data at failed to commit';
};

done_testing;
