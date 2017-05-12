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

my $artist_view_url = "$base/api/rpc/artist/id/";

{
    my $id = 1;
    my $req = GET( $artist_view_url . $id, 'Accept' => 'application/json' );
    $mech->request($req);
    cmp_ok( $mech->status, '==', 200, 'open attempt okay' );
    my %expected_response =
        $schema->resultset('Artist')->find($id)->get_columns;
    my $response = $json->decode( $mech->content );
    is_deeply(
        $response,
        { data => \%expected_response, success => 'true' },
        'correct data returned'
    );
}

{
    my $id = 5;
    my $req = GET( $artist_view_url . $id, 'Accept' => 'application/json' );
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

done_testing();
