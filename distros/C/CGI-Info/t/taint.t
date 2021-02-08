#!perl -wT

use strict;
use warnings;
use Test::Most;

eval 'use Test::Taint';
if($@) {
	plan(skip_all => 'Test::Taint required for testing untainting');
} else {
	plan(tests => 7);

	taint_checking_ok();
	require_ok('CGI::Info');

	$ENV{'C_DOCUMENT_ROOT'} = $ENV{'HOME'};
	delete $ENV{'DOCUMENT_ROOT'};

	my $i = new_ok('CGI::Info');
	untainted_ok($i->tmpdir());
	untainted_ok($i->script_name());
	untainted_ok($i->tmpdir() . '/' . $i->script_name() . '.foo');
	untainted_ok($i->script_path());
}
