#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Data::Validate::DNS::NAPTR::Regexp;

use FindBin qw($Bin);
use lib "$Bin/lib/";

use GoodTests;
use BadTests;

for my $t (GoodTests->tests) {
	my ($regexp, $ret, $comment) = @$t;

	is(
		is_naptr_regexp($regexp),
		$ret,
		(defined $regexp ? "'$regexp'" : "'<undef>'") . " is a valid regexp ($comment)"
	) or diag("Got error: " . naptr_regexp_error());
}

# Bad tests
for my $t (BadTests->tests) {
	my ($regexp, $expect) = @$t;

	ok(!is_naptr_regexp($regexp), "$regexp is not a valid regexp");
	like(naptr_regexp_error(), $expect, "Got expected error $expect");
}

done_testing;
