#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;

use Business::Fixflo::Client;

use_ok( 'Business::Fixflo::Agency' );
isa_ok(
    my $Agency = Business::Fixflo::Agency->new(
        'Id'              => 1,
        'client'          => Business::Fixflo::Client->new(
            username      => 'foo',
            password      => 'bar',
            custom_domain => 'baz',
        ),
    ),
    'Business::Fixflo::Agency'
);

can_ok(
    $Agency,
    qw/
		url
		get
		to_hash
		to_json
        create
        delete

        Id
        AgencyName
        CustomDomain
        EmailAddress
        IsDeleted
        Created
        FeatureType
        IssueTreeRoot
        SiteBaseUrl
        DefaultTimeZoneId
        Locale
        Password
        ApiKey
        TermsAcceptanceUrl
    /,
);

is( $Agency->url,'https://baz.fixflo.com/api/v2/Agency/1','url' );

no warnings 'redefine';
*Business::Fixflo::Client::api_post   = sub { 'updated' };
*Business::Fixflo::Client::api_delete = sub { 'deleted' };

isa_ok( $Agency->update,'Business::Fixflo::Agency','update' );
isa_ok( $Agency->delete,'Business::Fixflo::Agency','delete' );
isa_ok( $Agency->undelete,'Business::Fixflo::Agency','undelete' );

throws_ok(
    sub { $Agency->create },
    'Business::Fixflo::Exception',
    '->create throws when Id is set'
);

like(
    $@->message,
    qr/Can't create Agency when Id is already set/,
    ' ... with expected message'
);

delete( $Agency->{Id} );
isa_ok( $Agency->create,'Business::Fixflo::Agency','create' );

throws_ok(
    sub { $Agency->update },
    'Business::Fixflo::Exception',
    '->update throws when Id is not set'
);

like(
    $@->message,
    qr/Can't update Agency if Id is not set/,
    ' ... with expected message'
);

throws_ok(
    sub { $Agency->delete },
    'Business::Fixflo::Exception',
    '->delete throws when Id is not set'
);

like(
    $@->message,
    qr/Can't delete Agency if Id is not set/,
    ' ... with expected message'
);

done_testing();

# vim: ts=4:sw=4:et
