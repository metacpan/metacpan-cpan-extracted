#!/usr/bin/perl -w 

use strict;
use warnings;
use v5.10;
use lib 'lib', '../lib'; # able to run prove in project dir and .t locally
    
use Test::More tests => 19;

use_ok('Data::URIID');

my $extractor = Data::URIID->new;

isa_ok($extractor, 'Data::URIID');

{
    my $result = $extractor->lookup('https://uriid.org/uuid/95817676-a0e0-4532-a1c6-f9cd76d5cb0a');
    isa_ok($result, 'Data::URIID::Result');
    is($result->id_type, '8be115d2-dc2f-4a98-91e1-a6e3075cbc31', 'id_type test');
    is($result->id, '95817676-a0e0-4532-a1c6-f9cd76d5cb0a', 'id test');
    is($result->ise, '95817676-a0e0-4532-a1c6-f9cd76d5cb0a', 'ise test');
    is($result->url, 'https://uriid.org/uuid/95817676-a0e0-4532-a1c6-f9cd76d5cb0a', 'url test');
}

{
    my $service = $extractor->service('wikidata');
    isa_ok($service, 'Data::URIID::Service');
    is($service->name, 'wikidata', 'name');
    ok(defined($service->displayname), 'displayname defined');
    is($service->displayname, 'Wikidata', 'displayname');
    ok(!$service->online, 'is offline');
    $service->online(1);
    ok($service->online, 'is online');
    $service->online(0);
    ok(!$service->online, 'is offline');
}

{
    my $result = $extractor->lookup('ni:///sha-256;f4OxZX_x_FO5LcGBSKHWXfwtSx-j1ncoSt3SABJtkGk'); # example from RFC 6920
    my $digest;

    isa_ok($result, 'Data::URIID::Result');
    is($result->digest('sha-2-256'), '7f83b1657ff1fc53b92dc18148a1d65dfc2d4b1fa3d677284addd200126d9069', 'digest match');

    $digest = $result->digest('sha-2-256', as => 'Digest');
    isa_ok($digest, 'Data::URIID::Digest');
    isa_ok($digest, 'Digest::base');
    is($digest->hexdigest, '7f83b1657ff1fc53b92dc18148a1d65dfc2d4b1fa3d677284addd200126d9069', 'digest match');
}

exit 0;
