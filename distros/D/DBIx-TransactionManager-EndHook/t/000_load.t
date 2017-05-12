#!perl -w
use strict;
use Test::More tests => 1;

BEGIN {
    use_ok 'DBIx::TransactionManager::EndHook';
}

diag "Testing DBIx::TransactionManager::EndHook/$DBIx::TransactionManager::EndHook::VERSION";
