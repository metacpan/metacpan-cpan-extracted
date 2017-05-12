#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
	use_ok('Algorithm::MedianSelect::XS');
}

diag("Testing Algorithm::MedianSelect::XS $Algorithm::MedianSelect::XS::VERSION, Perl $], $^X");
