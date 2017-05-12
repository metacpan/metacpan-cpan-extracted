#!/usr/bin/env perl -w

use lib::abs 'lib','../lib';#, '../../AE-Cnn/lib';
use Test::AE::MC;
use common::sense;

runtest {
	my ($host,$port) = @_;
	diag "testing $host : $port";
	require Test::NoWarnings;Test::NoWarnings->import;
	plan tests => 5 + 1;
	my $cv = AE::cv;
	
	my $memd = AnyEvent::Memcached->new(
		servers   => "$host:$port",
		cv        => $cv,
		debug     => 0,
		namespace => "AE::Memd::t/$$/" . (time() % 100) . "/",
		compress_enable    => 1,
		compress_threshold => 1, # Almost everything is greater than 1
	);
	
	isa_ok($memd, 'AnyEvent::Memcached');
	# Repeated structures will be compressed
	$memd->set(key1 => { some => 'struct'x10, "\0" => "\1" }, cb => sub {
		ok(shift,"set key1") or diag "  Error: @_";
		$memd->get("key1", cb => sub {
			is_deeply(shift, { some => 'struct'x10, "\0" => "\1" }, "get key1") or diag "  Error: @_";
		});
	});
	$memd->get("test%s", cb => sub {
		ok !shift, 'no value';
		ok !@_, 'no errors';
	});
	
	$cv->recv;
};
