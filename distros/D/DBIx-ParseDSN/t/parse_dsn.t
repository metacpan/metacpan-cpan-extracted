#!/usr/bin/perl

use strict;
use warnings;
use utf8::all;
use Test::Most;
use Test::FailWarnings;

use DBIx::ParseDSN;

isa_ok( my $dsn = parse_dsn("dbi:Pg:database=foo"), "DBIx::ParseDSN::Default" );

is( $dsn->driver, "Pg", "parse_dsn; driver" );
is( $dsn->scheme, "dbi", "parse_dsn; scheme" );
is( $dsn->database, "foo", "parse_dsn; database" );

## some aliases:
is( $dsn->db, "foo", "parse_dsn; db alias" );
is( $dsn->dbname, "foo", "parse_dsn; dbname alias" );

isa_ok( my $dsn2 = parse_dsn("dbi:Pg:database=foo;host=bar"), "DBIx::ParseDSN::Default" );

is( $dsn2->host, "bar", "dsn2; host" );
is( $dsn2->server, "bar", "dsn2; server alias" );

done_testing;
