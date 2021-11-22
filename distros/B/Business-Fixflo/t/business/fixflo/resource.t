#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;

use Business::Fixflo::Client;

use_ok( 'Business::Fixflo::Resource' );
isa_ok(
    my $Resource = Business::Fixflo::Resource->new(
        'client'          => Business::Fixflo::Client->new(
            username      => 'foo',
            password      => 'bar',
            custom_domain => 'baz',
        ),
    ),
    'Business::Fixflo::Resource'
);

can_ok(
    $Resource,
    qw/
		url
		url_no_id
		to_hash
		to_json
    /,
);

cmp_deeply(
    { $Resource->to_hash },
    {},
    'to_hash',
);

cmp_deeply(
    $Resource->to_json,
    '{}',
    'to_json',
);

no warnings 'redefine';
no warnings 'once';
*Business::Fixflo::Resource::Id    = sub { 1 };
*Business::Fixflo::Client::api_get = sub {
	return {
        Id => 2,
        # this shouldn't kill the call to ->get
        ThisDoesNotExists => 'BOOO!',
	}
};

{
    local $SIG{__WARN__} = sub {
        my ( $warning ) = @_;
        like(
            $warning,
            qr/Couldn't set ThisDoesNotExists on Business::Fixflo::Resource/,
            'unknown attribute warns, but is not fatal',
        );
    };

    cmp_deeply(
        $Resource->get,
        bless( {
            'warn_unknown_attributes' => ignore(),
            'client' => ignore(),
            'url'    => 'https://baz.fixflo.com/api/v2/Resource/1',
            'url_no_id' => 'https://baz.fixflo.com/api/v2/Resource',
        }, 'Business::Fixflo::Resource' ),
        'get'
    );
}

isa_ok(
    $Resource->_parse_envelope_data({
        Entity             => undef,
        Errors             => undef,
        HttpStatusCode     => 200,
        HttpStatusCodeDesc => 'OK',
        Messages           => undef,
    }),
    'Business::Fixflo::Resource',
    '_parse_envelope_data (no data)',
);

done_testing();

# vim: ts=4:sw=4:et
