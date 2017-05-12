use strict;

use Test::More tests => 28;
use Test::Files;
use Test::Warn;

use lib 't';
use Purge;

# This script uses Test::Files in an unconventional way.  Normally one
# generates a file, then checks to see if that file was correctly built.
# Here ajax returns from tentmaker arrives as strings which are compared
# to expected files.
# The main effect is upon test failure, the senses of Expected and Got
# are REVERSED.  Expected is the ajax output which arrived from tentmaker,
# while Got is the file on the disk of what it should have been.

my $skip_all = 0;

BEGIN {
    eval { require Gantry; };
    $skip_all = ( $@ ) ? 1 : 0;

    SKIP: {
        skip "tentmaker requires Gantry", 28 if $skip_all;
    }
    exit 0 if $skip_all;
}

use File::Spec;

use Bigtop::TentMaker qw/ -Engine=CGI -TemplateEngine=TT /;
use Bigtop::ScriptHelp::Style;

$ENV{ BIGTOP_REAL_DEF } = 1;

my $style = Bigtop::ScriptHelp::Style->get_style();

Bigtop::TentMaker->take_performance_hit( $style );

my $ajax_dir   = File::Spec->catdir( qw( t tentmaker ajax_04 ) );
my $expected_file;
my $ajax;
my $tent_maker = Bigtop::TentMaker->new();
$tent_maker->uri( '/' );
$tent_maker->root( 'tenttemplates' );
$tent_maker->set_testing( 1 );

#--------------------------------------------------------------------
# Add table
#--------------------------------------------------------------------

$ajax = $tent_maker->do_create_app_block( 'table::street_address' );

$ajax = strip_build_dir( $ajax );

# ident counting:
#   6     table address
#   7-11  its fields
#   12    controller Address
#   13-14 its methods

$expected_file = File::Spec->catfile( $ajax_dir, 'atable' );

file_ok( $expected_file, $ajax, 'add table (atable)' );

#--------------------------------------------------------------------
# Reorder blocks
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_move_block_after( 'ident_6', 'ident_12' );

$ajax = strip_build_dir( $ajax );

$expected_file = File::Spec->catfile( $ajax_dir, 'reorder' );

file_ok( $expected_file, $ajax, 'reorder blocks (reorder)' );

#--------------------------------------------------------------------
# Create first field
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_create_subblock( 'table::ident_6::field::name' );

$ajax = strip_build_dir( $ajax );

# this field becomes ident_23

$expected_file = File::Spec->catfile( $ajax_dir, 'cfield' );

file_ok( $expected_file, $ajax, 'create field (cfield)' );

#--------------------------------------------------------------------
# Create field in missing table
#--------------------------------------------------------------------

warning_like { $tent_maker->do_create_subblock( 'table::missing::field::id' ); }
        qr/Couldn't add subblock/,
        'attempt to create field in missing table';

#--------------------------------------------------------------------
# Change table name
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_name( 'table::ident_6', 'address_tbl' );

$ajax = strip_build_dir( $ajax );

$expected_file = File::Spec->catfile( $ajax_dir, 'ctablename' );

file_ok( $expected_file, $ajax, 'create table name (ctablename)' );

#--------------------------------------------------------------------
# Add statement to table.
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_table_statement_text(
    'ident_6::foreign_display', '%name'
);

$ajax = strip_build_dir( $ajax );

$expected_file = File::Spec->catfile( $ajax_dir, 'atablest' );

file_ok( $expected_file, $ajax, 'new table statement (atablest)' );

#--------------------------------------------------------------------
# Remove statement from table.
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_table_statement_text(
    'ident_6::foreign_display', 'undefined'
);

$ajax = strip_build_dir( $ajax );

$expected_file = File::Spec->catfile( $ajax_dir, 'remtablest' );

file_ok( $expected_file, $ajax, 'remove table statement (remtablest)' );

#--------------------------------------------------------------------
# Add statement to new field.
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_field_statement_bool(
    'ident_15::html_form_optional', 'true'
);

$ajax = strip_build_dir( $ajax );

$expected_file = File::Spec->catfile( $ajax_dir, 'afieldbool' );

file_ok( $expected_file, $ajax, 'new boolean statement (afieldbool)' );

#--------------------------------------------------------------------
# Change field statement.
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_field_statement_text(
    'ident_7::is', 'int8][primary_key][assign_by_sequence'
);

$ajax = strip_build_dir( $ajax );

$expected_file = File::Spec->catfile( $ajax_dir, 'cis' );

file_ok( $expected_file, $ajax, 'change is field statement (cis)' );

#--------------------------------------------------------------------
# Third field.
#--------------------------------------------------------------------

$tent_maker->do_create_subblock( 'table::ident_6::field::street' );

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_table_statement_text(
    'ident_6::foreign_display', '%street'
);

$ajax = strip_build_dir( $ajax );

# this field is ident_16

$expected_file = File::Spec->catfile( $ajax_dir, 'afieldcst' );

file_ok(
    $expected_file,
    $ajax,
    'add second field and change statement (afieldcst)'
);

