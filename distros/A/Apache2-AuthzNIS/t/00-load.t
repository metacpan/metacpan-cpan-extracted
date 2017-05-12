#!perl -T

use Test::More tests => 1;

BEGIN {
    SKIP:
    {
        eval 'use mod_perl2';
        skip( 'because mod_perl2 required', 1 ) if $@;
        use_ok( 'Apache2::AuthzNIS' );
    }
}

diag( "Testing Apache2::AuthzNIS $Apache2::AuthzNIS::VERSION, Perl $], $^X" );
