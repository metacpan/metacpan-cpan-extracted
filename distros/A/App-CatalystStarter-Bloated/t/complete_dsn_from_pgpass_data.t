#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use Test::Most;
use Test::FailWarnings;

use lib 't/lib';
use TestUtils;

use_ok "App::CatalystStarter::Bloated", ":test";

local $ENV{HOME} = "t/lib";

{

    local %ARGV = test_argv;

    App::CatalystStarter::Bloated::_complete_dsn_from_pgpass("dbi:Pg:db=thedb");

    subtest "user and pass set, 1st entry" => sub {

        plan tests => 2;

        is( $ARGV{'--dbuser'}, "user", "dbuser set from pgpass" );
        is( $ARGV{'--dbpass'}, "pass", "dbpass set from pgpass" );

    };

};

{

    local %ARGV = test_argv;

    App::CatalystStarter::Bloated::_complete_dsn_from_pgpass
          ("dbi:Pg:host=someserver;db=otherdb;port=5433");

    subtest "user and pass set, 2nd entry" => sub {

        plan tests => 2;

        is( $ARGV{'--dbuser'}, "user2", "dbuser set from pgpass" );
        is( $ARGV{'--dbpass'}, "pass2", "dbpass set from pgpass" );

    };

};

# bare minimum #1
{

    local %ARGV = test_argv;

    my $dsn = App::CatalystStarter::Bloated::_complete_dsn_from_pgpass
        ("dbi:Pg:port=5433");

    my %dsn = App::CatalystStarter::Bloated::_parse_dsn($dsn);

    cmp_deeply(
        [@dsn{qw/database host port/}],
        [qw/otherdb someserver 5433/],
        "dsn completed" );

    subtest "user and pass set from port only" => sub {

        plan tests => 2;

        is( $ARGV{'--dbuser'}, "user2", "dbuser set from pgpass" );
        is( $ARGV{'--dbpass'}, "pass2", "dbpass set from pgpass" );

    };

};


done_testing;
