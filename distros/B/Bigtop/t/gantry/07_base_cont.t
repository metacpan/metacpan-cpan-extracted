use strict;

use Test::More tests => 1;
use Test::Files;

use File::Spec;

use lib 't';
use Purge;

use Bigtop::Parser;

my $play_dir = File::Spec->catdir( qw( t gantry play ) );
my $ship_dir = File::Spec->catdir( qw( t gantry playbc ) );

Purge::real_purge_dir( $play_dir );
mkdir $play_dir;

my $bigtop_string = <<"EO_Bigtop_File";
config {
    base_dir               `$play_dir`;
    engine                 CGI;
    template_engine        TT;
    SQL     SQLite         {}
    CGI     Gantry         { gen_root 1; with_server 1; flex_db 1; }
    Control Gantry         { dbix 1; }
    SiteLook GantryDefault {}
}
app Sample {
    authors SomeOne;
    table tbl1 {
        field id    { is int4, primary_key, auto; }
        field name  { is varchar; label Name;  }
        field phone { is varchar; label Phone; }
    }
    controller is base_controller {
        method do_main is main_listing {
            cols name, phone;
            header_options Add;
            row_options Edit, Delete;
            title `Sample`;
        }
        method form is AutoCRUD_form {
            all_fields_but id;
        }
        text_description `sample row`;
        controls_table tbl1;
        gen_uses  Gantry::Plugins::NewOne;
        stub_uses Gantry::Plugins::NewTwo;
        uses      Missing::Module;
        page_link_label `Simple Sample Label`;
    }
}
EO_Bigtop_File

Bigtop::Parser->gen_from_string(
    {
        bigtop_string => $bigtop_string,
        create        => 'create',
        build_list    => [ 'Control' ],
    }
);

compare_dirs_filter_ok(
        $play_dir, $ship_dir, \&strip_copyright, 'one controller app'
);

Purge::real_purge_dir( $play_dir );
