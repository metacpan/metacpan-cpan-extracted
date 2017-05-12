#!/usr/bin/perl -w
use strict;

# testing the backup process

use CPAN::Testers::Data::Uploads;
use DBI;
use Test::More tests => 5;

my %available_drivers = map { $_ => 1 } DBI->available_drivers;

my $config  = 't/_DBDIR/test-config.ini';
my $sqlite  = 't/_DBDIR/uploads.db';
my $csvfile = 't/_DBDIR/uploads.csv';

SKIP: {
    skip "Test::Database required for DB testing", 5 unless(-f $config);

    my $obj;
    eval { $obj = CPAN::Testers::Data::Uploads->new( config => $config, backup => 1 ) };
    isa_ok($obj,'CPAN::Testers::Data::Uploads');

    SKIP: {
        skip "Problem creating object", 4 unless($obj);

        ok( ! -f $sqlite, '.. no SQLite backup' );
        ok( ! -f $csvfile, '.. no CSV backup' );

        $obj->process;

        ok( -f $sqlite, '.. got SQLite backup' );

        SKIP: {
            skip "DBD::CSV not installed", 1 unless($available_drivers{'CSV'});
            ok( -f $csvfile, '.. got CSV backup' );
        }
    }
}
