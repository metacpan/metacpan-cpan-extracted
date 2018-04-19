#!/usr/bin/env perl
#
# This program uses Test::Database::Migrator to test using Postgres.
#
# This way Test::Database::Migrator exercises both Database::Migrator and
# Database::Migrator::Pg.
#
# As it depends on Postgres available to run, it's not run automatically.
# However it is still possibly useful for developers.

package MyMigrator;

use strict;
use warnings;

use Moose;

extends 'Database::Migrator::Pg';

has '+database' => (
    default => 'test',
);

has '+host' => (
    default => '127.0.0.1',
);

has '+port' => (
    default => 5432,
);

has '+username' => (
    default => 'test',
);

has '+password' => (
    default => 'test',
);

has '+verbose' => (
    default => 1,
);

1;

package main;

use strict;
use warnings;

use Test::Database::Migrator ();
use Test::More;

sub main {
    my $migrator = Test::Database::Migrator->new(
        class => 'MyMigrator',
    );

    $migrator->run_tests;

    done_testing();
    return 1;
}

exit(main() ? 0 : 1);
