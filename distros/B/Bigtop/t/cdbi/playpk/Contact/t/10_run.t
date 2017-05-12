use strict;

use Test::More tests => 1;

use Contact qw{ -Engine=CGI -TemplateEngine=TT };

use Gantry::Server;
use Gantry::Engine::CGI;

# these tests must contain valid template paths to the core gantry templates
# and any application specific templates

my $cgi = Gantry::Engine::CGI->new( {
    config => {
        dbconn => 'dbi:SQLite:dbname=app.db',
        dbuser => 'apache',
        root => 'html',
    },
    locations => {
        '/' => 'Contact',
    },
} );

my @tests = qw(
    /
);

my $server = Gantry::Server->new();
$server->set_engine_object( $cgi );

SKIP: {

    eval {
        require DBD::SQLite;
    };
    skip 'DBD::SQLite is required for run tests.', 1 if ( $@ );

    unless ( -f 'app.db' ) {
        skip 'app.db sqlite database required for run tests.', 1;
    }

    foreach my $location ( @tests ) {
        my( $status, $page ) = $server->handle_request_test( $location );
        ok( $status eq '200',
                "expected 200, received $status for $location" );

        if ( $status ne '200' ) {
            print STDERR $page . "\n\n";
        }
    }

}
