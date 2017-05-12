use strict;

use Scalar::Util qw(blessed);
use Test::More;

plan tests => 13;

use_ok('Data::Transform::SSL');

my $client = Data::Transform::SSL->new(flags => Data::Transform::SSL::FLAGS_ALLOW_SELFSIGNED());
my $server = Data::Transform::SSL->new(type => 'Server', key => 't/key.pem', cert => 't/cert.pem');

my $data = ["this line has to reach the other end"];
pass("sending data to the server");
my $client_data = $client->put($data);
is(@$client_data, 1, "... got a single chunk of data from the filter");

my $loop = 0;
while (1) {
        BAIL_OUT("uh oh, seems like we're in an infinite loop") if ($loop > 100);
        $loop++;
	my $server_data = $server->get($client_data);
	if (blessed ($server_data->[0])) {
                cmp_ok($loop, '<', 3, "... looping through the connect phase");
                isa_ok($server_data->[0], 'Data::Transform::Meta::SENDBACK', '... got some ssl negotiation data, which');
		my $result = $client->get([$server_data->[0]->{data}]);
                if (blessed ($result->[0])) {
                        $client_data = [$result->[0]->{data}];
                }
		next;
	} else {
                is($loop, 3, "... getting real data after the connect");
                is_deeply($server_data, $data, "... it reached the other end");
		last;
	}
}

my $return = ["and this goes the other way"];
pass("sending data back to the client");
my $server_data = $server->put($return);
is(@$server_data, 1, "... got a single chunk of data from the filter");
$loop = 0;

while (1) {
        BAIL_OUT("uh oh, seems like we're in an infinite loop") if ($loop > 100);
        $loop++;
	my $client_data = $client->get($server_data);
	if (blessed ($client_data->[0])) {
                warn $client_data->[0];
		$server_data = $server->get([$client_data->[0]->{data}]);
                if (blessed ($server_data->[0])) {
                        $server_data = [$server_data->[0]->{data}];
                }
		next;
	} else {
                is($loop, 1, "... getting real data immediately; already connected");
                is_deeply($client_data, $return, "... it reached the other end");
		last;
	}
}

