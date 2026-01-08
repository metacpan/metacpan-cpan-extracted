#!/usr/bin/env perl

###################################################################
#### NOTE env-var PERL_TEST_TEMPDIR_TINY_NOCLEANUP=1 will stop erasing tmp files
###################################################################

###################################################################
### The cookies cases are from:
###    HTTP-Cookies-6.11/t/cookies.t
###################################################################

use strict;
use warnings;

our $VERSION = '0.01';

use Test::More;
use Test::More::UTF8;
use Test::Deep '!blessed';
use FindBin;
use Test::TempDir::Tiny;
use HTTP::CookieJar;
use HTTP::Cookies;
use HTTP::Cookies ();
use HTTP::Request ();
use HTTP::Response ();
use URI ();

use Data::Roundtrip qw/perl2dump no-unicode-escape-permanently/;

use lib ($FindBin::Bin, 'blib/lib');

use Cookies::Roundtrip qw/:count :as_string :equal
	httpcookiejar2httpcookies httpcookies2httpcookiejar
/;

my $VERBOSITY = 4; # we need verbosity of 10 (max), so this is not used

my $curdir = $FindBin::Bin;

require(File::Spec->catfile($curdir, 'MY', 'CookieMaker.pm'));
#ok(@MY::CookieMaker::HTTPCookieJar_cases, "Library 'CookieMaker.pm' loaed OK/1.") or BAIL_OUT;
ok(@MY::CookieMaker::HTTPCookies_cases, "Library 'CookieMaker.pm' loaed OK/2.") or BAIL_OUT;

# if for debug you change this make sure that it has path in it e.g. ./xyz
#my $tmpdir = tempdir(); # will be erased unless a BAIL_OUT or env var set
#ok(-d $tmpdir, "tmpdir exists $tmpdir") or BAIL_OUT;

my $skip_discard = 0;
for my $c (@MY::CookieMaker::HTTPCookies_cases) {
	# these 2 fail because they have a leading dot in the domain
	# which is supported by HTTP::Cookies but not by HTTP::CookieJar
	# which removes it. So skip them:
	#next unless $c->{label} eq 'test02';
	#next if $c->{label} eq 'test06';
	#next if $c->{label} eq 'test50';

        diag "\n==================\ntest " . $c->{label} . "\n==================\n";    

	my $httpcookies = $c->{getcookie}->();
	ok(defined $httpcookies, "(label : ".$c->{'label'}.") : got the HTTP::Cookies object by running the test sub.") or BAIL_OUT;

	# cookies to cookiejar
	my $httpcookiejar = httpcookies2httpcookiejar($httpcookies, undef, $skip_discard, $VERBOSITY);
	ok(defined $httpcookiejar, 'httpcookies2httpcookiejar()'." (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;
	# cookiejar to cookies
	my $new_httpcookies = httpcookiejar2httpcookies($httpcookiejar, undef, $skip_discard, $VERBOSITY);
	ok(defined $new_httpcookies, 'httpcookiejar2httpcookies()'." (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;
	
	if( $VERBOSITY > 2 ){
		# NOTE: if cookie is not showing, check its expiry!!!!
		diag "OLD (label '".$c->{label}."') : (Started) HTTP::Cookies:\n"; diag as_string_cookies($httpcookies);
		diag "OLD (label '".$c->{label}."') : (Converted) HTTP::CookieJar:\n"; diag as_string_cookies($httpcookiejar);
		diag "NEW (label '".$c->{label}."') : HTTP::Cookies:\n"; diag as_string_cookies($new_httpcookies);
	}

	# compare number of cookies
	my $c1 = count_cookies($httpcookies, $skip_discard, $VERBOSITY);
        ok(defined($c1), 'count_cookies()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;
	my $c2 = count_cookies($httpcookiejar, $skip_discard, $VERBOSITY);
        ok(defined($c2), 'count_cookies()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;
	my $c3 = count_cookies($new_httpcookies, $skip_discard, $VERBOSITY);
        ok(defined($c3), 'count_cookies()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;

	# NOTE: if cookie is not showing, check its expiry!!!!
	is($c1, $c2, "(label '".$c->{label}."') : there is the same number of cookies in 1 ($c1) and 2 ($c2).") or BAIL_OUT;
	is($c2, $c3, "(label '".$c->{label}."') : there is the same number of cookies in 2 ($c2) and 3 ($c3).") or BAIL_OUT;

	# compare new and old cookiejar
	is(cookies_are_equal_httpcookies(
		$httpcookies,
		$new_httpcookies,
		$skip_discard,
		$VERBOSITY
	), 1, "(label '".$c->{label}."') : roundtrip objects are equal.") or BAIL_OUT;

	# now compare to a random cookie, they must not be the same
	my $httpcookies_neq = MY::CookieMaker::HTTPCookies_make_random();
	ok(defined($httpcookies_neq), 'MY::CookieMaker::HTTPCookies_make_random()'.": called and got good result.") or BAIL_OUT;

	# this must fail	
	is(cookies_are_equal(
		$httpcookies,
		$httpcookies_neq,
		$skip_discard,
		$VERBOSITY
	), 0, "(label '".$c->{label}."') : roundtrip objects are not equal as expected.") or BAIL_OUT;
}

#diag "temp dir: $tmpdir ..." if exists($ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}) && $ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}>0;

# END
done_testing();
