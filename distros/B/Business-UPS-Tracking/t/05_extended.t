#!perl

use Test::NoWarnings;
use Test::More tests => 12 + 1;

use lib qw(t/);
use testlib;

# Disable checksum test
$Business::UPS::Tracking::CHECKSUM = 0;

SKIP:{
    skip "Could not connect to UPS online tracking webservices", 12 
        unless testcheck();

    my $response1 = testrequest(
        TrackingNumber    => '1Z12345E0390515214',
    );
    
    my $shipment1 = $response1->shipment->[0];
    my $package1 = $shipment1->Package->[0];
    my $package2 = $shipment1->Package->[1];
    
    isa_ok($package1,'Business::UPS::Tracking::Element::Package');
    isa_ok($package2,'Business::UPS::Tracking::Element::Package');
    
    my $reference = $package2->ReferenceNumber;
    
    isa_ok($reference,'ARRAY');
    isa_ok($reference->[0],'Business::UPS::Tracking::Element::ReferenceNumber');
    is($reference->[0]->Value,'RIN1319','Reference number is ok');
    is($reference->[0]->Code,'01','Reference number code is ok');
    is($reference->[0]->Description,'Unspecified','Reference number code type is ok');
    
    
    my $response2 = testrequest(
        TrackingNumber => '1Z12345E6892410845',
    );
    my $shipment2 = $response2->shipment->[0];
    my $package3 = $shipment2->Package->[0];
    my $activity = $package3->Activity;
    
    is($shipment2->Service->Code,'13','ServiceCode is ok');
    is($shipment2->Service->Description,'NEXT DAY AIR SAVER','ServiceDescription is ok');
    is(scalar @$activity,6,'Has six activities');
    is($package3->CurrentStatus,'Delivered','CurrentStatus is ok');
    is($activity->[0]->DateTime->dmy('-'),'12-09-2010','CurrentStatusDateTime is ok');
}