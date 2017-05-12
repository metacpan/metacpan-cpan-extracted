use warnings;
use strict;
use Test::More tests => 1;

BEGIN { use_ok( 'Async::Defer' ) or BAIL_OUT('unable to load module') }

diag( "Testing Async::Defer $Async::Defer::VERSION, Perl $], $^X" );
