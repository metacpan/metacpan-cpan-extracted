use 5.006;
use strict;
use warnings;
use Test::More;
 
plan tests => 1;
 
BEGIN {
    use_ok( 'BusyBird::DateTime::Format' ) || print "Bail out!\n";
}
 
diag( "Testing BusyBird::DateTime::Format $BusyBird::DateTime::Format::VERSION, Perl $], $^X" );
