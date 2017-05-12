use strict;

use Test::More tests => 14;
use Test::Files;
use File::Spec;

use lib 't';
use Purge;

my $skip_all = 0;

BEGIN {
    eval { require Gantry; };
    $skip_all = ( $@ ) ? 1 : 0;

    SKIP: {
        skip "tentmaker requires Gantry", 14 if $skip_all;
    }
    exit 0 if $skip_all;
}

use Bigtop::TentMaker qw/ -Engine=CGI -TemplateEngine=TT /;
use Bigtop::ScriptHelp::Style;

$ENV{ BIGTOP_REAL_DEF } = 1;

my $style = Bigtop::ScriptHelp::Style->get_style();

Bigtop::TentMaker->take_performance_hit( $style );

my $ajax_dir = File::Spec->catdir( qw( t tentmaker ajax_05 ) );
my $expected_file;
my $ajax;
my $tent_maker = Bigtop::TentMaker->new();
$tent_maker->uri( '/' );
$tent_maker->root( 'tenttemplates' );
$tent_maker->set_testing( 1 );

#--------------------------------------------------------------------
# Add controller
#--------------------------------------------------------------------

$ajax = $tent_maker->do_create_app_block( 'controller::Address', 'AutoCRUD' );

# this made idents 4-6

$ajax = strip_build_dir( $ajax );

$expected_file = File::Spec->catfile( $ajax_dir, 'acontrol' );

file_ok( $expected_file, $ajax, 'create default controller (acontrol)' );

#--------------------------------------------------------------------
# Add method
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_create_subblock(
    'controller::ident_6::method::do_alt_main', 'main_listing'
);

$ajax = strip_build_dir( $ajax );

# the new method is ident_7

$expected_file = File::Spec->catfile( $ajax_dir, 'amethod' );

file_ok( $expected_file, $ajax, 'add method to controller (amethod)' );

#--------------------------------------------------------------------
# Add statement to new controller.
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_controller_statement_text(
    'ident_6::uses', 'Date::Calc][Carp'
);

$ajax = strip_build_dir( $ajax );

$expected_file = File::Spec->catfile( $ajax_dir, 'acontrolst' );

file_ok( $expected_file, $ajax, 'new controller statement (acontrolst)' );

#--------------------------------------------------------------------
# Change previous statement.
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_controller_statement_text(
    'ident_6::uses', 'Carp][Date::Calc'
);

$ajax = strip_build_dir( $ajax );

$expected_file = File::Spec->catfile( $ajax_dir, 'ccontrolst' );

file_ok( $expected_file, $ajax, 'change controller statement (ccontrolst)' );

#--------------------------------------------------------------------
# Add method statement.
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_method_statement_text(
    'ident_9::title', 'A Label'
);

$ajax = strip_build_dir( $ajax );

$expected_file = File::Spec->catfile( $ajax_dir, 'amethodst' );

file_ok( $expected_file, $ajax, 'new method statement (amethodst)' );

#--------------------------------------------------------------------
# Change method statement.
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_method_statement_text(
    'ident_9::title', 'Addresses'
);

$ajax = strip_build_dir( $ajax );

$expected_file = File::Spec->catfile( $ajax_dir, 'cmethodst' );

file_ok( $expected_file, $ajax, 'change method statement (cmethodst)' );

#--------------------------------------------------------------------
# Change controller name.
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_name( 'controller::ident_6', 'AddressControl' );

$ajax = strip_build_dir( $ajax );

$expected_file = File::Spec->catfile( $ajax_dir, 'ccontrolname' );

file_ok( $expected_file, $ajax, 'change controller name (ccontrolname)' );

#--------------------------------------------------------------------
# Change method name.
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_name( 'method::ident_7', 'do_main_listing' );

$ajax = strip_build_dir( $ajax );

$expected_file = File::Spec->catfile( $ajax_dir, 'cmethodname' );

file_ok( $expected_file, $ajax, 'change method name (cmethodname)' );

#--------------------------------------------------------------------
# Remove controller statement.
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_controller_statement_text(
    'ident_6::uses', 'undefined'
);

$ajax = strip_build_dir( $ajax );

$expected_file = File::Spec->catfile( $ajax_dir, 'rcontrolst' );

file_ok( $expected_file, $ajax, 'remove controller statement (rcontrolst)' );

#--------------------------------------------------------------------
# Remove method statement.
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_method_statement_text(
    'ident_9::title', 'undefined'
);

$ajax = strip_build_dir( $ajax );

$expected_file = File::Spec->catfile( $ajax_dir, 'rmethodst' );

file_ok( $expected_file, $ajax, 'remove method statement (rmethodst)' );

#--------------------------------------------------------------------
# Add paged_conf method statement
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_method_statement_text(
    'ident_9::paged_conf', 'list_rows'
);

$ajax = strip_build_dir( $ajax );

$expected_file = File::Spec->catfile( $ajax_dir, 'apagedst' );

file_ok( $expected_file, $ajax, 'add paged_conf method statement (apagedst)' );

#--------------------------------------------------------------------
# Add pair statement with quoted value
#--------------------------------------------------------------------
$tent_maker->params(
    {
        keys   => 'Edit][Tasks][Delete',
        values => 'undefined]["/tasks/$id"][',
    }
);

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_method_statement_pair( 'ident_9::row_options' );

$ajax = strip_build_dir( $ajax );

$expected_file = File::Spec->catfile( $ajax_dir, 'arowopts' );

file_ok( $expected_file, $ajax, 'add paired method statement (arowopts)' );

$tent_maker->params( { keys   => '', values => '', } );
$tent_maker->do_update_method_statement_pair( 'ident_9::row_options' );

#--------------------------------------------------------------------
# Remove method.
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_delete_block( 'ident_7' );

$ajax = strip_build_dir( $ajax );

$expected_file = File::Spec->catfile( $ajax_dir, 'rmethod' );

file_ok( $expected_file, $ajax, 'remove method (rmethod)' );

#--------------------------------------------------------------------
# Removed base controller and make a new one
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

# first remove the existing one
my $discard = $tent_maker->do_delete_block( 'ident_5' );

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_create_app_block(
        'controller::base_controller', 'base_controller'
);

$ajax = strip_build_dir( $ajax );

$expected_file = File::Spec->catfile( $ajax_dir, 'newbase' );

file_ok( $expected_file, $ajax, 'new base controller (newbase)' );

