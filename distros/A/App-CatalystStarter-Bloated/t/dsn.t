#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use Test::Most;
# use Test::FailWarnings;

use Path::Tiny;

use lib 't/lib';
use TestUtils;

use_ok "App::CatalystStarter::Bloated", ":test";

## makes it o so more convenient
note("prepare_dsn");
local *prepare_dsn = *App::CatalystStarter::Bloated::_prepare_dsn;

{

    ## not testing .pgpass functionality here
    local $ENV{HOME} = Path::Tiny->tempdir;

    is( prepare_dsn( "Pg" ), "dbi:Pg:", "bare driver name" );
    is( prepare_dsn( "dbi:Pg" ), "dbi:Pg:", "lacking 2nd :" );
    is( prepare_dsn( "dBi:Pg" ), "dbi:Pg:", "bad case in dbi" );
    is( prepare_dsn( "Pg:dbname=foo" ), "dbi:Pg:dbname=foo", "missing leading dbi:" );
    is( prepare_dsn( ":Pg" ), "dbi:Pg:", "missing leading dbi" );

    ## some wrong cases
    is( prepare_dsn( "pg" ), "dbi:Pg:", "mis-case'd driver name 1" );
    is( prepare_dsn( "dbi:PG" ), "dbi:Pg:", "mis-case'd driver name 2" );
    is( prepare_dsn( "dBi:pG" ), "dbi:Pg:", "mis-case'd driver name 3" );
    is( prepare_dsn( "PG:dbname=foo" ), "dbi:Pg:dbname=foo", "mis-case'd driver name 4" );
    is( prepare_dsn( ":pg" ), "dbi:Pg:", "mis-case'd driver name 5" );

}

{
    local %ARGV = test_argv "--nodsnfix" => 1;
    is( prepare_dsn( "Pg" ), "Pg", "dsn left untouched with --nodsnfix" );
}


note( "parse_dbi_dsn" );
local *parse_dbi_dsn = *App::CatalystStarter::Bloated::_parse_dbi_dsn;

cmp_deeply(
    {parse_dbi_dsn("database=foo;host=bar;port=1234")},
    { database => "foo", host => "bar", port => 1234 },
    "plain values for db, host and port"
);

cmp_deeply(
    {parse_dbi_dsn("dbname=foo;host=bar;port=2345")},
    { database => "foo", host => "bar", port => 2345 },
    "database variation 1: dbname"
);

cmp_deeply(
    {parse_dbi_dsn("db=foo;host=bar;port=3456")},
    { database => "foo", host => "bar", port => 3456 },
    "database variation 2: db"
);

cmp_deeply(
    {parse_dbi_dsn("")},
    { database => undef, host => undef, port => undef },
    "empty string dsn"
);

cmp_deeply(
    {parse_dbi_dsn("db=foo;host=bar;port=3456;foo=bar;baz=test")},
    { database => "foo", host => "bar", port => 3456, foo => "bar", baz => "test" },
    "unknown parameters included"
);

is(
    parse_dbi_dsn(),
    undef,
    "missing dsn"
);

note("parse_dsn");
local *parse_dsn = *App::CatalystStarter::Bloated::_parse_dsn;

cmp_deeply(
    {parse_dsn("dbi:Pg:database=foo;host=bar;port=1234")},
    { driver => "Pg", scheme => "dbi", attr_string => undef,
      database => "foo", host => "bar", port => 1234 },
    "Pg example, plain values for db, host and port"
);

cmp_deeply(
    {parse_dsn("dbi:mysql:db=foo;host=bar;port=1234")},
    { scheme => "dbi", driver => "mysql", attr_string => undef,
      database => "foo", host => "bar", port => 1234 },
    "mysql example, plain values for db, host and port"
);

note("fixing case");

cmp_deeply(
    {parse_dsn("dbi:pg:database=foo;host=bar;port=1234")},
    { driver => "Pg", scheme => "dbi", attr_string => undef,
      database => "foo", host => "bar", port => 1234 },
    "wrong driver case, otherwise plain values for db, host and port"
);

cmp_deeply(
    {parse_dsn("dbi:MySQL:database=foo;host=bar;port=1234")},
    { driver => "mysql", scheme => "dbi", attr_string => undef,
      database => "foo", host => "bar", port => 1234 },
    "wrong driver case 2, plain values for db, host and port"
);

note( "hash to string" );

local *dsn_hash_to_dsn_string =
    *App::CatalystStarter::Bloated::_dsn_hash_to_dsn_string;

subtest "dsn hash to string" => sub {

    my %test_cases = (
        "dbi:Pg:database=foo;host=bar;port=1234" =>
            "complete, no defaults",
        "dbi:Pg:db=bar" => "db only",
    );

    plan tests => scalar keys %test_cases;

    while ( my($dsn,$description) = each %test_cases ) {

        ## because the order will be random, the dsn must be parsed
        ## again to ensure its equal, or equivalent rather
        my %dsn_hash = parse_dsn( $dsn );
        my $dsn_1 = dsn_hash_to_dsn_string( %dsn_hash );
        my %dsn_hash_there_and_back_again = parse_dsn( $dsn_1 );

        note( "$dsn => $dsn_1" );

        cmp_deeply(
            \%dsn_hash,
            \%dsn_hash_there_and_back_again,
            $description . " (" . $dsn . ")"
        );
    }

};

done_testing;
