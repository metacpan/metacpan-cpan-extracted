use strict;

use Test::More tests => 4;
use Test::Files;
use File::Spec;

use lib 't';
use Purge;

my $skip_all = 0;

BEGIN {
    eval { require Gantry; };
    $skip_all = ( $@ ) ? 1 : 0;

    SKIP: {
        skip "tentmaker requires Gantry", 4 if $skip_all;
    }
    exit 0 if $skip_all;
}

use File::Spec;

use Bigtop::TentMaker qw/ -Engine=CGI -TemplateEngine=TT /;
use Bigtop::ScriptHelp::Style;

$ENV{ BIGTOP_REAL_DEF } = 1;

my $tent_maker;
my @maker_deparse;
my $ajax_dir = File::Spec->catdir( qw( t tentmaker ajax_03 ) );
my $expected_file;
my $ajax;
my $style = Bigtop::ScriptHelp::Style->get_style();

#--------------------------------------------------------------------
# Sanity Check (repeated test from 02....t)
#--------------------------------------------------------------------

Bigtop::TentMaker->take_performance_hit( $style );

my @correct_input = split /\n/, <<'EO_sample_input';
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

$tent_maker = Bigtop::TentMaker->new();
$tent_maker->uri( '/' );
$tent_maker->root( 'tenttemplates' );

@maker_deparse = split /\n/, strip_build_dir( $tent_maker->deparsed() );

is_deeply( \@maker_deparse, \@correct_input, 'simple sample deparse' );

#--------------------------------------------------------------------
# Add config statement to existing config block
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_app_conf_statement(
            'ident_1::new_conf_st',
            'new_value',
            'true'
);

$ajax = strip_build_dir( $ajax );

$expected_file = File::Spec->catfile( $ajax_dir, 'aconfst' );

file_ok( $expected_file, $ajax, 'add conf statement (aconfst)' );

#--------------------------------------------------------------------
# Add config statement when config block exists, but is empty
#--------------------------------------------------------------------

my $empty_config = File::Spec->catfile( 't', 'tentmaker', 'sample' );

Bigtop::TentMaker->take_performance_hit( $style, $empty_config );

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_app_conf_statement(
        'ident_6::new_conf_st',
        'value',
        'false'
);

$ajax = strip_build_dir( $ajax );

$expected_file = File::Spec->catfile( $ajax_dir, 'aconfstempty' );

file_ok( $expected_file, $ajax, 'first conf statement (aconfstempty)' );

#--------------------------------------------------------------------
# Change statement value
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_app_conf_statement(
            'ident_6::new_conf_st',
            'other_value',
            'false',
);

$ajax = strip_build_dir( $ajax );

$expected_file = File::Spec->catfile( $ajax_dir, 'cconfstempty' );

file_ok( $expected_file, $ajax, 'change first conf statement (cconfstempty)' );

