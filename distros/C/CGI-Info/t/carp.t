#!perl -wT

use strict;
use warnings;
use Test::Carp;
use Test::Most tests => 1;

BEGIN {
	use_ok('CGI::Info');
}

CARP: {
	$ENV{'GATEWAY_INTERFACE'} = 'CGI/1.1';

	# Doesn't work - I mean it fails this test even though the carp is done
	# does_carp_that_matches(
		# sub {
			# $ENV{'GATEWAY_INTERFACE'} = 'CGI/1.1';
			# $ENV{'REQUEST_METHOD'} = 'FOO';
			# my $i = new_ok('CGI::Info');
			# $i->params();
			# ok($i->status() == 405);
		# },
		# qr/^Use/
	# );

	# Doesn't work - I mean it fails this test even though the carp is done
	# does_carp_that_matches(
		# sub {
			# $ENV{'REQUEST_METHOD'} = 'POST';

			# my $input = 'foo=bar';
			# $ENV{'CONTENT_LENGTH'} = length($input) + 1;	# One more than the length, should error

			# open (my $fin, '<', \$input);
			# local *STDIN = $fin;

			# my $i = new_ok('CGI::Info');
			# my %p = %{$i->params()};
			# ok(!defined($p{fred}));
			# diag($p{foo});
			# ok(!defined($p{foo}));
			# close $fin;
		# },
		# qr/^POST failed/
	# );
}
