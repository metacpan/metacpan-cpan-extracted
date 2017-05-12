#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Data::Serializer::Sereal' ) || print "Bail out!
";
}

diag( "Testing Data::Serializer::Sereal $Data::Serializer::Sereal::VERSION, Perl $], $^X" );
