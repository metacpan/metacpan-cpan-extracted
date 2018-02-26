#!perl -w
use strict;
use Test::More;

use DBIx::RunSQL;
use Data::Dumper;

# Test against a "real" database if we have one:
if( ! eval { require DBD::SQLite; 1 }) {
    plan skip_all => $@;
    exit;
};

plan tests => 1;

# Redirect STDOUT to a variable
close STDOUT; # sssh
open STDOUT, '>', \my $output;

my $exitcode = DBIx::RunSQL->handle_command_line(
    "my-test-app",
    [
    '--bool',
    '--dsn' => 'dbi:SQLite:dbname=:memory:',
    '--sql' => <<'SQL',
        create table foo (bar integer, baz varchar);
        insert into foo (bar,baz) values (1,'hello');
        insert into foo (bar,baz) values (2,'world');
        select * from foo;
SQL
    ]
);

is $exitcode, 1, "We get a nonzero exit code if a row gets selected with --bool"
    or diag $output;

done_testing();