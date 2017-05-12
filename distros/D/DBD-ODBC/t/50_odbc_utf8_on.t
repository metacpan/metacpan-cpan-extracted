#!/usr/bin/perl -w -I./t

use Test::More;
use strict;

$| = 1;

plan tests => 3;

use DBI;
my $dbh;

BEGIN {
	plan skip_all => "DBI_DSN is undefined" unless($ENV{DBI_DSN});
}


$dbh = DBI->connect();
unless($dbh) {
   BAIL_OUT("Unable to connect to the database $DBI::errstr\nTests skipped.\n");
   exit 0;
}

ok(exists($dbh->{odbc_utf8_on}), "odbc_utf8_on exists with value=$dbh->{odbc_utf8_on}");
is($dbh->{odbc_utf8_on}, 0, "odbc_utf8_on is off by default");

$dbh->{odbc_utf8_on} = 1;
is($dbh->{odbc_utf8_on}, 1, "odbc_utf8_on set value=$dbh->{odbc_utf8_on}");
