use warnings;
use strict;

use Test::More tests => 13;

BEGIN { use_ok "Data::Entropy", qw(with_entropy_source entropy_source); }

my $default_source;

with_entropy_source 4, sub {
	is entropy_source, 4;
	with_entropy_source undef, sub {
		$default_source = entropy_source;
		ok $default_source;
	};
	is entropy_source, 4;
	with_entropy_source 5, sub {
		is entropy_source, 5;
	};
	is entropy_source, 4;
};
is entropy_source, $default_source;

my $s0_called;
with_entropy_source sub { $s0_called = 1; "foo"; }, sub {
	ok 1;
};
ok !$s0_called;
my $s1_called;
with_entropy_source sub { $s1_called = 1; undef; }, sub {
	is entropy_source, $default_source;
};
ok $s1_called;
my $s2_called;
with_entropy_source sub { $s2_called = 1; "bar"; }, sub {
	is entropy_source, "bar";
};
ok $s2_called;

1;
