#!/usr/bin/env perl

###################################################################
#### NOTE env-var PERL_TEST_TEMPDIR_TINY_NOCLEANUP=1 will stop erasing tmp files
###################################################################

###################################################################
### The cookies cases are from:
###    HTTP-CookieJar-0.014/t/add.t
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

use Data::Roundtrip qw/perl2dump no-unicode-escape-permanently/;

use lib ($FindBin::Bin, 'blib/lib');

use Cookies::Roundtrip qw/:count :as_string :equal
	httpcookiejar2httpcookies httpcookies2httpcookiejar
/;

my $VERBOSITY = 0; # we need verbosity of 10 (max), so this is not used

my $curdir = $FindBin::Bin;

require(File::Spec->catfile($curdir, 'MY', 'CookieMaker.pm'));
ok(@MY::CookieMaker::HTTPCookieJar_cases, "Library 'CookieMaker.pm' loaed OK/1.") or BAIL_OUT;
#ok(@MY::CookieMaker::HTTPCookies_cases, "Library 'CookieMaker.pm' loaed OK/2.") or BAIL_OUT; 

# if for debug you change this make sure that it has path in it e.g. ./xyz
#my $tmpdir = tempdir(); # will be erased unless a BAIL_OUT or env var set
#ok(-d $tmpdir, "tmpdir exists $tmpdir") or BAIL_OUT;

my $skip_discard = 0;

for my $c (@MY::CookieMaker::HTTPCookieJar_cases) {
        diag "\n==================\ntest " . $c->{label} . "\n==================\n";    

	my $httpcookiejar = HTTP::CookieJar->new;
	for my $cookie ( @{ $c->{cookies} } ) {
		$httpcookiejar->add( $c->{request}, $cookie );
	}

	my $httpcookiejar_count = count_cookies($httpcookiejar, $skip_discard, $VERBOSITY);
	ok(defined($httpcookiejar_count), 'count_cookies()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;
	my $httpcookies = httpcookiejar2httpcookies($httpcookiejar, undef, $skip_discard, $VERBOSITY);
	ok(defined $httpcookies, 'httpcookiejar2httpcookies()'." (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;
	my $httpcookies_count = count_cookies($httpcookies, $skip_discard, $VERBOSITY);
	ok(defined($httpcookies_count), 'count_cookies()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;
	is($httpcookiejar_count, $httpcookies_count, "(label '".$c->{label}."') : count is the same for both httpcookiejar ($httpcookiejar_count) and httpcookies ($httpcookies_count).") or BAIL_OUT;
}

#diag "temp dir: $tmpdir ..." if exists($ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}) && $ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}>0;

# END
done_testing();
