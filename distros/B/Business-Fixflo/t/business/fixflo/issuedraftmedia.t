#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;

use Business::Fixflo::Client;

use_ok( 'Business::Fixflo::IssueDraftMedia' );
isa_ok(
    my $IssueDraftMedia = Business::Fixflo::IssueDraftMedia->new(
		'Id'              => 1,
        'client'          => Business::Fixflo::Client->new(
            username      => 'foo',
            password      => 'bar',
            custom_domain => 'baz',
        ),
    ),
    'Business::Fixflo::IssueDraftMedia'
);

can_ok(
    $IssueDraftMedia,
    qw/
		url
		get
		to_hash
		to_json

        Id
        IssueDraftId
        Url
        ContentType
        ShortDesc
        EncodedByteData
    /,
);

no warnings 'redefine';
throws_ok(
    sub { $IssueDraftMedia->create },
    'Business::Fixflo::Exception',
    '->create throws when Id is set'
);

like(
    $@->message,
    qr/Can't create IssueDraftMedia when Id is already set/,
    ' ... with expected message'
);

delete( $IssueDraftMedia->{Id} );
*Business::Fixflo::Client::api_post = sub { 'updated' };
ok( $IssueDraftMedia->create,'->create when IssueDraftMedia is not set' );
isa_ok( $IssueDraftMedia->create,'Business::Fixflo::IssueDraftMedia','create' );

$IssueDraftMedia->Id( 1 );
no warnings 'redefine';
*Business::Fixflo::Client::api_get = sub { return { $IssueDraftMedia->to_hash } };
isa_ok( $IssueDraftMedia->get,'Business::Fixflo::IssueDraftMedia','get' );

*Business::Fixflo::Client::api_post = sub {
	return {
        client             => $IssueDraftMedia->client,
        HttpStatusCodeDesc => 'OK',
        HttpStatusCode     => '200',
        Errors             => [],
        Messages           => [],
		Entity             => {
            Business::Fixflo::Issue->new(
                client => $IssueDraftMedia->client,
            )->to_hash
        },
	}
};

*Business::Fixflo::Client::api_post = sub { 'deleted' };
isa_ok( $IssueDraftMedia->delete,'Business::Fixflo::IssueDraftMedia','->delete' );

*Business::Fixflo::Client::api_get = sub { 'some content' };
is( $IssueDraftMedia->download,'some content','->download' );

done_testing();

# vim: ts=4:sw=4:et
