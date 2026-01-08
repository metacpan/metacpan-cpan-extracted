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
use WWW::Mechanize;

use Data::Roundtrip qw/perl2dump no-unicode-escape-permanently/;

use lib ($FindBin::Bin, 'blib/lib');

use Cookies::Roundtrip qw/:count :as_string :equal
	httpcookiejar2httpcookies httpcookies2httpcookiejar
	:wwwmechanize
/;

my $VERBOSITY = 4; # we need verbosity of 10 (max), so this is not used

my $curdir = $FindBin::Bin;

require(File::Spec->catfile($curdir, 'MY', 'CookieMaker.pm'));
#ok(@MY::CookieMaker::HTTPCookieJar_cases, "Library 'CookieMaker.pm' loaed OK/1.") or BAIL_OUT;
ok(@MY::CookieMaker::HTTPCookies_cases, "Library 'CookieMaker.pm' loaed OK/2.") or BAIL_OUT;

# if for debug you change this make sure that it has path in it e.g. ./xyz
my $tmpdir = tempdir(); # will be erased unless a BAIL_OUT or env var set
ok(-d $tmpdir, "tmpdir exists $tmpdir") or BAIL_OUT;

my $skip_discard = 0;

for my $c (@MY::CookieMaker::HTTPCookies_cases) {
        diag "\n==================\ntest " . $c->{label} . "\n==================\n";    

	my $httpcookiejar = HTTP::CookieJar->new;
	for my $cookie ( @{ $c->{cookies} } ) {
		$httpcookiejar->add( $c->{request}, $cookie );
	}
	my $httpcookiejar_count = count_cookies($httpcookiejar, $skip_discard, $VERBOSITY);
	ok(defined($httpcookiejar_count), 'count_cookies()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;

	my $mechobj1 = WWW::Mechanize->new(cookie_jar_class=>'HTTP::CookieJar');
	ok(defined($mechobj1), 'WWW::Mechanize->new()'." : (label '".$c->{label}."') : with cookie_jar_class => 'HTTP::CookieJar' and got good result/1.") or BAIL_OUT;
	my $ret = wwwmechanize_load_cookies($mechobj1, $httpcookiejar, $VERBOSITY);
	ok(defined($ret), 'wwwmechanize_load_cookies()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;

	my $httpcookiejar2 = wwwmechanize_get_cookies($mechobj1, $VERBOSITY);
	ok(defined($httpcookiejar2), 'wwwmechanize_get_cookies()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;

	my $httpcookiejar2_count = count_cookies($httpcookiejar2, $skip_discard, $VERBOSITY);
	ok(defined($httpcookiejar2_count), 'count_cookies()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;
	is($httpcookiejar2_count, $httpcookiejar2_count, 'wwwmechanize_load_cookies()'." : (label '".$c->{label}."') : the number of loaded cookies (${httpcookiejar_count}) is the same as the number of extracted cookies (${httpcookiejar2_count}).") or BAIL_OUT;

	my $httpcookies = httpcookiejar2httpcookies($httpcookiejar, undef, $skip_discard, $VERBOSITY);
	ok(defined $httpcookies, 'httpcookiejar2httpcookies()'." (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;
	my $httpcookies_count = count_cookies($httpcookies, $skip_discard, $VERBOSITY);
	ok(defined($httpcookies_count), 'count_cookies()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;
	is($httpcookiejar_count, $httpcookies_count, "(label '".$c->{label}."') : count is the same for both httpcookiejar ($httpcookiejar_count) and httpcookies ($httpcookies_count).") or BAIL_OUT;

	# save to file
	my $cooksfile = File::Spec->catfile($tmpdir, 'wwwmechanize_cookies.txt');
	$ret = wwwmechanize_save_cookies_to_file($mechobj1, $cooksfile, $skip_discard, $VERBOSITY);
	ok(defined($ret), 'wwwmechanize_save_cookies_to_file()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;
	ok(-f $cooksfile, 'wwwmechanize_save_cookies_to_file()'." : (label '".$c->{label}."') : output cookies file '$cooksfile' exists on disk.") or BAIL_OUT;
	ok(!-z $cooksfile, 'wwwmechanize_save_cookies_to_file()'." : (label '".$c->{label}."') : output cookies file '$cooksfile' has some content.") or BAIL_OUT;

	# create a new UA and load the cookies from file
	my $mechobj2 = WWW::Mechanize->new(cookie_jar_class=>'HTTP::CookieJar');
	ok(defined($mechobj2), 'WWW::Mechanize->new()'." : (label '".$c->{label}."') : with cookie_jar_class => 'HTTP::CookieJar' and got good result/2.") or BAIL_OUT;
	# this must fail because file does not exist
	$ret = wwwmechanize_load_cookies($mechobj2, $cooksfile.'.xxxx', $VERBOSITY);
	ok(!defined($ret), 'wwwmechanize_load_cookies()'." : (label '".$c->{label}."') : called for loading cookies from file (${cooksfile}xxxx) and got failure as expected because input file does not exist.") or BAIL_OUT;
	$ret = wwwmechanize_load_cookies($mechobj2, $cooksfile, $VERBOSITY);
	ok(defined($ret), 'wwwmechanize_load_cookies()'." : (label '".$c->{label}."') : called for loading cookies from file ($cooksfile) and got good result.") or BAIL_OUT;

	# UA and UA2 must have exactly the same cookies
	my $mech_httpcookiejar1 = wwwmechanize_get_cookies($mechobj1, $VERBOSITY);
	ok(defined($mech_httpcookiejar1), 'wwwmechanize_get_cookies()'." : (label '".$c->{label}."') : called and got good results/1.") or BAIL_OUT;

	my $mech_httpcookiejar2 = wwwmechanize_get_cookies($mechobj2, $VERBOSITY);
	ok(defined($mech_httpcookiejar2), 'wwwmechanize_get_cookies()'." : (label '".$c->{label}."') : called and got good results/2.") or BAIL_OUT;

	# compare number of cookies
	my $c1 = count_cookies($httpcookiejar, $skip_discard, $VERBOSITY);
        ok(defined($c1), 'count_cookies()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;
	my $c2 = count_cookies($httpcookiejar2, $skip_discard, $VERBOSITY);
        ok(defined($c2), 'count_cookies()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;
	my $c3 = count_cookies($httpcookies, $skip_discard, $VERBOSITY);
        ok(defined($c3), 'count_cookies()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;

	is($c1, $c2, "there is the same number of cookies in 1 ($c1) and 2 ($c2).") or BAIL_OUT;
	is($c2, $c3, "there is the same number of cookies in 2 ($c2) and 3 ($c3).") or BAIL_OUT;

	# compare
	$ret = cookies_are_equal($mech_httpcookiejar1, $mech_httpcookiejar2, $VERBOSITY);
	ok(defined $ret, 'cookies_are_equal()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;
	is($ret, 1, 'cookies_are_equal()'." : (label '".$c->{label}."') : cookies from the two browsers are equal.") or BAIL_OUT;

	# now create a UA whose cookie_jar's class is 'HTTP::Cookies' (as opposed to 'HTTP::CookieJar' above).
	my $mechobj3 = WWW::Mechanize->new(cookie_jar_class=>'HTTP::Cookies');
	ok(defined($mechobj3), 'WWW::Mechanize->new()'." : (label '".$c->{label}."') : with cookie_jar_class => 'HTTP::CookieJar' and got good result/2.") or BAIL_OUT;
	$ret = wwwmechanize_load_cookies($mechobj3, $httpcookiejar, $VERBOSITY);
	ok(defined($ret), 'wwwmechanize_load_cookies()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;

	my $mech_httpcookies = wwwmechanize_get_cookies($mechobj3, $VERBOSITY);
	ok(defined($mech_httpcookies), 'wwwmechanize_get_cookies()'." : (label '".$c->{label}."') : called and got good results/3.") or BAIL_OUT;
	# compare
	$ret = cookies_are_equal($httpcookies, $mech_httpcookies, $skip_discard, $VERBOSITY);
	ok(defined $ret, 'cookies_are_equal()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;
	is($ret, 1, 'cookies_are_equal()'." : (label '".$c->{label}."') : cookies from the two browsers are equal.") or BAIL_OUT;

	unlink($cooksfile);
}

diag "temp dir: $tmpdir ..." if exists($ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}) && $ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}>0;

# END
done_testing();
