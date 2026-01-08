#!/usr/bin/env perl

###################################################################
#### NOTE env-var PERL_TEST_TEMPDIR_TINY_NOCLEANUP=1 will stop erasing tmp files
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
use URI;
use Firefox::Marionette;

use Data::Roundtrip qw/perl2dump no-unicode-escape-permanently/;

use lib ($FindBin::Bin, 'blib/lib');

use Cookies::Roundtrip qw/:count :as_string :equal
	httpcookiejar2httpcookies httpcookies2httpcookiejar
	:firefoxmarionettecookies2
	:firefoxmarionette
/;

my $VERBOSITY = 4; # we need verbosity of 10 (max), so this is not used

my $curdir = $FindBin::Bin;

require(File::Spec->catfile($curdir, '..', '..', 't', 'MY', 'CookieMaker.pm'));
#ok(@MY::CookieMaker::HTTPCookieJar_cases, "Library 'CookieMaker.pm' loaed OK/1.") or BAIL_OUT;
#ok(@MY::CookieMaker::HTTPCookies_cases, "Library 'CookieMaker.pm' loaed OK/2.") or BAIL_OUT;
ok(@MY::CookieMaker::FirefoxMarionetteCookies_cases, "Library 'CookieMaker.pm' loaed OK/3.") or BAIL_OUT;

# if for debug you change this make sure that it has path in it e.g. ./xyz
my $tmpdir = tempdir(); # will be erased unless a BAIL_OUT or env var set
ok(-d $tmpdir, "tmpdir exists $tmpdir") or BAIL_OUT;

my $skip_discard = 0;

my %ffmar_constructor_params = (
	'visible' => 0,
	#'debug' => ($VERBOSITY>0) ? 5 : 0,
);

