#!perl -Tw

use warnings;
use strict;

use Test::Most tests => 2;

BEGIN {
	use_ok('Class::Simple::Cached') || print 'Bail out!';
}

require_ok('Class::Simple::Cached') || print 'Bail out!';

diag("Testing Class::Simple::Cached $Class::Simple::Cached::VERSION, Perl $], $^X");
