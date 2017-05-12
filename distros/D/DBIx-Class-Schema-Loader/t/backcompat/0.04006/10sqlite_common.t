use DBIx::Class::Schema::Loader::Optional::Dependencies
    -skip_all_without => 'test_backcompat';

use strict;
use warnings;
use lib qw(t/backcompat/0.04006/lib);
use dbixcsl_common_tests;
use dbixcsl_test_dir qw/$tdir/;

use Test::More;

eval { require DBD::SQLite };
my $class = $@ ? 'SQLite2' : 'SQLite';

dbixcsl_common_tests->new(
        vendor          => 'SQLite',
        auto_inc_pk     => 'INTEGER NOT NULL PRIMARY KEY',
        dsn             => "dbi:$class:dbname=$tdir/sqlite_test.db",
        user            => '',
        password        => '',
)->run_tests;

END {
    unlink "$tdir/sqlite_test.db" if $ENV{SCHEMA_LOADER_TESTS_BACKCOMPAT};
}
