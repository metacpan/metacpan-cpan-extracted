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
	httpcookiejar2httpcookies httpcookies2httpcookiejar
	merge_cookies
/;

my $VERBOSITY = 4; # we need verbosity of 10 (max), so this is not used

my $curdir = $FindBin::Bin;

require(File::Spec->catfile($curdir, 'MY', 'CookieMaker.pm'));
ok(@MY::CookieMaker::HTTPCookieJar_cases, "Library 'CookieMaker.pm' loaed OK/1.") or BAIL_OUT;
#ok(@MY::CookieMaker::HTTPCookies_cases, "Library 'CookieMaker.pm' loaed OK/2.") or BAIL_OUT;

# if for debug you change this make sure that it has path in it e.g. ./xyz
#my $tmpdir = tempdir(); # will be erased unless a BAIL_OUT or env var set
#ok(-d $tmpdir, "tmpdir exists $tmpdir") or BAIL_OUT;

my $skip_discard = 0;

for my $c (@MY::CookieMaker::HTTPCookieJar_cases) {
	#next unless $c->{label} =~ /imple key=value quoted value$/;

        diag "\n==================\ntest " . $c->{label} . "\n==================\n";    

	# that's how it is instantiated in original test:
	my $httpcookiejar = HTTP::CookieJar->new;
	for my $cookie ( @{ $c->{cookies} } ) {
		$httpcookiejar->add( $c->{request}, $cookie );
	}
	# original file's test:
	cmp_deeply $httpcookiejar->{store}, $c->{store}, $c->{label}
		or diag explain $httpcookiejar->{store}
	;
	# now do the roundtrip

	if( $VERBOSITY > 2 ){ explain $httpcookiejar->{store} }

	# cookiejar -> cookies
	my $httpcookies = httpcookiejar2httpcookies($httpcookiejar, undef, $skip_discard, $VERBOSITY);
	ok(defined $httpcookies, 'httpcookiejar2httpcookies()'." (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;

	if( $c->{label} =~ /simple key=value quoted value$/ ){
	  is(
		($httpcookiejar->cookies_for("https://example.com/"))[0]->{'value'},
		$httpcookies->get_cookies("https://example.com/")->{'SID'},
		"Quoted values are equal"
	   ) or BAIL_OUT("the first cookie:\n".as_string_cookies($httpcookiejar)."\nthe other cookie:\n".as_string_cookies($httpcookiejar)."\nno they differ, see above");
	}

	if( $VERBOSITY > 2 ){ diag "HTTP::Cookies: ".as_string_cookies($httpcookies) }

	# cookies -> cookiejar
	my $new_httpcookiejar = httpcookies2httpcookiejar($httpcookies, undef, $skip_discard, $VERBOSITY);
	ok(defined($new_httpcookiejar), 'httpcookies2httpcookiejar()'." : (label '".$c->{label}."') : called and got good results.") or BAIL_OUT;

	if( $VERBOSITY > 2 ){
		diag "(label '".$c->{label}."') : OLD:\n"; diag explain $httpcookiejar->{store};
		diag "(label '".$c->{label}."') : NEW:\n"; diag explain $new_httpcookiejar->{store};
	}

	# compare new and old cookiejar
	my $c1 = count_cookies($httpcookiejar, $skip_discard, $VERBOSITY);
        ok(defined($c1), 'count_cookies()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;
	my $c2 = count_cookies($httpcookies, $skip_discard, $VERBOSITY);
        ok(defined($c2), 'count_cookies()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;
	my $c3 = count_cookies($new_httpcookiejar, $skip_discard, $VERBOSITY);
        ok(defined($c3), 'count_cookies()'." : (label '".$c->{label}."') : called and got good result.") or BAIL_OUT;

	is($c1, $c2, "(label '".$c->{label}."') : there is the same number of cookies in 1 ($c1) and 2 ($c2).") or BAIL_OUT;
	is($c2, $c3, "(label '".$c->{label}."') : there is the same number of cookies in 2 ($c2) and 3 ($c3).") or BAIL_OUT;

	# this must succeed:
	is(cookies_are_equal(
		$httpcookiejar,
		$new_httpcookiejar,
		$VERBOSITY
	), 1, "(label '".$c->{label}."') : roundtrip objects are equal.") or BAIL_OUT("the first cookie:\n".as_string_cookies($httpcookiejar)."\nthe other cookie:\n".as_string_cookies($new_httpcookiejar)."\nno they differ, see above");

	# now add one more cookie to one, they will not be equal
	my $httpcookiejar_neq = HTTP::CookieJar->new;
	$httpcookiejar_neq->add('http://bingo.clowns.edu', ["HATS=383sjhahau172361", "NOSES=sdhdf7318aa"]);

	# this must fail
	is(cookies_are_equal(
		$httpcookiejar,
		$httpcookiejar_neq,
		$VERBOSITY
	), 0, "(label '".$c->{label}."') : roundtrip objects are not equal as expected.") or BAIL_OUT;
}

#diag "temp dir: $tmpdir ..." if exists($ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}) && $ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}>0;

# END
done_testing();
