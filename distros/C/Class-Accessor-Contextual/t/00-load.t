#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Class::Accessor::Contextual' );
}

diag( "Testing Class::Accessor::Contextual $Class::Accessor::Contextual::VERSION, Perl $], $^X" );