for my $c (@MY::CookieMaker::FirefoxMarionetteCookies_cases) {
	diag "\n==================\ntest " . $c->{label} . "\n==================\n";

	my $firefoxmarionettecookies = $c->{getcookie}->($c->{'constructor-params'});

	my $firefoxmarionettecookies_count = count_cookies($firefoxmarionettecookies, $skip_discard, $VERBOSITY);
	ok(defined($firefoxmarionettecookies_count), 'count_cookies()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;
	ok($firefoxmarionettecookies_count > 0, 'count_cookies()'." : (label '".$c->{label}."') : at least one cookie to test with.") or BAIL_OUT(as_string_cookies($firefoxmarionettecookies)."\nno, see above cookies.");

	my $ffmarobj1 = Firefox::Marionette->new(%ffmar_constructor_params);
	ok(defined($ffmarobj1), 'Firefox::Marionette->new()'." : (label '".$c->{label}."') : called and got good result/1.") or BAIL_OUT;
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
	if( $VERBOSITY > 0 ){ diag "Cookies from Firefox Marionette browser:\n".as_string_cookies($firefoxmarionettecookies2); }

	my $firefoxmarionettecookies2_count = count_cookies($firefoxmarionettecookies2, $skip_discard, $VERBOSITY);
	ok(defined($firefoxmarionettecookies2_count), 'count_cookies()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;
	is($firefoxmarionettecookies2_count, $firefoxmarionettecookies2_count, 'firefoxmarionette_load_cookies()'." : (label '".$c->{label}."') : the number of loaded cookies (${firefoxmarionettecookies_count}) is the same as the number of extracted cookies (${firefoxmarionettecookies2_count}).") or BAIL_OUT;

	my $httpcookies = firefoxmarionettecookies2httpcookies($firefoxmarionettecookies2, undef, $skip_discard, $VERBOSITY);
	ok(defined $httpcookies, 'firefoxmarionettecookies2httpcookies()'." (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;
	my $httpcookies_count = count_cookies($httpcookies, $skip_discard, $VERBOSITY);
	ok(defined($httpcookies_count), 'count_cookies()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;
	is($firefoxmarionettecookies_count, $httpcookies_count, "(label '".$c->{label}."') : count is the same for both firefoxmarionettecookies ($firefoxmarionettecookies_count) and httpcookies ($httpcookies_count).") or BAIL_OUT;
	if( $VERBOSITY > 0 ){ diag "Cookies from Firefox Marionette browser as HTTP::Cookies:\n".as_string_cookies($httpcookies); }

	# save to file
	my $cooksfile = File::Spec->catfile($tmpdir, 'firefoxmarionette_cookies.txt');
	$ret = firefoxmarionette_save_cookies_to_file($ffmarobj1, $cooksfile, $skip_discard, $VERBOSITY);
	ok(defined($ret), 'firefoxmarionette_save_cookies_to_file()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;
	ok(-f $cooksfile, 'firefoxmarionette_save_cookies_to_file()'." : (label '".$c->{label}."') : output cookies file '$cooksfile' exists on disk.") or BAIL_OUT;
	# beware, it can be just a single line of #LWP...
	ok(!-z $cooksfile, 'firefoxmarionette_save_cookies_to_file()'." : (label '".$c->{label}."') : output cookies file '$cooksfile' has some content.") or BAIL_OUT;

	# create a new UA and load the cookies from file
	my $ffmarobj2 = Firefox::Marionette->new(%ffmar_constructor_params);
	ok(defined($ffmarobj2), 'Firefox::Marionette->new()'." : (label '".$c->{label}."') : called and got good result/1.") or BAIL_OUT;
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

	is($c1, $c2, "there is the same number of cookies in 1 ($c1) and 2 ($c2).") or BAIL_OUT;
	is($c2, $c3, "there is the same number of cookies in 2 ($c2) and 3 ($c3).") or BAIL_OUT;

	# compare
	$ret = cookies_are_equal($mech_firefoxmarionettecookies1, $mech_firefoxmarionettecookies2, $VERBOSITY);
	ok(defined $ret, 'cookies_are_equal()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;
	is($ret, 1, 'cookies_are_equal()'." : (label '".$c->{label}."') : cookies from the two browsers are equal.") or BAIL_OUT;

	unlink($cooksfile);
}

diag "Testing by going to actual URL instead of the cookie's domain ...";

# now check the load cookies by specifying the url to go, not the domain
for my $c (@MY::CookieMaker::FirefoxMarionetteCookies_cases) {
	# we will do this for just one cookie, there is a last at the end

	diag "\n==================\ntest " . $c->{label} . "\n==================\n";

	my $firefoxmarionettecookies = $c->{getcookie}->($c->{'constructor-params'});

	my $firefoxmarionettecookies_count = count_cookies($firefoxmarionettecookies, $skip_discard, $VERBOSITY);
	ok(defined($firefoxmarionettecookies_count), 'count_cookies()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;
	ok($firefoxmarionettecookies_count > 0, 'count_cookies()'." : (label '".$c->{label}."') : at least one cookie to test with.") or BAIL_OUT(as_string_cookies($firefoxmarionettecookies)."\nno, see above cookies.");

	my $ffmarobj1 = Firefox::Marionette->new(%ffmar_constructor_params);
	ok(defined($ffmarobj1), 'Firefox::Marionette->new()'." : (label '".$c->{label}."') : called and got good result/1.") or BAIL_OUT;
	# you need to load the url of the cookie domain before you add the cookie
	# because adding cookies to no document says 'cookie-averse' document
	# you also CAN NOT add cookies for different domains!!!! only same domain
	# cookies to the document you visited.
	# visit another domain and you can add cookies for that domain
	# but now we will create a URL from the domain with a fictitious path
	# hopefully it won't redirect us to some shit place because of error...
	# get the cookie domain:
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
	if( $VERBOSITY > 0 ){ diag "Cookies from Firefox Marionette browser:\n".as_string_cookies($firefoxmarionettecookies2); }

	my $firefoxmarionettecookies2_count = count_cookies($firefoxmarionettecookies2, $skip_discard, $VERBOSITY);
	ok(defined($firefoxmarionettecookies2_count), 'count_cookies()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;
	is($firefoxmarionettecookies2_count, $firefoxmarionettecookies2_count, 'firefoxmarionette_load_cookies()'." : (label '".$c->{label}."') : the number of loaded cookies (${firefoxmarionettecookies_count}) is the same as the number of extracted cookies (${firefoxmarionettecookies2_count}).") or BAIL_OUT;

	my $httpcookies = firefoxmarionettecookies2httpcookies($firefoxmarionettecookies2, undef, $skip_discard, $VERBOSITY);
	ok(defined $httpcookies, 'firefoxmarionettecookies2httpcookies()'." (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;
	my $httpcookies_count = count_cookies($httpcookies, $skip_discard, $VERBOSITY);
	ok(defined($httpcookies_count), 'count_cookies()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;
	is($firefoxmarionettecookies_count, $httpcookies_count, "(label '".$c->{label}."') : count is the same for both firefoxmarionettecookies ($firefoxmarionettecookies_count) and httpcookies ($httpcookies_count).") or BAIL_OUT;
	if( $VERBOSITY > 0 ){ diag "Cookies from Firefox Marionette browser as HTTP::Cookies:\n".as_string_cookies($httpcookies); }

	# save to file
	my $cooksfile = File::Spec->catfile($tmpdir, 'firefoxmarionette_cookies.txt');
	$ret = firefoxmarionette_save_cookies_to_file($ffmarobj1, $cooksfile, $skip_discard, $VERBOSITY);
	ok(defined($ret), 'firefoxmarionette_save_cookies_to_file()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;
	ok(-f $cooksfile, 'firefoxmarionette_save_cookies_to_file()'." : (label '".$c->{label}."') : output cookies file '$cooksfile' exists on disk.") or BAIL_OUT;
	# beware, it can be just a single line of #LWP...
	ok(!-z $cooksfile, 'firefoxmarionette_save_cookies_to_file()'." : (label '".$c->{label}."') : output cookies file '$cooksfile' has some content.") or BAIL_OUT;

	# create a new UA and load the cookies from file
	my $ffmarobj2 = Firefox::Marionette->new(%ffmar_constructor_params);
	ok(defined($ffmarobj2), 'Firefox::Marionette->new()'." : (label '".$c->{label}."') : called and got good result/1.") or BAIL_OUT;
	# this must fail because file does not exist
	# visit another domain and you can add cookies for that domain
	# but now we will create a URL from the domain with a fictitious path
	# hopefully it won't redirect us to some shit place because of error...
	# get the cookie domain
	# well since this will fail just give it undef (meaning no visit) to check that too
	my $file_cookies = firefoxmarionette_load_cookies($ffmarobj2, $cooksfile.'.xxxx', undef, $skip_discard, $VERBOSITY);
	ok(!defined($file_cookies), 'firefoxmarionette_load_cookies()'." : (label '".$c->{label}."') : called for loading cookies from file (${cooksfile}xxxx) and got failure as expected because input file does not exist.") or BAIL_OUT;
	# visit another domain and you can add cookies for that domain
	# but now we will create a URL from the domain with a fictitious path
	# hopefully it won't redirect us to some shit place because of error...
	# get the cookie domain
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
		$uri->path(defined($firefoxmarionettecookies->[0]->path)?$firefoxmarionettecookies->[0]->path:'a/b/c');
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

	is($c1, $c2, "there is the same number of cookies in 1 ($c1) and 2 ($c2).") or BAIL_OUT;
	is($c2, $c3, "there is the same number of cookies in 2 ($c2) and 3 ($c3).") or BAIL_OUT;

	# compare
	$ret = cookies_are_equal($mech_firefoxmarionettecookies1, $mech_firefoxmarionettecookies2, $VERBOSITY);
	ok(defined $ret, 'cookies_are_equal()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;
	is($ret, 1, 'cookies_are_equal()'." : (label '".$c->{label}."') : cookies from the two browsers are equal.") or BAIL_OUT;

	unlink($cooksfile);

	diag "will not test any more, that's fine ...";

	last; # we do this once
}


diag "temp dir: $tmpdir ..." if exists($ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}) && $ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}>0;

# END
done_testing();
