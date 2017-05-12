use strict;

use Test::More tests => 1;
use Test::Files;
use File::Spec;
use File::Find;

use Bigtop::Parser qw/Model=GantryCDBI Control=Gantry/;

my $play_dir = File::Spec->catdir( qw( t cdbi play ) );
my $ship_dir = File::Spec->catdir( qw( t cdbi playship ) );
my $add_loc  = '$$site{exoticlocation}/strangely_named_add';
my $edit_loc = '$$site{exlocation}/editor';

mkdir $play_dir;

my $bigtop_string = <<"EO_Bigtop_File";
config {
    base_dir        `$play_dir`;
    engine          MP20;
    template_engine TT;
    app_dir         ``;
    SQL             Postgres { }
    Model           GantryCDBI { }
}
app Apps::Checkbook {
    config {
        DB     app_db;
        DBName someone;
    }
    sequence payee_seq {}
    sequence trans_seq {}
    table payee {
        field id   { is int4, primary_key, assign_by_sequence; }
        field first_name {
            is                     varchar;
            label                  `First Name`;
            html_form_type         text;
            html_form_display_size 20;
        }
        field last_name {
            is                     varchar;
            label                  `Last Name`;
            html_form_type         text;
            html_form_display_size 20;
        }
        field confuses_cdbi {
            is int4;
            not_for Model;
        }
        sequence        payee_seq;
        foreign_display `%last_name, %first_name`;
    }
    table no_model {
        not_for Model;
        field id        { is int4, primary_key, auto; }
        field something { is varchar; }
    }
    table auth_db_user {
        model_base_class Gantry::Utils::AuthCDBI;
        field id        { is int4, primary_key, auto; }
        field something { is varchar; }
    }
    table trans {
        field id { is int4, primary_key, assign_by_sequence; }
        field status {
            is                     int4; 
            label                  Status;
            refers_to              status;
            html_form_type         text;
            html_form_display_size 2;
        }
        field trans_date {
            is                     date;
            label                  `Trans Date`;
            html_form_type         text;
            html_form_display_size 10;
            date_select_text       Select;
        }
        field amount {
            is                     int4; 
            label                  Amount;
            html_form_type         text;
            html_form_display_size 10;
        }
        field payee_payor {
            is                     int4; 
            refers_to              payee;
            label                  `Paid To/Rec\\'v\\'d From`;
            html_form_type         select;
        }
        field descr {
            is                     varchar;
            label                  Descr;
            html_form_type         textarea;
            html_form_rows         3;
            html_form_cols         60;
            html_form_optional     1;
            non_essential          1;
        }
        foreign_display `%id`;
        sequence        trans_seq;
        field foreigner {
            is int4;
            refers_to `sch.name`;
            html_form_type select;
        }
    }
    controller PayeeOr {
        uses            Gantry::Plugins::AutoCRUD;
        controls_table  payee;
        method do_main is main_listing {
            title             Payees;
            cols              name;
            header_options    Add => `$add_loc`;
            row_options       Edit, Delete;
        }
        method form is AutoCRUD_form {
            form_name         payee;
            fields            name;
        }
    }
    controller Trans {
        uses            Gantry::Plugins::AutoCRUD;
        controls_table  trans;
        method do_main is main_listing {
            title             Transactions;
            cols              status, trans_date, amount, payee_payor;
            header_options    Add;
            row_options       Edit, Delete;
        }
        method form is AutoCRUD_form {
            form_name         trans;
            fields            status, trans_date, amount, payee_payor, descr;
        }
    }
    sequence sch.name_seq {}
    table sch.name {
        sequence `sch.name_seq`;
        field id { is int4, primary_key, auto; }
        field name { is varchar; label Name; html_form_type text; }
        field number { is varchar; label Name; html_form_type text; }
    }
}
EO_Bigtop_File

# Add this to status field of trans table:
#            validate_with          `R|O|C`;
# Add this to amount field of trans table:
#            to_db_filter           strip_decimal_point;
#            from_db_filter         insert_decimal_point;
# strip_decimal_point and insert_decimal_point would be functions in the
# data model class.

Bigtop::Parser->gen_from_string(
    {
        bigtop_string => $bigtop_string,
        create        => 1,
        build_list    => [ 'Model' ],
    }
);

compare_dirs_ok( $play_dir, $ship_dir, 'CDBI models' );

use lib 't';
use Purge;

Purge::real_purge_dir( $play_dir );
