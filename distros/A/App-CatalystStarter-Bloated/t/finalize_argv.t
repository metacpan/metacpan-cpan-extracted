#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use Test::Most;
use Test::FailWarnings;

use lib 't/lib';
use TestUtils;

use_ok "App::CatalystStarter::Bloated", ":test";

## Check that they arent set when --no prefixed
{
    local %ARGV = test_argv( '--nohtml5' => 1 );

    App::CatalystStarter::Bloated::_finalize_argv();

    cmp_deeply( [@ARGV{qw/-html5 --html5 -h5 --h5/}],
                [(undef)x4], "html5 defaults not set with --no" );

}

## pgpass defaults

## check that pgpass gets initalized with right defaults
{
    local %ARGV = test_argv;

    App::CatalystStarter::Bloated::_finalize_argv();

    cmp_deeply( [@ARGV{qw/-pgpass --pgpass/}],
                [1,1], "pgpass defaults" );

}

## Check that they arent set when --no prefixed
{
    local %ARGV = test_argv( '--nopgpass' => 1 );

    App::CatalystStarter::Bloated::_finalize_argv();

    cmp_deeply( [@ARGV{qw/-pgpass --pgpass/}],
                [(undef)x2], "pgpass flags not set when --no" );

}

## check that dnsfix gets initalized with right defaults
{
    local %ARGV = test_argv;

    App::CatalystStarter::Bloated::_finalize_argv();

    cmp_deeply( [@ARGV{qw/-dsnfix --dsnfix/}],
                [1,1], "dsnfix defaults" );

}

## nodsnfix works
{
    local %ARGV = test_argv( '--nodsnfix' => 1 );

    App::CatalystStarter::Bloated::_finalize_argv();

    cmp_deeply( [@ARGV{qw/-dsnfix --dsnfix/}],
                [(undef)x2], "dsnfix flags not set when --no" );

}


## Models

## check default model name convention
{
    local %ARGV = test_argv( "--model" => "AppNameDB" );

    App::CatalystStarter::Bloated::_finalize_argv();

    cmp_deeply( [@ARGV{qw/-model --model/}],
                [ (cat_name."DB")x2], "model name convention" );

}

## check that explicit model names are preserved
{
    local %ARGV = test_argv( "--model" => "FooDB" );

    App::CatalystStarter::Bloated::_finalize_argv();

    cmp_deeply( [@ARGV{qw/-model --model/}], [ ("FooDB")x2 ],
                "model name not changed when set" );

}

## check that model value 1 is treated correctly
{
    local %ARGV = test_argv( "--model" => 1 );

    App::CatalystStarter::Bloated::_finalize_argv();

    cmp_deeply( [@ARGV{qw/-model --model/}], [ (cat_name."DB")x2 ],
                "model name fixed when value is 1" );

}

## Views

## check that --views are sets up both views
{
    local %ARGV = test_argv( "--views" => 1 );

    ## check that --views trigger both TT and JSON
    delete @ARGV{qw/--TT --JSON/};
    App::CatalystStarter::Bloated::_finalize_argv();

    cmp_deeply( [@ARGV{qw/-TT --TT -JSON --JSON/}],
                [qw/HTML HTML JSON JSON/], "TT and JSON when --views");

}

## check that --views doesnt touch existnig --tt or --json
{
    local %ARGV = test_argv( "--views" => 1, "--TT" => "MyView" );

    ## check that --views trigger both TT and JSON
    delete @ARGV{qw/--JSON -JSON/};
    App::CatalystStarter::Bloated::_finalize_argv();

    cmp_deeply( [@ARGV{qw/-TT --TT -JSON --JSON/}],
                [qw/MyView MyView JSON JSON/], "TT and JSON when --views");

}

## DSN

## dsn set from --model
{
    local %ARGV = test_argv( "--model" => "dbi:Pg:dbname=foo" );

    App::CatalystStarter::Bloated::_finalize_argv();

    cmp_deeply( [@ARGV{qw/-model --model/}],
                [ (cat_name."DB")x2 ], "dsn set from model name" );

    cmp_deeply( [@ARGV{qw/-dsn --dsn/}],
                [qw/dbi:Pg:dbname=foo/x2], "dsn set from --model" );

}

## check that dbuser and dbpass initializes to empty strings
{
    local %ARGV = test_argv;

    App::CatalystStarter::Bloated::_finalize_argv();

    is( $ARGV{'--dbuser'}, "", "dbuser defaults to empty string" );
    is( $ARGV{'--dbpass'}, "", "dbuser defaults to empty string" );

}

## a bad dsn that gets fixed
{
    local %ARGV = test_argv( "--dsn" => "pg:dbname=foo" );

    App::CatalystStarter::Bloated::_finalize_argv();

    cmp_deeply( [@ARGV{qw/-dsn --dsn/}],
                [qw/dbi:Pg:dbname=foo/x2], "dsn corrected" );

    ## also setting dsn should set --model
    cmp_deeply(
        [@ARGV{qw/-model --model/}],
        [ (cat_name."DB")x2 ],
        "model triggered by dsn"
    );

}

## nodsnfix prevents fixing
{
    local %ARGV = test_argv( "--dsn" => "foo",
                             "--nodsnfix" => 1 );

    App::CatalystStarter::Bloated::_finalize_argv();

    cmp_deeply( [@ARGV{qw/-dsn --dsn/}],
                [qw/foo/x2],
                "dsn not corrected when instructed not to" );
}

## --schema related

## a model triggers --schema that gets fixed
{
    local %ARGV = test_argv( "--model" => "1" );

    App::CatalystStarter::Bloated::_finalize_argv();

    cmp_deeply(
        [@ARGV{qw/-schema --schema/}],
        [ (cat_name."::Schema")x2 ],
        "schema triggered by model"
    );

}

## a specified --schema is untouched
{
    local %ARGV = test_argv( "--model" => "1",
                             "--schema" => "Foo" );

    App::CatalystStarter::Bloated::_finalize_argv();

    cmp_deeply(
        [@ARGV{qw/-schema --schema/}],
        [qw/Foo/x2],
        "valid schema is ok"
    );

}

done_testing;
