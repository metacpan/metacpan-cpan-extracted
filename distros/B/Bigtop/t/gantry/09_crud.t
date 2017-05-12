use strict;

use Test::More tests => 1;
use Test::Files;

use lib 't';

use Bigtop::Parser;
use Purge;  # for real_purge_dir and strip_copyright

my $play_dir = File::Spec->catdir( qw( t gantry play ) );
my $ship_dir = File::Spec->catdir( qw( t gantry playcrud ) );

Purge::real_purge_dir( $play_dir );
mkdir $play_dir;

my $bigtop_string = <<"EO_Bigtop";
config {
    base_dir        `$play_dir`;
    engine          MP20;
    template_engine TT;
    Control         Gantry { run_test 0; }
    SQL             Postgres { }
}
app Blog {
    authors `Phil Crow` => `mail\@example.com`;
    license_text `All rights reserved.`;
    controller is base_controller {
    }
    table post {
        field id { is int4, primary_key, auto; }
        field title { is varchar; label Title; html_form_type text; }
        field body  { is varchar; label Body;  html_form_type text; }
    }
    controller Post is CRUD {
        rel_location     post;
        controls_table   post;
        text_description post;
        skip_test 1;
        method controller_config is hashref {
            permissions `crud-rudcr--`;
        }
        method post_form is CRUD_form {
            all_fields_but id;
        }
    }
}
EO_Bigtop

Bigtop::Parser->gen_from_string(
    {
        bigtop_string => $bigtop_string,
        create        => 'create',
        build_list    => [ 'Control' ],
    }
);

# test just the file of interest
my $crud_mod = 'Post.pm';
my $mod_dir  = File::Spec->catdir(  qw( Blog lib Blog ) );
my $play_mod = File::Spec->catfile( $play_dir, $mod_dir, $crud_mod );
my $ship_mod = File::Spec->catfile( $ship_dir, $mod_dir, $crud_mod );

compare_filter_ok(
        $play_mod, $ship_mod, \&strip_copyright, 'crud with perms'
);

Purge::real_purge_dir( $play_dir );
