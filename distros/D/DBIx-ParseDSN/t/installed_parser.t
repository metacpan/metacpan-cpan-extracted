#!/usr/bin/perl

use strict;
use warnings;
use utf8::all;
use Test::Most;
use Test::FailWarnings;
use Module::Load::Conditional qw/can_load/;

use DBIx::ParseDSN;

require "t/lib/Foo.pm";

## an already loaded namespace
{
    isa_ok( my $dsn = parse_dsn("dbi:Foo:database=foo"), "DBIx::ParseDSN::Foo" );
    ok( $dsn->i_am_a_custom_driver, "custom driver loaded" );
    ##
    is( $dsn->driver, "Foo", "parse_dsn; driver" );
    is( $dsn->scheme, "dbi", "parse_dsn; scheme" );
    is( $dsn->database, "foo", "parse_dsn; database" );
}

## a namespace that needs loading
{
    local @INC = ('t/lib', @INC);
    isa_ok( my $dsn = parse_dsn("dbi:Bar:database=foo"), "DBIx::ParseDSN::Bar" );
    ok( $dsn->i_am_also_a_custom_driver, "custom driver loaded" );
    ##
    is( $dsn->driver, "Bar", "parse_dsn; driver" );
    is( $dsn->scheme, "dbi", "parse_dsn; scheme" );
    is( $dsn->database, "foo", "parse_dsn; database" );
}

done_testing;
