#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;

use Business::Fixflo::Client;

use_ok( 'Business::Fixflo::LandlordProperty' );
isa_ok(
    my $LandlordProperty = Business::Fixflo::LandlordProperty->new(
        'Id'              => 1,
        'client'          => Business::Fixflo::Client->new(
            username      => 'foo',
            password      => 'bar',
            custom_domain => 'baz',
        ),
        'Address' => {},
        'LandlordId' => 1,
        'PropertyId' => 1,
    ),
    'Business::Fixflo::LandlordProperty'
);

can_ok(
    $LandlordProperty,
    qw/
		url
		get
		to_hash
		to_json
        create

        Id
        LandlordId
        PropertyId
        DateFrom
        DateTo
        Address
    /,
);

no warnings 'redefine';
*Business::Fixflo::Client::api_post   = sub { 'updated' };

isa_ok( $LandlordProperty->update,'Business::Fixflo::LandlordProperty','update' );

throws_ok(
    sub { $LandlordProperty->create },
    'Business::Fixflo::Exception',
    '->create throws when Id is set'
);

like(
    $@->message,
    qr/Can't create LandlordProperty when Id is already set/,
    ' ... with expected message'
);

delete( $LandlordProperty->{Id} );
ok( $LandlordProperty->create,'->create when LandlordProperty is not set' );
isa_ok( $LandlordProperty->create,'Business::Fixflo::LandlordProperty','create' );

throws_ok(
    sub { $LandlordProperty->update },
    'Business::Fixflo::Exception',
    '->update throws when Id is not set'
);

like(
    $@->message,
    qr/Can't update LandlordProperty if Id is not set/,
    ' ... with expected message'
);

$LandlordProperty->Id( 1 );
no warnings 'redefine';
*Business::Fixflo::Client::api_get = sub { return { $LandlordProperty->to_hash } };
isa_ok( $LandlordProperty->get,'Business::Fixflo::LandlordProperty','get' );

*Business::Fixflo::Client::api_get = sub {
	return {
	}
};

isa_ok( my $address = $LandlordProperty->address,'Business::Fixflo::Address' );
isa_ok( my $landlord = $LandlordProperty->landlord,'Business::Fixflo::Landlord' );
isa_ok( my $property = $LandlordProperty->property,'Business::Fixflo::Property' );

done_testing();

# vim: ts=4:sw=4:et
