#!perl

use strict;
use warnings;
use Test::More qw(no_plan);
use lib 't/tlib';
use Test::DummyDBI;

use DBIx::Migration::Directories;

my $m = DBIx::Migration::Directories->new(
    dbh     => Test::DummyDBI->new, 
    driver  => 'dummy',
    schema  => 'TestSchema',
    base    => 't/tetc',
);

is_deeply([$m->migration_path(0, 4)], [ qw(002.50 2.5-004) ], 'migrate forwards');
is_deeply([$m->migration_path(4, 2.5)], [ qw(004-003 003-02.50) ], 'migrate backwards');
is_deeply([$m->migration_path(1, 1)], [ qw() ], 'same version');

eval { $m->migration_path(1, 0) };
like($@, qr/^No migrations in direction/, 'no migration path');

eval { $m->migration_path(5, 0) };
like($@, qr/^No migrations available/, 'nonexistant version');
