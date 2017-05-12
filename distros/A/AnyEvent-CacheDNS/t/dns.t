#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 11;

use AnyEvent;
use AnyEvent::CacheDNS ':register';
use AnyEvent::DNS;
use Data::Dumper;


sub main {

	# Make sure we timeout fast
	my $dns = AnyEvent::DNS::resolver;
	isa_ok($dns, 'AnyEvent::CacheDNS');
	$dns->{timeout} = [0.5];
	$dns->_compile();

	my $cv;

	my $host = 'bee.meon.eu';
	$cv = AnyEvent->condvar;
	$dns->resolve($host, 'a', $cv);
	my ($first) = $cv->recv();
	if (defined $first) {
		ok($first, "First DNS lookup");
	}
	else {
		# DNS request failed, ok as long as the second one fails too we're ok
		SKIP: {
			skip "DNS lookup for $host failed", 1;
		};
	}

	$cv = AnyEvent->condvar;
	$dns->resolve($host, 'a', $cv);
	my ($second) = $cv->recv();

	# Inspect the cache
	ok(keys %{ $dns->{_cache} } == 1, "DNS cache was used");
	ok(keys %{ $dns->{_cache}{a} } == 1, "DNS cache has a sinle host");
	my $cached = $dns->{_cache}{a}{$host};


	if (! defined $first) {
		# DNS request failed, ok as long as the second one fails too we're ok
		ok(! defined $second, "Second DNS lookup failed, just as the first one");

		# Inspect the cache
		ok(! defined $cached, "Cache has no record for host");

		SKIP: {
			skip "DNS lookup for $host failed", 3;
		};

		return 0;
	}

	ok($second, "Second DNS lookup");
	is_deeply($first, $second, "DNS records identical");
	ok($first == $second, "DNS records same ref");

	# Check that the cache as a DNS record
	ok(pop @{ $cached }, "IP address is true");
	is($cached->[0], $host, "Response packet host matches");
	is($cached->[1], 'a', "Response packet record type matches");
	is($cached->[2], 'in', "Response packet record class matches");

	return 0;
}


exit main() unless caller;
