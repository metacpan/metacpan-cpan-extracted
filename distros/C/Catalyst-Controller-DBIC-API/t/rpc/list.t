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

my $artist_list_url   = "$base/api/rpc/artist/list";
my $producer_list_url = "$base/api/rpc/producer/list";
my $track_list_url    = "$base/api/rpc/track/list";
my $cd_list_url       = "$base/api/rpc/cd/list";

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
    my $uri = URI->new($artist_list_url);
    $uri->query_form(
        {   'search.name.LIKE'     => '%waul%',
            'list_returns.0.count' => '*',
            'as.0'                 => 'count'
        }
    );
    my $req = GET( $uri, 'Accept' => 'text/x-json' );
    $mech->request($req);
    cmp_ok( $mech->status, '==', 200, 'attempt with basic count' );

    my @expected_response = map {
        { $_->get_columns }
        } $schema->resultset('Artist')
        ->search( { name => { LIKE => '%waul%' } },
        { select => [ { count => '*' } ], as => ['count'] } )->all;
    my $response = $json->decode( $mech->content );
    is_deeply(
        $response,
        { list => \@expected_response, success => 'true' },
        'correct data returned for count'
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
        'correct data returned for class with list_returns specified'
    );
}

{
    my $uri = URI->new($track_list_url);
    $uri->query_form( { 'list_ordered_by' => 'position' } );
    my $req = GET( $uri, 'Accept' => 'text/x-json' );
    $mech->request($req);
    cmp_ok( $mech->status, '==', 200, 'search related request okay' );

    my @expected_response = map {
        { $_->get_columns }
        } $schema->resultset('Track')->search(
        {},
        {   group_by => 'position',
            order_by => 'position ASC',
            select   => 'position'
        }
        )->all;
    my $response = $json->decode( $mech->content );
    is_deeply(
        $response,
        { list => \@expected_response, success => 'true' },
        'correct data returned for class with everything specified in class'
    );
}

{
    my $uri = URI->new($track_list_url);
    $uri->query_form(
        {   'list_ordered_by' => 'cd',
            'list_returns'    => 'cd',
            'list_grouped_by' => 'cd'
        }
    );
    my $req = GET( $uri, 'Accept' => 'text/x-json' );
    $mech->request($req);
    cmp_ok( $mech->status, '==', 200, 'search related request okay' );

    my @expected_response = map {
        { $_->get_columns }
        } $schema->resultset('Track')
        ->search( {},
        { group_by => 'cd', order_by => 'cd ASC', select => 'cd' } )->all;
    my $response = $json->decode( $mech->content );
    is_deeply(
        $response,
        { list => \@expected_response, success => 'true' },
        'correct data returned when everything overridden in query'
    );
}

{
    my $uri = URI->new($track_list_url);
    $uri->query_form( { 'list_ordered_by' => 'cd', 'list_count' => 2 } );
    my $req = GET( $uri, 'Accept' => 'text/x-json' );
    $mech->request($req);
    cmp_ok( $mech->status, '==', 200, 'list count request okay' );

    my @expected_response = map {
        { $_->get_columns }
        } $schema->resultset('Track')->search(
        {},
        {   group_by => 'position',
            order_by => 'position ASC',
            select   => 'position',
            rows     => 2
        }
        )->all;
    my $response = $json->decode( $mech->content );
    is_deeply(
        $response,
        { list => \@expected_response, success => 'true' },
        'correct data returned'
    );
}

{
    my $uri = URI->new($track_list_url);
    $uri->query_form(
        {   'list_ordered_by' => 'cd',
            'list_count'      => 2,
            'list_page'       => 'fgdg'
        }
    );
    my $req = GET( $uri, 'Accept' => 'text/x-json' );
    $mech->request($req);
    cmp_ok( $mech->status, '==', 400,
        'non numeric list_page request not okay' );
    my $response = $json->decode( $mech->content );
    is( $response->{success}, 'false', 'correct data returned' );
    like(
        $response->{messages}->[0],
        qr/Attribute \(page\) does not pass the type constraint because: Validation failed for 'Int' (failed )?with value (")?fgdg(")?/,
        'correct data returned'
    );
}

{
    my $uri = URI->new($track_list_url);
    $uri->query_form(
        {   'list_ordered_by' => 'cd',
            'list_count'      => 'sdsdf',
            'list_page'       => 2
        }
    );
    my $req = GET( $uri, 'Accept' => 'text/x-json' );
    $mech->request($req);
    cmp_ok( $mech->status, '==', 400,
        'non numeric list_count request not okay' );
    my $response = $json->decode( $mech->content );
    is( $response->{success}, 'false', 'correct data returned' );
    like(
        $response->{messages}->[0],
        qr/Attribute \(count\) does not pass the type constraint because: Validation failed for 'Int' (failed )?with value (")?sdsdf(")?/,
        'correct data returned'
    );

}

