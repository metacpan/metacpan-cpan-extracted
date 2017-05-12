#!perl -T

use Test::More tests => 9;

BEGIN { 
    use_ok( 'AnyEvent' );
    use_ok( 'AnyEvent::Curl::Multi' );
    use_ok( 'HTTP::Request');
}

my $TEST_URL = 'http://www.perl.org';

my $cv = AE::cv;

my $client = new_ok('AnyEvent::Curl::Multi' => [timeout => 30]);
my $request = new_ok('HTTP::Request' => [GET => $TEST_URL]);

ok($client->request($request), "issued request");
$client->reg_cb(response => sub { $cv->(@_) });
$client->reg_cb(error => sub { $cv->(@_) });

my (undef, undef, $response, $stats) = $cv->recv;

isa_ok($response, 'HTTP::Response');
isa_ok($stats, 'HASH');

ok($response->is_success, "HTTP response from $TEST_URL was successful");

# vim:syn=perl:ts=4:sw=4:et:ai
