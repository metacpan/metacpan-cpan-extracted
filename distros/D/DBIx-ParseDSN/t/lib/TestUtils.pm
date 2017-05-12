package t::lib::TestUtils;

use utf8::all;
use strict;
use warnings;
use autodie;

use base 'Exporter';
our @EXPORT = qw/test_dsn_basics sample_dsns/;

use Test::Most;

sub test_dsn_basics {

    ## 1: dsn
    ## 2: driver, eg SQLite
    ## 3: konwn data, zero or more of:
    ##    { database => "foo", host => "bar", port => 1234 }
    ## 4: raw key=value pairs from dsn attributes
    ## 5: (attr, attr_hash, driver dsn) as returned by DBI->parse_dsn

    my ($test_dsn,$driver,$known,$attr,@parts) = @_;

    my $dsn;

    subtest $test_dsn => sub {

        # note( $test_dsn );

        $dsn = DBIx::ParseDSN::Default->new($test_dsn);

        ## DBI's parse
        cmp_deeply(
            [$dsn->dsn_parts],
            ["dbi", $driver, @parts ],
            "DBI's parse_dsn gives expected results"
        );

        ## basics
        is( $dsn->driver, $driver, "driver" );
        is( $dsn->scheme, "dbi", "scheme" );

        ## specifics
        is( $dsn->dbd_driver, "DBD::" . $driver, "driver identified" );
        cmp_deeply( $dsn->driver_attr, $parts[1], "attr" );
        is( $dsn->driver_dsn, $parts[2], "driver dsn" );

        ## parsed values
        is( $dsn->database, $known->{database}, "known database" );
        is( $dsn->host, $known->{host}, "known host" );
        is( $dsn->port, $known->{port}, "known port" );

        ## all driver dsn attributes
        cmp_deeply(
            $dsn->attr,
            $attr,
            "dsn attributes"
        );

    };

    return $dsn;

}

sub sample_dsns {

    qw{
dbi:ODBC:server=1.2.3.4;port=5678;database=DBNAME;driver=FreeTDS;tds_version=8.0
dbi:Sybase:server=5.6.7.8:1234;database=DBNAME
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

}

1;
