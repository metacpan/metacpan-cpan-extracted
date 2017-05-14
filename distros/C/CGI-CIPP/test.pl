# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use CGI::CIPP;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$ENV{PATH_INFO} = "/test.cipp";
$ENV{REQUEST_METHOD} = "GET";

CGI::CIPP->request (
	document_root  => '.',
	directoy_index => 'index.cipp',
	cache_dir      => 'blib/cipp_cache',
	databases      => {
		test => {
			data_source => 'dbi:mysql:test',
			user        => 'dbuser',
			password    => 'dbpassword',
			auto_commit => 1
		},
	},
	default_database => 'test',
	lang => 'EN'
);

