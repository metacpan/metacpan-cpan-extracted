use 5.006;
use strict;
use warnings;
use Test::More;
 
plan tests => 1;
 
BEGIN {
    use_ok( 'BusyBird::Input::Feed' ) || print "Bail out!\n";
}
 
diag( "Testing BusyBird::Input::Feed $BusyBird::Input::Feed::VERSION, Perl $], $^X" );
