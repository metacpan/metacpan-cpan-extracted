#!perl -w

use warnings;
use strict;

use Test::Most tests => 2;

BEGIN {
	use_ok('Array::Iterator') || print 'Bail out!';
}

require_ok('Array::Iterator') || print 'Bail out!';

diag("Testing Array::Iterator $Array::Iterator::VERSION, Perl $], $^X");