#--------------------------------------------------------------------
# Change field name
#--------------------------------------------------------------------

# pretend street was popular in the controller
$tent_maker->do_update_method_statement_text(
    'ident_13::cols', 'ident][street][description'
);
# pretend street was unpopular in the form
$tent_maker->do_update_method_statement_text(
    'ident_14::all_fields_but', 'id][created][street][modified'
);
# ... or not  (This combination is no illegal.)
$tent_maker->do_update_method_statement_text(
    'ident_14::fields', 'street'
);

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_name( 'field::ident_16', 'street_address' );

$ajax = strip_build_dir( $ajax );

$expected_file = File::Spec->catfile( $ajax_dir, 'cfieldname' );

file_ok( $expected_file, $ajax, 'change field name (cfieldname)' );

# put things back the way they were
$tent_maker->do_update_method_statement_text(
    'ident_13::cols', 'ident][description'
);
$tent_maker->do_update_method_statement_text(
    'ident_14::all_fields_but', 'id][created][modified'
);
$tent_maker->do_update_method_statement_text(
    'ident_14::fields', 'undef'
);

#--------------------------------------------------------------------
# Set a multi-word label.
#--------------------------------------------------------------------
# first, get rid of foreign display
$tent_maker->do_update_table_statement_text(
    'ident_6::foreign_display', 'undef'
);

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_field_statement_text(
    'ident_16::label', 'Their Street Address'
);

$ajax = strip_build_dir( $ajax );

$expected_file = File::Spec->catfile( $ajax_dir, 'clabel' );

file_ok( $expected_file, $ajax, 'set multi-word label (clabel)' );

#--------------------------------------------------------------------
# Remove field statement
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_field_statement_text(
    'ident_16::label', 'undefined'
);

$ajax = strip_build_dir( $ajax );

$expected_file = File::Spec->catfile( $ajax_dir, 'rlabel' );

file_ok( $expected_file, $ajax, 'removed field statement (rlabel)' );

#--------------------------------------------------------------------
# Add field statement with pair values
#--------------------------------------------------------------------
# params is a routine in the Gantry engine which sets query strings.
$tent_maker->params(
    {
        values => '1][0',
        keys   => 'Happy][Unhappy',
    }
);

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_field_statement_pair(
    'ident_16::html_form_options'
);

$ajax = strip_build_dir( $ajax );

$expected_file = File::Spec->catfile( $ajax_dir, 'apair' );

file_ok( $expected_file, $ajax, 'new pair statement (apair)' );

#--------------------------------------------------------------------
# Change field statement with pair values
#--------------------------------------------------------------------
# params is an engine method which sets query string params
$tent_maker->params(
    {
        values => '1][2][0',
        keys   => 'Happy][Neutral][Unhappy',
    }
);

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_field_statement_pair(
    'ident_16::html_form_options'
);

$ajax = strip_build_dir( $ajax );

$expected_file = File::Spec->catfile( $ajax_dir, 'cpair' );

file_ok( $expected_file, $ajax, 'update pair statement (cpair)' );

#--------------------------------------------------------------------
# Remove field statement with pair values
#--------------------------------------------------------------------
$tent_maker->params(
    {
        values => '1][2][0',
        keys   => '',
    }
);

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_field_statement_pair(
    'ident_16::html_form_options'
);

$ajax = strip_build_dir( $ajax );

$expected_file = File::Spec->catfile( $ajax_dir, 'rpair' );

file_ok( $expected_file, $ajax, 'remove pair statement (rpair)' );

#--------------------------------------------------------------------
# Add a foreign key to table, change other table name
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_field_statement_text(
    'ident_16::refers_to', 'addresses'
);

$ajax = strip_build_dir( $ajax );

$expected_file = File::Spec->catfile( $ajax_dir, 'afieldtext' );

file_ok( $expected_file, $ajax, 'add refers_to statement (afieldtext)' );

#--------------------------------------------------------------------
# Change table name, check foreign key updates
#--------------------------------------------------------------------

$tent_maker->do_create_app_block( 'table::addresses' );

# ident numbering continues:
#  16 addresses table
#  17-21 its fields
#  22 controller Addresses
#  23-24 its methods

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_name( 'table::ident_17', 'new_table_name' );

$ajax = strip_build_dir( $ajax );

$expected_file = File::Spec->catfile( $ajax_dir, 'ctablename2' );

file_ok(
    $expected_file,
    $ajax,
    'refers_to updates on table name change (ctablename2)'
);

#--------------------------------------------------------------------
# Delete field.
#--------------------------------------------------------------------

my $tree = $tent_maker->get_tree;

$tent_maker->template_disable( 0 );

$tent_maker->do_update_method_statement_text(
        'ident_13::cols', 'ident][street_address][description'
);

$tent_maker->do_update_method_statement_text(
        'ident_14::all_fields_but', 'id][street_address][created][modified'
);

$tent_maker->do_update_table_statement_text(
        'ident_6::foreign_display', '%ident %street_address'
);

