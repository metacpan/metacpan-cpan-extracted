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

ok( $mech->get_ok('/add/8/to/9') );

is( $mech->content, '17', 'calculator works' );

ok( $mech->get( $api->{url} ) );

is( $mech->status, 400, 'bad request' );

my $request = {
    action => 'Calculator',
    method => 'add',
    data   => [ 1, 3 ],
    tid    => $tid,
    type   => 'rpc'
};

ok(
    $mech->request(
        POST $api->{url},
        Content_Type => 'application/json',
        Content      => encode_json($request)
    ),
    'get via json in body'
);

ok( my $json = decode_json( $mech->content ), 'response is valid json' );

is_deeply(
    $json,
    {
        action => 'Calculator',
        method => 'add',
        result => 4,
        tid    => $tid++,
        type   => 'rpc'
    },
    'expected response'
);

ok(
    $mech->request(
        POST $api->{url},
        [
            extAction => 'Calculator',
            extMethod => 'add',
            extData   => encode_json( [ 1, 3 ] ),
            extTID    => $tid,
            extType   => 'rpc'
        ]
    ),
    'get via body parameters'
);

ok( $json = decode_json( $mech->content ), 'response is valid json' );

is_deeply(
    $json,
    {
        action => 'Calculator',
        method => 'add',
        result => 4,
        tid    => $tid,
        type   => 'rpc'
    },
    'expected response'
);

my $requests = [
    map {
        { %$request, tid => $_ }
      } ( 1 .. 4 )
];
ok(
    $mech->request(
        POST $api->{url},
        Content_Type => 'application/json',
        Content      => encode_json($requests)
    ),
    'batched requests'
);

ok( $json = decode_json( $mech->content ), 'response is valid json' );

my $response = [
    map {
        {
            action => 'Calculator',
            method => 'add',
            result => 4,
            tid    => $_,
            type   => 'rpc'
        }
      } ( 1 .. 4 )
];
is_deeply( $json, $response, 'expected response' );

ok(
    $mech->request(
        POST $api->{url},
        Content_Type => 'multipart/form-data',
        Accept => "application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5",
        Content      => [
            extAction => 'Calculator',
            extMethod => 'upload',
            extTID    => 9,
            extUpload => 'true',
            extType   => 'rpc',
            file      => [
                undef, 'calc.txt',
                'Content-Type' => 'text/plain',
                Content        => '4*8'
            ],
        ]
    ),
    'upload request'
);

is( $mech->content_type, 'application/json', 'content type is application/json' );
ok( $json = decode_json($mech->content), 'response is valid json' );

is( $json->{result}, 32, 'eval calculator works' );

ok(
    $mech->request(
        POST $api->{url},
        Content_Type => 'multipart/form-data',
        Accept => "application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5",
        Content      => [
            extAction => 'Calculator',
            extMethod => 'upload',
            extTID    => 9,
            extUpload => 'true',
            extType   => 'rpc',
            file      => [
                undef, 'calc.txt',
                'Content-Type' => 'text/plain',
                Content        => '4*8*' # Syntax error
            ],
        ]
    ),
    'upload request'
);

like( $mech->content, qr/exception/, 'content contains exception' );


done_testing;
