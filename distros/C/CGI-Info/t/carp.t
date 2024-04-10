#!perl -w

use strict;
use warnings;
use Test::Carp;
use Test::Most tests => 8;

BEGIN {
	use_ok('CGI::Info');
}

CARP: {
	$ENV{'GATEWAY_INTERFACE'} = 'CGI/1.1';

	does_carp_that_matches(
		sub {
			$ENV{'GATEWAY_INTERFACE'} = 'CGI/1.1';
			$ENV{'REQUEST_METHOD'} = 'FOO';
			my $i = new_ok('CGI::Info');
			$i->params();
			ok($i->status() == 501);
		},
		qr/^Use/
	);

	does_carp_that_matches(
		sub {
			$ENV{'REQUEST_METHOD'} = 'POST';

			my $input = 'foo=bar';
			$ENV{'CONTENT_LENGTH'} = length($input) + 1;	# One more than the length, should error

			open (my $fin, '<', \$input);
			local *STDIN = $fin;

			my $i = new_ok('CGI::Info');
			my %p = %{$i->params()};
			ok(!defined($p{fred}));
			is($p{'foo'}, 'bar', 'foo=bar');
			close $fin;
		},
		qr/^POST failed/
	);
}
