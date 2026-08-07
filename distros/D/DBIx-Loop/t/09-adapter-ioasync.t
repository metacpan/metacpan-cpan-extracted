#!perl
use 5.008003;
use strict;
use warnings;
use lib 't/lib';
use Test::More;

BEGIN {
    plan skip_all => 'IO::Async required' unless eval { require IO::Async::Loop; 1 };
    plan skip_all => 'DBD::SQLite required' unless eval { require DBD::SQLite; 1 };
}
use AdapterConformance;
use DBIx::Loop::Loop::IOAsync;

AdapterConformance::run(DBIx::Loop::Loop::IOAsync->new, name => 'IOAsync');
done_testing();
