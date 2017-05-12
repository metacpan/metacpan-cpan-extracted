#!perl -w
use strict;

use Test::More tests => 100;

use Test::Exception;

use Data::Util qw(:all);
use Tie::Scalar;

use constant INF => 9**9**9;
use constant NAN => sin(INF());

my $s;

tie $s, 'Tie::StdScalar', 'magic';
foreach my $x('foo', '', 0, -100, 3.14, $s){
	ok is_value($x), sprintf 'is_value(%s)', neat($x);
}
tie $s, 'Tie::StdScalar', \'magic';
foreach my $x(undef, [], *STDIN{IO}, *ok, $s){
	ok !is_value($x), sprintf '!is_value(%s)', neat($x);
}

tie $s, 'Tie::StdScalar', 'magic';
foreach my $x('foo', 0, -100, 3.14, $s){
	ok is_string($x), sprintf 'is_string(%s)', neat($x);
}
tie $s, 'Tie::StdScalar', \'magic';
foreach my $x('', undef, [], *STDIN{IO}, *ok, $s){
	ok !is_string($x), sprintf '!is_string(%s)', neat($x);
}

tie $s, 'Tie::StdScalar', 1234;
foreach my $x(0, 42, -42, 3.00, '0', '+0', '-0', ' -42', '+42 ', 2**30, $s){
	ok is_integer($x), sprintf 'is_integer(%s)', neat($x);

	my $w;
	local $SIG{__WARN__} = sub{ $w = "@_" };
	my $i = 0+$x;

	is $w, undef, 'numify-safe';
}
tie $s, 'Tie::StdScalar', 'magic';
foreach my $x(
		undef, 3.14, '0.0', 'foo', (9**9**9), -(9**9**9), 'NaN',
		INF(), -INF(), NAN(), -NAN(), 1 != 1,
	*ok, [42], *STDIN{IO}, '0 but true', $s){

	ok !is_integer($x), sprintf '!is_integer(%s)', neat($x);
}

tie $s, 'Tie::StdScalar', 123.456;
foreach my $x(0, 1, -1, 3.14, '0', '+0', '-0', '0E0', ' 0.0', '1e-1', 2**32+0.1, $s){
	ok is_number($x), sprintf 'is_number(%s)', neat($x);

	my $w;
	local $SIG{__WARN__} = sub{ $w = "@_" };
	my $n = 0+$x;

	is $w, undef, 'numify-safe';
}

tie $s, 'Tie::StdScalar', 'magic';
foreach my $x(undef, 'foo', 'Inf', '-Infinity', 'NaN',
		INF(), -INF(), NAN(), -NAN(), 1 != 1,
		'0 but true', *ok, [42], *STDIN{IO}, $s){

	ok !is_number($x), sprintf '!is_number(%s)', neat($x);
}
