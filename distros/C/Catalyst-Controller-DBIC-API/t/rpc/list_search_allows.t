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

my $track_list_url = "$base/api/rpc/track_exposed/list";
my $base_rs =
    $schema->resultset('Track')
    ->search( {},
    { select => [qw/me.title me.position/], order_by => 'position' } );

# test open request
{
    my $req = GET(
        $track_list_url,
        {

        },
        'Accept' => 'text/x-json'
    );
    $mech->request($req);
    cmp_ok( $mech->status, '==', 200, 'open attempt okay' );

    my @expected_response = map {
        { $_->get_columns }
    } $base_rs->all;
    my $response = $json->decode( $mech->content );
    is_deeply(
        $response,
        { list => \@expected_response, success => 'true' },
        'correct message returned'
    );
}

{
    my $uri = URI->new($track_list_url);
    $uri->query_form( { 'search.position' => 1 } );
    my $req = GET(
        $uri,
        {

        },
        'Accept' => 'text/x-json'
    );
    $mech->request($req);
    cmp_ok( $mech->status, '==', 200, 'search on position okay' );
    my @expected_response = map {
        { $_->get_columns }
    } $base_rs->search( { position => 1 } )->all;
    my $response = $json->decode( $mech->content );
    is_deeply(
        $response,
        { list => \@expected_response, success => 'true' },
        'correct message returned'
    );
}

{
    my $uri = URI->new($track_list_url);
    $uri->query_form( { 'search.title' => 'Stripy' } );
    my $req = GET(
        $uri,
        {

        },
        'Accept' => 'text/x-json'
    );
    $mech->request($req);
    cmp_ok( $mech->status, '==', 400, 'search on title not okay' );

    my @expected_response = map {
        { $_->get_columns }
    } $base_rs->search( { position => 1 } )->all;
    my $response = $json->decode( $mech->content );
    is( $response->{success}, 'false', 'correct message returned' );
    like(
        $response->{messages}->[0],
        qr/is not an allowed search term/,
        'correct message returned'
    );
}

{
    my $uri = URI->new($track_list_url);
    $uri->query_form( { 'search.title' => 'Stripy' } );
    my $req = GET(
        $uri,
        {

        },
        'Accept' => 'text/x-json'
    );
    $mech->request($req);
    cmp_ok( $mech->status, '==', 400, 'search on title not okay' );

    my $expected_response = map {
        { $_->get_columns }
    } $base_rs->search( { position => 1 } )->all;
    my $response = $json->decode( $mech->content );
    is( $response->{success}, 'false', 'correct message returned' );
    like(
        $response->{messages}->[0],
        qr/is not an allowed search term/,
        'correct message returned'
    );
}

{
    my $uri = URI->new($track_list_url);
    $uri->query_form( { 'search.cd.artist' => '1' } );
    my $req = GET(
        $uri,
        {

        },
        'Accept' => 'text/x-json'
    );
    $mech->request($req);
    cmp_ok( $mech->status, '==', 400,
        'search on various cd fields not okay' );
    my $response = $json->decode( $mech->content );
    is( $response->{success}, 'false', 'correct message returned' );
    like(
        $response->{messages}->[0],
        qr/is not an allowed search term/,
        'correct message returned'
    );
}

{
    my $uri = URI->new($track_list_url);
    $uri->query_form(
        {   'search.cd.title' => 'Spoonful of bees',
            'search.cd.year'  => '1999'
        }
    );
    my $req = GET(
        $uri,
        {

        },
        'Accept' => 'text/x-json'
    );
    $mech->request($req);
    cmp_ok( $mech->status, '==', 200, 'search on various cd fields okay' );
    my @expected_response = map {
        { $_->get_columns }
        } $base_rs->search(
        { 'cd.year' => '1999', 'cd.title' => 'Spoonful of bees' },
        { join      => 'cd' } )->all;
    my $response = $json->decode( $mech->content );
    is_deeply(
        $response,
        { list => \@expected_response, success => 'true' },
        'correct message returned'
    );
}

{
    my $uri = URI->new($track_list_url);
    $uri->query_form(
        {   'search.cd.title'   => 'Spoonful of bees',
            'search.cd.pretend' => '1999'
        }
    );
    my $req = GET(
        $uri,
        {

        },
        'Accept' => 'text/x-json'
    );
    $mech->request($req);
    cmp_ok( $mech->status, '==', 200, 'search with custom col okay' );
    my @expected_response = map {
        { $_->get_columns }
        } $base_rs->search(
        { 'cd.year' => '1999', 'cd.title' => 'Spoonful of bees' },
        { join      => 'cd' } )->all;
    my $response = $json->decode( $mech->content );
    is_deeply(
        $response,
        { list => \@expected_response, success => 'true' },
        'correct message returned'
    );
}

{
    my $uri = URI->new($track_list_url);
    $uri->query_form( { 'search.cd.artist.name' => 'Random Boy Band' } );
    my $req = GET(
        $uri,
        {

        },
        'Accept' => 'text/x-json'
    );
    $mech->request($req);
    cmp_ok( $mech->status, '==', 200,
        'search on artist field okay due to wildcard' );
    my @expected_response = map {
        { $_->get_columns }
        } $base_rs->search(
        { 'artist.name' => 'Random Boy Band' },
        { join          => { cd => 'artist' } }
        )->all;
    my $response = $json->decode( $mech->content );
    is_deeply(
        $response,
        { list => \@expected_response, success => 'true' },
        'correct message returned'
    );
}

done_testing();
