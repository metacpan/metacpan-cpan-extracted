use strict;
use lib 't/lib';
use Apache::test qw( have_httpd skip_test );
skip_test unless have_httpd;

$|=1;

print "1..1\n";
use Apache::AppCluster::Client;
my $client = Apache::AppCluster::Client->new();

$client->add_request(
key => 'key1',
method => 'MyLib::testit()',
params => ['val1', 'val2', 'another_val', 'more_stuff'],
url => 'http://localhost:8228/appc_svr',
);

my $timeout = 5.6; #seconds - can be a float
my $num_succesful = $client->send_requests($timeout);
my $num_failed = $client->get_total_failed();

if($client->request_ok('key1')) {
my $key1_data = $client->get_request_data('key1');
if($key1_data->{key1} eq 'val1')
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

