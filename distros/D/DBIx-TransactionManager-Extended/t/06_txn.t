use strict;
use warnings;

use Test::More 0.98;
use FindBin;
use lib "$FindBin::Bin/lib";
use t::Util;
use t::Mock;

use DBIx::TransactionManager::Extended;
use DBIx::TransactionManager::Extended::Txn;

{
    my $txn = DBIx::TransactionManager::Extended->new(create_mock_dbh())->txn_scope();
    isa_ok $txn, 'DBIx::TransactionManager::Extended::Txn';
    $txn->rollback();
}

subtest commit => sub {
    my $dbh = create_mock_dbh();
    my $manager = DBIx::TransactionManager::Extended->new($dbh);
    my $txn = $manager->txn_scope();
    is $dbh->called_count('commit'), 0, 'not yet commited';
    $txn->commit();
    is $dbh->called_count('commit'), 1, 'success to commit';
};

subtest rollback => sub {
    my $dbh = create_mock_dbh();
    my $manager = DBIx::TransactionManager::Extended->new($dbh);
    my $txn = $manager->txn_scope();
    is $dbh->called_count('rollback'), 0, 'not yet rollbacked';
    $txn->rollback();
    is $dbh->called_count('rollback'), 1, 'success to rollback';
};

subtest 'DESTROY' => sub {
    my $dbh = create_mock_dbh();
    my $manager = DBIx::TransactionManager::Extended->new($dbh);

    my @warn;
    local $SIG{__WARN__} = sub { push @warn => @_ };

    my ($file, $line);
    {
        my $txn = $manager->txn_scope(); ($file, $line) = (__FILE__, __LINE__);
        is $dbh->called_count('rollback'), 0, 'not yet rollbacked';
    }
    is $dbh->called_count('rollback'), 1, 'success to rollback';
    is @warn, 1, 'a warning was found';
    like $warn[0], qr/Guard created at $file line $line/, 'caller is collect';

    subtest 'modified caller' => sub {
        my $dbh = create_mock_dbh();
        my $manager = DBIx::TransactionManager::Extended->new($dbh);
        @warn = ();
        $manager->txn_scope(caller => [__PACKAGE__, '/path/to/caller.pl', 999]);
        is @warn, 1, 'a warning was found';
        like $warn[0], qr!Guard created at /path/to/caller.pl line 999!, 'caller is modified'
            or diag explain \@warn;
    };
};

subtest context_data => sub {
    my $dbh = create_mock_dbh();
    my $manager = DBIx::TransactionManager::Extended->new($dbh);
    my $txn = $manager->txn_scope();
    is $txn->context_data(), $manager->context_data(), 'should equal each addresses';
    $txn->commit();
};

subtest 'add/remove hooks' => sub {
    my @methods = qw/
        add_hook_after_commit
        add_hook_before_commit
        remove_hook_after_commit
        remove_hook_before_commit
    /;
    my $manager = t::Mock->new('DBIx::TransactionManager::Extended' => {
        txn_begin  => sub {},
        txn_commit => sub {},
        map { $_ => sub {} } @methods
    });

    for my $method (@methods) {
        is $manager->called_count($method), 0, "$method is not yet called";
        my $txn = DBIx::TransactionManager::Extended::Txn->new($manager);
        $txn->$method();
        $txn->commit();
        is $manager->called_count($method), 1, "$method is called at once";
    }
};

done_testing();
