use strict;
use warnings;

use lib 't/lib';

my $base = 'http://localhost';

use RestTest;
use DBICTest;
use URI;
use Test::More tests => 17;
use Test::WWW::Mechanize::Catalyst 'RestTest';
use HTTP::Request::Common;
use JSON;

my $json = JSON->new->utf8;

my $mech = Test::WWW::Mechanize::Catalyst->new;
ok( my $schema = DBICTest->init_schema(), 'got schema' );

my $artist_list_url = "$base/api/rpc/artist/list";
my $cd_list_url     = "$base/api/rpc/cd/list";

foreach my $req_params ( { 'list_prefetch' => '["cds"]' },
    { 'list_prefetch' => 'cds' } )
{
    my $uri = URI->new($artist_list_url);
    $uri->query_form($req_params);
    my $req = GET( $uri, 'Accept' => 'text/x-json' );
    $mech->request($req);
    cmp_ok( $mech->status, '==', 200,
        'search with simple prefetch request okay' );
    my $rs =
        $schema->resultset('Artist')
        ->search( undef, { prefetch => ['cds'] } );
    $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
    my @rows              = $rs->all;
    my $expected_response = { list => \@rows, success => 'true' };
    my $response          = $json->decode( $mech->content );

    #use Data::Dumper; warn Dumper($response, $expected_response);
    is_deeply( $expected_response, $response,
        'correct data returned for search with simple prefetch specified as param'
    );
}

foreach my $req_params (
    { 'list_prefetch'     => '{"cds":"tracks"}' },
    { 'list_prefetch.cds' => 'tracks' }
    )
{
    my $uri = URI->new($artist_list_url);
    $uri->query_form($req_params);
    my $req = GET( $uri, 'Accept' => 'text/x-json' );
    $mech->request($req);
    cmp_ok( $mech->status, '==', 200,
        'search with multi-level prefetch request okay' );
    my $rs =
        $schema->resultset('Artist')
        ->search( undef, { prefetch => { 'cds' => 'tracks' } } );
    $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
    my @rows              = $rs->all;
    my $expected_response = { list => \@rows, success => 'true' };
    my $response          = $json->decode( $mech->content );

    #use Data::Dumper; warn Dumper($response, $expected_response);
    is_deeply( $expected_response, $response,
        'correct data returned for search with multi-level prefetch specified as param'
    );
}

foreach my $req_params ( { 'list_prefetch' => '["artist"]' },
    { 'list_prefetch' => 'artist' } )
{
    my $uri = URI->new($cd_list_url);
    $uri->query_form($req_params);
    my $req = GET( $uri, 'Accept' => 'text/x-json' );
    $mech->request($req);
    cmp_ok( $mech->status, '==', 400, 'prefetch of artist not okay' );

    my $expected_response = map {
        { $_->get_columns }
    } $schema->resultset('CD')->all;
    my $response = $json->decode( $mech->content );

    #use Data::Dumper; warn Dumper($response, $expected_response);
    is( $response->{success}, 'false', 'correct message returned' );
    like(
        $response->{messages}->[0],
        qr/not an allowed prefetch in:/,
        'correct message returned'
    );
}

{
    my $uri = URI->new($cd_list_url);
    $uri->query_form(
        {   'list_prefetch'   => 'tracks',
            'list_ordered_by' => 'title',
            'list_count'      => 2,
            'list_page'       => 1
        }
    );
    my $req = GET( $uri, 'Accept' => 'text/x-json' );
    $mech->request($req);
    if (cmp_ok(
            $mech->status, '==', 400,
            'order_by on non-unique col with paging returns error'
        )
        )
    {
        my $response = $json->decode( $mech->content );
        is_deeply(
            $response,
            {   messages => ['a database error has occured.'],
                success  => 'false'
            },
            'error returned for order_by on non-existing col with paging'
        );
    }
}
