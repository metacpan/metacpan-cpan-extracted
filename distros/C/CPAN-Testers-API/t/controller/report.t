
=head1 DESCRIPTION

This file tests the L<CPAN::Testers::API::Controller::Report> controller.

=cut

use CPAN::Testers::API::Base 'Test';
use FindBin ();
use Mojo::File qw( path );
use Mojo::JSON qw( decode_json );
my $SHARE_DIR = path( $FindBin::Bin, '..', 'share' );
my $HEX = qr{[A-Fa-f0-9]};

my $t = prepare_test_app();

subtest '/v3/report' => \&_test_api, '/v3';

sub _test_api( $base ) {
    subtest 'post valid report' => sub {
        my $report = decode_json( $SHARE_DIR->child( qw( report perl5 valid.v3.json ) )->slurp );
        $t->post_ok( $base . '/report', json => $report )
          ->status_is( 201 )
          ->or( sub { diag shift->tx->res->body } )
          ->json_like( '/id' => qr{${HEX}{8}-${HEX}{4}-${HEX}{4}-${HEX}{4}-${HEX}{12}} )
          ;
    };

    subtest 'invalid report: version number starts with v' => sub {
        my $report = decode_json( $SHARE_DIR->child( qw( report perl5 invalid-version-v.json ) )->slurp );
        $t->post_ok( $base . '/report', json => $report )
          ->status_is( 400 )
          ->or( sub { diag shift->tx->res->body } )
          ->json_is( '/errors/0/path' => '/report/environment/language/version' )
          ->or( sub { diag shift->tx->res->body } )
          ->json_like( '/errors/0/message' => qr{String does not match} )
          ->or( sub { diag shift->tx->res->body } )
          ;
    };

    subtest 'get report' => sub {
        my $row = $t->app->schema->resultset( 'TestReport' )->first;
        $t->get_ok( $base . '/report/' . $row->id )
          ->status_is( 200 )
          ->or( sub { diag shift->tx->res->body } )
          ->json_is( $row->report );

        subtest 'error: report not found' => sub {
            $t->get_ok( $base . '/report/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX' )
              ->status_is( 404 )
              ->json_is({
                    errors => [
                        {
                            message => 'Report ID not found',
                            path => '/id',
                        },
                    ],
                });
        };
    };
}

done_testing;

