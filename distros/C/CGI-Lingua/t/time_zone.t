#!perl -Tw

use strict;
use warnings;
use Test::Most;
use lib 't/lib';
use MyLogger;

unless(-e 't/online.enabled') {
	plan skip_all => 'On-line tests disabled';
} elsif((eval { require Geo::IP; }) ||
	((eval { require LWP::Simple }) &&
	 (eval { require JSON::Parse } ))) {
	plan tests => 8;

	use_ok('CGI::Lingua');
	
	require Test::NoWarnings;
	Test::NoWarnings->import();

	# Stop I18N::LangTags::Detect from detecting something
	delete $ENV{'LANGUAGE'};
	delete $ENV{'LC_ALL'};
	delete $ENV{'LC_MESSAGES'};
	delete $ENV{'LANG'};
	if($^O eq 'MSWin32') {
		$ENV{'IGNORE_WIN32_LOCALE'} = 1;
	}

	delete $ENV{'HTTP_ACCEPT_LANGUAGE'};
	delete $ENV{'REMOTE_ADDR'};

	$ENV{'REMOTE_ADDR'} = '212.159.106.41';
	my $l = CGI::Lingua->new(
		supported => ['en'],
		logger => MyLogger->new()
	);
	ok(defined($l));
	ok($l->isa('CGI::Lingua'));
	is($l->time_zone(), 'Europe/London', 'Europe/London');

	$ENV{'REMOTE_ADDR'} = '72.83.250.144';

	$l = CGI::Lingua->new(
		supported => ['en'],
		logger => MyLogger->new()
	);
	ok(defined($l));
	ok($l->isa('CGI::Lingua'));
	is($l->time_zone(), 'America/New_York', 'America/New_York');
} else {
	plan skip_all => 'Need either Geo::IP, or JSON::Parse and LWP::Simple to test t/time_zone.t'
}
