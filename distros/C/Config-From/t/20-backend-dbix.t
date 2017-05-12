#!/usr/bin/env perl
use strict;
use warnings;
use Test::More 'no_plan';
use FindBin '$Bin';
use lib 't/lib';
use Schema::Config;

use_ok('Config::From::Backend::DBIx');

my $schema = Schema::Config->connect('dbi:SQLite:dbname=:memory:')
    or die "Failed to connect to database";
$schema->deploy;
$schema->_populate;


ok( my $backend = Config::From::Backend::DBIx->new( table => 'Config', schema => $schema ),
    'new backend DBIx');

isa_ok($backend->datas, 'HASH', 'backend');
