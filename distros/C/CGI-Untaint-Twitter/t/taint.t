#!perl -wT

use strict;
use warnings;
use Test::Most;

eval 'use Test::Taint';
if($@) {
	plan skip_all => 'Test::Taint required for testing untainting';
} else {
	plan tests => 13;

	use_ok('CGI::Untaint');
	require_ok('CGI::Untaint::Twitter');

	my $vars = {
	    twitter1 => 'nigelhorne',
	    twitter2 => ' @nigelhorne  ',
	};

	taint_checking_ok();

	untainted_ok_deeply($vars);
	taint_deeply($vars);
	tainted_ok_deeply($vars);

	my $untainter = CGI::Untaint->new($vars);

	SKIP: {
		skip 'Twitter API1.1 needs authentication', 8;

		my $c = $untainter->extract(-as_Twitter => 'twitter1');
		ok(defined($c));
		tainted_ok($vars->{'twitter1'});
		untainted_ok($c);
		ok($c eq 'nigelhorne', 'nigelhorne');

		$c = $untainter->extract(-as_Twitter => 'twitter2');
		ok(defined($c));
		tainted_ok($vars->{'twitter2'});
		untainted_ok($c);
		ok($c eq 'nigelhorne', 'nigelhorne');
	}
}
