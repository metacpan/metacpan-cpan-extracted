#!perl -wT

use strict;
use Test::Most tests => 15;

BEGIN {
	require_ok('CGI::Untaint::Twitter');
	# use_ok('CGI::Untaint::Twitter', { consumer_key => 'xxxx' etc. });
}

TWITTER: {
	# Check regular expression checker
	my $regex = CGI::Untaint::Twitter::_untaint_re();
	ok('nigelhorne' =~ $regex, 'valid Twitter ID');
	ok('@nigelhorne' =~ $regex, 'valid Twitter ID');
	ok('%%*%' !~ $regex, 'invalid Twitter ID');

	use_ok('CGI::Untaint');
	SKIP: {
		# To run the test, comment out the skip line then enter your
		# consumer_key/secret and access_token/secret stuff to the use_ok
		skip 'Twitter API1.1 needs authentication', 10;

		my $vars = {
		    twitter1 => 'nigelhorne',
		    twitter2 => '@nigelhorne',
		    twitter3 => ' @nigelhorne',
		    twitter4 => '  @nigelhorne ',
		    twitter5 => 'shf#*)',
		    twitter6 => ' ',
		    twitter7 => '@',
		    twitter8 => '@EcclestonBrass',
		    twitter9 => 'cholseycb',
		};

		my $untainter = new_ok('CGI::Untaint' => [ $vars ]);
		my $c = $untainter->extract(-as_Twitter => 'twitter1');
		is($c, 'nigelhorne', 'nigelhorne');

		$c = $untainter->extract(-as_Twitter => 'twitter2');
		is($c, 'nigelhorne', '@nigelhorne');

		$c = $untainter->extract(-as_Twitter => 'twitter3');
		is($c, 'nigelhorne', '@nigelhorne');

		$c = $untainter->extract(-as_Twitter => 'twitter4');
		is($c, 'nigelhorne', '@nigelhorne');

		$c = $untainter->extract(-as_Twitter => 'twitter5');
		is($c, undef, 'Junk');

		# and what about empty fields?
		$c = $untainter->extract(-as_Twitter => 'twitter6');
		is($c, undef, 'Empty');

		$c = $untainter->extract(-as_Twitter => 'twitter7');
		is($c, undef, 'At sign');

		$c = $untainter->extract(-as_Twitter => 'twitter8');
		is($c, 'EcclestonBrass', 'EcclestonBrass');

		$c = $untainter->extract(-as_Twitter => 'twitter9');
		is($c, 'cholseycb', 'cholseycb');
	}
}
