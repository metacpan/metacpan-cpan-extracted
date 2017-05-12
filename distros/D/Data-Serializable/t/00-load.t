#!perl -T

use Test::More tests => 1;
BEGIN { use_ok( 'Data::Serializable' ); }
diag( "Testing Data::Serializable $Data::Serializable::VERSION, Perl $], $^X" );
