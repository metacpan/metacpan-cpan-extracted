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

my $dsn = 'dbi:SQLite:dbname=:memory:';

my $lives = eval {
    DBIx::RunSQL->create(
       verbose => 0,
       dsn     => $dsn,
       sql     => 't/rt77378.sql',
    );
    1
};
ok $lives, "We can parse triggers (RT 77378)"
    or diag $@;