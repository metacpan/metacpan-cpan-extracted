use strict;
use warnings;
use t::Utils;
use Test::More;
use DBIx::TransactionManager;

subtest 'do basic transaction' => sub {
    my $dbh = t::Utils::setup;
    my $tm = DBIx::TransactionManager->new($dbh);

    $tm->txn_begin;
    
        $dbh->do("insert into foo (id, var) values (1,'baz')");

    $tm->txn_commit;

    my $row = $dbh->selectrow_hashref('select * from foo');
    is $row->{id},  1;
    is $row->{var}, 'baz';
};
 
subtest 'do rollback' => sub {
    my $dbh = t::Utils::setup;
    my $tm = DBIx::TransactionManager->new($dbh);

    $tm->txn_begin;
    
        $dbh->do("insert into foo (id, var) values (2,'bal')");

    $tm->txn_rollback;

    my $row = $dbh->selectrow_hashref('select * from foo');
    ok not $row;
};
 
subtest 'in_transaction' => sub {
    my $dbh = t::Utils::setup;
    my $tm = DBIx::TransactionManager->new($dbh);

    ok not $tm->in_transaction;
    $tm->txn_begin;
    
    my $info = $tm->in_transaction;
    ok $info;
    is $info->{pid}, $$;
    is $info->{caller}->[1], __FILE__;
    is $info->{caller}->[2], 41;

    $tm->txn_commit;

    ok not $tm->in_transaction;
};

subtest "don't block subsequent calls upon failing to execute begin_work (RaiseError = 1)" => sub {
    SKIP: {
        eval { require Test::MockObject::Extends };
        if ($@) {
            skip "Test requires Test::MockObject::Extends", 4;
        }
        my $dbh = t::Utils::setup;
        my $mock = Test::MockObject::Extends->new( $dbh );
        $mock->mock( begin_work => sub {
            die "DBD doesn't implement AutoCommit or something"
        } );

        my $tm = DBIx::TransactionManager->new($mock);

        # should fail
        eval {
            $tm->txn_begin;
        };
        like $@, qr/DBD doesn't implement AutoCommit or something/;

        # above call to txn_begin should not have changed active_transactions
        ok ! $tm->in_transaction, "Should not be in transaction";
    }
};

subtest "don't block subsequent calls upon failing to execute begin_work (RaiseError = 0)" => sub {
    SKIP: {
        eval { require Test::MockObject::Extends };
        if ($@) {
            skip "Test requires Test::MockObject::Extends", 4;
        }
        my $dbh = t::Utils::setup;

        my $mock = Test::MockObject::Extends->new( $dbh );
        $mock->mock( begin_work => sub { 0 } );

        my $tm = DBIx::TransactionManager->new($mock);

        # should fail
        $tm->txn_begin;

        # above call to txn_begin should not have changed active_transactions
        ok ! $tm->in_transaction, "Should not be in transaction";
    }
};

subtest 'do basic transaction with AutoCommit: 0' => sub {
    my $dbh = t::Utils::setup;
    $dbh->{AutoCommit} = 0;
    my $tm = DBIx::TransactionManager->new($dbh);

    $tm->txn_begin;
    
        $dbh->do("insert into foo (id, var) values (666,'baz')");

    $tm->txn_commit;

    my $row = $dbh->selectrow_hashref('select * from foo where id = 666');
    is $row->{id},  666;
    is $row->{var}, 'baz';

    $dbh->disconnect;
};

subtest 'do basic transaction with AutoCommit: 0 and rollback' => sub {
    my $dbh = t::Utils::setup;
    $dbh->{AutoCommit} = 0;
    my $tm = DBIx::TransactionManager->new($dbh);

    $tm->txn_begin;
    
        $dbh->do("insert into foo (id, var) values (666,'baz')");

    $tm->txn_rollback;

    ok not $dbh->selectrow_hashref('select * from foo where id = 666');

    $dbh->disconnect;
};

done_testing;


