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

my $artist_list_url = "$base/api/rpc/artist/list";
my $base_rs =
    $schema->resultset('Track')
    ->search( {},
    { select => [qw/me.title me.position/], order_by => 'position' } );

{
    my $uri = URI->new($artist_list_url);
    $uri->query_form( { 'search' => '{"gibberish}' } );
    my $req = GET( $uri, 'Accept' => 'text/x-json' );
    $mech->request($req);
    cmp_ok( $mech->status, '==', 400,
        'attempt with gibberish json not okay' );
    my $response = $json->decode( $mech->content );
    is( $response->{success}, 'false',
        'correct data returned for gibberish in search' );
    like(
        $response->{messages}->[0],
        qr/Attribute \(search\) does not pass the type constraint because/,
        'correct data returned for gibberish in search'
    );
}

{
    my $uri = URI->new($artist_list_url);
    $uri->query_form( { 'search' => '{"name":{"LIKE":"%waul%"}}' } );
    my $req = GET( $uri, 'Accept' => 'text/x-json' );
    $mech->request($req);
    cmp_ok( $mech->status, '==', 200, 'attempt with basic search okay' );

    my @expected_response = map {
        { $_->get_columns }
        } $schema->resultset('Artist')
        ->search( { name => { LIKE => '%waul%' } } )->all;
    my $response = $json->decode( $mech->content );
    is_deeply( { list => \@expected_response, success => 'true' },
        $response, 'correct data returned for complex query' );
}

{
    my $uri = URI->new($artist_list_url);
    $uri->query_form(
        { 'search' => '{ "cds": { "title": "Spoonful of bees" }}' } );
    my $req = GET( $uri, 'Accept' => 'text/x-json' );
    $mech->request($req);
    cmp_ok( $mech->status, '==', 200, 'attempt with related search okay' );
    my @expected_response = map {
        { $_->get_columns }
        } $schema->resultset('Artist')
        ->search( { 'cds.title' => 'Spoonful of bees' }, { join => 'cds' } )
        ->all;
    my $response = $json->decode( $mech->content );
    is_deeply( { list => \@expected_response, success => 'true' },
        $response, 'correct data returned for complex query' );
}

{
    my $uri = URI->new($artist_list_url);
    $uri->query_form( { 'search.name' => '{"LIKE":"%waul%"}' } );
    my $req = GET( $uri, 'Accept' => 'text/x-json' );
    $mech->request($req);
    cmp_ok( $mech->status, '==', 200,
        'attempt with mixed CGI::Expand + JSON search okay' );

    my @expected_response = map {
        { $_->get_columns }
        } $schema->resultset('Artist')
        ->search( { name => { LIKE => '%waul%' } } )->all;
    my $response = $json->decode( $mech->content );
    is_deeply( { list => \@expected_response, success => 'true' },
        $response, 'correct data returned for complex query' );
}

done_testing();
