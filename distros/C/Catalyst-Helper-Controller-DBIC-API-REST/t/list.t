use 5.6.0;

use strict;
use warnings;

use lib 'lib';
use lib 't/lib';

my $host = 'http://localhost';

use RestTest;
use DBICTest;
use URI;
use Test::More tests => 20;

use Test::Deep;
use Test::WWW::Mechanize::Catalyst 'RestTest';
use HTTP::Request::Common;
use JSON::XS;

my $mech = Test::WWW::Mechanize::Catalyst->new;
ok( my $schema = DBICTest->init_schema(), 'got schema' );

my $artist_list_url   = "$host/api/rest/artist";
my $producer_list_url = "$host/api/rest/producer";

# test open request
{
    my $req = GET( $artist_list_url, {}, 'Accept' => 'text/x-json' );
    $mech->request($req);
    cmp_ok( $mech->status, '==', 200, 'open attempt okay' );
    my @expected_response = map {
        { $_->get_columns }
    } $schema->resultset('Artist')->all;
    my $response = decode_json( $mech->content );
    is( $response->{"list"}[0]->{name},
        $expected_response[0]->{name},
        'correct name in hash returned from list, element 1'
    );
    is( $response->{"list"}[0]->{artistid},
        $expected_response[0]->{artistid},
        'correct id in hash returned from list, element 1'
    );
    is( $response->{"list"}[1]->{name},
        $expected_response[1]->{name},
        'correct name in hash returned from list, element 2'
    );
    is( $response->{"list"}[1]->{artistid},
        $expected_response[1]->{artistid},
        'correct id in hash returned from list, element 2'
    );
    is( $response->{"list"}[2]->{name},
        $expected_response[2]->{name},
        'correct name in hash returned from list, element 3'
    );
    is( $response->{"list"}[2]->{artistid},
        $expected_response[2]->{artistid},
        'correct id in hash returned from list, element 3'
    );
}

{
    my $uri = URI->new($artist_list_url);
    $uri->query_form( { 'search.artistid' => 1 } );
    my $req = GET( $uri, 'Accept' => 'text/x-json' );
    $mech->request($req);
    cmp_ok( $mech->status, '==', 200, 'attempt with basic search okay' );

    my @expected_response = map {
        { $_->get_columns }
    } $schema->resultset('Artist')->search( { artistid => 1 } )->all;
    my $response = decode_json( $mech->content );
    is( $response->{"list"}[0]->{name},
        $expected_response[0]->{name},
        'correct name in basic search hash'
    );
    is( $response->{"list"}[0]->{artistid},
        $expected_response[0]->{artistid},
        'correct id in basic search hash'
    );
}

{
    my $uri = URI->new($artist_list_url);
    $uri->query_form( { 'search.name.LIKE' => '%waul%' } );
    my $req = GET( $uri, 'Accept' => 'text/x-json' );
    $mech->request($req);
    cmp_ok( $mech->status, '==', 200, 'attempt with basic search okay' );

    my @expected_response = map {
        { $_->get_columns }
        } $schema->resultset('Artist')
        ->search( { name => { LIKE => '%waul%' } } )->all;
    my $response = decode_json( $mech->content );
    is( $response->{"list"}[0]->{name},
        $expected_response[0]->{name},
        'correct name in complex query hash'
    );
    is( $response->{"list"}[0]->{artistid},
        $expected_response[0]->{artistid},
        'correct id in complex query hash'
    );
}

{
    my $uri = URI->new($producer_list_url);
    my $req = GET( $uri, 'Accept' => 'text/x-json' );
    $mech->request($req);
    cmp_ok( $mech->status, '==', 200, 'open producer request okay' );

    my @expected_response = map {
        { $_->get_columns }
        } $schema->resultset('Producer')->search( {}, { select => ['name'] } )
        ->all;
    my $response = decode_json( $mech->content );
    is( $response->{"list"}[0]->{name},
        $expected_response[0]->{name},
        'correct name in hash with list_returns, element 1'
    );
    is( $response->{"list"}[1]->{name},
        $expected_response[1]->{name},
        'correct name in hash with list_returns, element 2'
    );
    is( $response->{"list"}[2]->{name},
        $expected_response[2]->{name},
        'correct name in hash with list_returns, element 3'
    );
}

{
    my $uri = URI->new($artist_list_url);
    $uri->query_form( { 'search.cds.title' => 'Forkful of bees' } );
    my $req = GET( $uri, 'Accept' => 'text/x-json' );
    $mech->request($req);
    cmp_ok( $mech->status, '==', 200, 'search related request okay' );

    my @expected_response = map {
        { $_->get_columns }
        } $schema->resultset('Artist')
        ->search( { 'cds.title' => 'Forkful of bees' }, { join => 'cds' } )
        ->all;
    my $response = decode_json( $mech->content );
    is_deeply( { list => \@expected_response, success => 'true' },
        $response,
        'correct data returned for class with list_returns specified' );
}
