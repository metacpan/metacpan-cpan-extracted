#!perl -wT

use strict;
use warnings;
use File::Spec;
use Test::More;

if(not $ENV{RELEASE_TESTING}) {
	plan(skip_all => 'Author tests not required for installation');
}

eval "use Test::Pod::Snippets";

if($@) {
	plan skip_all => 'Test::Pod::Snippets required for testing POD code snippets';
} else {
	# Prevent CGI::Info from reading from STDIN, which hangs the test
	$ENV{'GATEWAY_INTERFACE'} = 1;
	$ENV{'REQUEST_METHOD'} = 'HEAD';

	my $tps = Test::Pod::Snippets->new;

	my @modules = qw/ CGI::Untaint::CountyStateProvince::US /;

	$tps->runtest( module => $_, testgroup => 1 ) for @modules;
}
