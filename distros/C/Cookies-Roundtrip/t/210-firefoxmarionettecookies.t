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
	firefoxmarionettecookies2setcookies
	httpcookiejar2firefoxmarionettecookies
	firefoxmarionettecookies2httpcookiejar
	merge_cookies
	as_string_cookies
/;

my $VERBOSITY = 4; # we need verbosity of 10 (max), so this is not used

my $curdir = $FindBin::Bin;

require(File::Spec->catfile($curdir, 'MY', 'CookieMaker.pm'));
# if you don't use any of these it will complain:
#   "..." used only once: possible typo at ...
ok(@MY::CookieMaker::FirefoxMarionetteCookies_cases, "Library 'CookieMaker.pm' loaed OK/1.") or BAIL_OUT;

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
			ok(exists($acookie->{$k}), "(label '".$c->{label}."') : New Firefox::Marionette::Cookie has field '$k'.") or BAIL_OUT(perl2dump($acookie_params)."no, see above.");
			ok(defined($acookie->{$k}), "(label '".$c->{label}."') : New Firefox::Marionette::Cookie has field '$k' and it has a defined value.") or BAIL_OUT(perl2dump($acookie_params)."no, see above.");
		}
	}

	if( $VERBOSITY > 0 ){ diag "(label '".$c->{label}."') :\n".as_string_cookies($firefoxmarionettecookies) }
}

#diag "temp dir: $tmpdir ..." if exists($ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}) && $ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}>0;

# END
done_testing();
