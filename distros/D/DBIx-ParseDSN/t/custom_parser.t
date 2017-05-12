#!/usr/bin/perl

use strict;
use warnings;
use utf8::all;
use Test::Most;
use Test::FailWarnings;

{

    package DBIx::ParseDSN::Custom;

    use Moo;
    extends "DBIx::ParseDSN::Default";

    sub names_for_database {
        return qw/bucket/;
    }

    sub is_local { return; }

}

my $dsn = DBIx::ParseDSN::Custom->new("dbi:SQLite:bucket=bar");

isa_ok( $dsn, "DBIx::ParseDSN::Default" );

is( $dsn->database, "bar", "custom database label" );
ok( $dsn->is_remote, "it is remote because it is not local" );

done_testing;
