use Test::More;

use strict;
use warnings;

use HTTP::Request::Common;
use JSON::XS;

use lib qw(t/lib);

use Test::WWW::Mechanize::Catalyst 'MyApp';

my $mech = Test::WWW::Mechanize::Catalyst->new();
my $tid  = 1;

ok(
    my $api = MyApp->controller('API')->api,
    'get api directly from controller'
);

is( $api->{url}, '/api/router' );

ok( $mech->request( POST '/rest/object/1' ), 'chained action is working' );

foreach my $action (qw(create read update destroy)) {
    ok(
        $mech->request(
            POST $api->{url},
            Content_Type => 'application/json',
            Content      => encode_json(
                {
                    action => 'REST',
                    method => $action,
                    data   => [1],
                    tid    => $tid,
                    type   => 'rpc'
                }
            )
        ),
        'rest interface: ' . $action
    );

    ok( my $json = decode_json( $mech->content ), 'response is valid json' );

    is_deeply(
        $json,
        {
            action => 'REST',
            method => $action,
            result => { action => $action },
            tid    => $tid++,
            type   => 'rpc'
        },
        'expected response'
    );
}

ok(
    $mech->request(
        POST $api->{url},
        [
            extAction => 'User',
            extMethod => 'create',
            extTID    => $tid,
            extType   => 'rpc',
            password  => 'foobar',
            name      => 'testuser',
        ]
    ),
    'create user'
);

ok( my $json = decode_json( $mech->content ), 'response is valid json' );
is( ref $json->{result}, 'HASH', 'result is a hash' );

$json = count_users(1);

is_deeply(
    $json->{result}->{data},
    [
        {
            'password' => 'foobar',
            'name'     => 'testuser',
            'id'       => 1
        },
    ]
);

ok(     $mech->request(
        POST $api->{url},
        Content_Type => 'application/json',
        Content      => encode_json(
            {
                action => 'User',
                method => 'read',
                data   => [],
                tid    => $tid,
                type   => 'rpc'
            }
        )
    ),
    'list users'
);


ok( $json = decode_json( $mech->content ), 'response is valid json' );
is( $json->{type}, 'rpc', 'type is rpc' );
is( $json->{result}->{results}, 1, 'one result' );

ok(
    $mech->request(
        POST $api->{url},
        Content_Type => 'multipart/form-data',
        Accept => "application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5",
        Content => [
            extAction => 'User',
            extMethod => 'update',
            extTID    => $tid,
            extType   => 'rpc',
            extUpload => 'true',
            id => 1,
            password  => 'foobar2',
            name      => 'testuser',
        ]
    ),
    'change user'
);

ok( $json = decode_json($mech->content), 'response is valid json' );

is( ref $json->{result}, 'HASH', 'result is a HASH' );

ok(
    $mech->request(
        POST $api->{url},
        [
            extAction => 'User',
            extMethod => 'update',
            extTID    => $tid,
            extType   => 'rpc',
            id => 1,
            password  => 'foobar2',
            name      => 'testuser',
        ]
    ),
    'change user'
);

ok( $json = decode_json( $mech->content ), 'response is valid json' );
is( ref $json->{result}, 'HASH', 'result is a hash' );

$json = count_users(1);

is_deeply(
    $json->{result}->{data},
    [
        {
            'password' => 'foobar2',
            'name'     => 'testuser',
            'id'       => 1
        },
    ]
);

ok(
    $mech->request(
        POST $api->{url},
        Content_Type => 'application/json',
        Content      => encode_json(
            {
                action => 'User',
                method => 'destroy',
                data   => [1],
                tid    => $tid,
                type   => 'rpc'
            }
        )
    ),
    'delete user'
);

ok( $json = decode_json( $mech->content ), 'response is valid json' );
is( ref $json->{result}, 'HASH', 'result is a hash' );

count_users(0);


ok(
    $mech->request(
        POST $api->{url},
        [
            extAction => 'User',
            extMethod => 'create',
            extTID    => $tid,
            extType   => 'rpc',
            password  => 'foobar',
        ]
    ),
    'create user without a name'
);

ok( $json = decode_json( $mech->content ), 'response is valid json' );

is( ref $json->{message}, 'HASH', 'result is a hash' );

ok(exists $json->{message}->{success}, 'Success status exists');

ok(!$json->{message}->{success}, 'Success is false');

is($json->{status_code}, 400, 'Status is set to 400');

sub count_users {
	my $user = shift;
	ok(
		$mech->request(
			POST $api->{url},
			Content_Type => 'application/json',
			Content      => encode_json(
				{
					action => 'User',
					method => 'list',
					tid    => $tid,
					data   => [],
					type   => 'rpc',
				}
			)
		),
		'get list of users'
	);

	ok( my $_json = decode_json( $mech->content ), 'response is valid json' );
	is($_json->{result}->{results}, $user, $user . ' users');
	return $_json;

}

done_testing;
