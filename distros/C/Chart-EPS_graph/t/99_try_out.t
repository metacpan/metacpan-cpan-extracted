#!perl -T

use Test::Output;
use Chart::EPS_graph::Test;
use Test::More tests => 1;

$expected = "File 'foo.eps' has expected first two lines"
	. ".*\n.*"
	. "File 'foo.eps' looks fresh"
	. ".*\n.*"
	. "File 'foo.eps' looks big enough";

stdout_like(
	sub { print Chart::EPS_graph::Test->full_test() },
	qr/$expected/,
	'Compose an EPS.'
);
