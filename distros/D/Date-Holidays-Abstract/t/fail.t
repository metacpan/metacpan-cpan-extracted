# $Id: fail.t 1306 2004-05-13 10:59:01Z jonasbn $

use Test::More tests => 1;

BEGIN {
	use lib qw(t);
	require NN;
};

warn "This is a fake test, please refer to the TODO file";

ok(1);
