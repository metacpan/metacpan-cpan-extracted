#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;

use Business::Fixflo::Client;

use_ok( 'Business::Fixflo::PropertyAddress' );
isa_ok(
    my $PropertyAddress = Business::Fixflo::PropertyAddress->new(
        'Id'              => 1,
        'client'          => Business::Fixflo::Client->new(
            username      => 'foo',
            password      => 'bar',
            custom_domain => 'baz',
        ),
    ),
    'Business::Fixflo::PropertyAddress'
);

can_ok(
    $PropertyAddress,
    qw/
		url
		get
		to_hash
		to_json
        property

        Id
        ExternalPropertyRef
		PropertyId
    /,
);

is(
    $PropertyAddress->url,
    'https://baz.fixflo.com/api/v2/PropertyAddress/1',
    'url'
);

# merging property addresses with properties
throws_ok(
    sub { $PropertyAddress->merge },
    'Business::Fixflo::Exception',
    '->merge throws when no Property passed'
);

like(
    $@->message,
    qr/PropertyAddress->merge requires a Business::Fixflo::Property/,
    ' ... with expected message'
);

use_ok( 'Business::Fixflo::Property' );
my $Property = Business::Fixflo::Property->new(
    client => $PropertyAddress->client,
);

delete( $PropertyAddress->{Id} );

throws_ok(
    sub { $PropertyAddress->merge( $Property ) },
    'Business::Fixflo::Exception',
    '->merge throws when PropertyAddress->Id not set'
);

like(
    $@->message,
    qr/PropertyAddress->Id must be set to merge/,
    ' ... with expected message'
);

$PropertyAddress->Id( 1 );

throws_ok(
    sub { $PropertyAddress->merge( $Property ) },
    'Business::Fixflo::Exception',
    '->merge throws when Property->Id not set'
);

like(
    $@->message,
    qr/Property->Id must be set to merge/,
    ' ... with expected message'
);

$Property->Id( 1 );
no warnings 'redefine';
*Business::Fixflo::Client::api_get = sub { return { $PropertyAddress->to_hash } };
isa_ok( $PropertyAddress->get,'Business::Fixflo::PropertyAddress','get' );

*Business::Fixflo::Client::api_post = sub { 'merged' };
isa_ok(
    $PropertyAddress->merge( $Property ),
    'Business::Fixflo::PropertyAddress'
);

delete( $PropertyAddress->{Id} );

throws_ok(
    sub { $PropertyAddress->split },
    'Business::Fixflo::Exception',
    '->split throws when PropertyAddress->Id not set'
);

like(
    $@->message,
    qr/PropertyAddress->Id must be set to split/,
    ' ... with expected message'
);

$PropertyAddress->Id( 1 );
isa_ok(
    $PropertyAddress->split,
    'Business::Fixflo::PropertyAddress'
);

isa_ok(
    $PropertyAddress->property,
    'Business::Fixflo::Property'
);

done_testing();

# vim: ts=4:sw=4:et
