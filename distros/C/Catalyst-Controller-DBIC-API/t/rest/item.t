use strict;
use warnings;

use lib 't/lib';

my $base = 'http://localhost';

use RestTest;
use DBICTest;
use URI;
use Test::More;
use Test::WWW::Mechanize::Catalyst 'RestTest';
use HTTP::Request::Common;
use JSON;

my $json = JSON->new->utf8;

my $mech = Test::WWW::Mechanize::Catalyst->new;
ok( my $schema = DBICTest->init_schema(), 'got schema' );

my $artist_view_url = "$base/api/rest/artist/";

{
    my $id = 1;
    my $req =
        GET( $artist_view_url . $id, 'Accept' => 'application/json' );
    $mech->request($req);
    cmp_ok( $mech->status, '==', 200, 'open attempt okay' );
    my %expected_response =
        $schema->resultset('Artist')->find($id)->get_columns;
    my $response = $json->decode( $mech->content );
    #artist does not have use_json_boolean => 1, so true values are stringified to 'true'
    is_deeply(
        $response,

        # artist doesn't set use_json_boolean
        { data => \%expected_response, success => 'true' },
        'correct data returned'
    );
}

{
    my $id = 5;
    my $req =
        GET( $artist_view_url . $id, 'Accept' => 'application/json' );
    $mech->request($req);
    cmp_ok( $mech->status, '==', 400, 'open attempt not ok' );
    my $response = $json->decode( $mech->content );
    is( $response->{success}, 'false',
        'not existing object fetch failed ok' );
    like(
        $response->{messages}->[0],
        qr/^No object found for id/,
        'error message for not existing object fetch ok'
    );
}

my $track_view_url = "$base/api/rest/track/";

{
    my $id = 9;
    my $req =
        GET( $track_view_url . $id, 'Accept' => 'application/json' );
    $mech->request($req);
    cmp_ok( $mech->status, '==', 200, 'got track with datetime object okay' );
    my %expected_response =
        $schema->resultset('Track')->find($id)->get_columns;
    my $response = $json->decode( $mech->content );
    is_deeply(
        $response,

        # track does set use_json_boolean
        { data => \%expected_response, success => JSON::true },
        'correct data returned for track with datetime'
    );
}

{
    my $req =
        GET( $artist_view_url . 'action_with_error', 'Accept' => 'application/json' );
    $mech->request($req);
    cmp_ok( $mech->status, '==', 404, 'action returned error 404' );
    my $response = $json->decode( $mech->content );
    is_deeply(
        $response,

        # artist doesn't set use_json_boolean
        { success => 'false' },
        'correct data returned'
    );
}

done_testing();
