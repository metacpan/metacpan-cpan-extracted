# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Apache::Test qw(plan ok have_lwp);
use Apache::TestRequest qw(GET);
use Apache::TestUtil qw(t_cmp);

plan tests => 6, have_lwp;

# Basic request
my $response = GET '/test/static/index.html';
if(!$response->is_success) {
	ok(0);
	print STDERR "Received failure code: " . $response->code . "\n";
}
else {
	ok(1);
}

# Test no path
my $response = GET '/test/static2/test.html';
if(!$response->is_success) {
	ok(0);
	print STDERR "Received failure code: " . $response->code . "\n";
}
else {
	ok(1);
}

# Test indexing
$response = GET '/test/static/';
if(!$response->is_success) {
	ok(0);
	print STDERR "Received failure code: " . $response->code . "\n";
}
else {
	ok(1);
}

# Test default mime type
$response = GET '/test/static/test/test.tst';
if(!$response->is_success) {
	ok(0);
	print STDERR "Received failure code: " . $response->code . "\n";
}
else {
	ok t_cmp('text/plain', $response->header('Content-Type'));
}

# Test bad request (not found)
my $response = GET '/test/static/test/doc.txt';
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

# Test bad request (no directory indexing)
my $response = GET '/test/static/test/';
if($response->is_success) {
	ok(0);
	print STDERR "Should have failed, instead received: " . $response->code . "\n";
}
else {
	if($response->code != 403) {
		ok(0);
		print STDERR "Should have received forbidden, instead got: " . $response->code . "\n";
	}
	else {
		ok(1);
	}
}
