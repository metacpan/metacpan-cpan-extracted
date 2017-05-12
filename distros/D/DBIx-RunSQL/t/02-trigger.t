#!perl -w
use strict;
use Test::More;

use DBIx::RunSQL;

my $can_run = eval {
    require DBD::SQLite;
    1
};

if (not $can_run) {
    plan skip_all => "SQLite not installed";
}

plan tests => 1;
my $lives = eval {
    my $test_dbh = DBIx::RunSQL->create(
        dsn     => 'dbi:SQLite:dbname=:memory:',
        sql     => 't/trigger.sql',
        #verbose => 1,
    );
    1;
};
my $err = $@;
ok $lives, "We can parse triggers"
    or diag $err;

