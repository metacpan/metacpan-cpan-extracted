#!/usr/bin/perl

use strict;
use warnings;
use utf8::all;
use Test::Most;
use Test::FailWarnings;

use DBIx::ParseDSN;

use lib 't/lib';

my @test_dsns = qw{
dbi:ODBC:server=$IP;port=$PORT;database=$DBNAME;driver=FreeTDS;tds_version=8.0
dbi:Sybase:server=$IP:$PORT;database=$DBNAME
dbi:mysql:database=dbic_test;host=127.0.0.1
dbi:Pg:database=dbic_test;host=127.0.0.1
dbi:Firebird:dbname=/var/lib/firebird/2.5/data/dbic_test.fdb
dbi:InterBase:dbname=/var/lib/firebird/2.5/data/dbic_test.fdb
dbi:Oracle://localhost:1521/XE
dbi:ADO:PROVIDER=sqlncli10;SERVER=tcp:172.24.2.10;MARSConnection=True;InitialCatalog=CIS;UID=cis_web;PWD=...;DataTypeCompatibility=80;
dbi:ODBC:Driver=Firebird;Dbname=/var/lib/firebird/2.5/data/hlaghdb.fdb
dbi:InterBase:db=/var/lib/firebird/2.5/data/hlaghdb.fdb
dbi:Firebird:db=/var/lib/firebird/2.5/data/hlaghdb.fdb
  };

my @expected_spilts = (
    [qw(dbi ODBC server=$IP;port=$PORT;database=$DBNAME;driver=FreeTDS;tds_version=8.0)],
    [qw(dbi Sybase server=$IP:$PORT;database=$DBNAME)],
    [qw(dbi mysql database=dbic_test;host=127.0.0.1)],
    [qw(dbi Pg database=dbic_test;host=127.0.0.1)],
    [qw(dbi Firebird dbname=/var/lib/firebird/2.5/data/dbic_test.fdb)],
    [qw(dbi InterBase dbname=/var/lib/firebird/2.5/data/dbic_test.fdb)],
    [qw(dbi Oracle //localhost:1521/XE)],
    [qw(dbi ADO PROVIDER=sqlncli10;SERVER=tcp:172.24.2.10;MARSConnection=True;InitialCatalog=CIS;UID=cis_web;PWD=...;DataTypeCompatibility=80;)],
    [qw(dbi ODBC Driver=Firebird;Dbname=/var/lib/firebird/2.5/data/hlaghdb.fdb)],
    [qw(dbi InterBase db=/var/lib/firebird/2.5/data/hlaghdb.fdb)],
    [qw(dbi Firebird db=/var/lib/firebird/2.5/data/hlaghdb.fdb)],
);

for ( 0..$#test_dsns ) {

    cmp_deeply(
        [ DBIx::ParseDSN::_split_dsn($test_dsns[$_]) ],
        $expected_spilts[$_],
        "dsn_split " . $test_dsns[$_]
    );

}

done_testing;
