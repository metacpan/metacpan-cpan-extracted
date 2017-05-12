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

my $request = {
    action => 'Calculator',
    method => 'sum',
    data   => { a => 1, b => 2 },
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

is( $json->{result}, 3 );

done_testing;
