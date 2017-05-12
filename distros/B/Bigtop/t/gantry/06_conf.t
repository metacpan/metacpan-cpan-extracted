use strict;

use Test::More tests => 3;
use Test::Files;

use File::Spec;

use Bigtop::Parser;

use lib 't';
use Purge;

my $bigtop_string;
my $tree;
my @conf;
my $correct_conf;
my @split_dollar_at;
my @correct_dollar_at;
my $base_dir   = File::Spec->catdir( 't', 'gantry' );
my $docs_dir   = File::Spec->catdir( $base_dir, 'docs' );
my $lib_dir    = File::Spec->catdir( $base_dir, 'lib' );
my $t_dir      = File::Spec->catdir( $base_dir, 't' );
my $conf       = File::Spec->catfile( $docs_dir, 'Apps-Checkbook.conf' );
my $gconf      = File::Spec->catfile(
        $docs_dir,
        'Apps-Checkbook.gantry.conf'
);
my $run_t      = File::Spec->catfile(
        $t_dir,
        '10_run.t',
);

Purge::real_purge_dir( $docs_dir );
Purge::real_purge_dir( $t_dir );

#---------------------------------------------------------------------------
# correct (though small) for Conf General backend
#---------------------------------------------------------------------------

$bigtop_string = << 'EO_correct_bigtop';
config {
    Conf General { }
}
app Apps::Checkbook {
    location `/app_base`;
    config {
        DB     app_db => no_accessor;
        DBName some_user;
        two_word `Two Words`;
        root `/my/very/own`;
    }
    literal Conf `hello shane`;
    controller PayeeOr {
        rel_location   payee;
        config {
            importance     3 => no_accessor;
            lines_per_page 3;
        }
        literal GantryLocation `    hello savine`;
    }
    controller Trans {
        location   `/foreign_loc/trans`;
    }
}
EO_correct_bigtop

$tree = Bigtop::Parser->parse_string($bigtop_string);

Bigtop::Backend::Conf::General->gen_Conf( $base_dir, $tree );

$correct_conf = <<'EO_CORRECT_CONF';
DB app_db
DBName some_user
two_word Two Words
root /my/very/own
hello shane

<GantryLocation /app_base/payee>
    importance 3
    lines_per_page 3
    hello savine
</GantryLocation>

EO_CORRECT_CONF

file_ok( $conf, $correct_conf, 'generated output' );

Purge::real_purge_dir( $docs_dir );

#---------------------------------------------------------------------------
# for Conf Gantry backend
#---------------------------------------------------------------------------

$bigtop_string = << 'EO_correct_bigtop';
config {
    template_engine TT;
    Conf Gantry { instance happy; }
    Control Gantry { }
}
app Apps::Checkbook {
    location `/app_base`;
    config {
        DB     app_db => no_accessor;
        DBName some_user;
    }
    config prod {
        DB prod_db;
        dbconn `dbi:SQLite:dbname=proddb;host=localhost`;
    }
    literal Conf `hello shane`;
    controller PayeeOr {
        rel_location   payee;
        config {
            importance     3 => no_accessor;
            lines_per_page 3;
        }
        config prod {
            lines_per_page 25;
        }
        literal GantryLocation `    hello savine`;
    }
    controller Trans {
        location   `/foreign_loc/trans`;
    }
}
EO_correct_bigtop

$tree = Bigtop::Parser->parse_string($bigtop_string);

Bigtop::Backend::Conf::Gantry->gen_Conf( $base_dir, $tree );

$correct_conf = <<'EO_CORRECT_CONF';
<instance happy>
    DB app_db
    DBName some_user
    root html:html/templates
    hello shane
    <GantryLocation /app_base/payee>
        importance 3
        lines_per_page 3
        hello savine
    </GantryLocation>
</instance>

<instance happy_prod>
    DB prod_db
    dbconn dbi:SQLite:dbname=proddb;host=localhost
    root html:html/templates
    DBName some_user
    hello shane
    <GantryLocation /app_base/payee>
        lines_per_page 25
        importance 3
        hello savine
    </GantryLocation>
</instance>

EO_CORRECT_CONF

file_ok( $gconf, $correct_conf, 'generated gantry output' );

Purge::real_purge_dir( $docs_dir );

#---------------------------------------------------------------------------
# for Control Gantry backend to test the run tests
#---------------------------------------------------------------------------

Bigtop::Backend::Control::Gantry->gen_Control( $base_dir, $tree );

my $correct_run_t = <<'EO_RUN_T';
use strict;
use warnings;

use Test::More tests => 3;

use Apps::Checkbook qw{
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
        DB => 'app_db',
        DBName => 'some_user',
        root => 'html:html/templates',
    },
    locations => {
        '/' => 'Apps::Checkbook',
        '/payee' => 'Apps::Checkbook::PayeeOr',
        '/foreign_loc/trans' => 'Apps::Checkbook::Trans',
    },
} );

my @tests = qw(
    /
    /payee
    /foreign_loc/trans
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
EO_RUN_T

file_ok( $run_t, $correct_run_t, 'generated run test' );

Purge::real_purge_dir( $t_dir );
Purge::real_purge_dir( $lib_dir );