$ajax = $tent_maker->do_delete_block( 'ident_16' );

$ajax = strip_build_dir( $ajax );

$expected_file = File::Spec->catfile( $ajax_dir, 'rfield' );

file_ok( $expected_file, $ajax, 'remove field (rfield)' );

#--------------------------------------------------------------------
# Delete table.
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_delete_block( 'ident_6' );

$ajax = strip_build_dir( $ajax );

$expected_file = File::Spec->catfile( $ajax_dir, 'rtable' );

file_ok( $expected_file, $ajax, 'remove table (rtable)' );

#--------------------------------------------------------------------
#--------------------------------------------------------------------
# Switch to reading files and modifying them.
#--------------------------------------------------------------------
#--------------------------------------------------------------------

#--------------------------------------------------------------------
# Change table statement value on missing table.
#--------------------------------------------------------------------

my $sql_config = File::Spec->catfile( 't', 'tentmaker', 'sql.bigtop' );

Bigtop::TentMaker->take_performance_hit( $style, $sql_config );

warning_like {
    $tent_maker->do_update_table_statement_text(
        'ident_29::sequence', 'new_seq'
    )
} qr/Couldn't change table statement/,
  'attempt to change statement in missing table';

#--------------------------------------------------------------------
# Change table statement value.
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_table_statement_text(
    'ident_27::sequence', 'new_seq'
);

$ajax = strip_build_dir( $ajax );

$expected_file = File::Spec->catfile( $ajax_dir, 'scratchctst' );

file_ok(
    $expected_file,
    $ajax,
    'update table statement (scratchctst)'
);

#--------------------------------------------------------------------
# Add table statment by changing its value.
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_table_statement_text(
    'ident_27::foreign_display', '%name'
);

$ajax = strip_build_dir( $ajax );

$expected_file = File::Spec->catfile( $ajax_dir, 'scratchctst2' );

file_ok( $expected_file, $ajax, 'new table statement (scratchctst2)' );

#--------------------------------------------------------------------
# Add join_table
#--------------------------------------------------------------------

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_create_app_block( 'join_table::fox_sock' );

$ajax = strip_build_dir( $ajax );

$expected_file = File::Spec->catfile( $ajax_dir, 'scratchaj' );

file_ok( $expected_file, $ajax, 'new join table (scratchaj)' );

#--------------------------------------------------------------------
# Add join_table statment by changing its value.
#--------------------------------------------------------------------
# params is a routine in the Gantry engine which sets query strings.
$tent_maker->params(
    {
        values => 'sock',
        keys   => 'fox',
    }
);

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_join_table_statement_pair(
    'ident_28::joins'
);

$ajax = strip_build_dir( $ajax );

$expected_file = File::Spec->catfile( $ajax_dir, 'scratchajst' );

file_ok( $expected_file, $ajax, 'new join table statement (scratchajst)' );

#--------------------------------------------------------------------
# Change join_table statment value
#--------------------------------------------------------------------
# params is a routine in the Gantry engine which sets query strings.
$tent_maker->params(
    {
        values => 'stocking',
        keys   => 'fox',
    }
);

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_join_table_statement_pair(
    'ident_28::joins'
);

$ajax = strip_build_dir( $ajax );

$expected_file = File::Spec->catfile( $ajax_dir, 'scratchcjst' );

file_ok(
    $expected_file,
    $ajax,
    'change join table statement (scratchcjst)'
);

#--------------------------------------------------------------------
# Check app_block_hash
#--------------------------------------------------------------------

my $expected_blocks  = [
    {
        body => undef,
        name => 'address_seq',
        type => 'sequence',
        ident => 'ident_26',
    },
    {
        body => {
            statements => {
                sequence => bless ( [ 'new_seq' ], 'arg_list' ),
                foreign_display => bless ( [ '%name' ], 'arg_list' ),
            },
            fields => [],
        },
        name => 'address',
        type => 'table',
        ident => 'ident_27',
    },
    {
        body => {
            statements => {
                joins => bless ( [ { 'fox' => 'stocking' } ], 'arg_list' ),
            },
        },
        name => 'fox_sock',
        type => 'join_table',
        ident => 'ident_28',
    },
];

my $app_blocks = $tent_maker->get_tree()->get_app_blocks();

is_deeply( $app_blocks, $expected_blocks, 'app blocks join_table' );

#--------------------------------------------------------------------
# Remove join_table statment by giving it blank keys.
#--------------------------------------------------------------------
# params is a routine in the Gantry engine which sets query strings.
$tent_maker->params(
    {
        values => '',
        keys   => '',
    }
);

$tent_maker->template_disable( 0 );

$ajax = $tent_maker->do_update_join_table_statement_pair(
    'ident_28::joins'
);

$ajax = strip_build_dir( $ajax );

$expected_file = File::Spec->catfile( $ajax_dir, 'scratchrjst' );

file_ok(
    $expected_file,
    $ajax,
    'remove join table statement (scratchrjst)'
);

#use Data::Dumper; warn Dumper( $tent_maker->get_tree() );
#exit;

