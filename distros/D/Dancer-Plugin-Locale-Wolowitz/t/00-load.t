use strict;
use warnings;

use Test::More tests => 1;                      # last test to print

BEGIN {
    use_ok ( 'Dancer::Plugin::Locale::Wolowitz' ) || print 'Bail out';
}

diag( "Testing Dancer::Plugin::Locale::Wolowitz $Dancer::Plugin::Locale::Wolowitz::VERSION, Perl $], $^X" );
