use 5.006;
use strict;
use warnings;
use Test::More;
 
plan tests => 1;
 
BEGIN {
    use_ok( 'BusyBird::Input::Lingr' ) || print "Bail out!\n";
}
 
diag( "Testing BusyBird::Input::Lingr $BusyBird::Input::Lingr::VERSION, Perl $], $^X" );
