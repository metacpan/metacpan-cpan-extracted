#!perl -wT

# Check CGI::Buffer traps if you try to set the cache too late

use strict;
use warnings;
use Test::Most;
# use Test::NoWarnings;	# HTML::Clean has them

eval 'use Test::Carp';

if($@) {
	plan skip_all => 'Test::Carp required for test';
} else {
	use_ok('CGI::Buffer');

	TOOLATE: {
		delete $ENV{'REMOTE_ADDR'};
		delete $ENV{'HTTP_USER_AGENT'};

		ok(CGI::Buffer::can_cache() == 1);
		ok(CGI::Buffer::is_cached() == 0);

		my $test_count = 5;

		SKIP: {
			eval {
				require CHI;

				CHI->import;
			};

			if($@) {
				$test_count = 4;
				skip 'CHI not installed', 1 if $@;
			}

			diag("Using CHI $CHI::VERSION");

			# Print anything
			print "hello, world";

			my $cache = CHI->new(driver => 'Memory', datastore => {});

			diag("Ignore the error that it can't retrieve the given body");
			does_carp(\&CGI::Buffer::set_options, cache => $cache, cache_key => 'xyzzy');

			ok(CGI::Buffer::is_cached() == 0);
		}
		done_testing($test_count);
	}
}
