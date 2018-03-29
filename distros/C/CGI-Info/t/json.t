#!perl -wT

use strict;
use warnings;
use Test::Most tests => 5;
use Test::NoWarnings;
use lib 't/lib';
use MyLogger;

eval 'use autodie qw(:all)';	# Test for open/close failures

BEGIN {
	use_ok('CGI::Info');
}

JSON: {
	my $json = '{ "first": "Nigel", "last": "Horne" }';

	$ENV{'GATEWAY_INTERFACE'} = 'CGI/1.1';
	$ENV{'REQUEST_METHOD'} = 'POST';
	$ENV{'CONTENT_TYPE'} = 'application/json; charset=utf-8';
	$ENV{'CONTENT_LENGTH'} = length($json);

	my $allowed = { 'first' => undef, 'last' => undef };

	open (my $fin, '<', \$json);
	local *STDIN = $fin;

	my $i = new_ok('CGI::Info' => [ logger => MyLogger->new() ]);
	ok(defined($i->params(allow => $allowed)));
	ok($i->first() eq 'Nigel');
}
