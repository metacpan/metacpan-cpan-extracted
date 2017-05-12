#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;

use Business::Fixflo::Client;

use_ok( 'Business::Fixflo::IssueDraft' );
isa_ok(
    my $IssueDraft = Business::Fixflo::IssueDraft->new(
		'Id'              => 1,
        'client'          => Business::Fixflo::Client->new(
            username      => 'foo',
            password      => 'bar',
            custom_domain => 'baz',
        ),
    ),
    'Business::Fixflo::IssueDraft'
);

# extends Issue
isa_ok( $IssueDraft,'Business::Fixflo::Issue' );

can_ok(
    $IssueDraft,
    qw/
		url
		get
		to_hash
		to_json

        Address
        ContactNumber
        ContactNumberAlt
        Updated
        EmailAddress
        FaultId
        FaultNotes
        FirstName
        Id
        IssueDraftMedia
        IssueTitle
        Surname
        Title
    /,
);

no warnings 'redefine';
*Business::Fixflo::Client::api_post = sub { 'updated' };
isa_ok( $IssueDraft->update,'Business::Fixflo::IssueDraft','update' );

throws_ok(
    sub { $IssueDraft->create },
    'Business::Fixflo::Exception',
    '->create throws when Id is set'
);

like(
    $@->message,
    qr/Can't create IssueDraft when Id is already set/,
    ' ... with expected message'
);

delete( $IssueDraft->{Id} );
ok( $IssueDraft->create,'->create when IssueDraft is not set' );
isa_ok( $IssueDraft->create,'Business::Fixflo::IssueDraft','create' );

throws_ok(
    sub { $IssueDraft->update },
    'Business::Fixflo::Exception',
    '->update throws when Id is not set'
);

like(
    $@->message,
    qr/Can't update IssueDraft if Id is not set/,
    ' ... with expected message'
);

$IssueDraft->Id( 1 );
no warnings 'redefine';
*Business::Fixflo::Client::api_get = sub { return { $IssueDraft->to_hash } };
isa_ok( $IssueDraft->get,'Business::Fixflo::IssueDraft','get' );

*Business::Fixflo::Client::api_post = sub {
	return {
        client             => $IssueDraft->client,
        HttpStatusCodeDesc => 'OK',
        HttpStatusCode     => '200',
        Errors             => [],
        Messages           => [],
		Entity             => {
            Business::Fixflo::Issue->new(
                client => $IssueDraft->client,
            )->to_hash
        },
	}
};

isa_ok(
	my $Issue = $IssueDraft->commit,
	'Business::Fixflo::Issue'
);

*Business::Fixflo::Client::api_post = sub { 'deleted' };
isa_ok( $IssueDraft->delete,'Business::Fixflo::IssueDraft','->delete' );

ok( $IssueDraft->FirstName( "new_first_name" ),'FirstName' );
is( $IssueDraft->Firstname,"new_first_name",' ... sets Firstname' );

done_testing();

# vim: ts=4:sw=4:et
