#!perl -Tw

# This test requires finding an IP address which whois maps to 'EU' rather
# than a country.  The IP address to use tends to change as the data are
# updated

use strict;
use warnings;
use Test::Most;
use lib 't/lib';
use MyLogger;

# Check comments in Whois records

unless(-e 't/online.enabled') {
	plan skip_all => 'On-line tests disabled';
} else {
	plan tests => 11;

	use_ok('CGI::Lingua');
	diag('Ignore messages about the unknown country eu. Some whois records list the country as EU even though it is not a country');
	# Stop I18N::LangTags::Detect from detecting something
	delete $ENV{'LANGUAGE'};
	delete $ENV{'LC_ALL'};
	delete $ENV{'LC_MESSAGES'};
	delete $ENV{'LANG'};
	if($^O eq 'MSWin32') {
		$ENV{'IGNORE_WIN32_LOCALE'} = 1;
	}

	$ENV{'HTTP_ACCEPT_LANGUAGE'} = 'en';
	$ENV{'REMOTE_ADDR'} = '212.49.88.99';
	my $l = new_ok('CGI::Lingua' => [
		supported => ['en'],
		logger => MyLogger->new()
	]);
	ok(defined $l);
	ok($l->isa('CGI::Lingua'));

	# GeoIP correctly identifies this IP as being in Kenya, so
	# force lookup on Whois
	$l->{_have_geoip} = 0;
	$l->{_have_geoipfree} = 0;
	$l->{_have_ipcountry} = 0;

	SKIP: {
		skip 'Tests require Internet access', 6 unless(-e 't/online.enabled');
		skip 'FIXME: find another EU IP address', 6 if(defined($l->country()) && ($l->country() eq 'ke'));
		skip 'FIXME: find another EU IP address', 6 if(defined($l->country()) && ($l->country() eq 'nl'));
		ok(defined($l->country()));
		ok($l->country() eq 'Unknown');
		ok($l->language_code_alpha2() eq 'en');
		ok($l->language() eq 'English');
		ok(defined($l->requested_language()));
		ok($l->requested_language() eq 'English');
	}
	ok(!defined($l->sublanguage()));
	# diag($l->locale());
}
