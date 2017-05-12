package TestLib2::Mod2;
use strict;
use Digest::MD5 qw( md5_hex );
use Apache::AppCluster::Client;

sub call_yourself
{
	my $input = shift @_;
	my $num_times = $input->{num_times};
	my $timeout = $input->{timeout};

	my $client = Apache::AppCluster::Client->new();
	my @vals;
	for(my $counter = 0; $counter < $num_times; $counter++)
	{
		my $temp = join('', map { int(rand(10000000)) } (1.. int(rand(1000))));
		my $tval = { 
		  data => $temp,
		  digest => md5_hex($temp) };
		  
		$vals[$counter] = $tval;
		$client->add_request( key => $counter,
			method => 'TestLib1::Mod1::send_digest()',
			params => $tval,
			url => 'http://localhost:8228/appc_svr',
			);
	}

	my $success = $client->send_requests($timeout);

	die "Failed during loopback call!\n" if($success != $num_times);

	for(my $counter = 0; $counter < $num_times; $counter++)
	{
		my $retval = $client->get_request_data($counter);
		if($retval != $vals[$counter]->{digest})
		{
			die "Failed digest check during loopback!\n";
		}
	}

	return 1;
}

1;
