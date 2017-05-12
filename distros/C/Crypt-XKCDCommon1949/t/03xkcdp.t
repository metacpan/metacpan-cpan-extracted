#!/usr/bin/env perl

BEGIN {
	unless (eval "use Crypt::XkcdPassword; 1") {
		eval "use Test::More skip_all => 'Crypt::XkcdPassword not installed'";
		exit;
	}
}

use Test::More tests => 1;

my @words = split /\s+/, Crypt::XkcdPassword->new( words => "XKCDCommon1949" )
                                            ->make_password(10_000);

my %is_in = map { $_ => 1 } Crypt::XKCDCommon1949::xkcd_common_1949();
ok !grep { !$is_in{ $_ }} @words;