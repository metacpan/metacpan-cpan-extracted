use Test::More tests => 7;

use Data::FormValidator;
use Data::FormValidator::Constraints::HTTP qw( POST );

BEGIN { 
    my %profile = (
        required           => [ qw( method ) ],
        constraint_methods => {
            method         => POST,
        },
    );
    
    ok( Data::FormValidator->check( { method => 'post' }, \%profile )->success );
    ok( Data::FormValidator->check( { method => 'POST' }, \%profile )->success );
    ok( Data::FormValidator->check( { method => 'PoSt' }, \%profile )->success );
    ok( not Data::FormValidator->check( { method => 'get' }, \%profile )->success );
    ok( not Data::FormValidator->check( { method => 'GET' }, \%profile )->success );
    ok( not Data::FormValidator->check( { method => 'GeT' }, \%profile )->success );
    ok( not Data::FormValidator->check( {}, \%profile )->success );
}
