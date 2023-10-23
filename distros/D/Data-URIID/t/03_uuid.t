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
    urn:uuid:95817676-a0e0-4532-a1c6-f9cd76d5cb0a
    95817676-a0e0-4532-a1c6-f9cd76d5cb0a
    )) {
    my $result = $extractor->lookup( $uri );
    isa_ok($result, 'Data::URIID::Result');
    is($result->attribute('service', default => undef), undef, 'service test');
    is($result->id_type, '8be115d2-dc2f-4a98-91e1-a6e3075cbc31', 'id_type test');
    is($result->id, '95817676-a0e0-4532-a1c6-f9cd76d5cb0a', 'id test');
    is($result->ise, '95817676-a0e0-4532-a1c6-f9cd76d5cb0a', 'ise test');
    is($result->id('uuid'), '95817676-a0e0-4532-a1c6-f9cd76d5cb0a', 'to UUID test');
    is($result->id('uri'), 'urn:uuid:95817676-a0e0-4532-a1c6-f9cd76d5cb0a', 'to URI test');
}

done_testing();

exit 0;
