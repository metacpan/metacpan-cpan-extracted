use strict;
use warnings;

use Test::More tests => 4;

use Apps::Checkbook qw{
    -Engine=CGI
    -TemplateEngine=TT
    -PluginNamespace=Apps::Checkbook
    PluginQ
};

use Gantry::Server;
use Gantry::Engine::CGI;

# these tests must contain valid template paths to the core gantry templates
# and any application specific templates

my $cgi = Gantry::Engine::CGI->new( {
    config => {
        dbconn => 'dbi:SQLite:dbname=app.db',
        DB => 'app_db',
        DBName => 'someone',
        root => 'html:html/templates',
    },
    locations => {
        '/payee' => 'Apps::Checkbook::PayeeOr',
        '/foreign/location' => 'Apps::Checkbook::Trans',
        '/transaction' => 'Apps::Checkbook::Trans::Action',
        '/sch_tbl' => 'Apps::Checkbook::SchTbl',
    },
} );

my @tests = qw(
    /payee
    /foreign/location
    /transaction
    /sch_tbl
);

my $server = Gantry::Server->new();
$server->set_engine_object( $cgi );

SKIP: {

    eval {
        require DBD::SQLite;
    };
    skip 'DBD::SQLite is required for run tests.', 4 if ( $@ );

    unless ( -f 'app.db' ) {
        skip 'app.db sqlite database required for run tests.', 4;
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
