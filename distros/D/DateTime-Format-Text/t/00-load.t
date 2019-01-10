#!perl -T

use warnings;
use strict;

use Test::Most tests => 2;

BEGIN {
	use_ok('DateTime::Format::Text') || print 'Bail out!';
}

require_ok('DateTime::Format::Text') || print 'Bail out!';

diag( "Testing DateTime::Format::Text $DateTime::Format::Text::VERSION, Perl $], $^X" );
