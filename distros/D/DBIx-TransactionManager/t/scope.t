use strict;
use warnings;
use utf8;
use t::Utils;
use Test::More;
use DBIx::TransactionManager;

subtest 'do scope commit' => sub {
    my $dbh = t::Utils::setup;
    my $tm = DBIx::TransactionManager->new($dbh);

    my $txn = $tm->txn_scope;

        $dbh->do("insert into foo (id, var) values (1,'baz')");

    $txn->commit;

    my $row = $dbh->selectrow_hashref('select * from foo');
    is $row->{id},  1;
    is $row->{var}, 'baz';
};
 
subtest 'do scope rollback' => sub {
    my $dbh = t::Utils::setup;
    my $tm = DBIx::TransactionManager->new($dbh);

    my $txn = $tm->txn_scope;

        $dbh->do("insert into foo (id, var) values (2,'boo')");

    $txn->rollback;

    my $row = $dbh->selectrow_hashref('select * from foo');
    ok not $row;
};
 
subtest 'do scope guard for rollback' => sub {
    my $dbh = t::Utils::setup;
    my $tm = DBIx::TransactionManager->new($dbh);

    {
        local $SIG{__WARN__} = sub {};
        my $txn = $tm->txn_scope;
        $dbh->do("insert into foo (id, var) values (3,'bebe')");
    } # do rollback auto.
 
    my $row = $dbh->selectrow_hashref('select * from foo');
    ok not $row;
};


subtest 'do nested scope rollback-rollback' => sub {
    my $dbh = t::Utils::setup;
    my $tm = DBIx::TransactionManager->new($dbh);

    my $txn = $tm->txn_scope;
    {
        my $txn2 = $tm->txn_scope;
            $dbh->do("insert into foo (id, var) values (4,'kumu')");
        $txn2->rollback;
    }
    $dbh->do("insert into foo (id, var) values (5,'kaka')");
    $txn->rollback;

    ok not $dbh->selectrow_hashref('select * from foo');
};

subtest 'do nested scope commit-rollback' => sub {
    my $dbh = t::Utils::setup;
    my $tm = DBIx::TransactionManager->new($dbh);

    my $txn = $tm->txn_scope;
    {
        my $txn2 = $tm->txn_scope;
            $dbh->do("insert into foo (id, var) values (6,'muki')");
        $txn2->commit;
        ok $dbh->selectrow_hashref('select * from foo');
    }
    $dbh->do("insert into foo (id, var) values (7,'mesi')");
    $txn->rollback;

    ok not $dbh->selectrow_hashref('select * from foo');
};

subtest 'do nested scope rollback-commit' => sub {
    my $dbh = t::Utils::setup;
    my $tm = DBIx::TransactionManager->new($dbh);

    {
        local $SIG{__WARN__} = sub {};
        my $txn = $tm->txn_scope;
        {
            my $txn2 = $tm->txn_scope;
                $dbh->do("insert into foo (id, var) values (8,'uso')");
            $txn2->rollback;
        }
        $dbh->do("insert into foo (id, var) values (9,'nani')");
        eval {$txn->commit}; # XXX
        like $@, qr/tried to commit but already rollbacked in nested transaction./;
    }

    my $row = $dbh->selectrow_hashref('select * from foo');
    ok not $dbh->selectrow_hashref('select * from foo');
};

subtest 'do nested scope commit-commit' => sub {
    my $dbh = t::Utils::setup;
    my $tm = DBIx::TransactionManager->new($dbh);

    my $txn = $tm->txn_scope;
    {
        my $txn2 = $tm->txn_scope;
            $dbh->do("insert into foo (id, var) values (10,'ahi')");
        $txn2->commit;
    }
    $dbh->do("insert into foo (id, var) values (11,'uhe')");
    $txn->commit;

    my @rows = $dbh->selectrow_array('select * from foo');
    is scalar(@rows), 2;
};

subtest 'do automatic rollback' => sub {
    my $dbh = t::Utils::setup;
    my $tm = DBIx::TransactionManager->new($dbh);

    my $warn;
    local $SIG{__WARN__} = sub {
        local $SIG{__WARN__} = 'DEFAULT';
        $warn = $_[0]
    };
    {
        my $txn = $tm->txn_scope;
    }
    like($warn, qr/Transaction was aborted without calling an explicit commit or rollback\. \(Guard created at \.?\/?t\/scope.t line 133\)/);
};

subtest 'pass arbitrary caller info' => sub {
    my $dbh = t::Utils::setup;
    my $tm = DBIx::TransactionManager->new($dbh);

    my $warn;
    local $SIG{__WARN__} = sub {
        local $SIG{__WARN__} = 'DEFAULT';
        $warn = $_[0]
    };
    {
        my $txn = $tm->txn_scope( caller => [ "foo", "hoge.pm", 1 ] );
    }
    like($warn, qr/Transaction was aborted without calling an explicit commit or rollback\. \(Guard created at hoge.pm line 1\)/);
};

done_testing;

