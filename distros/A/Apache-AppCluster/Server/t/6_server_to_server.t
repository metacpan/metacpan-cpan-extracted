use strict;
use lib 't/lib';
$|=1;

use Apache::test qw( have_httpd skip_test );
skip_test unless have_httpd;



print "1..3\n";
use Apache::AppCluster::Client;
my $client = Apache::AppCluster::Client->new();

for(my $counter=1; $counter <= 3; $counter++)
{
	my $data = { num_times => $counter,
		timeout => 30, };
	
	$client->add_request(
		key => $counter,
		method => 'TestLib2::Mod2::call_yourself()',
		params => $data,
		url => 'http://localhost:8228/appc_svr',
		);
}

$client->send_requests(30);

for(my $counter = 1; $counter <= 3; $counter++)
{
	if($client->request_ok($counter))
	{
		if($client->get_request_data($counter))
		{
			print "ok $counter\n";
		} else
		{
			print "not ok $counter\n";
		}
	} else
	{
		print "not ok $counter\n";
	}
}
