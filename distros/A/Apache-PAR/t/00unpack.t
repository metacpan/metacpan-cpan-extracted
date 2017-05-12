# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Apache::Test qw(plan ok have_lwp);
use Apache::TestRequest qw(GET);
use Apache::TestUtil qw(t_cmp);

plan tests => 6, have_lwp;

# Basic request
my $response = GET '/test/unpack/index.html';
if(!$response->is_success) {
	ok(0);
	print STDERR "Received failure code: " . $response->code . "\n";
}
else {
	ok(1);
}

# Test indexing
$response = GET '/test/unpack/';
if(!$response->is_success) {
	ok(0);
	print STDERR "Received failure code: " . $response->code . "\n";
}
else {
	ok(1);
}

# Test default mime type
$response = GET '/test/unpack/test/test.tst';
if(!$response->is_success) {
	ok(0);
	print STDERR "Received failure code: " . $response->code . "\n";
}
else {
	ok t_cmp('text/plain', $response->header('Content-Type'));
}

# Test bad request (not found)
my $response = GET '/test/unpack/test/doc.txt';
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

use Archive::Zip;
my $zip = Archive::Zip->new('par/unpack.par');
my $new_member = $zip->addString('TEST NEW CONTENT', 'htdocs/newcontent.txt');
#$zip->addMember($new_member);
$zip->overwrite();
undef($zip);

# Need to make sure that the modified time is different
# Granularity on mtime checks is one second.
# Note, unfortunately, this will make the test look like it is hanging...
sleep 2;

# Test changed content
my $response = GET '/test/unpack/newcontent.txt';
if(!$response->is_success) {
	ok(0);
	print STDERR "Received failure code: " . $response->code . "\n";
}
else {
	my $content = $response->content;
	ok t_cmp('TEST NEW CONTENT', $content);
}

my $remove_zip = Archive::Zip->new('par/unpack.par');
$remove_zip->removeMember('htdocs/newcontent.txt');
$remove_zip->overwrite();
undef($remove_zip);

# Need to make sure that the modified time is different
# Granularity on mtime checks is one second.
# Note, unfortunately, this will make the test look like it is hanging...
sleep 2;

# Test bad request for changed content (not found)
my $response = GET '/test/unpack/newcontent.txt';
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