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

ok(
    $mech->request(
        POST $api->{url},
        Content_Type => 'application/json',
        Content      => q({"action":"User","method":"create","data":[{"rows":[{"name":"a","password":1},{"name":"a","password":1},{"name":"m","password":1}]}],"type":"rpc","tid":6})
    ),
    'create users'
);

count_users(3);

count_users(1, [{gt => 2 }]);

count_users(2, [{gt => 1 }]);

count_users(0, [{resultset => 'none'}]);

count_users(0, [['foo', not => [1], not => [2], not => [3], 'not']]);

ok(
    $mech->request(
        POST $api->{url},
        Content_Type => 'application/json',
        Content      => q(
        {"action":"User","method":"destroy","data":[{"rows":"1"}],"type":"rpc","tid":3}
)
    ),
    'delete user 1'
);

count_users(2);

ok(
    $mech->request(
        POST $api->{url},
        Content_Type => 'application/json',
        Content      => q(
        {"action":"User","method":"destroy","data":[{"rows":[2,3]}],"type":"rpc","tid":3}
)
    ),
    'delete user 1'
);


count_users(0);

ok(
    $mech->request(
        POST $api->{url},
        Content_Type => 'application/json',
        Content      => q({"action":"User","method":"create","data":[{"name":"a"}],"type":"rpc","tid":6})
    ),
    'create users with only one attribute'
);

count_users(1);

sub count_users {
	my $user = shift;
    my $data = shift || [];
	ok(
		$mech->request(
			POST $api->{url},
			Content_Type => 'application/json',
			Content      => encode_json(
				{
					action => 'User',
					method => 'list',
					tid    => $tid,
					data   => $data,
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
