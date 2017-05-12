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
use Data::Printer;

my $json = JSON->new->utf8;

my $mech = Test::WWW::Mechanize::Catalyst->new;
ok( my $schema = DBICTest->init_schema(), 'got schema' );

my $artist_list_url          = "$base/api/rest/artist";
my $filtered_artist_list_url = "$base/api/rest/bound_artist";
my $producer_list_url        = "$base/api/rest/producer";
my $cd_list_url              = "$base/api/rest/cd";
my $track_list_url           = "$base/api/rest/track";

# test open request
{
    my $req = GET(
        $artist_list_url,
        {

        },
        'Accept' => 'text/x-json'
    );
    $mech->request($req);
    cmp_ok( $mech->status, '==', 200, 'open attempt okay' );
    my @expected_response = map {
        { $_->get_columns }
    } $schema->resultset('Artist')->all;
    my $response = $json->decode( $mech->content );
    is_deeply(
        $response,
        { list => \@expected_response, success => 'true' },
        'correct message returned'
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
    my $response = $json->decode( $mech->content );
    is_deeply(
        $response,
        { list => \@expected_response, success => 'true' },
        'correct data returned'
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
    my $response = $json->decode( $mech->content );
    is_deeply(
        $response,
        { list => \@expected_response, success => 'true' },
        'correct data returned for complex query'
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
    my $response = $json->decode( $mech->content );
    is_deeply(
        $response,
        { list => \@expected_response, success => 'true' },
        'correct data returned for class with list_returns specified'
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
    my $response = $json->decode( $mech->content );
    is_deeply(
        $response,
        { list => \@expected_response, success => 'true' },
        'correct data returned for class with select specified'
    );
}

{
    my $uri = URI->new($artist_list_url);
    $uri->query_form(
        {   'search.cds.title'     => 'Forkful of bees',
            'list_returns.0.count' => '*',
            'as.0'                 => 'count'
        }
    );
    my $req = GET( $uri, 'Accept' => 'text/x-json' );
    $mech->request($req);
    cmp_ok( $mech->status, '==', 200, 'search related request okay' );

    my @expected_response = map {
        { $_->get_columns }
        } $schema->resultset('Artist')
        ->search( { 'cds.title' => 'Forkful of bees' },
        { select => [ { count => '*' } ], as => ['count'], join => 'cds' } )
        ->all;
    my $response = $json->decode( $mech->content );
    is_deeply(
        $response,
        { list => \@expected_response, success => 'true' },
        'correct data returned for count'
    );
}

{
    my $uri = URI->new($filtered_artist_list_url);
    $uri->query_form( { 'search.artistid' => '2' } );
    my $req = GET( $uri, 'Accept' => 'text/x-json' );
    $mech->request($req);
    cmp_ok( $mech->status, '==', 200, 'search related request okay' );
    my $response          = $json->decode( $mech->content );
    my @expected_response = map {
        { $_->get_columns }
    } $schema->resultset('Artist')->search( { 'artistid' => '1' } )->all;
    is_deeply(
        $response,
        { list => \@expected_response, success => 'true' },
        'correct data returned for class with setup_list_method specified'
    );
}

{
    my $uri = URI->new($cd_list_url);
    $uri->query_form(
        {   'search.tracks.position' => '1',
            'search.artist.name'     => 'Caterwauler McCrae'
        }
    );
    my $req = GET( $uri, 'Accept' => 'text/x-json' );
    $mech->request($req);
    cmp_ok( $mech->status, '==', 200, 'search multiple params request okay' );
    my $response          = $json->decode( $mech->content );
    my @expected_response = map {
        { $_->get_columns }
        } $schema->resultset('CD')->search(
        {   'artist.name'     => 'Caterwauler McCrae',
            'tracks.position' => 1,
        },
        { join => [qw/ artist tracks /], }
        )->all;
    is_deeply(
        $response,
        { list => \@expected_response, success => 'true' },
        'correct data returned for multiple search params'
    );
}

# page specified in controller config (RT#56226)
{
    my $uri = URI->new($track_list_url);
    $uri->query_form();
    my $req = GET( $uri, 'Accept' => 'text/x-json' );
    $mech->request($req);
    cmp_ok( $mech->status, '==', 200, 'get first page ok' );
    my $response          = $json->decode( $mech->content );
    my @expected_response = map {
        { $_->get_columns }
    } $schema->resultset('Track')->search( undef, { page => 1, } )->all;
    is_deeply(
        $response,

        # track does set use_json_boolean
        { list => \@expected_response, success => JSON::true, totalcount => 15 },
        'correct data returned for static configured paging'
    );
}

# -and|-or condition
{
    my @variants = (
        # -or
        {
            search => {
                title => [qw(Yowlin Howlin)],
            },
        },
        {
            search => {
                -or => [
                    title => [qw(Yowlin Howlin)],
                ],
            },
        },
        {
            search => {
                -or => [
                    title => [qw(Yowlin)],
                    title => [qw(Howlin)],
                ],
            },
        },
        {
            search => {
                -or => [
                    { title => [qw(Yowlin)] },
                    { title => [qw(Howlin)] },
                ],
            },
        },
        # -and
        {
            search => {
                cd => 2,
                position => [1, 2],
            },
        },
        {
            search => {
                -and => [
                    cd => 2,
                    position => [1, 2],
                ],
            },
        },
        # -and & -or
        {
            search => {
                -or => [
                    -and => [
                        cd => 2,
                        position => [0, 1],
                    ],
                    -and => [
                        cd => 2,
                        position => [0, 2],
                    ],
                ],
            },
        },
        {
            search => {
                -or => [
                    {
                        -and => [
                            cd => 2,
                            position => [0, 1],
                        ],
                    },
                    {
                        -and => [
                            cd => 2,
                            position => [0, 2],
                        ],
                    },
                ],
            },
        },
        {
            search => {
                -or => [
                    {
                        -and => [
                            cd => 2,
                            position => [0, 1],
                        ],
                    },
                    {
                        -and => [
                            cd => 2,
                            position => [0, 2],
                        ],
                    },
                ],
            },
        },
    );

    for my $case ( @variants ) {
        is $schema->resultset('Track')->search($case->{search})->count, 2, 'check -and|-or search param correctness';

        my $uri = URI->new($track_list_url);
        $uri->query_form( map { $_ => encode_json($case->{$_}) } keys %$case );
        my $req = GET( $uri, 'Accept' => 'text/x-json' );
        $mech->request($req);
        cmp_ok( $mech->status, '==', 200, 'attempt with -or search okay' );
        my $response          = $json->decode( $mech->content );
        my @expected_response = map {
            { $_->get_columns }
        } $schema->resultset('Track')->search($case->{search})->all;
        is_deeply(
            $response,
            # track does set use_json_boolean
            { list => \@expected_response, success => JSON::true, totalcount => 2 },
            'correct data returned for -and|-or search param'
        )
            or diag p($case) . p($response);
    }
}

{
    my $uri = URI->new($artist_list_url);
    $uri->query_form( { 'search.cds.track.title' => 'Suicidal' } );
    my $req = GET( $uri, 'Accept' => 'text/x-json' );
    $mech->request($req);
    cmp_ok( $mech->status, '==', 400,
        'attempt with nonexisting relationship fails' );
    my $response = $json->decode( $mech->content );
    like(
        $response->{messages}->[0],
        qr/unsupported value 'HASH\([^\)]+\)' for column 'track'/,
        'correct error message returned'
    );
}

{
    my $uri = URI->new($artist_list_url);
    $uri->query_form( { 'search.cds.tracks.foo' => 'Bar' } );
    my $req = GET( $uri, 'Accept' => 'text/x-json' );
    $mech->request($req);
    cmp_ok( $mech->status, '==', 400,
        'attempt with nonexisting column fails' );
    my $response = $json->decode( $mech->content );
    is_deeply(
        $response->{messages},
        ['a database error has occured.'],
        'correct error message returned'
    );
}

{
    my $uri = URI->new($artist_list_url);
    $uri->query_form( { 'search.cds.tracks.title.like' => 'Boring%' } );
    my $req = GET( $uri, 'Accept' => 'text/x-json' );
    $mech->request($req);
    cmp_ok( $mech->status, '==', 200, 'attempt with sql function ok' );
    my $response          = $json->decode( $mech->content );
    my @expected_response = map {
        { $_->get_columns }
        } $schema->resultset('Artist')
        ->search( { 'tracks.title' => { 'like' => 'Boring%' }, },
        { join => { cds => 'tracks' }, } )->all;
    is_deeply(
        $response,

        # artist doesn't set use_json_boolean
        { list => \@expected_response, success => 'true' },
        'correct data returned for search with sql function'
    );
}

done_testing();
