use warnings;
use strict;
use Test::More tests => 1;

BEGIN { use_ok( 'AnyEvent::DBI::MySQL' ) or BAIL_OUT('unable to load module') }

diag( "Testing AnyEvent::DBI::MySQL $AnyEvent::DBI::MySQL::VERSION, Perl $], $^X" );
