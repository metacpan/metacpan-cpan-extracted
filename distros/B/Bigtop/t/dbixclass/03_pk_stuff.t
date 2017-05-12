use strict;

use Test::More tests => 1;
use Test::Files;
use Test::Exception;
use File::Spec;
use File::Find;

use lib 't';
use Purge;

use Bigtop::Parser qw/Model=GantryDBIxClass Control=Gantry/;

#---------------------------------------------------------------------------
# Large scale DBIx::Class model generation test
#---------------------------------------------------------------------------

my $play_dir = File::Spec->catdir( qw( t dbixclass play ) );
my $ship_dir = File::Spec->catdir( qw( t dbixclass playpk ) );
my $edit_loc = '$$site{exlocation}/editor';

Purge::real_purge_dir( $play_dir );
mkdir $play_dir;

my $bigtop_string = <<"EO_Bigtop_File";
config {
    base_dir        `$play_dir`;
    engine          MP20;
    template_engine TT;
    app_dir         ``;
    Model           GantryDBIxClass { }
    Control         Gantry { dbix 1; full_use 1; }
    SQL             Postgres { }
    SQL             MySQL    { }
}
app Contact {
    config {
        dbconn `dbi:Pg:dbname=contact` => no_accessor;
        dbuser `apache` => no_accessor;
    }
    authors `Phil Crow` => `crow.phil\@gmail.com`;
    table number {
        field id   { is int4; }
        field name {
            is                     varchar;
            label                  `Name`;
            html_form_type         text;
        }
        field number {
            is                     varchar;
            label                  `Number`;
            html_form_type         text;
        }
        sequence        number_seq;
        foreign_display `%name`;
    }
    table bday {
        field id      { is int4, primary_key; }
        field subid   { is int4, primary_key; }
        field contact {
            is               int4;
            refers_to        number;
            html_form_type   select;
        }
        field bday    {
            is               date;
            html_form_type   text;
        }
    }
}
EO_Bigtop_File

Bigtop::Parser->gen_from_string(
    {
        bigtop_string => $bigtop_string,
        create        => 'create',
        build_list    => [ 'Control', 'Model', ],
    }
);

compare_dirs_filter_ok(
        $play_dir, $ship_dir, \&strip_copyright, 'primary key funny business'
);

Purge::real_purge_dir( $play_dir );

