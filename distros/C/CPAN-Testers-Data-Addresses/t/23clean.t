#!/usr/bin/perl -w
use strict;

use CPAN::Testers::Data::Addresses;
use Data::Dumper;
use File::Slurp;
use Test::More tests => 3;

my $config = 't/_DBDIR/test-config.ini';
my $output = 't/_DBDIR/output.txt';

## Test Data

my @data = (
    [ 0, 'barbie@missbarbell.co.uk', 'barbie@missbarbell.co.uk' ],
    [ 0, 'barbie@missbarbell.co.uk', 'barbie@missbarbell.co.uk' ],
    [ 0, 'barbie@missbarbell.co.uk', 'barbie@missbarbell.co.uk' ],
    [ 0, 'barbie@missbarbell.co.uk', 'barbie@missbarbell.co.uk' ],
    [ 0, 'barbie@cpan.org', 'barbie@cpan.org' ],
    [ 0, 'barbie@example.com', 'barbie@example.com' ],
);


SKIP: {
    skip "Unable to locate config file [$config]", 3    unless(-f $config);

    ### Prepare object
    my $obj;
    unlink($output)  if(-f $output);
    ok( $obj = CPAN::Testers::Data::Addresses->new(config => $config, output => $output), "got object" );

    my $dbh = $obj->dbh;
    my @ct1 = $dbh->get_query('array','select count(*) from tester_address');

    for my $data (@data) {
        $dbh->do_query('insert into tester_address (testerid, address, email) VALUES (?,?,?)',@$data);
    }
    my @ct2 = $dbh->get_query('array','select count(*) from tester_address');
    is($ct2[0]->[0] - $ct1[0]->[0], 6, '.. 6 addresses added');

    $obj->clean;

    @ct2 = $dbh->get_query('array','select count(*) from tester_address');
    is($ct2[0]->[0] - $ct1[0]->[0], 2, '.. 3 addresses cleaned');
}
