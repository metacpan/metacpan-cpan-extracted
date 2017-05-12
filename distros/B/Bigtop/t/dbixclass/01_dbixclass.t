use strict;

use Test::More tests => 3;
use Test::Files;
use Test::Exception;
use File::Spec;
use File::Find;

use lib 't';
use Purge;

my $skip_all = 0;
BEGIN {
    eval { require Gantry; };
    $skip_all = ( $@ ) ? 1 : 0;

    SKIP: {
        skip "tentmaker requires Gantry", 3 if $skip_all;
    }
    exit 0 if $skip_all;
}

use Bigtop::Parser qw/Model=GantryDBIxClass Control=Gantry/;

#$::RD_TRACE = 1;

#---------------------------------------------------------------------------
# Large scale DBIx::Class model generation test
#---------------------------------------------------------------------------

my $play_dir = File::Spec->catdir( qw( t dbixclass play ) );
my $ship_dir = File::Spec->catdir( qw( t dbixclass playship ) );
my $edit_loc = '$$site{exlocation}/editor';

Purge::real_purge_dir( $play_dir );
mkdir $play_dir;

my $bigtop_string = <<"EO_Bigtop_File";
config {
    base_dir        `$play_dir`;
    engine          MP20;
    template_engine TT;
    app_dir         ``;
    Model           GantryDBIxClass {
        extra_components `InflateColumn::DateTime`;
    }
    Control         Gantry { dbix 1; full_use 1; }
    SQL             Postgres { }
    SQL             MySQL    { }
    SQL             SQLite   { }
}
app Contact {
    config {
        dbconn `dbi:Pg:dbname=contact` => no_accessor;
        dbuser `apache` => no_accessor;
    }
    authors `Phil Crow` => `crow.phil\@gmail.com`;
    sequence number_seq {}
    table number {
        field id   { is int4, primary_key, assign_by_sequence; }
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
        field phone_type {
            is varchar;
            label `Phone Type`;
            html_form_type select;
            html_form_options Cell => cell, Home => home;
        }
        sequence        number_seq;
        foreign_display `%name`;
        refered_to_by   bday => `birth_days`;
        refered_to_by   missing;
    }
    table bday {
        field id      { is int4, primary_key, assign_by_sequence; }
        field contact {
            is               int4;
            label            Contact;
            refers_to        number;
            html_form_type   select;
        }
        field bday    {
            is               date;
            label            `Birth Day`;
            html_form_type   text;
            accessor         bday_acc;
        }
        field anniversary {
            is             date;
            label          `Anniversary`;
            html_form_type text;
            add_columns    `data_type` => `datetime`;
        }
        field known_since {
            is date;
            add_columns data_type => datetime;
        }
    }
    table tshirt {
        field id      { is int4, primary_key, assign_by_sequence; }
        field ident   { is varchar; label Ident; html_form_type text; }
    }
    table color {
        field id      { is int4, primary_key, assign_by_sequence; }
        field ident   { is varchar; label Ident; html_form_type text; }
        field foreigner {
            is int4;
            refers_to `sch.name`;
            html_form_type select;
        }
    }
    join_table tshirt_color {
        joins tshirt => color;
    }
    join_table tshirt_author {
        joins tshirt => author;
    }
    table author {
        field id      { is int4, primary_key, assign_by_sequence; }
        field ident   { is varchar; label Ident; html_form_type text; }
    }
    table book {
        field id      { is int4, primary_key, assign_by_sequence; }
        field ident   { is varchar; label Ident; html_form_type text; }
    }
    join_table author_book {
        joins author  => book;
        names writers => books;
        field extra_field {
            is varchar;
            html_form_type select;
            html_form_options Happy => happy, Sad => sad;
        }
        field second_extra {
            is boolean;
            html_form_type select;
            html_form_options Yes => 1, No => 2;
        }
        data author => 1, book => 1, extra_field => hello;
    }
    controller Number is AutoCRUD {
        autocrud_helper  Gantry::Plugins::AutoCRUDHelper::NewHelper;
        controls_table   number;
        text_description `contact number`;
        rel_location     `number`;
        method do_main is main_listing {
            title             Contacts;
            rows              25;
            cols              name, number;
            header_options    Add, CSV;
            row_options       Edit, Delete;
        }
        method form is AutoCRUD_form {
            form_name         contact;
            all_fields_but    id;
        }
        method do_csv is stub {
            extra_args `\$id`;
        }
    }
    controller BDay is stub {
        controls_table bday;
        rel_location bday;
        method do_main is main_listing {
            title `Birth Days`;
            cols contact, bday;
            header_options Add;
            row_options Edit, Delete;
            limit_by contact;
        }
    }
    sequence sch.name_seq {}
    table sch.name {
        sequence `sch.name_seq`;
        field id   { is int4, primary_key, assign_by_sequence; }
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
    }
}
EO_Bigtop_File

Bigtop::Parser->gen_from_string(
    {
        bigtop_string => $bigtop_string,
        create        => 'create',
        build_list    => [ 'SQL', 'Control', 'Model' ],
    }
);

compare_dirs_filter_ok(
        $play_dir, $ship_dir, \&strip_copyright, 'DBIxClass models'
);

Purge::real_purge_dir( $play_dir );

#---------------------------------------------------------------------------
# multiple joins statements in a join_table block error test
#---------------------------------------------------------------------------

my $errant_string = <<"EO_Double_Joiner";
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
    table tshirt {
        field id      { is int4, primary_key, assign_by_sequence; }
        field ident   { is varchar; label Ident; html_form_type text; }
    }
    table color {
        field id      { is int4, primary_key, assign_by_sequence; }
        field ident   { is varchar; label Ident; html_form_type text; }
    }
    join_table tshirt_color {
        joins tshirt => color;
        joins author => book;
    }
    table author {
        field id      { is int4, primary_key, assign_by_sequence; }
        field ident   { is varchar; label Ident; html_form_type text; }
    }
    table book {
        field id      { is int4, primary_key, assign_by_sequence; }
        field ident   { is varchar; label Ident; html_form_type text; }
    }
    join_table author_book {
        joins author => book;
    }
}
EO_Double_Joiner

dies_ok {
    Bigtop::Parser->parse_string( $errant_string );
} "multiple joins fatal to join_table";

like(
    $@,
    qr/^join_table tshirt_color has multiple/,
    'multiple error message'
);

