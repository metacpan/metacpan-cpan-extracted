#!perl -T

use strict;

use Test::Most tests => 2;

BEGIN {
    use_ok('Data::Text') || print 'Bail out!';
}

require_ok('Data::Text') || print 'Bail out!';

diag("Testing Data::Text $Data::Text::VERSION, Perl $], $^X");
