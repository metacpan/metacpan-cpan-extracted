#!/usr/bin/env perl

###################################################################
#### NOTE env-var PERL_TEST_TEMPDIR_TINY_NOCLEANUP=1 will stop erasing tmp files
###################################################################

use strict;
use warnings;

#use utf8;

our $VERSION = '0.01';

use Test::More;
use Test::More::UTF8;
use Test::Deep '!blessed';
use FindBin;
use Test::TempDir::Tiny;
use HTTP::CookieJar;

use Data::Roundtrip qw/perl2dump no-unicode-escape-permanently/;

use lib ($FindBin::Bin, 'blib/lib');

use Cookies::Roundtrip qw/:count :as_string :equal
	firefoxmarionettecookies2httpcookies
	httpcookies2firefoxmarionettecookies
	as_string_cookies
	count_cookies
	merge_cookies
/;

my $VERBOSITY = 4; # we need verbosity of 10 (max), so this is not used

my $curdir = $FindBin::Bin;

require(File::Spec->catfile($curdir, 'MY', 'CookieMaker.pm'));
# if you don't use any of these it will complain:
#   "..." used only once: possible typo at ...
#ok(@MY::CookieMaker::HTTPCookies_cases, "Library 'CookieMaker.pm' loaed OK/1.") or BAIL_OUT;
ok(@MY::CookieMaker::FirefoxMarionetteCookies_cases, "Library 'CookieMaker.pm' loaed OK/2.") or BAIL_OUT;

# if for debug you change this make sure that it has path in it e.g. ./xyz
#my $tmpdir = tempdir(); # will be erased unless a BAIL_OUT or env var set
#ok(-d $tmpdir, "tmpdir exists $tmpdir") or BAIL_OUT;

my $skip_discard = 0;

for my $c (@MY::CookieMaker::FirefoxMarionetteCookies_cases) {
        diag "\n==================\ntest " . $c->{label} . "\n==================\n";    

	ok(exists($c->{'constructor-params'}), "cookie data has field 'constructor-params'.") or BAIL_OUT("no, check t/MY/CookieMaker.pm under 'FirefoxMarionetteCookies_cases'.");
	ok(defined($c->{'constructor-params'}), "cookie data has field 'constructor-params'. and it has a defined value.") or BAIL_OUT("no, check t/MY/CookieMaker.pm under 'FirefoxMarionetteCookies_cases'.");
	my $ffparams = $c->{'constructor-params'};

	my $firefoxmarionettecookies = $c->{'getcookie'}->($c->{'constructor-params'});
	ok(defined $firefoxmarionettecookies, 'getcookie()'.": (label '".$c->{label}."') : called and got the cookie.") or BAIL_OUT;

	for(my $i=scalar(@$firefoxmarionettecookies);$i-->0;){
		my $acookie = $firefoxmarionettecookies->[$i];
		my $acookie_params = $ffparams->[$i];
		for my $k (keys %$acookie_params){
			ok(exists($acookie->{$k}), "New Firefox::Marionette::Cookie has field '$k'.") or BAIL_OUT(perl2dump($acookie_params)."no, see above.");
			ok(defined($acookie->{$k}), "New Firefox::Marionette::Cookie has field '$k' and it has a defined value.") or BAIL_OUT(perl2dump($acookie_params)."no, see above.");
		}
	}

	if( $VERBOSITY > 0 ){ diag "Created array of Firefox::Marionette::Cookie is this:\n".as_string_cookies($firefoxmarionettecookies) }

	# now do the roundtrip
	my $httpcookies = firefoxmarionettecookies2httpcookies($firefoxmarionettecookies, undef, undef, $VERBOSITY);
	ok(defined $httpcookies, 'firefoxmarionettecookies2httpcookies()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;

	if( $VERBOSITY > 0 ){ diag as_string_cookies($httpcookies); }

	# firefoxmarionettecookies -> httpcookies
	my $new_httpcookies = firefoxmarionettecookies2httpcookies($firefoxmarionettecookies, undef, $skip_discard, $VERBOSITY);
	ok(defined($new_httpcookies), 'firefoxmarionettecookies2httpcookies()'." : (label '".$c->{label}."') : (label '".$c->{label}."') : called and got good results.") or BAIL_OUT;

	if( $VERBOSITY > 2 ){
		diag "OLD (label '".$c->{label}."') :\n"; diag explain as_string_cookies($httpcookies);
		diag "NEW (label '".$c->{label}."') :\n"; diag explain as_string_cookies($new_httpcookies);
	}

	# compare new and old httpcookies
	my $c1 = count_cookies($httpcookies, $skip_discard, $VERBOSITY);
        ok(defined($c1), 'count_cookies()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;
	my $c2 = count_cookies($firefoxmarionettecookies, $skip_discard, $VERBOSITY);
        ok(defined($c2), 'count_cookies()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;
	my $c3 = count_cookies($new_httpcookies, $skip_discard, $VERBOSITY);
        ok(defined($c3), 'count_cookies()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;

	is($c1, $c2, "(label '".$c->{label}."') : there is the same number of cookies in 1 ($c1) and 2 ($c2).") or BAIL_OUT;
	is($c2, $c3, "(label '".$c->{label}."') : there is the same number of cookies in 2 ($c2) and 3 ($c3).") or BAIL_OUT;

	# this must succeed:
	is(cookies_are_equal(
		$httpcookies,
		$new_httpcookies,
		$VERBOSITY
	), 1, "(label '".$c->{label}."') : roundtrip objects are equal.") or BAIL_OUT;
}

#diag "temp dir: $tmpdir ..." if exists($ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}) && $ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}>0;

# END
done_testing();
