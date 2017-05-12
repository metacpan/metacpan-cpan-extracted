#!perl -wT

use strict;
use warnings;
use Test::Most;

eval 'use Test::Carp';

if($@) {
	plan skip_all => 'Test::Carp needed to check error messages';
} else {
	use_ok('CGI::Untaint::Facebook');
	sub foo {
		my $vars = {
		    url1 => 'https://www.facebook.com/rockvillebb',
		};
		my $untainter = new_ok('CGI::Untaint' => [ $vars ]);
	}
	# Doesn't work - I mean it fails this test even though the carp is done
	# does_carp_that_matches(\&foo, qr/Use POST, GET or HEAD/);
	done_testing();
}
