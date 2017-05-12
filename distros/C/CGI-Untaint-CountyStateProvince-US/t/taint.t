#!perl -wT

use strict;
use warnings;
use Test::More;

eval 'use Test::Taint';
if($@) {
	plan skip_all => 'Test::Taint required for testing untainting';
} else {
	plan tests => 11;

	use_ok('CGI::Untaint');
	use_ok('CGI::Untaint::CountyStateProvince::US');

	my $vars = {
	    state1 => 'MD',
	    state2 => 'Virginia',
	};

	taint_checking_ok();

	untainted_ok_deeply($vars);
	taint_deeply($vars);
	tainted_ok_deeply($vars);

	my $untainter = CGI::Untaint->new($vars);

	my $c = $untainter->extract(-as_CountyStateProvince => 'state1');
	tainted_ok($vars->{'state1'});
	untainted_ok($c);
	ok($c eq 'MD', 'MD');

	$c = $untainter->extract(-as_CountyStateProvince => 'state2');
	tainted_ok($vars->{'state2'});
	untainted_ok($c);
	ok($c eq 'VA', 'Virginia');
}
