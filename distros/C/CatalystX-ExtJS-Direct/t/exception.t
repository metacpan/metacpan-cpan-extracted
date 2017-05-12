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
    action => 'JSON',
    method => 'exception',
    data   => {},
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

my $json = decode_json($mech->content);

is($json->{status_code}, 200);

done_testing;