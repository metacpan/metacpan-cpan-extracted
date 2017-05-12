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
	require_ok('CGI::Untaint::Facebook');

	my $vars = {
	    url1 => 'rockvillebb',
	    url2 => ' voicetimemoney ',
	};

	taint_checking_ok();

	untainted_ok_deeply($vars);
	taint_deeply($vars);
	tainted_ok_deeply($vars);

	my $untainter = CGI::Untaint->new($vars);

	my $c = $untainter->extract(-as_Facebook => 'url1');
	ok(defined($c));
	tainted_ok($vars->{'url1'});
	untainted_ok($c);
	ok($c eq 'https://www.facebook.com/rockvillebb', 'RBB');

	$c = $untainter->extract(-as_Facebook => 'url2');
	ok(defined($c));
	tainted_ok($vars->{'url2'});
	untainted_ok($c);
	ok($c eq 'https://www.facebook.com/voicetimemoney', 'Votimo');
}
