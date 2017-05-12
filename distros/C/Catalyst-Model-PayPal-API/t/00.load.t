use warnings;
use strict;
use Test::More tests => 1;

BEGIN { use_ok( 'Catalyst::Model::PayPal::API' ) or BAIL_OUT('unable to load module') }

diag( "Testing Catalyst::Model::PayPal::API $Catalyst::Model::PayPal::API::VERSION, Perl $], $^X" );
