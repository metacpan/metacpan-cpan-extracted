use strict;

use Test::More tests => 2;
use Test::Files;
use File::Spec;

use lib 't';
use Purge;

my $skip_all = 0;

BEGIN {
    eval { require Gantry; };
    $skip_all = ( $@ ) ? 1 : 0;

    SKIP: {
        skip "tentmaker requires Gantry", 2 if $skip_all;
    }
    exit 0 if $skip_all;
}

use Bigtop::TentMaker qw/ -Engine=CGI -TemplateEngine=Default /;
use Bigtop::ScriptHelp::Style;

$ENV{ BIGTOP_REAL_DEF } = 1;

my $style = Bigtop::ScriptHelp::Style->get_style();

Bigtop::TentMaker->take_performance_hit( $style, undef, 'family', 'Address' );

my $tent_maker = Bigtop::TentMaker->new();

my @maker_deparse;
my @correct_input;

#--------------------------------------------------------------------
# Sanity Check
#--------------------------------------------------------------------

@correct_input = split /\n/, <<'EO_sanity';
config {
    engine MP20;
    template_engine TT;
    Init Std {  }
    Conf Gantry { conffile `docs/app.gantry.conf`; instance address; }
    HttpdConf Gantry { gantry_conf 1; }
    SQL SQLite {  }
    SQL Postgres {  }
    SQL MySQL {  }
    CGI Gantry { with_server 1; flex_db 1; gantry_conf 1; }
    Control Gantry { dbix 1; }
    Model GantryDBIxClass {  }
    SiteLook GantryDefault {  }
}
app Address {
    config {
        dbconn `dbi:SQLite:dbname=app.db` => no_accessor;
        template_wrapper `genwrapper.tt` => no_accessor;
        doc_rootp `/static` => no_accessor;
        show_dev_navigation 1 => no_accessor;
    }
    config CGI {
        dbconn `dbi:SQLite:dbname=app.db` => no_accessor;
        app_rootp `/cgi-bin/address.cgi` => no_accessor;
    }
    controller is base_controller {
        method do_main is base_links {
        }
        method site_links is links {
        }
    }
    table family {
        field id {
            is int4, primary_key, auto;
        }
        field ident {
            is varchar;
            label Ident;
            html_form_type text;
        }
        field description {
            is varchar;
            label Description;
            html_form_type text;
        }
        field created {
            is datetime;
        }
        field modified {
            is datetime;
        }
        foreign_display `%ident`;
    }
    controller Family is AutoCRUD {
        controls_table family;
        rel_location family;
        text_description family;
        page_link_label Family;
        method do_main is main_listing {
            cols ident, description;
            header_options Add;
            row_options Edit, Delete;
            title Family;
        }
        method form is AutoCRUD_form {
            all_fields_but id, created, modified;
            extra_keys
                legend => `$self->path_info =~ /edit/i ? q!Edit! : q!Add!`;
        }
    }
}
EO_sanity

my $deparsed   = strip_build_dir( $tent_maker->deparsed() );
@maker_deparse = split /\n/, $deparsed;

is_deeply( \@maker_deparse, \@correct_input, 'one table sanity check' );

#--------------------------------------------------------------------
# Change description's type to date -- see the magic
#--------------------------------------------------------------------

# There are variation tests commented out.  I'll add real ones for them
# if they prove problematic.  The ones in current use work the harder
# option in each case.

#$tent_maker->do_update_field_statement_text(
#    'ident_6::date_select_text', 'Set Date'
#);

$tent_maker->do_update_controller_statement_text(
    'ident_12::uses', 'Missing][Module'
);

#$tent_maker->do_update_method_statement_text(
#    'ident_11::form_name', 'family_form'
#);

my $ajax = $tent_maker->do_update_field_statement_text(
    'ident_9::is', 'date'
);

$ajax = strip_build_dir( $ajax );

my $expected_file = File::Spec->catfile( qw( t tentmaker ajax_07 todate ) );

file_filter_ok(
    $expected_file,
    $ajax,
    \&strip_build_dir,
    'field is changed to date (todate)'
);

