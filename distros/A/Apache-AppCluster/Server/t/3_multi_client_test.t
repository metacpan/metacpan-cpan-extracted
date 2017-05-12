use strict;

use lib 't/lib';
$|=1;

use Apache::test qw( have_httpd skip_test );
skip_test unless have_httpd;



print "1..5\n";
use Apache::AppCluster::Client;
my $client = Apache::AppCluster::Client->new();

for(my $counter = 1; $counter <= 5; $counter++)
{
	$client->add_request(
	key => $counter,
	method => 'MyLib::testit()',
	params => ['val1', 'val2', 'another_val', 'more_stuff'],
	url => 'http://localhost:8228/appc_svr',
	);
}
my $timeout = 30.5; #seconds - can be a float
my $num_succesful = $client->send_requests($timeout);
my $num_failed = $client->get_total_failed();


for(my $counter = 1; $counter <= 5; $counter++)
{
	
	if($client->request_ok($counter)) 
	{
		my $key_data = $client->get_request_data($counter);
		if($key_data->{key1} eq 'val1')
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


