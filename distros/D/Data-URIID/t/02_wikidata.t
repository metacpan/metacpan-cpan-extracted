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
    http://www.wikidata.org/entity/Q1
    https://www.wikidata.org/wiki/Q1
    )) {
    my $result = $extractor->lookup( $uri );
    isa_ok($result, 'Data::URIID::Result');
    is($result->attribute('service', as => 'ise'), '198bc92a-be09-42d2-bf96-20a177294b79', 'service test');
    is($result->id_type, 'ce7aae1e-a210-4214-926a-0ebca56d77e3', 'id_type test');
    is($result->id, 'Q1', 'id test');
    is($result->ise, 'http://www.wikidata.org/entity/Q1', 'ise test');
    is($result->id('uuid'), '8a46cc5e-5c8f-5ec3-b73f-37d3748e7a55', 'to UUID test');
    is($result->id('uri'), 'http://www.wikidata.org/entity/Q1', 'to URI test');
}

done_testing();

exit 0;
