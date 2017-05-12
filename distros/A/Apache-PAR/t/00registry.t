# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Apache::Test qw(plan ok have_lwp);
use Apache::TestRequest qw(GET);
use Apache::TestUtil qw(t_cmp);

plan tests => 10, have_lwp;

# Basic request
for(1..2)
{
	my $response = GET '/test/registry/test.pl';
	if(!$response->is_success) {
		ok(0);
		print STDERR "Received failure code: " . $response->code . "\n";
	}
	else {
		ok(1);
	}
}

# test configuration setup directly in httpd
for(1..2)
{
	foreach my $url qw(/test/registryroot/test.pl /test/registry2/test2.pl)
	{
		my $response = GET $url;
		if(!$response->is_success) {
			ok(0);
			print STDERR "Received failure code: " . $response->code . "\n";
		}
		else {
			ok(1);
		}
	}
}

# Test indexing
$response = GET '/test/registry/';
if($response->is_success) {
	ok(0);
	print STDERR "Should have received failure code, instead got: " . $response->code . "\n";
}
else {
	ok(1);
}

# Test extra_path_info
for (1..2)
{
	$response = GET '/test/registry/test/path.pl/JAPH';
	if(!$response->is_success) {
		ok(0);
		print STDERR "Received failure code: " . $response->code . "\n";
	}
	else {
		ok t_cmp('/JAPH', $response->content);
	}
}


# Test bad request (not found)
my $response = GET '/test/registry/test/not_found.pl';
if($response->is_success) {
	ok(0);
	print STDERR "Should have failed, instead received: " . $response->code . "\n";
}
else {
	if($response->code != 404) {
		ok(0);
		print STDERR "Should have gotten file not found, instead received: " . $response->code . "\n";
	}
	else {
		ok(1);
	}
}
