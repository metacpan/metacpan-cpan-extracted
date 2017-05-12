#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

# setup library path
use FindBin qw($Bin);
use lib "$Bin/lib";

use HTTP::Headers;
use HTTP::Request::Common;
use LWP::Simple qw(!get);

use JSON::Any;

# make sure testapp works
use ok 'TestApp';

# a live test against TestApp, the test application
use Test::WWW::Mechanize::Catalyst 'TestApp';
my $mech = Test::WWW::Mechanize::Catalyst->new;
$mech->get_ok('http://localhost/', 'get main page');
$mech->content_like(qr/it works/i, 'see if it has our text');

subtest 'simple test for endpoint', sub {
    my $client_id = "36d24a484e8782decbf82a46459220a10518239e";
    $mech->get_ok("http://localhost/oauth/token?client_id=$client_id", 'a token endpoint');
    $mech->get("http://localhost/oauth/authorize?client_id=$client_id", 'an authorize endpoint');
    is( $mech->status, 200, "Login required" );
};

subtest 'test for protected resource', sub {
     my $mac = "MAC token=h480djs93hd8,";
     $mac .= "timestamp=137131200,";
     $mac .= "nonce=dj83hs9s,";
     $mac .= "signature=U2FsdGVkX1/3UV6R0SnZvqNDtP7evqzSY12FQoAhemnSJhLDhXpwb2sjPeeBJH14cb3fD1kdREMVyQGl8UlwSg==";
     $mech->add_header( Authorization => $mac );
     my $test_api = 'http://localhost/my/test';
     $mech->get_ok($test_api);
     my $j   = JSON::Any->new();
     my $obj = $j->from_json($mech->content);
     is($obj->{'error'}, 'invalid_request');
};

done_testing();
