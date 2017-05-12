use 5.6.0;

use strict;
use warnings;

use lib 't/lib';

my $host = 'http://localhost';

require DBICTest;
use Test::More tests => 7;
use Test::WWW::Mechanize::Catalyst 'RestTest';
use HTTP::Request::Common;
use JSON::XS;

my $mech = Test::WWW::Mechanize::Catalyst->new;
ok( my $schema = DBICTest->init_schema(), 'got schema' );

my $artist_create_url   = "$host/api/rest/artist";
my $producer_create_url = "$host/api/rest/producer";

# test validation when wrong params sent
{
    my $test_data = encode_json( { color => 'green' } );
    my $req = PUT($artist_create_url);
    $req->content_type('text/x-json');
    $req->content_length(
        do { use bytes; length($test_data) }
    );
    $req->content($test_data);
    $mech->request($req);
    diag $mech->content;

    cmp_ok( $mech->status, '==', 400,
        'attempt without required params caught' );
    my $response = decode_json( $mech->content );
    is_deeply(
        $response->{messages},
        ['No value supplied for name and no default'],
        'correct message returned'
    );
}

# test default value used if default value exists
{
    my $test_data = encode_json( {} );
    my $req = PUT($producer_create_url);
    $req->content_type('text/x-json');
    $req->content_length(
        do { use bytes; length($test_data) }
    );
    $req->content($test_data);
    $mech->request($req);

    cmp_ok( $mech->status, '==', 200,
        'default value used when not supplied' );
    ok( $schema->resultset('Producer')->find( { name => 'fred' } ),
        'record created with default name' );
}

# test create works as expected when passing required value
{
    my $test_data = encode_json( { name => 'king luke' } );
    my $req = PUT($producer_create_url);
    $req->content_type('text/x-json');
    $req->content_length(
        do { use bytes; length($test_data) }
    );
    $req->content($test_data);
    $mech->request($req);
    cmp_ok( $mech->status, '==', 200, 'request with valid content okay' );
    my $new_obj
        = $schema->resultset('Producer')->find( { name => 'king luke' } );
    ok( $new_obj, 'record created with specified name' );

}
