#!perl -Tw

use strict;
use warnings;
use Test::More;
use Test::Without::Module qw(LWP::Simple);

use lib 't/lib';
use MyLogger;

# See https://rt.cpan.org/Public/Bug/Display.html?id=79214


unless(-e 't/online.enabled') {
	plan skip_all => 'On-line tests disabled';
} elsif((eval { require Geo::IP; }) ||
	(eval { require JSON::Parse } )) {
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
	eval {
		my $t = $l->time_zone();
		die "Shouldn't succeed";
	};
	like($@, qr/^You must have LWP::Simple/, 'Need connection to ip-api.com');
} else {
	plan skip_all => 'Need either Geo::IP or JSON::Parse to test t/time_zone.t'
}
