#!/usr/bin/perl

use strict;
use warnings;
use utf8::all;
use Test::Most;
use Test::FailWarnings;

use DBIx::ParseDSN::Default;
use t::lib::TestUtils;

{
    note( "simple two arg constructed case" );
    isa_ok( my $dsn = DBIx::ParseDSN::Default->new("dbi:Pg:", 'user@bar'),
            "DBIx::ParseDSN::Default" );
    ##
    is( $dsn->driver, "Pg", "two arg dsn; driver" );
    is( $dsn->scheme, "dbi", "two arg dsn; scheme" );
    is( $dsn->database, "bar", "bar arg dsn; database" );
}

{
    note( "complex two arg oracle dsn" );
    ## see: https://metacpan.org/pod/DBD::Oracle#connect
    isa_ok( my $dsn = DBIx::ParseDSN::Default->new
                ('dbi:Oracle:host=foobar;port=1521', 'scott@DB/tiger'),
            "DBIx::ParseDSN::Default" );
    ##
    is( $dsn->driver, "Oracle", "two arg dsn; driver" );
    is( $dsn->scheme, "dbi", "two arg dsn; scheme" );
    is( $dsn->database, "DB", "two arg dsn; database" );
    is( $dsn->port, 1521, "two arg dsn; port" );
    is( $dsn->host, "foobar", "two arg dsn; port" );
}

done_testing;
