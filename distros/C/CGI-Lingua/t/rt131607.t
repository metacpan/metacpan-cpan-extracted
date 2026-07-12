#!perl -Tw

use strict;
use warnings;
use Test::More;
use Test::Without::Module qw(LWP::Simple::WithCache LWP::Simple);
use Test::Needs 'Geo::IP', 'JSON::Parse';

use lib 't/lib';
use MyLogger;

# See https://rt.cpan.org/Public/Bug/Display.html?id=79214

if(-e 't/online.enabled') {
	plan tests => 4;

	use_ok('CGI::Lingua');

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
	# time_zone() degrades gracefully when both LWP variants are absent:
	# it warns via the logger and returns undef rather than croaking.
	my $t = $l->time_zone();
	is($t, undef, 'time_zone() returns undef when LWP::Simple::WithCache and LWP::Simple are absent');
} else {
	plan skip_all => 'On-line tests disabled';
}
