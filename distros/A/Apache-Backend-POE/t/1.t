# -*- perl -*-
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'
# vim: syntax=perl ts=4
#########################

use Test::More tests => 2;

BEGIN {
	use_ok( 'Apache' ); # 1
	use_ok( 'Apache::Backend::POE' ); # 2
};
#########################
