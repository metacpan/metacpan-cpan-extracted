#!perl -w
use strict;
use Test::More;

use DBIx::RunSQL;
use Data::Dumper;

# Test against a "real" database if we have one:
if( ! eval { require DBD::SQLite;
             require 5.008; # for scalar open
             1;  }) {
    plan skip_all => $@;
    exit;
};

plan tests => 2;

# Redirect STDOUT to a variable
close STDOUT; # sssh
open STDOUT, '>', \my $output;

my $exitcode = DBIx::RunSQL->handle_command_line(
    "my-test-app",
    [
    '--quiet',
    '--dsn' => 'dbi:SQLite:dbname=:memory:',
    '--sql' => <<'SQL',
        create table foo (bar integer, baz varchar);
        insert into foo (bar,baz) values (1,'hello');
        insert into foo (bar,baz) values (2,'world');
        select * from foo;
SQL
    ]
);

isn't $output, '', "We get output if rows are found";

$output = '';
$exitcode = DBIx::RunSQL->handle_command_line(
    "my-test-app",
    [
    '--quiet',
    '--dsn' => 'dbi:SQLite:dbname=:memory:',
    '--sql' => <<'SQL',
        create table foo (bar integer, baz varchar);
        insert into foo (bar,baz) values (1,'hello');
        insert into foo (bar,baz) values (2,'world');
        select * from foo where 1=0;
SQL
    ]
);
is $output, '', "We get no output if no rows are found";

done_testing();