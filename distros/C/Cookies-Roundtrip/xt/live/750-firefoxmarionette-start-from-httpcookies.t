#!/usr/bin/env perl

###################################################################
#### NOTE env-var PERL_TEST_TEMPDIR_TINY_NOCLEANUP=1 will stop erasing tmp files
###################################################################

# this fails randomly in cmp cookies
# and this is due to the fact that @firefoxmarionettecookies
# has an order of cookies, fixed in source.

use strict;
use warnings;

our $VERSION = '0.01';

use Test::More;
use Test::More::UTF8;
use Test::Deep '!blessed';
use FindBin;
use Test::TempDir::Tiny;
use HTTP::CookieJar;
use Firefox::Marionette;

use Data::Roundtrip qw/perl2dump no-unicode-escape-permanently/;

use lib ($FindBin::Bin, 'blib/lib');

use Cookies::Roundtrip qw/:count :as_string :equal
	httpcookies2firefoxmarionettecookies
	:firefoxmarionettecookies2
	:firefoxmarionette
/;

my $VERBOSITY = 4; # we need verbosity of 10 (max), so this is not used

my $curdir = $FindBin::Bin;

require(File::Spec->catfile($curdir, '..', '..', 't', 'MY', 'CookieMaker.pm'));

#ok(@MY::CookieMaker::HTTPCookieJar_cases, "Library 'CookieMaker.pm' loaed OK/1.") or BAIL_OUT;
ok(@MY::CookieMaker::HTTPCookies_cases, "Library 'CookieMaker.pm' loaed OK/2.") or BAIL_OUT;
#ok(@MY::CookieMaker::FirefoxMarionetteCookies_cases, "Library 'CookieMaker.pm' loaed OK/3.") or BAIL_OUT;

# if for debug you change this make sure that it has path in it e.g. ./xyz
my $tmpdir = tempdir(); # will be erased unless a BAIL_OUT or env var set
ok(-d $tmpdir, "tmpdir exists $tmpdir") or BAIL_OUT;

my $skip_discard = 0;

my %ffmar_constructor_params = (
	'visible' => 0,
	'addons' => 1,
	#'profile_name' => 'marionette-insecure-do-not-use',
	#'debug' => ($VERBOSITY>0) ? 'all:5' : undef,
);

# note: session cookies (i.e. expiry is undef) are not fetched from browser!

