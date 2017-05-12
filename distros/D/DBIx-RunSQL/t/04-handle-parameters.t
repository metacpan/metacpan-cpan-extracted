#!perl -w
use strict;
use Test::More tests => 2;

use DBIx::RunSQL;
use Data::Dumper;

my @received;
{
    no warnings 'redefine';
    sub DBIx::RunSQL::create {
        @received= @_;
    };
};

DBIx::RunSQL->handle_command_line(
    "my-test-app",
);
my ($package,%options)= @received;
is $options{ dsn }, "dbi:SQLite:dbname=db/my-test-app.sqlite", "DSN gets appname used as default";

DBIx::RunSQL->handle_command_line(
    "my-test-app",
    '--dsn' => 'dbi:Magic:',
);
($package,%options)= @received;

is $options{ dsn }, "dbi:Magic:", "DSN gets passed through";
