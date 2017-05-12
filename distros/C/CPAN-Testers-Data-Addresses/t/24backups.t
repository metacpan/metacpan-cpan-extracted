#!/usr/bin/perl -w
use strict;

use CPAN::Testers::Data::Addresses;
use DBI;
use Test::More tests => 5;

my $config = 't/_DBDIR/test-config.ini';
my $output = 't/_DBDIR/output.txt';

# available DBI drivers
my %DRIVERS_DBI = map { $_ => 1 } DBI->available_drivers();

SKIP: {
    skip "Unable to locate config file [$config]", 5    unless(-f $config);

    ### Prepare object
    my $obj;
    unlink($output)  if(-f $output);
    ok( $obj = CPAN::Testers::Data::Addresses->new(config => $config, output => $output, backup => 1), "got object" );

    $obj->backup;

    is(-f 't/_DBDIR/address.bogus'  ? 1 : 0, 0, ".. BOGUS backup doesn't exist");

    SKIP: {
        skip "SQLite driver not installed", 1   unless($DRIVERS_DBI{SQLite});
        is(-f 't/_DBDIR/address.db'     ? 1 : 0, 1, '.. SQLite backup exists');
    }

    SKIP: {
        skip "CSV driver not installed", 2      unless($DRIVERS_DBI{CSV});
        is(-f 't/_DBDIR/address'        ? 1 : 0, 0, ".. default CSV backup doesn't exist");
        is(-f 't/_DBDIR/address.csv'    ? 1 : 0, 1, '.. CSV backup exists');
    }
}
