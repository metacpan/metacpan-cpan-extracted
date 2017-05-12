#!perl -wT

use strict;
use warnings;
use Test::More;

eval 'use Test::Taint';
if($@) {
	plan skip_all => 'Test::Taint required for testing untainting';
} else {
	plan tests => 14;

	use_ok('CGI::Untaint');
	require_ok('CGI::Untaint::CountyStateProvince::GB');

	my $vars = {
	    state1 => 'Kent',
	    state2 => 'West Yorkshire',
	    state3 => 'West Yorks',
	    state4 => 'westmidlands',
	};

	taint_checking_ok();

	untainted_ok_deeply($vars);
	taint_deeply($vars);
	tainted_ok_deeply($vars);

	my $untainter = CGI::Untaint->new($vars);

	my $c = $untainter->extract(-as_CountyStateProvince => 'state1');
	tainted_ok($vars->{'state1'});
	untainted_ok($c);
	ok($c eq 'kent', 'Kent');

	$c = $untainter->extract(-as_CountyStateProvince => 'state2');
	untainted_ok($c);
	ok($c eq 'west yorkshire', 'West Yorkshire');

	$c = $untainter->extract(-as_CountyStateProvince => 'state3');
	untainted_ok($c);
	ok($c eq 'west yorkshire', 'West Yorks');

	$c = $untainter->extract(-as_CountyStateProvince => 'state4');
	untainted_ok($c);
	ok($c eq 'west midlands', 'westmidlands');
}
