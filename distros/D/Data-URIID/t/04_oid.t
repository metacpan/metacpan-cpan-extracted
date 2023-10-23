#!/usr/bin/perl -w 
    
use strict;
use warnings;
use v5.10;
use lib 'lib', '../lib'; # able to run prove in project dir and .t locally
    
use Test::More;

use_ok('Data::URIID');

my $extractor = Data::URIID->new;

isa_ok($extractor, 'Data::URIID');

foreach my $uri (qw(
    urn:oid:2.25.198727180389748593139340236790527544074
    2.25.198727180389748593139340236790527544074
    )) {
    my $result = $extractor->lookup( $uri );
    isa_ok($result, 'Data::URIID::Result');
    is($result->attribute('service', default => undef), undef, 'service test');
    is($result->id_type, 'd08dc905-bbf6-4183-b219-67723c3c8374', 'id_type test');
    is($result->id, '2.25.198727180389748593139340236790527544074', 'id test');
    is($result->ise, '2.25.198727180389748593139340236790527544074', 'ise test');
    is($result->id('oid'), '2.25.198727180389748593139340236790527544074', 'to OID test');
    is($result->id('uri'), 'urn:oid:2.25.198727180389748593139340236790527544074', 'to URI test');
}

done_testing();

exit 0;
