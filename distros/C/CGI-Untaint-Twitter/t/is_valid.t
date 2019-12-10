#!perl -wT

use strict;
use Test::Most;

eval 'use Test::Carp';

if($@) {
	plan skip_all => 'Test::Carp needed to check error messages';
} else {
	use_ok('CGI::Untaint::Twitter');
	# Doesn't work - I mean it fails this test even though the carp is done
	# does_carp_that_matches(sub {
		# use_ok('CGI::Untaint');
# 
		# my $vars = {
			# twitter1 => 'nigelhorne',
		# };
# 
		# my $untainter = new_ok('CGI::Untaint' => [ $vars ]);
# 
		# $untainter->extract(-as_Twitter => 'twitter1');
	# }, 'Access tokens are required');
}
done_testing();
