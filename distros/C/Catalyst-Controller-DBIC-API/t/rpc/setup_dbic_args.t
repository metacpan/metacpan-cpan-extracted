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

my $track_list_url = "$base/api/rpc/track_setup_dbic_args/list";
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
    } $base_rs->search( { position => { '!=' => '1' } } )->all;
    my $response = $json->decode( $mech->content );
    is_deeply( { list => \@expected_response, success => 'true' },
        $response, 'correct message returned' );
}

done_testing();
