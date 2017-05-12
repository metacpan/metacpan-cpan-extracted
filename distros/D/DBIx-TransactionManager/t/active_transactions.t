use strict;
use warnings;
use utf8;
use t::Utils;
use Test::More;
use DBIx::TransactionManager;

my $dbh = t::Utils::setup;
my $tm = DBIx::TransactionManager->new($dbh);

is scalar(@{$tm->active_transactions}), 0;

my $txn = $tm->txn_scope;

is scalar(@{$tm->active_transactions}), 1;
is $tm->active_transactions->[0]->{caller}->[0], 'main';
is $tm->active_transactions->[0]->{caller}->[1], __FILE__;
is $tm->active_transactions->[0]->{caller}->[2], 13;
is $tm->active_transactions->[0]->{pid}        , $$;

    {
        my $txn = $tm->txn_scope;
        is scalar(@{$tm->{active_transactions}}), 2;
        is $tm->active_transactions->[1]->{caller}->[0], 'main';
        is $tm->active_transactions->[1]->{caller}->[1], __FILE__;
        is $tm->active_transactions->[1]->{caller}->[2], 22;
        is $tm->active_transactions->[1]->{pid}        , $$;
        $txn->commit;
    }

is scalar(@{$tm->active_transactions}), 1;
is $tm->active_transactions->[0]->{caller}->[0], 'main';
is $tm->active_transactions->[0]->{caller}->[1], __FILE__;
is $tm->active_transactions->[0]->{caller}->[2], 13;
is $tm->active_transactions->[0]->{pid}        , $$;

    $tm->txn_begin;

    is scalar(@{$tm->active_transactions}), 2;
    is $tm->active_transactions->[1]->{caller}->[0], 'main';
    is $tm->active_transactions->[1]->{caller}->[1], __FILE__;
    is $tm->active_transactions->[1]->{caller}->[2], 37;
    is $tm->active_transactions->[1]->{pid}        , $$;

    $tm->txn_commit;

    $tm->txn_begin;

    is scalar(@{$tm->active_transactions}), 2;
    is $tm->active_transactions->[1]->{caller}->[0], 'main';
    is $tm->active_transactions->[1]->{caller}->[1], __FILE__;
    is $tm->active_transactions->[1]->{caller}->[2], 47;
    is $tm->active_transactions->[1]->{pid}        , $$;

    $tm->txn_rollback;

$txn->rollback;

is scalar(@{$tm->active_transactions}), 0;

$txn = $tm->txn_scope;

is scalar(@{$tm->active_transactions}), 1;
is $tm->active_transactions->[0]->{caller}->[0], 'main';
is $tm->active_transactions->[0]->{caller}->[1], __FILE__;
is $tm->active_transactions->[0]->{caller}->[2], 61;
is $tm->active_transactions->[0]->{pid}        , $$;

    {
        package Mock;
        sub do_txn {
            my $tm = shift;
            my $txn = $tm->txn_scope;

            ::is scalar(@{$tm->active_transactions}), 2;
            ::is $tm->active_transactions->[1]->{caller}->[0], 'Mock';
            ::is $tm->active_transactions->[1]->{caller}->[1], __FILE__;
            ::is $tm->active_transactions->[1]->{caller}->[2], 73;
            ::is $tm->active_transactions->[1]->{pid}        , $$;

            $txn->commit;
        }
    }

    Mock::do_txn($tm);

$txn->commit;
 
is scalar(@{$tm->active_transactions}), 0;

done_testing;

