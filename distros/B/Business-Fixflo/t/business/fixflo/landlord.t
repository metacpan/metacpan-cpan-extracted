#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;

use Business::Fixflo::Client;

use_ok( 'Business::Fixflo::Landlord' );
isa_ok(
    my $Landlord = Business::Fixflo::Landlord->new(
        'Id'              => 1,
        'client'          => Business::Fixflo::Client->new(
            username      => 'foo',
            password      => 'bar',
            custom_domain => 'baz',
        ),
    ),
    'Business::Fixflo::Landlord'
);

can_ok(
    $Landlord,
    qw/
		url
		get
		to_hash
		to_json
        create

        Id
        CompanyName
        Title
        FirstName
        Surname
        EmailAddress
		ContactNumber
        ContactNumberAlt
        DisplayName
        WorksAuthorisationLimit
        EmailCC
        IsDeleted
        ExternalRef
    /,
);

no warnings 'redefine';
*Business::Fixflo::Client::api_post   = sub { 'updated' };

isa_ok( $Landlord->update,'Business::Fixflo::Landlord','update' );

throws_ok(
    sub { $Landlord->create },
    'Business::Fixflo::Exception',
    '->create throws when Id is set'
);

like(
    $@->message,
    qr/Can't create Landlord when Id is already set/,
    ' ... with expected message'
);

delete( $Landlord->{Id} );
ok( $Landlord->create,'->create when Landlord is not set' );
isa_ok( $Landlord->create,'Business::Fixflo::Landlord','create' );

throws_ok(
    sub { $Landlord->update },
    'Business::Fixflo::Exception',
    '->update throws when Id is not set'
);

like(
    $@->message,
    qr/Can't update Landlord if Id is not set/,
    ' ... with expected message'
);

$Landlord->Id( 1 );
no warnings 'redefine';
*Business::Fixflo::Client::api_get = sub { return { $Landlord->to_hash } };
isa_ok( $Landlord->get,'Business::Fixflo::Landlord','get' );

*Business::Fixflo::Client::api_get = sub {
	return {
		NextURL     => 'foo',
		PreviousURL => 'bar',
		Items       => [ {},{},{} ],
	}
};

isa_ok(
	my $Addresses = $Landlord->Properties,
	'Business::Fixflo::Paginator'
);

done_testing();

# vim: ts=4:sw=4:et
