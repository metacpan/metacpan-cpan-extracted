use 5.6.0;

use strict;
use warnings;

use lib 'lib';
use lib 't/lib';

my $host = 'http://localhost';
my $content_type = [ 'Content-Type', 'application/x-www-form-urlencoded' ];

use RestTest;
use DBICTest;
use Test::More tests => 15;
use Test::WWW::Mechanize::Catalyst 'RestTest';
use HTTP::Request::Common;
use JSON::XS;

my $mech = Test::WWW::Mechanize::Catalyst->new;
ok( my $schema = DBICTest->init_schema(), 'got schema' );

my $track = $schema->resultset('Track')->first;

my %original_cols = $track->get_columns;

my $track_update_url = "$host/api/rest/track/" . $track->id;

# test invalid track id caught
{
    foreach my $wrong_id ( 'sdsdsdsd', 3434234 ) {
        my $incorrect_url = "$host/api/rest/track/" . $wrong_id;
        my $test_data     = encode_json( { title => 'value' } );
        my $req           = POST( $incorrect_url, Content => $test_data );
        $req->content_type('text/x-json');
        $mech->request($req);

        cmp_ok( $mech->status, '==', 400,
            'Attempt with invalid track id caught' );
        my $response = decode_json( $mech->content );
        like(
            @{ $response->{messages} }[0],
            qr/No object found for id/,
            'correct message returned'
        );

        $track->discard_changes;
        is_deeply(
            { $track->get_columns },
            \%original_cols,
            'no update occurred'
        );
    }
}

# validation when no params sent
{
    my $test_data = encode_json( { wrong_param => 'value' } );
    my $req = POST( $track_update_url, Content => $test_data );
    $req->content_type('text/x-json');
    $mech->request($req);

    cmp_ok( $mech->status, '==', 400, 'Update with no keys causes error' );

    my $response = decode_json( $mech->content );
    is_deeply( $response->{messages}, ['No valid keys passed'],
        'correct message returned' );

    $track->discard_changes;
    is_deeply(
        { $track->get_columns },
        \%original_cols,
        'no update occurred'
    );
}

{
    my $test_data = encode_json( { title => undef } );
    my $req = POST( $track_update_url, Content => $test_data );
    $req->content_type('text/x-json');
    $mech->request($req);
    cmp_ok( $mech->status, '==', 200, 'Update with key with no value okay' );

    $track->discard_changes;
    isnt( $track->title, $original_cols{title}, 'Title changed' );
    is( $track->title, undef, 'Title changed to undef' );
}

{
    my $test_data = encode_json( { title => 'monkey monkey' } );
    my $req = POST( $track_update_url, Content => $test_data );
    $req->content_type('text/x-json');
    $mech->request($req);

    cmp_ok( $mech->status, '==', 200, 'Update with key with value okay' );

    $track->discard_changes;
    is( $track->title, 'monkey monkey', 'Title changed to "monkey monkey"' );
}
