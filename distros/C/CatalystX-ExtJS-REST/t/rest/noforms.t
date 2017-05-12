use Test::More;

use strict;
use warnings;

use HTTP::Request::Common;

use lib qw(t/lib);
use JSON::XS;

use Test::WWW::Mechanize::Catalyst 'MyApp';

my $mech = Test::WWW::Mechanize::Catalyst->new();

$mech->add_header('Accept' => 'application/json');

*MyApp::debug = sub { 1 };
MyApp->log->disable('debug', 'info');

my $res = $mech->request(GET "/noforms"); # name is required

ok(my $json = JSON::XS::decode_json($res->content), 'response is JSON response');

ok(exists $json->{success}, 'Success status exists');

is("$json->{success}", '0', 'Success is false');

like($json->{error}, qr/exist/, 'Error made it to the backend in debug mode');

done_testing;