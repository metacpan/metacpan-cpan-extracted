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
use HTTP::CookieJar::LWP;

use Data::Roundtrip qw/perl2dump no-unicode-escape-permanently/;

use lib ($FindBin::Bin, 'blib/lib');

use Cookies::Roundtrip qw/:count :as_string :equal :file
	httpcookies2httpcookiejar
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

	my $httpcookiejar = HTTP::CookieJar::LWP->new;
	for my $cookie ( @{ $c->{cookies} } ) {
		$httpcookiejar->add( $c->{request}, $cookie );
	}

	# save to file
	my $cooksfile = File::Spec->catfile($tmpdir, 'cookies.txt');
	my $ret = cookies2file($httpcookiejar, $cooksfile, $skip_discard, $VERBOSITY);
	ok(defined($ret), 'cookies2file()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;
	ok(-f $cooksfile, 'cookies2file()'." : (label '".$c->{label}."') : output cookies file '$cooksfile' exists on disk.") or BAIL_OUT;
	ok(!-z $cooksfile, 'cookies2file()'." : (label '".$c->{label}."') : output cookies file '$cooksfile' has some content.") or BAIL_OUT;

	# load from file
	my $httpcookiejar2 = file2httpcookiejar($cooksfile, undef, $skip_discard, $VERBOSITY);
	ok(defined($ret), 'file2httpcookiejar()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;
	ok(-f $cooksfile, 'file2httpcookiejar()'." : (label '".$c->{label}."') : output cookies file '$cooksfile' exists on disk.") or BAIL_OUT;
	ok(!-z $cooksfile, 'file2httpcookiejar()'." : (label '".$c->{label}."') : output cookies file '$cooksfile' has some content.") or BAIL_OUT;

	# compare number of cookies
	my $c1 = count_cookies($httpcookiejar, $skip_discard, $VERBOSITY);
        ok(defined($c1), 'count_cookies()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;
	my $c2 = count_cookies($httpcookiejar2, $skip_discard, $VERBOSITY);
        ok(defined($c2), 'count_cookies()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;
	is($c1, $c2, "there is the same number of cookies in 1 ($c1) and 2 ($c2).") or BAIL_OUT;

	# compare
	$ret = cookies_are_equal_httpcookiejar(
		$httpcookiejar,
		$httpcookiejar2,
		$VERBOSITY
	);
	ok(defined($ret), 'cookies_are_equal_httpcookies()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;
	is($ret, 1, "(label '".$c->{label}."') : cookies are equal.") or BAIL_OUT;

	# load from file but the format of the produced cookie jarmust be HTTP::Cookies
	my $httpcookies = file2httpcookies($cooksfile, undef, $skip_discard, $VERBOSITY);
	ok(defined($ret), 'file2httpcookies()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;
	ok(-f $cooksfile, 'file2httpcookies()'." : (label '".$c->{label}."') : output cookies file '$cooksfile' exists on disk.") or BAIL_OUT;
	ok(!-z $cooksfile, 'file2httpcookies()'." : (label '".$c->{label}."') : output cookies file '$cooksfile' has some content.") or BAIL_OUT;

	# compare number of cookies
	$c1 = count_cookies($httpcookiejar, $skip_discard, $VERBOSITY);
        ok(defined($c1), 'count_cookies()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;
	$c2 = count_cookies($httpcookies, $skip_discard, $VERBOSITY);
        ok(defined($c2), 'count_cookies()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;
	is($c1, $c2, "there is the same number of cookies in 1 ($c1) and 2 ($c2).") or BAIL_OUT;

	# before compare, convert
	my $new_httpcookiejar = httpcookies2httpcookiejar($httpcookies, $httpcookiejar, $skip_discard, $VERBOSITY);
	ok(defined($new_httpcookiejar), 'httpcookies2httpcookiejar()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;
	# now compare
	$ret = cookies_are_equal_httpcookiejar(
		$httpcookiejar,
		$new_httpcookiejar,
		$VERBOSITY
	);
	ok(defined($ret), 'cookies_are_equal_httpcookies()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;
	is($ret, 1, "(label '".$c->{label}."') : cookies are equal.") or BAIL_OUT;

	unlink($cooksfile);
}

diag "temp dir: $tmpdir ..." if exists($ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}) && $ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}>0;

# END
done_testing();
