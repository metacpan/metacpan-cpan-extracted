# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl AnyEvent-Yubico.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 6;
use Test::Exception;
BEGIN { use_ok('AnyEvent::Yubico') };

#########################

my $client_id = 10450;
my $api_key = "uSzStPl2FolBbpJyDrDQxlIQElk=";

my $validator = AnyEvent::Yubico->new({
	client_id => $client_id,
	api_key => $api_key
});

my $test_params = {
	a => 12345,
	c => "hello world",
	b => "foobar"
};

my $test_signature = "k7ZRKLOn3C6565YVqmG2rd4PHVU=";

ok(defined($validator) && ref $validator eq "AnyEvent::Yubico", "new() works");

is($validator->sign($test_params), $test_signature, "sign() works");

my $default_urls = $validator->{urls};
$validator->{urls} = [ "http://127.0.0.1:0" ];

is($validator->verify_async("vvgnkjjhndihvgdftlubvujrhtjnllfjneneugijhfll")->recv()->{status}, "Connection refused", "invalid URL");

$validator->{urls} = $default_urls;
$validator->{local_timeout} = 0.01;

is($validator->verify_sync("vvgnkjjhndihvgdftlubvujrhtjnllfjneneugijhfll")->{status}, "Connection timed out", "timeout");

$validator->{local_timeout} = 30.0;

subtest 'Tests that require access to the Internet' => sub {
	if(exists($ENV{'NO_INTERNET'})) {
		plan skip_all => 'Internet tests';
	} else {
		plan tests => 5;
	}

	is($validator->verify_sync("ccccccbhjkbulvkhvfuhlltctnjtgrvjuvcllliufiht")->{status}, "REPLAYED_OTP", "replayed OTP");

	$validator = AnyEvent::Yubico->new({
		client_id => $client_id,
	});

	my $result = $validator->verify_sync("ccccccbhjkbubrbnrtifbiuhevinenrhtlckuctjjuuu");

	is($result->{status}, "BAD_OTP", "invalid OTP");

	#Test manual signature verification
	ok(exists($result->{h}), "signature exists");
	my $sig = $result->{h};
	delete $result->{h};
	$validator->{api_key} = $api_key;
	is($validator->sign($result), $sig, "signature is correct");

	ok(! $validator->verify("ccccccbhjkbubrbnrtifbiuhevinenrhtlckuctjjuuu"), "verify(\$bad_otp)");
};
