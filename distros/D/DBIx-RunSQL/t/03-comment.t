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

plan tests => 2;
my @statements;
my $test_dbh = DBIx::RunSQL->create(
    dsn     => 'dbi:SQLite:dbname=:memory:',
    sql     => 't/trigger.sql',
    verbose_handler  => sub { push @statements, $_[0] },
    verbose => 1,
);

unlike $statements[0], qr/commented-out/, "Commented out things that look like statements get filtered";
like $statements[0], qr/-- SECRET PRAGMA #foo/, "Comments survive parsing";
