#!perl -Tw

use strict;
use warnings;
use Test::Most tests => 11;
use Test::NoWarnings;

BEGIN {
	require_ok('CGI::Info');
}

PATHS: {
	delete $ENV{'LOGDIR'};

	my $i = new_ok('CGI::Info');
	my $dir = $i->logdir();
	ok(defined($dir));
	diag($dir);
	ok(-w $dir);
	ok(-d $dir);

	ok($i->logdir('.') eq '.');
	ok($i->logdir() eq '.');

	$dir = CGI::Info::logdir();
	ok(defined($dir));
	diag($dir);
	ok(-w $dir);
	ok(-d $dir);
}
