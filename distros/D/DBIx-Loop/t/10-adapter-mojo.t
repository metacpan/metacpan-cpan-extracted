#!perl
use 5.008003;
use strict;
use warnings;
use lib 't/lib';
use Test::More;

BEGIN {
    plan skip_all => 'Mojolicious required' unless eval { require Mojo::IOLoop; require Mojo::Promise; 1 };
    plan skip_all => 'DBD::SQLite required' unless eval { require DBD::SQLite; 1 };
}
use AdapterConformance;
use DBIx::Loop::Loop::Mojo;

AdapterConformance::run(DBIx::Loop::Loop::Mojo->new, name => 'Mojo');
done_testing();
