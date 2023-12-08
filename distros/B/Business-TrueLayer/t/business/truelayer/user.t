#!perl

use strict;
use warnings;

use Test::Most;
use Test::Warnings;

use_ok( 'Business::TrueLayer::User' );

my $User = Business::TrueLayer::User->new(
    # taken from https://docs.truelayer.com/docs/create-a-payment
    {
        "id"            => "f9b48c9d-176b-46dd-b2da-fe1a2b77350c",
        "name"          => "Remi Terr",
        "email"         => 'remi.terr@aol.com',
        "phone"         => "+447777777777",
        "date_of_birth" => "1990-01-31"
    }
);

isa_ok(
    $User,
    'Business::TrueLayer::User',
);

is( $User->id,'f9b48c9d-176b-46dd-b2da-fe1a2b77350c','->id' );
is( $User->name,'Remi Terr','->name' );
is( $User->email,'remi.terr@aol.com','->email' );
is( $User->phone,'+447777777777','->phone' );
isa_ok( $User->date_of_birth,'DateTime' );

done_testing();
