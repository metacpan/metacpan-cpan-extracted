#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use Test::Most;
use Test::FailWarnings;

use_ok "App::CatalystStarter::Bloated", ":test";

use lib 't/lib';
use TestUtils;

note( "parse .pgpass" );
{

    local $ENV{HOME} = "t/lib";

    cmp_deeply(
        [App::CatalystStarter::Bloated::_parse_pgpass()],
        [
            {
                host => "localhost",
                port => 5432,
                database => "thedb",
                user => "user",
                pass => "pass",
            },
            {
                host => "someserver",
                port => 5433,
                database => "otherdb",
                user => "user2",
                pass => "pass2",
            },
        ],
        ".pgpass parsed"
    );

}

note( "pgpass entry to dsn" );
is( App::CatalystStarter::Bloated::_pgpass_entry_to_dsn
    (
        {host=>"foo", port=>5433, database=>"bar"}
    ),
    "dbi:Pg:database=bar;host=foo;port=5433",
    "pgpass with no defaults"
);

is( App::CatalystStarter::Bloated::_pgpass_entry_to_dsn
    (
        {host=>"localhost.localdomain", port=>5432, database=>"bar"}
    ),
    "dbi:Pg:database=bar",
    "pgpass with localhost and default port"
);

is( App::CatalystStarter::Bloated::_pgpass_entry_to_dsn
    (
        {host=>"localhost", port=>5432, database=>"bar"}
    ),
    "dbi:Pg:database=bar",
    "pgpass with localhost and default port #2"
);

done_testing;
