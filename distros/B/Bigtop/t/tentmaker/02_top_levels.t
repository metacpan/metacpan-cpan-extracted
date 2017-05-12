use strict;

use Test::More tests => 8;
use Test::Files;

use lib 't';
use Purge;

my $skip_all = 0;

BEGIN {
    eval { require Gantry; };
    $skip_all = ( $@ ) ? 1 : 0;

    SKIP: {
        skip "tentmaker requires Gantry", 8 if $skip_all;
    }
    exit 0 if $skip_all;
}

use Bigtop::TentMaker qw/ -Engine=CGI -TemplateEngine=TT /;
use Bigtop::ScriptHelp::Style;

use File::Spec;

$ENV{ BIGTOP_REAL_DEF } = 1;

my $tent_maker;
my @maker_input;
my @maker_deparse;
my @correct_input;
my $ajax;
my $ajax_dir = File::Spec->catdir( qw( t tentmaker ajax_02 ) );
my $expected_file;
my $style = Bigtop::ScriptHelp::Style->get_style();

#--------------------------------------------------------------------
# Reading sample file from TentMaker __DATA__ block.
#--------------------------------------------------------------------

@correct_input = split /\n/, <<'EO_sample_input';
config {
    engine MP20;
    template_engine TT;
    Init Std {  }
    Conf Gantry { conffile `docs/app.gantry.conf`; instance sample; }
    HttpdConf Gantry { gantry_conf 1; }
    SQL SQLite {  }
    SQL Postgres {  }
    SQL MySQL {  }
    CGI Gantry { with_server 1; flex_db 1; gantry_conf 1; }
    Control Gantry { dbix 1; }
    Model GantryDBIxClass {  }
    SiteLook GantryDefault {  }
}
app Sample {
    config {
        dbconn `dbi:SQLite:dbname=app.db` => no_accessor;
        template_wrapper `genwrapper.tt` => no_accessor;
        doc_rootp `/static` => no_accessor;
        show_dev_navigation 1 => no_accessor;
    }
    config CGI {
        dbconn `dbi:SQLite:dbname=app.db` => no_accessor;
        app_rootp `/cgi-bin/sample.cgi` => no_accessor;
    }
    controller is base_controller {
        method do_main is base_links {
        }
        method site_links is links {
        }
    }
}
EO_sample_input

Bigtop::TentMaker->take_performance_hit( $style );

$tent_maker  = Bigtop::TentMaker->new();

$tent_maker->uri( '/' );
$tent_maker->root( 'tenttemplates' );

@maker_input = split /\n/, strip_build_dir( $tent_maker->input() );

is_deeply( \@maker_input, \@correct_input, 'simple sample input' );

#--------------------------------------------------------------------
# Deparsing __DATA__ input
#--------------------------------------------------------------------

@maker_deparse = split /\n/, strip_build_dir( $tent_maker->deparsed() );

is_deeply( \@maker_deparse, \@correct_input, 'simple sample deparse' );

#--------------------------------------------------------------------
# Change App Name
#--------------------------------------------------------------------

$ajax = $tent_maker->do_update_std( 'appname', 'MySample' );

$ajax = strip_build_dir( $ajax );

$expected_file = File::Spec->catfile( $ajax_dir, 'cappname' );

file_ok( $expected_file, $ajax, 'change app name (cappname)' );

#--------------------------------------------------------------------
# Add backend keyword
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_conf_text(
    'SiteLook::GantryDefault::gantry_wrapper', '/path/to/gantry/root'
);

$ajax = strip_build_dir( $ajax );

$expected_file = File::Spec->catfile( $ajax_dir, 'abackword' );

file_ok( $expected_file, $ajax, 'add backend keyword (abackword)' );

#--------------------------------------------------------------------
# Change backend keyword
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_conf_text(
    'SiteLook::GantryDefault::gantry_wrapper', 'meaning_less_value'
);

$ajax = strip_build_dir( $ajax );

$expected_file = File::Spec->catfile( $ajax_dir, 'cbackword' );

file_ok( $expected_file, $ajax, 'change backend keyword (cbackword)' );

#--------------------------------------------------------------------
# Add backend bool
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_conf_bool(
            'SiteLook::GantryDefault::no_gen',
            'true'
);

$ajax = strip_build_dir( $ajax );

$expected_file = File::Spec->catfile( $ajax_dir, 'abackbool' );

file_ok( $expected_file, $ajax, 'add backend boolean (abackbool)' );

#--------------------------------------------------------------------
# Turn off backend bool
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_conf_bool(
            'SiteLook::GantryDefault::no_gen',
            'false'
);

$ajax = strip_build_dir( $ajax );

$expected_file = File::Spec->catfile( $ajax_dir, 'cbackbool' );

file_ok( $expected_file, $ajax, 'change backend boolean (cbackbool)' );

#--------------------------------------------------------------------
# Add base location statement
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_app_statement_text( 'location', '/site' );

$ajax = strip_build_dir( $ajax );

$expected_file = File::Spec->catfile( $ajax_dir, 'aappst' );

file_ok( $expected_file, $ajax, 'add app statement (aappst)' );

