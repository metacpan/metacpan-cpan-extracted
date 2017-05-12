use Test::More  tests => 5;

use strict;
use warnings;

use HTTP::Request::Common;
use JSON;

use lib qw(t/lib);

use Test::WWW::Mechanize::Catalyst 'MyApp';

my $mech = Test::WWW::Mechanize::Catalyst->new();

$mech->add_header('Accept' => 'application/json');

my $res = $mech->request(POST '/user', [name => 'bar', password => 'foo']);

ok(my $json = JSON::decode_json($res->content), 'response is JSON response');

is($json->{success}, JSON::true, 'submission was successful');

$res = $mech->request(POST '/user/1?x-tunneled-method=DELETE');

$mech->get_ok('/users', undef, 'request list of users');

ok($json = JSON::decode_json($mech->content), 'response is JSON response');

is($json->{results}, 0, 'no results');