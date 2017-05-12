# vim: ft=perl
use Test::More 'no_plan';
use strict;
$^W = 1;

# Test that two dbs with the same priority are actually randomly selected.

use DBI;
use DBD::SQLite;
use DBD::Multi;
use Data::Dumper;
use DBI::Const::GetInfoType;

my $dbh_1 = DBI->connect("dbi:SQLite:one.db");
my $multi = DBI->connect('DBI:Multi:', undef, undef, { dsns => [ 1 => $dbh_1 ] } );


foreach my $i ( qw( SQL_DBMS_NAME SQL_DBMS_VER SQL_IDENTIFIER_QUOTE_CHAR SQL_CATALOG_NAME_SEPARATOR SQL_CATALOG_LOCATION ) ) {
    my $type = $GetInfoType{$i};
    is ( $dbh_1->get_info($type), $multi->get_info($type), "Compare $i info." );
}

$multi->disconnect();

unlink "one.db";
