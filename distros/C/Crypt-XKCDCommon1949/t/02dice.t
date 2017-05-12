#!/usr/bin/env perl

BEGIN {
	unless (eval "use Crypt::Diceware; 1") {
		eval "use Test::More skip_all => 'Crypt::Diceware not installed'";
		exit;
	}
}

use Test::More tests => 1;

use Crypt::Diceware words => { wordlist => 'XKCDCommon1949' };
my %is_in = map { $_ => 1 } Crypt::XKCDCommon1949::xkcd_common_1949();
ok !grep { !$is_in{ $_ }} words(10_000);