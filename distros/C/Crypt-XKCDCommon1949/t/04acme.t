#!/usr/bin/env perl

BEGIN {
	unless (eval "use Acme::MetaSyntactic; 1") {
		eval "use Test::More skip_all => 'Acme::MetaSyntactic not installed'";
		exit;
	}
}

use Test::More tests => 1;

use Acme::MetaSyntactic qw(xkcdcommon1949);

my @words = metaxkcdcommon1949(10_000);
my %is_in = map { $_ => 1 } Crypt::XKCDCommon1949::xkcd_common_1949();
ok !grep { !$is_in{ $_ }} @words;