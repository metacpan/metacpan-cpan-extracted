use strict;
use warnings;

use Test::More tests => 1;                      # last test to print

BEGIN {
    use_ok ( 'Dancer2::Plugin::Locale::Wolowitz' ) || print 'Bail out';
}

diag( "Testing Dancer2::Plugin::Locale::Wolowitz $Dancer2::Plugin::Locale::Wolowitz::VERSION, Perl $], $^X" );
