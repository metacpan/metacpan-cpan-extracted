use strict;
use warnings;

use Test::More tests => 3;

use AddressBook qw{
    -Engine=CGI
    -TemplateEngine=TT
};

use Gantry::Server;
use Gantry::Engine::CGI;

# these tests must contain valid template paths to the core gantry templates
# and any application specific templates

my $cgi = Gantry::Engine::CGI->new( {
    config => {
        dbconn => 'dbi:SQLite:dbname=app.db',
        doc_rootp => '/static',
        show_dev_navigation => '1',
        template_wrapper => 'genwrapper.tt',
        root => 'html:html/templates',
    },
    locations => {
        '/' => 'AddressBook',
        '/family' => 'AddressBook::Family',
        '/child' => 'AddressBook::Child',
    },
} );

my @tests = qw(
    /
    /family
    /child
);

my $server = Gantry::Server->new();
$server->set_engine_object( $cgi );

SKIP: {

    eval {
        require DBD::SQLite;
    };
    skip 'DBD::SQLite is required for run tests.', 3 if ( $@ );

    unless ( -f 'app.db' ) {
        skip 'app.db sqlite database required for run tests.', 3;
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
