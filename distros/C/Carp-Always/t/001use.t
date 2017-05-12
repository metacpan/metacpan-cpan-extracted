#perl -T 

use Test::More tests => 1;
BEGIN { use_ok('Carp::Always') };

diag( "Testing Carp::Always $Carp::Always::VERSION, Perl $], $^X" );


