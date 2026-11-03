#!perl -Tw

# Doesn't test anything useful yet

use strict;
use warnings;
use Test::Most tests => 5;
use Storable;
use Test::Log::Abstraction;
# use Test::NoWarnings;	# HTML::Clean has them

BEGIN {
	use_ok('CGI::Buffer');
}

CACHED: {
	delete $ENV{'REMOTE_ADDR'};
	delete $ENV{'HTTP_USER_AGENT'};

	ok(CGI::Buffer::is_cached() == 0);
	ok(CGI::Buffer::can_cache() == 1);

	SKIP: {
		eval {
			require CHI;

			CHI->import;
		};

		skip 'CHI not installed', 2 if $@;

		diag("Using CHI $CHI::VERSION");

		my $cache = CHI->new(driver => 'Memory', datastore => {});

		# On some platforms it's failing - find out why
		CGI::Buffer::init({
			cache => $cache,
			cache_key => 'xyzzy',
			logger => Test::Log::Abstraction->new()
		});
		ok(!CGI::Buffer::is_cached());

		my $c = {
			'body' => '',
			'etag' => '',
			'headers' => ''
		};

		$cache->set('xyzzy', Storable::freeze($c));
		ok(CGI::Buffer::is_cached());
	}
}
