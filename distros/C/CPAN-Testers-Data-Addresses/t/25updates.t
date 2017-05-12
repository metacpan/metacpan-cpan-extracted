#!/usr/bin/perl -w
use strict;

use CPAN::Testers::Data::Addresses;
use Data::Dumper;
use File::Slurp;
use Test::More tests => 5;

my $config = 't/_DBDIR/test-config.ini';
my $output = 't/_DBDIR/output.txt';

## Test Data

my $f = 't/_DBDIR/update.txt';
my @data = (
    '2975971,02975971-b19f-3f77-b713-d32bba55d77f,200901021220,0,0,barbie@example.com,Barbie,BARBIE',           # valid - existing tester
    '2975972,02975972-b19f-3f77-b713-d32bba55d77f,200901021220,0,0,,Barbie,BARBIE',                             # missing address
    '2975973,02975973-b19f-3f77-b713-d32bba55d77f,200901021220,0,0,barbie@example.com,,BARBIE',                 # missing name
    '2975974,02975974-b19f-3f77-b713-d32bba55d77f,200901021220,0,0,,,',                                         # missing address, name and display
    '2975975,02975975-b19f-3f77-b713-d32bba55d77f,200901021220,0,0,newtester@example.com,New Tester,NEWTESTER', # valid - new tester
    '2975971,02975971-b19f-3f77-b713-d32bba55d77f,200901021220,1,1,barbie@example.com,Barbie,BARBIE',           # valid - existing tester - wuth ids
    '2975971,02975971-b19f-3f77-b713-d32bba55d77f,,1,1,barbie@example.com,Barbie,BARBIE',                       # valid - missing date
    '2975971,,200901021220,1,1,barbie@example.com,Barbie,BARBIE',                                               # valid - missin guid
    ',,,1,1,barbie@example.com,Barbie,BARBIE',                                                                  # valid - no existing report
);

#            my ($reportid,$guid,$fulldate,$addressid,$testerid,$address,$name,$pause,$display,$match) = split(',');

SKIP: {
    skip "Unable to locate config file [$config]", 5   unless(-f $config);

    ### Prepare object
    my $obj;
    unlink($output)  if(-f $output);

    ### Test update() in more depth
    my $data = join("\n",@data);
    write_file($f,$data);
    $obj = CPAN::Testers::Data::Addresses->new(config => $config, output => $output, update => $f);

    # run update
    my $dbh = $obj->dbh;
    my @ct1 = $dbh->get_query('array','select count(*) from tester_profile');
    $obj->process;
    my @ct2 = $dbh->get_query('array','select count(*) from tester_profile');
    is($ct2[0]->[0] - $ct1[0]->[0], 1, '.. 2 address added');

    $obj = undef;

    # check output file
    my $content = read_file($output);
    like($content,qr/6 addresses mapped/s,'.. valid mapped addresses');
    like($content,qr/1 new testers/s,'.. new testers');
    like($content,qr/1 addresses added/s,'.. addresses added');
    like($content,qr/3 bogus lines/s,'.. bogus lines');
}
