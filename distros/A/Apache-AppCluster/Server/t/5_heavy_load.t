use Digest::MD5 qw( md5_hex );
use strict;
use lib 't/lib';
$|=1;

use Apache::test qw( have_httpd skip_test );
skip_test unless have_httpd;


print "1..100\n";
use Apache::AppCluster::Client;

for(my $main_counter = 0; $main_counter < 10; $main_counter++)
{
	my $passed = 1;
	my $client = Apache::AppCluster::Client->new();
	my @digs;
	for(my $counter = 1; $counter <= 10; $counter++)
	{
		my $str = join('', map { int(rand(10000000)) } (1.. int(rand(10000))));
		my $digest = md5_hex($str);
		$digs[$counter] = $digest;
		$client->add_request(
			key => $counter,
			method => 'TestLib1::Mod1::send_digest()',
			params => {data => $str, digest => $digest },
			url => 'http://localhost:8228/appc_svr',
		);
	}
	my $timeout = 5.6; #seconds - can be a float
	my $num_succesful = $client->send_requests($timeout);
	my $num_failed = $client->get_total_failed();

	for(my $counter = 1; $counter <= 10; $counter++)
	{
		if($client->request_ok($counter)) 
		{
			my $key1_data = $client->get_request_data($counter);
			if(!($key1_data eq $digs[$counter]))
			{
				print "not ok " . ($main_counter * 10 + $counter) . "\n";
			} else
			{
				print "ok " . ($main_counter * 10 + $counter) . "\n";
			}
		} else 
		{
			print "not ok " . ($main_counter * 10 + $counter) . "\n";
		}
	}
}
