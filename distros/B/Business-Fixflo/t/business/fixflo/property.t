#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;

use Business::Fixflo::Client;

use_ok( 'Business::Fixflo::Property' );
isa_ok(
    my $Property = Business::Fixflo::Property->new(
        'Id'              => 1,
        'client'          => Business::Fixflo::Client->new(
            username      => 'foo',
            password      => 'bar',
            custom_domain => 'baz',
        ),
    ),
    'Business::Fixflo::Property'
);

can_ok(
    $Property,
    qw/
		url
		get
		to_hash
		to_json
        create

        AssignedAgent
        AssignedTeam
        Id
        BlockId
        BlockName
        Brand
        ExternalPropertyRef
        PropertyManager
        PropertyAddressId
        KeyReference
        Address
        Addresses
        Issues
		PropertyId
		Warranties
        IsDeleted
        IsNotManaged
    /,
);

is( $Property->url,'https://baz.fixflo.com/api/v2/Property/1','url' );

no warnings 'redefine';
*Business::Fixflo::Client::api_post   = sub { 'updated' };

isa_ok( $Property->update,'Business::Fixflo::Property','update' );

throws_ok(
    sub { $Property->create },
    'Business::Fixflo::Exception',
    '->create throws when Id is set'
);

like(
    $@->message,
    qr/Can't create Property when Id is already set/,
    ' ... with expected message'
);

delete( $Property->{Id} );
ok( $Property->create,'->create when PropertyId is not set' );
isa_ok( $Property->create,'Business::Fixflo::Property','create' );

throws_ok(
    sub { $Property->update },
    'Business::Fixflo::Exception',
    '->update throws when Id is not set'
);

like(
    $@->message,
    qr/Can't update Property if Id is not set/,
    ' ... with expected message'
);

$Property->Id( 1 );
no warnings 'redefine';
*Business::Fixflo::Client::api_get = sub { return { $Property->to_hash } };
isa_ok( $Property->get,'Business::Fixflo::Property','get' );
$Property->ExternalPropertyRef( 'FOOBAR' );
isa_ok( $Property->get,'Business::Fixflo::Property','get' );

*Business::Fixflo::Client::api_get = sub {
	return {
		NextURL     => 'foo',
		PreviousURL => 'bar',
		Items       => [ {},{},{} ],
	}
};

isa_ok(
	my $Addresses = $Property->Addresses,
	'Business::Fixflo::Paginator'
);

isa_ok(
	my $Issues = $Property->Issues,
	'Business::Fixflo::Paginator'
);

done_testing();

# vim: ts=4:sw=4:et
