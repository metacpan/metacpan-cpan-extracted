use strict;
use warnings;

use lib 't/lib';

my $base = 'http://localhost';
my $content_type = [ 'Content-Type', 'application/x-www-form-urlencoded' ];

use RestTest;
use DBICTest;
use Test::More;
use Test::WWW::Mechanize::Catalyst 'RestTest';
use HTTP::Request::Common qw/ DELETE /;
use JSON;

my $json = JSON->new->utf8;

my $mech = Test::WWW::Mechanize::Catalyst->new;
ok( my $schema = DBICTest->init_schema(), 'got schema' );

my $track         = $schema->resultset('Track')->first;
my %original_cols = $track->get_columns;

my $track_url        = "$base/api/rest/track/";
my $track_delete_url = $track_url . $track->id;

{
    my $req = HTTP::Request->new( DELETE => $track_delete_url );
    $req->content_type('text/x-json');
    $mech->request($req);
    cmp_ok( $mech->status, '==', 200, 'Attempt to delete track ok' );

    my $deleted_track = $schema->resultset('Track')->find( $track->id );
    is( $deleted_track, undef, 'track deleted' );
}

{
    my $req = HTTP::Request->new( DELETE => $track_delete_url );
    $req->content_type('text/x-json');
    $mech->request($req);
    cmp_ok( $mech->status, '==', 400, 'Attempt to delete again caught' );
}

{
    my $track_cnt = $schema->resultset('Track')->count;
    my $tracks_rs =
        $schema->resultset('Track')
        ->search( undef, { select => ['trackid'], as => ['id'], rows => 3 } );
    $tracks_rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
    my $test_data = $json->encode( { list => [ $tracks_rs->all ] } );
    my $req = DELETE( $track_url, Content => $test_data );
    $req->content_type('text/x-json');
    $mech->request($req);
    cmp_ok( $mech->status, '==', 200, 'Attempt to delete three tracks ok' );

    is( $schema->resultset('Track')->count + 3,
        $track_cnt, 'Three tracks deleted' );
}

done_testing();
