use Digest::MD5 qw( md5_hex );
use strict;
use lib 't/lib';

use Apache::test qw( have_httpd skip_test );
skip_test unless have_httpd;


$|=1;
print "1..1\n";
use Apache::AppCluster::Client;

my $client = Apache::AppCluster::Client->new();
my $str = join('', map { int(rand(10000000)) } (1.. int(rand(1000))));
my $digest = md5_hex($str);
$client->add_request(
	key => 'key1',
	method => 'TestLib1::Mod1::send_digest()',
	params => {data => $str, digest => $digest },
	url => 'http://localhost:8228/appc_svr',
);

my $timeout = 5.6; #seconds - can be a float
my $num_succesful = $client->send_requests($timeout);
my $num_failed = $client->get_total_failed();

if($client->request_ok('key1')) 
{
	my $key1_data = $client->get_request_data('key1');
	if($key1_data eq $digest)
	{
		print "ok 1\n";
	} else
	{
		print "not ok 1\n";
	}
} else 
{
	print "not ok 1\n";
}

