#!perl
use 5.008003;
use strict;
use warnings;
use lib 't/lib';
use Test::More;

BEGIN {
    plan skip_all => 'AnyEvent required' unless eval { require AnyEvent; 1 };
    plan skip_all => 'DBD::SQLite required' unless eval { require DBD::SQLite; 1 };
}
use AdapterConformance;
use DBIx::Loop::Loop::AnyEvent;

AdapterConformance::run(DBIx::Loop::Loop::AnyEvent->new, name => 'AnyEvent');
done_testing();
