use strict;
use warnings;
use Test::More tests => 2;

BEGIN { use_ok( 'Catalyst::View::TT::Alloy' ) or BAIL_OUT('unable to load module') }
BEGIN { use_ok( 'Catalyst::Helper::View::TT::Alloy' ) or BAIL_OUT('unable to load module') }

diag( "Testing Catalyst::View::TT::Alloy $Catalyst::View::TT::Alloy::VERSION, Perl $], $^X" );

