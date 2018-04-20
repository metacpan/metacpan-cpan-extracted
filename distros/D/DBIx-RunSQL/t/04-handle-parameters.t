#!perl -w
use strict;
use Test::More tests => 7;

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
    ['--dsn' => 'dbi:Magic:'],
);
($package,%options)= @received;

is $options{ dsn }, "dbi:Magic:", "DSN gets passed through";

# Test the invocation styles for SQL
DBIx::RunSQL->handle_command_line(
    "my-test-app",
    ['--sql' => 'sql 1', "some more stuff that's ignored"],
);
($package,%options)= @received;

is ${$options{ sql }}, "sql 1", "Explicit SQL gets returned";

DBIx::RunSQL->handle_command_line(
    "my-test-app",
    ['--', 'sql 2 on command line'],
);
($package,%options)= @received;

is ${$options{ sql }}, "sql 2 on command line", "SQL on the command line gets returned";


{ open *STDIN, '<', \'sql from STDIN';
DBIx::RunSQL->handle_command_line(
    "my-test-app",
    ['--'],
);
($package,%options)= @received;
};
ok !$options{ sql }, "We got no SQL string";
ok $options{ fh }, "We'll read sql from STDIN";

{ open *STDIN, '<', \'sql from STDIN 2';
DBIx::RunSQL->handle_command_line(
    "my-test-app",
    ['--', "some SQL"],
);
($package,%options)= @received;
};
is ${$options{ sql }}, "some SQL", "We don't read from STDIN if we get other stuff";
