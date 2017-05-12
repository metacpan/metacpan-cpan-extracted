use Test::More;

use strict;
use warnings;

use HTTP::Request::Common;
use JSON;

use lib qw(t/lib);

use Test::WWW::Mechanize::Catalyst 'MyApp';

my $mech = Test::WWW::Mechanize::Catalyst->new();

$mech->add_header('Accept' => 'application/json');

my $res = $mech->request(POST "/user", [password => 'bar']); # name is required

ok(my $json = JSON::decode_json($res->content), 'response is JSON response');

ok(exists $json->{success}, 'Success status exists');

is($json->{success}, JSON::false, 'Success is false');

done_testing;