#!perl

BEGIN {
    use Test::More;
    eval "use Test::Compile 0.08";
    Test::More->builder->BAIL_OUT(
        "Test::Compile 0.08 required for testing compilation") if $@;
    all_pm_files_ok();
}

eval { require 'DBIx::TxnInsert' };
diag( "Testing DBICx::TxnInsert $DBICx::TxnInsert::VERSION, Perl $], $^X" );
