use strict;
use Test::More 0.98;

use_ok $_ for qw(
    DBIx::TransactionManager::Extended
    DBIx::TransactionManager::Extended::Compat
    DBIx::TransactionManager::Extended::Txn
);

done_testing;

