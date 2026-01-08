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
use LWP::UserAgent;

use Data::Roundtrip qw/perl2dump no-unicode-escape-permanently/;

use lib ($FindBin::Bin, 'blib/lib');

use Cookies::Roundtrip qw/:count :as_string :equal
	httpcookiejar2httpcookies httpcookies2httpcookiejar
	:lwpuseragent
/;

my $VERBOSITY = 0; # we need verbosity of 10 (max), so this is not used

my $curdir = $FindBin::Bin;

require(File::Spec->catfile($curdir, 'MY', 'CookieMaker.pm'));
ok(@MY::CookieMaker::HTTPCookieJar_cases, "Library 'CookieMaker.pm' loaed OK/1.") or BAIL_OUT;
#ok(@MY::CookieMaker::HTTPCookies_cases, "Library 'CookieMaker.pm' loaed OK/2.") or BAIL_OUT; 

# if for debug you change this make sure that it has path in it e.g. ./xyz
my $tmpdir = tempdir(); # will be erased unless a BAIL_OUT or env var set
ok(-d $tmpdir, "tmpdir exists $tmpdir") or BAIL_OUT;


my $skip_discard = 0;

for my $c (@MY::CookieMaker::HTTPCookieJar_cases) {
        diag "\n==================\ntest " . $c->{label} . "\n==================\n";    

	my $httpcookiejar = HTTP::CookieJar->new;
	for my $cookie ( @{ $c->{cookies} } ) {
		$httpcookiejar->add( $c->{request}, $cookie );
	}
	my $httpcookiejar_count = count_cookies($httpcookiejar, $skip_discard, $VERBOSITY);
	ok(defined($httpcookiejar_count), 'count_cookies()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;

	my $UA1 = LWP::UserAgent->new(cookie_jar_class=>'HTTP::CookieJar');
	ok(defined($UA1), 'LWP::UserAgent->new()'." : (label '".$c->{label}."') : with cookie_jar_class => 'HTTP::CookieJar' and got good result/1.") or BAIL_OUT;
	my $ret = lwpuseragent_load_cookies($UA1, $httpcookiejar, $VERBOSITY);
	ok(defined($ret), 'lwpuseragent_load_cookies()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;

	my $httpcookiejar2 = lwpuseragent_get_cookies($UA1, $VERBOSITY);
	ok(defined($httpcookiejar2), 'lwpuseragent_get_cookies()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;

	my $httpcookiejar2_count = count_cookies($httpcookiejar2, $skip_discard, $VERBOSITY);
	ok(defined($httpcookiejar2_count), 'count_cookies()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;
	is($httpcookiejar2_count, $httpcookiejar2_count, 'lwpuseragent_load_cookies()'." : (label '".$c->{label}."') : the number of loaded cookies (${httpcookiejar_count}) is the same as the number of extracted cookies (${httpcookiejar2_count}).") or BAIL_OUT;

	my $httpcookies = httpcookiejar2httpcookies($httpcookiejar, undef, $skip_discard, $VERBOSITY);
	ok(defined $httpcookies, 'httpcookiejar2httpcookies()'." (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;
	my $httpcookies_count = count_cookies($httpcookies, $skip_discard, $VERBOSITY);
	ok(defined($httpcookies_count), 'count_cookies()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;
	is($httpcookiejar_count, $httpcookies_count, "(label '".$c->{label}."') : count is the same for both httpcookiejar ($httpcookiejar_count) and httpcookies ($httpcookies_count).") or BAIL_OUT;

	# save to file
	my $cooksfile = File::Spec->catfile($tmpdir, 'ua_cookies.txt');
	$ret = lwpuseragent_save_cookies_to_file($UA1, $cooksfile, $skip_discard, $VERBOSITY);
	ok(defined($ret), 'lwpuseragent_save_cookies_to_file()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;
	ok(-f $cooksfile, 'lwpuseragent_save_cookies_to_file()'." : (label '".$c->{label}."') : output cookies file '$cooksfile' exists on disk.") or BAIL_OUT;
	ok(!-z $cooksfile, 'lwpuseragent_save_cookies_to_file()'." : (label '".$c->{label}."') : output cookies file '$cooksfile' has some content.") or BAIL_OUT;

	# create a new UA and load the cookies from file
	my $UA2 = LWP::UserAgent->new(cookie_jar_class=>'HTTP::CookieJar');
	ok(defined($UA2), 'LWP::UserAgent->new()'." : (label '".$c->{label}."') : with cookie_jar_class => 'HTTP::CookieJar' and got good result/2.") or BAIL_OUT;
	# this must fail because file does not exist
	$ret = lwpuseragent_load_cookies($UA2, $cooksfile.'.xxxx', $VERBOSITY);
	ok(!defined($ret), 'lwpuseragent_load_cookies()'." : (label '".$c->{label}."') : called for loading cookies from file (${cooksfile}xxxx) and got failure as expected because input file does not exist.") or BAIL_OUT;
	$ret = lwpuseragent_load_cookies($UA2, $cooksfile, $VERBOSITY);
	ok(defined($ret), 'lwpuseragent_load_cookies()'." : (label '".$c->{label}."') : called for loading cookies from file ($cooksfile) and got good result.") or BAIL_OUT;

	# UA and UA2 must have exactly the same cookies
	my $ua_httpcookiejar1 = lwpuseragent_get_cookies($UA1, $VERBOSITY);
	ok(defined($ua_httpcookiejar1), 'lwpuseragent_get_cookies()'." : (label '".$c->{label}."') : called and got good results/1.") or BAIL_OUT;

	my $ua_httpcookiejar2 = lwpuseragent_get_cookies($UA2, $VERBOSITY);
	ok(defined($ua_httpcookiejar2), 'lwpuseragent_get_cookies()'." : (label '".$c->{label}."') : called and got good results/2.") or BAIL_OUT;

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
	$ret = cookies_are_equal($ua_httpcookiejar1, $ua_httpcookiejar2, $VERBOSITY);
	ok(defined $ret, 'cookies_are_equal()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;
	is($ret, 1, 'cookies_are_equal()'." : (label '".$c->{label}."') : cookies from the two browsers are equal.") or BAIL_OUT;

	# now create a UA whose cookie_jar's class is 'HTTP::Cookies' (as opposed to 'HTTP::CookieJar' above).
	my $UA3 = LWP::UserAgent->new(cookie_jar_class=>'HTTP::Cookies');
	ok(defined($UA3), 'LWP::UserAgent->new()'." : (label '".$c->{label}."') : with cookie_jar_class => 'HTTP::CookieJar' and got good result/2.") or BAIL_OUT;
	$ret = lwpuseragent_load_cookies($UA3, $httpcookiejar, $VERBOSITY);
	ok(defined($ret), 'lwpuseragent_load_cookies()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;

	my $ua_httpcookies = lwpuseragent_get_cookies($UA3, $VERBOSITY);
	ok(defined($ua_httpcookies), 'lwpuseragent_get_cookies()'." : (label '".$c->{label}."') : called and got good results/3.") or BAIL_OUT;
	# compare
	$ret = cookies_are_equal($httpcookies, $ua_httpcookies, $VERBOSITY);
	ok(defined $ret, 'cookies_are_equal()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;
	is($ret, 1, 'cookies_are_equal()'." : (label '".$c->{label}."') : cookies from the two browsers are equal.") or BAIL_OUT;

	unlink($cooksfile);
}

diag "temp dir: $tmpdir ..." if exists($ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}) && $ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}>0;

# END
done_testing();
