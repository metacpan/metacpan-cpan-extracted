use warnings;
use strict;
use Test::More tests => 1;

BEGIN { use_ok( 'DBIx::SecureCGI' ) or BAIL_OUT('unable to load module') }

diag( "Testing DBIx::SecureCGI $DBIx::SecureCGI::VERSION, Perl $], $^X" );