{
    my $uri = URI->new($track_list_url);
    $uri->query_form(
        { 'list_ordered_by' => 'cd', 'list_count' => 2, 'list_page' => 2 } );
    my $req = GET( $uri, 'Accept' => 'text/x-json' );
    $mech->request($req);
    cmp_ok( $mech->status, '==', 200, 'list count with page request okay' );

    my @expected_response = map {
        { $_->get_columns }
        } $schema->resultset('Track')->search(
        {},
        {   group_by => 'position',
            order_by => 'position ASC',
            select   => 'position',
            rows     => 2,
            page     => 2
        }
        )->all;
    my $response = $json->decode( $mech->content );
    is_deeply(
        $response,
        { list => \@expected_response, success => 'true', totalcount => 3 },
        'correct data returned'
    );
}

{
    my $uri = URI->new($track_list_url);
    $uri->query_form( { 'list_ordered_by' => 'cd', 'list_page' => 2 } );
    my $req = GET( $uri, 'Accept' => 'text/x-json' );
    $mech->request($req);
    cmp_ok( $mech->status, '==', 400,
        'list page without count returns error' );
    my $response = $json->decode( $mech->content );
    like(
        $response->{messages}->[0],
        qr/a database error has occured/,
        'correct data returned'
    );
}

{
    my $uri = URI->new($cd_list_url);
    $uri->query_form( { 'search.artist.name' => 'Caterwauler McCrae' } );
    my $req = GET( $uri, 'Accept' => 'text/x-json' );
    $mech->request($req);
    if (cmp_ok(
            $mech->status, '==', 200,
            'search on rel with same name column request okay'
        )
        )
    {
        my @expected_response = map {
            { $_->get_columns }
        } $schema->resultset('CD')->search( { 'me.artist' => 1 } )->all;
        my $response = $json->decode( $mech->content );
        is_deeply(
            $response,
            { list => \@expected_response, success => 'true' },
            'correct data returned for search on rel with same name column'
        );
    }
}

{
    my $uri = URI->new($cd_list_url);
    $uri->query_form( { 'search.artist' => 1 } );
    my $req = GET( $uri, 'Accept' => 'text/x-json' );
    $mech->request($req);
    cmp_ok( $mech->status, '==', 200,
        'search on column with same name rel request okay' );

    my @expected_response = map {
        { $_->get_columns }
    } $schema->resultset('CD')->search( { 'me.artist' => 1 } )->all;
    my $response = $json->decode( $mech->content );
    is_deeply(
        $response,
        { list => \@expected_response, success => 'true' },
        'correct data returned for search on column with same name rel'
    );
}

{
    my $uri = URI->new($cd_list_url);
    $uri->query_form(
        {   'search.title'           => 'Spoonful of bees',
            'search.tracks.position' => 1
        }
    );
    my $req = GET( $uri, 'Accept' => 'text/x-json' );
    $mech->request($req);
    if (cmp_ok(
            $mech->status, '==', 200,
            'search on col which exists for me and related table okay'
        )
        )
    {
        my @expected_response = map {
            { $_->get_columns }
            } $schema->resultset('CD')
            ->search(
            { 'me.title' => 'Spoonful of bees', 'tracks.position' => 1 },
            { join       => 'tracks' } )->all;
        my $response = $json->decode( $mech->content );
        is_deeply(
            $response,
            { list => \@expected_response, success => 'true' },
            'correct data returned for search on col which exists for me and related table'
        );
    }
}

{
    my $uri = URI->new($cd_list_url);
    $uri->query_form( { 'list_ordered_by' => 'invalid_column' } );
    my $req = GET( $uri, 'Accept' => 'text/x-json' );
    $mech->request($req);
    if (cmp_ok(
            $mech->status, '==', 400,
            'order_by on non-existing col returns error'
        )
        )
    {
        my $response = $json->decode( $mech->content );
        is_deeply(
            $response,
            {   messages => ['a database error has occured.'],
                success  => 'false'
            },
            'error returned for order_by on non-existing col'
        );
    }
}

{
    my $uri = URI->new($cd_list_url);
    $uri->query_form(
        {   'list_ordered_by' => 'invalid_column',
            'list_count'      => 2,
            'list_page'       => 1
        }
    );
    my $req = GET( $uri, 'Accept' => 'text/x-json' );
    $mech->request($req);
    if (cmp_ok(
            $mech->status, '==', 400,
            'order_by on invalid col with paging returns error'
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

done_testing();
