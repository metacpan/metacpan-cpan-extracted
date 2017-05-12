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

use Bigtop::TentMaker qw/ -Engine=CGI -TemplateEngine=TT /;
use Bigtop::ScriptHelp::Style;

$ENV{ BIGTOP_REAL_DEF } = 1;

my $style = Bigtop::ScriptHelp::Style->get_style();

Bigtop::TentMaker->take_performance_hit( $style );

my $ajax_dir = File::Spec->catdir( qw( t tentmaker ajax_06 ) );
my $expected_file;
my $ajax;
my $tent_maker = Bigtop::TentMaker->new();
$tent_maker->uri( '/' );
$tent_maker->root( 'tenttemplates' );

#--------------------------------------------------------------------
# Add literal
#--------------------------------------------------------------------

$ajax = $tent_maker->do_create_app_block( 'literal::' );

$ajax = strip_build_dir( $ajax );

$expected_file = File::Spec->catfile( $ajax_dir, 'alit' );

file_filter_ok(
    $expected_file,
    $ajax,
    \&strip_build_dir,
    'create empty literal (alit)'
);

#--------------------------------------------------------------------
# Change literal type
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_type_change( 'ident_6', 'Location' );

$ajax = strip_build_dir( $ajax );

$expected_file = File::Spec->catfile( $ajax_dir, 'clittype' );

file_filter_ok(
    $expected_file,
    $ajax,
    \&strip_build_dir,
    'change literal type (clittype)'
);

#--------------------------------------------------------------------
# Change literal value
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_literal( 'ident_6', '    require valid-user' );

$ajax = strip_build_dir( $ajax );

$expected_file = File::Spec->catfile( $ajax_dir, 'clittext' );

file_filter_ok(
    $expected_file,
    $ajax,
    \&strip_build_dir,
    'change literal text (clittext)'
);

#--------------------------------------------------------------------
# Delete literal
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_delete_block( 'ident_6' );

$ajax = strip_build_dir( $ajax );

$expected_file = File::Spec->catfile( $ajax_dir, 'rlit' );

file_filter_ok(
    $expected_file,
    $ajax,
    \&strip_build_dir,
    'remove literal (rlit)'
);