for my $c (@MY::CookieMaker::HTTPCookies_cases) {
	# note: test-04: does not return the cookies! it returns empty, but test-02 gets them back
	#       even if expiry is undef for both.
	#       test-05: which has cookies for /acme and one for /acme/ammo fails
	next if $c->{label} eq 'test-05';
	next if $c->{label} eq 'test-08';
	#next unless $c->{label} =~ /\-1[2345]$/;
	diag "\n=====================\ntest " . $c->{label} . " (of ".scalar(@MY::CookieMaker::HTTPCookies_cases).")\n=====================\n";

	my $httpcookies = $c->{getcookie}->();
	ok(defined $httpcookies, "(label : ".$c->{'label'}.") : got the HTTP::Cookies object by running the test sub.") or BAIL_OUT;
	my $httpcookies_count = count_cookies($httpcookies, $skip_discard, $VERBOSITY);
	ok(defined($httpcookies_count), 'count_cookies()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;

	if( $VERBOSITY > 0 ){ diag "testing with this HTTP::Cookies object:\n".as_string_cookies($httpcookies); }

	my $firefoxmarionettecookies = httpcookies2firefoxmarionettecookies($httpcookies, undef, $skip_discard, $VERBOSITY);
	ok(defined($firefoxmarionettecookies), 'httpcookies2firefoxmarionettecookies()'." : (label '".$c->{label}."') : converted HTTP::Cookies (read from the test case) to firefoxmarionettecookies.") or BAIL_OUT(as_string_cookies($httpcookies)."\nno, it failed for above cookie.");

	my $firefoxmarionettecookies_count = count_cookies($firefoxmarionettecookies, $skip_discard, $VERBOSITY);
	ok(defined($firefoxmarionettecookies_count), 'count_cookies()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;
	# we can have empty cookie, so don't check
	#ok($firefoxmarionettecookies_count > 0, 'count_cookies()'." : (label '".$c->{label}."') : at least one cookie to test with.") or BAIL_OUT(as_string_cookies($firefoxmarionettecookies)."\nno, see above cookies.");

	my $num_session_cookies = 0;
	#for (@$firefoxmarionettecookies){ $num_session_cookies++ if ! exists($_->{expiry}) || ! defined($_->{expiry}) }

	if( $VERBOSITY > 0 ){ diag "converted HTTP::Cookies object to array of Firefox::Marionette::Cookie:\n".as_string_cookies($firefoxmarionettecookies)."\n NOTE: there are ${firefoxmarionettecookies_count} cookies, of those ${num_session_cookies} are session cookies."; }

	my $ffmarobj1 = Firefox::Marionette->new(%ffmar_constructor_params);
	ok(!$@ && defined($ffmarobj1), 'Firefox::Marionette->new()'." : (label '".$c->{label}."') : called and got good result/1.") or BAIL_OUT("got this exception: $@");
	# you need to load the url of the cookie domain before you add the cookie
	# because adding cookies to no document says 'cookie-averse' document
	# you also CAN NOT add cookies for different domains!!!! only same domain
	# cookies to the document you visited.
	# visit another domain and you can add cookies for that domain
	# that's why we pass '' (meaning go to the domain url) to below sub:
	my $ret = firefoxmarionette_load_cookies($ffmarobj1, $firefoxmarionettecookies, '', $skip_discard, $VERBOSITY);
	ok(defined($ret), 'firefoxmarionette_load_cookies()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;

	my $firefoxmarionettecookies2 = firefoxmarionette_get_cookies($ffmarobj1, $VERBOSITY);
	ok(defined($firefoxmarionettecookies2), 'firefoxmarionette_get_cookies()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;

	my $firefoxmarionettecookies2_count = count_cookies($firefoxmarionettecookies2, $skip_discard, $VERBOSITY);
	ok(defined($firefoxmarionettecookies2_count), 'count_cookies()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;
	if( $VERBOSITY > 0 ){ diag "Cookies from Firefox Marionette browser:\n".as_string_cookies($firefoxmarionettecookies2); }

	# it seems session cookies are not returned by ffmar! or not?
	ok(($firefoxmarionettecookies_count-$num_session_cookies) >= $firefoxmarionettecookies2_count, 'firefoxmarionette_load_cookies()'." : (label '".$c->{label}."') : the number of loaded cookies minus session cookies (which are not returned) (${firefoxmarionettecookies_count}-${num_session_cookies}) is at least equal to the number of extracted cookies (${firefoxmarionettecookies2_count}). It can be greater if the site added some more cookies to the browser.") or BAIL_OUT;

	my $httpcookies2 = firefoxmarionettecookies2httpcookies($firefoxmarionettecookies2, undef, $skip_discard, $VERBOSITY);
	ok(defined $httpcookies2, 'firefoxmarionettecookies2httpcookies()'." (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;
	my $httpcookies2_count = count_cookies($httpcookies2, $skip_discard, $VERBOSITY);
	ok(defined($httpcookies2_count), 'count_cookies()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;
	# the site itself may give us cookies, so we need to check >=
	ok($firefoxmarionettecookies2_count >= $httpcookies2_count, "(label '".$c->{label}."') : count of firefoxmarionettecookies ($firefoxmarionettecookies_count) is >= to the count of httpcookies ($httpcookies2_count) we started with, the site could have given us more cookies.") or BAIL_OUT;
	if( $VERBOSITY > 0 ){ diag "Cookies from Firefox Marionette browser as HTTP::Cookies:\n".as_string_cookies($httpcookies2); }

	# save to file
	my $cooksfile = File::Spec->catfile($tmpdir, 'firefoxmarionette_cookies.txt');
	$ret = firefoxmarionette_save_cookies_to_file($ffmarobj1, $cooksfile, $skip_discard, $VERBOSITY);
	ok(defined($ret), 'firefoxmarionette_save_cookies_to_file()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;
	ok(-f $cooksfile, 'firefoxmarionette_save_cookies_to_file()'." : (label '".$c->{label}."') : output cookies file '$cooksfile' exists on disk.") or BAIL_OUT;
	# beware, it can be just a single line of #LWP...
	ok(!-z $cooksfile, 'firefoxmarionette_save_cookies_to_file()'." : (label '".$c->{label}."') : output cookies file '$cooksfile' has some content.") or BAIL_OUT;

	# create a new UA and load the cookies from file
	my $ffmarobj2 = eval { Firefox::Marionette->new(%ffmar_constructor_params) };
	ok(!$@ && defined($ffmarobj2), 'Firefox::Marionette->new()'." : (label '".$c->{label}."') : called and got good result/1.") or BAIL_OUT("got this exception: $@");
	# this must fail because file does not exist
	# visit another domain and you can add cookies for that domain
	# that's why we pass '' (meaning go to the domain url) to below sub:
	my $file_cookies = firefoxmarionette_load_cookies($ffmarobj2, $cooksfile.'.xxxx', '', $skip_discard, $VERBOSITY);
	ok(!defined($file_cookies), 'firefoxmarionette_load_cookies()'." : (label '".$c->{label}."') : called for loading cookies from file (${cooksfile}xxxx) and got failure as expected because input file does not exist.") or BAIL_OUT;
	# visit another domain and you can add cookies for that domain
	# that's why we pass '' (meaning go to the domain url) to below sub:
	$file_cookies = firefoxmarionette_load_cookies($ffmarobj2, $cooksfile, '', $skip_discard, $VERBOSITY);
	ok(defined($file_cookies), 'firefoxmarionette_load_cookies()'." : (label '".$c->{label}."') : called for loading cookies from file ($cooksfile) and got good result.") or BAIL_OUT;
	if( $VERBOSITY > 0 ){ diag "Cookies from file '$cooksfile':\n".as_string_cookies($file_cookies); }

	# UA and UA2 must have exactly the same cookies
	my $mech_firefoxmarionettecookies1 = firefoxmarionette_get_cookies($ffmarobj1, $VERBOSITY);
	ok(defined($mech_firefoxmarionettecookies1), 'firefoxmarionette_get_cookies()'." : (label '".$c->{label}."') : called and got good results/1.") or BAIL_OUT;

	my $mech_firefoxmarionettecookies2 = firefoxmarionette_get_cookies($ffmarobj2, $VERBOSITY);
	ok(defined($mech_firefoxmarionettecookies2), 'firefoxmarionette_get_cookies()'." : (label '".$c->{label}."') : called and got good results/2.") or BAIL_OUT;

	# compare number of cookies
	my $c1 = count_cookies($firefoxmarionettecookies, $skip_discard, $VERBOSITY);
	ok(defined($c1), 'count_cookies()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;
	my $c2 = count_cookies($firefoxmarionettecookies2, $skip_discard, $VERBOSITY);
	ok(defined($c2), 'count_cookies()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;
	my $c3 = count_cookies($httpcookies, $skip_discard, $VERBOSITY);
	ok(defined($c3), 'count_cookies()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;

	ok($c1-$num_session_cookies >= $c2, "(label '".$c->{label}."') : the number of cookies in 1 ($c1-${num_session_cookies} session cookies) is at least the same as in 2 ($c2). The site could have added more cookies.") or BAIL_OUT;
	ok($c2 <= $c3-$num_session_cookies, "(label '".$c->{label}."') : the number of cookies in 3 ($c3-${num_session_cookies} session cookies) is at least the same as in 2 ($c2). The site could have added more cookies.") or BAIL_OUT;

	# compare only if the same number of cookies
	if( (($c1-$num_session_cookies) == $c2)
	 && (($c3-$num_session_cookies) == $c2)
	){
		$ret = cookies_are_equal(
			$mech_firefoxmarionettecookies1,
			$mech_firefoxmarionettecookies2,
			$skip_discard,
			$VERBOSITY
		);
		ok(defined $ret, 'cookies_are_equal()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;
		is($ret, 1, 'cookies_are_equal()'." : (label '".$c->{label}."') : cookies from the two browsers are equal.") or BAIL_OUT("--begin mech_firefoxmarionettecookies1:\n".as_string_cookies($mech_firefoxmarionettecookies1)."\n--end cookies1\n--begin mech_firefoxmarionettecookies2:\n".as_string_cookies($mech_firefoxmarionettecookies2)."\n--end coookies2.\nno they are not the same, see them above.");
	}

	unlink($cooksfile);
} 

for my $c (@MY::CookieMaker::HTTPCookies_cases) {
	# note: test-04: does not return the cookies! it returns empty, but test-02 gets them back
	#       even if expiry is undef for both.
	#next if $c->{label} eq 'test-04';
	#next unless $c->{label} =~ /\-1[2345]$/;

	diag "\n=====================\ntest " . $c->{label} . " (of ".scalar(@MY::CookieMaker::HTTPCookies_cases).")\n=====================\n";

	my $httpcookies = $c->{getcookie}->();
	ok(defined $httpcookies, "(label : ".$c->{'label'}.") : got the HTTP::Cookies object by running the test sub.") or BAIL_OUT;
	my $httpcookies_count = count_cookies($httpcookies, $skip_discard, $VERBOSITY);
	ok(defined($httpcookies_count), 'count_cookies()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;

	if( $VERBOSITY > 0 ){ diag "testing with this HTTP::Cookies object:\n".as_string_cookies($httpcookies); }

	my $firefoxmarionettecookies = httpcookies2firefoxmarionettecookies($httpcookies, undef, $skip_discard, $VERBOSITY);
	ok(defined($firefoxmarionettecookies), 'httpcookies2firefoxmarionettecookies()'." : (label '".$c->{label}."') : converted HTTP::Cookies (read from the test case) to firefoxmarionettecookies.") or BAIL_OUT(as_string_cookies($httpcookies)."\nno, it failed for above cookie.");

	my $firefoxmarionettecookies_count = count_cookies($firefoxmarionettecookies, $skip_discard, $VERBOSITY);
	ok(defined($firefoxmarionettecookies_count), 'count_cookies()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;
	# we can have empty cookie, so don't check
	#ok($firefoxmarionettecookies_count > 0, 'count_cookies()'." : (label '".$c->{label}."') : at least one cookie to test with.") or BAIL_OUT(as_string_cookies($firefoxmarionettecookies)."\nno, see above cookies.");

	my $num_session_cookies = 0;
	#for (@$firefoxmarionettecookies){ $num_session_cookies++ if ! exists($_->{expiry}) || ! defined($_->{expiry}) }

	if( $VERBOSITY > 0 ){ diag "converted HTTP::Cookies object to array of Firefox::Marionette::Cookie:\n".as_string_cookies($firefoxmarionettecookies)."\n NOTE: there are ${firefoxmarionettecookies_count} cookies, of those ${num_session_cookies} are session cookies."; }

	my $ffmarobj1 = Firefox::Marionette->new(%ffmar_constructor_params);
	ok(!$@ && defined($ffmarobj1), 'Firefox::Marionette->new()'." : (label '".$c->{label}."') : called and got good result/1.") or BAIL_OUT("got this exception: $@");
	# you need to load the url of the cookie domain before you add the cookie
	# because adding cookies to no document says 'cookie-averse' document
	# you also CAN NOT add cookies for different domains!!!! only same domain
	# cookies to the document you visited.
	# visit another domain and you can add cookies for that domain
	# so now we will pass a url (with paths) made from the domain
	# WARNING: we hope that the other cookies in this jar/file are all from the same domain and
	# will be set without complains (in the firefoxmarionette_load_firefoxmarionettecookies()
	# we do this for each cookie! but here just make sure the 1st test case does not have problems).
	# WARNING: we hope that the other cookies in this jar/file are all from the same domain and
	# will be set without complains (in the firefoxmarionette_load_firefoxmarionettecookies()
	# we do this for each cookie! but here just make sure the 1st test case does not have problems).
	my $domain = $firefoxmarionettecookies->[0]->domain;
	$domain =~ s/^\.//; # domain sometimes starts with a dot
	my $url = eval {
		my $uri = URI->new();
		$uri->scheme('https'); # i guess!!!
		$uri->host($domain);
		# there may be a path else use some imaginary path
		# hoping it will not redirect us OUTSIDE the domain, inside the domain is ok, cookie will be set.
		$uri->path(defined($firefoxmarionettecookies->[0]->path)?$firefoxmarionettecookies->[0]->path:'a/b/c');
		$uri->as_string;
	};
	ok(!$@&&defined($url), "got the url from the cookie domain ($url).") or BAIL_OUT("no: $@");
	my $ret = firefoxmarionette_load_cookies($ffmarobj1, $firefoxmarionettecookies, $url, $skip_discard, $VERBOSITY);
	ok(defined($ret), 'firefoxmarionette_load_cookies()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;

	my $firefoxmarionettecookies2 = firefoxmarionette_get_cookies($ffmarobj1, $VERBOSITY);
	ok(defined($firefoxmarionettecookies2), 'firefoxmarionette_get_cookies()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;

	my $firefoxmarionettecookies2_count = count_cookies($firefoxmarionettecookies2, $skip_discard, $VERBOSITY);
	ok(defined($firefoxmarionettecookies2_count), 'count_cookies()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;
	if( $VERBOSITY > 0 ){ diag "Cookies from Firefox Marionette browser:\n".as_string_cookies($firefoxmarionettecookies2); }

	# it seems session cookies are not returned by ffmar! or not?
	ok(($firefoxmarionettecookies_count-$num_session_cookies) >= $firefoxmarionettecookies2_count, 'firefoxmarionette_load_cookies()'." : (label '".$c->{label}."') : the number of loaded cookies minus session cookies (which are not returned) (${firefoxmarionettecookies_count}-${num_session_cookies}) is at least equal to the number of extracted cookies (${firefoxmarionettecookies2_count}). It can be greater if the site added some more cookies to the browser.") or BAIL_OUT;

	my $httpcookies2 = firefoxmarionettecookies2httpcookies($firefoxmarionettecookies2, undef, $skip_discard, $VERBOSITY);
	ok(defined $httpcookies2, 'firefoxmarionettecookies2httpcookies()'." (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;
	my $httpcookies2_count = count_cookies($httpcookies2, $skip_discard, $VERBOSITY);
	ok(defined($httpcookies2_count), 'count_cookies()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;
	# the site itself may give us cookies, so we need to check >=
	ok($firefoxmarionettecookies2_count >= $httpcookies2_count, "(label '".$c->{label}."') : count of firefoxmarionettecookies ($firefoxmarionettecookies_count) is >= to the count of httpcookies ($httpcookies2_count) we started with, the site could have given us more cookies.") or BAIL_OUT;
	if( $VERBOSITY > 0 ){ diag "Cookies from Firefox Marionette browser as HTTP::Cookies:\n".as_string_cookies($httpcookies2); }

	# save to file
	my $cooksfile = File::Spec->catfile($tmpdir, 'firefoxmarionette_cookies.txt');
	$ret = firefoxmarionette_save_cookies_to_file($ffmarobj1, $cooksfile, $skip_discard, $VERBOSITY);
	ok(defined($ret), 'firefoxmarionette_save_cookies_to_file()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;
	ok(-f $cooksfile, 'firefoxmarionette_save_cookies_to_file()'." : (label '".$c->{label}."') : output cookies file '$cooksfile' exists on disk.") or BAIL_OUT;
	# beware, it can be just a single line of #LWP...
	ok(!-z $cooksfile, 'firefoxmarionette_save_cookies_to_file()'." : (label '".$c->{label}."') : output cookies file '$cooksfile' has some content.") or BAIL_OUT;

	# create a new UA and load the cookies from file
	my $ffmarobj2 = eval { Firefox::Marionette->new(%ffmar_constructor_params) };
	ok(!$@ && defined($ffmarobj2), 'Firefox::Marionette->new()'." : (label '".$c->{label}."') : called and got good result/1.") or BAIL_OUT("got this exception: $@");
	# this must fail because file does not exist
	# visit another domain and you can add cookies for that domain
	# that's why we pass '' (meaning go to the domain url) to below sub:
	# well since this will fail just give it undef (meaning no visit) to check that too
	my $file_cookies = firefoxmarionette_load_cookies($ffmarobj2, $cooksfile.'.xxxx', undef, $skip_discard, $VERBOSITY);
	ok(!defined($file_cookies), 'firefoxmarionette_load_cookies()'." : (label '".$c->{label}."') : called for loading cookies from file (${cooksfile}xxxx) and got failure as expected because input file does not exist.") or BAIL_OUT;
	# visit another domain and you can add cookies for that domain
	# visit another domain and you can add cookies for that domain
	# so now we will pass a url (with paths) made from the domain
	# WARNING: we hope that the other cookies in this jar/file are all from the same domain and
	# will be set without complains (in the firefoxmarionette_load_firefoxmarionettecookies()
	# we do this for each cookie! but here just make sure the 1st test case does not have problems).
	$domain = $firefoxmarionettecookies2->[0]->domain; # i guess these are the cookies from the file!!
	$domain =~ s/^\.//; # domain sometimes starts with a dot
	$url = eval {
		my $uri = URI->new();
		$uri->scheme('https'); # i guess!!!
		$uri->host($domain);
		# there may be a path else use some imaginary path
		# hoping it will not redirect us OUTSIDE the domain, inside the domain is ok, cookie will be set.
		$uri->path(defined($firefoxmarionettecookies2->[0]->path)?$firefoxmarionettecookies2->[0]->path:'a/b/c');
		$uri->as_string;
	};
	ok(!$@&&defined($url), "got the url from the cookie domain ($url).") or BAIL_OUT("no: $@");
	$file_cookies = firefoxmarionette_load_cookies($ffmarobj2, $cooksfile, $url, $skip_discard, $VERBOSITY);
	ok(defined($file_cookies), 'firefoxmarionette_load_cookies()'." : (label '".$c->{label}."') : called for loading cookies from file ($cooksfile) and got good result.") or BAIL_OUT;
	if( $VERBOSITY > 0 ){ diag "Cookies from file '$cooksfile':\n".as_string_cookies($file_cookies); }

	# UA and UA2 must have exactly the same cookies
	my $mech_firefoxmarionettecookies1 = firefoxmarionette_get_cookies($ffmarobj1, $VERBOSITY);
	ok(defined($mech_firefoxmarionettecookies1), 'firefoxmarionette_get_cookies()'." : (label '".$c->{label}."') : called and got good results/1.") or BAIL_OUT;

	my $mech_firefoxmarionettecookies2 = firefoxmarionette_get_cookies($ffmarobj2, $VERBOSITY);
	ok(defined($mech_firefoxmarionettecookies2), 'firefoxmarionette_get_cookies()'." : (label '".$c->{label}."') : called and got good results/2.") or BAIL_OUT;

	# compare number of cookies
	my $c1 = count_cookies($firefoxmarionettecookies, $skip_discard, $VERBOSITY);
	ok(defined($c1), 'count_cookies()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;
	my $c2 = count_cookies($firefoxmarionettecookies2, $skip_discard, $VERBOSITY);
	ok(defined($c2), 'count_cookies()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;
	my $c3 = count_cookies($httpcookies, $skip_discard, $VERBOSITY);
	ok(defined($c3), 'count_cookies()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;

	ok($c1-$num_session_cookies >= $c2, "(label '".$c->{label}."') : the number of cookies in 1 ($c1-${num_session_cookies} session cookies) is at least the same as in 2 ($c2). The site could have added more cookies.") or BAIL_OUT;
	ok($c2 <= $c3-$num_session_cookies, "(label '".$c->{label}."') : the number of cookies in 3 ($c3-${num_session_cookies} session cookies) is at least the same as in 2 ($c2). The site could have added more cookies.") or BAIL_OUT;

	# compare only if the same number of cookies
	if( (($c1-$num_session_cookies) == $c2)
	 && (($c3-$num_session_cookies) == $c2)
	){
		$ret = cookies_are_equal(
			$mech_firefoxmarionettecookies1,
			$mech_firefoxmarionettecookies2,
			$skip_discard,
			$VERBOSITY
		);
		ok(defined $ret, 'cookies_are_equal()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;
		is($ret, 1, 'cookies_are_equal()'." : (label '".$c->{label}."') : cookies from the two browsers are equal.") or BAIL_OUT("--begin mech_firefoxmarionettecookies1:\n".as_string_cookies($mech_firefoxmarionettecookies1)."\n--end cookies1\n--begin mech_firefoxmarionettecookies2:\n".as_string_cookies($mech_firefoxmarionettecookies2)."\n--end coookies2.\nno they are not the same, see them above.");
	}

	unlink($cooksfile);

	diag "will not test any more, that's fine ...";

	last; # we do this once
} 

diag "temp dir: $tmpdir ..." if exists($ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}) && $ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}>0;

# END
done_testing();
