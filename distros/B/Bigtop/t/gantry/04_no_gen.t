use strict;

use Test::More tests => 3;
use Test::Warn;
use Test::Files;
use File::Spec;
use File::Find;

use lib 't';
use Purge;

#---------------------------------------------------------------------
# Similar to t/gantry/02_controllers, but with no_gen on the PayeeOr
#---------------------------------------------------------------------

use Bigtop::Parser qw/SQL=Postgres Control=Gantry/;

my $play_dir = File::Spec->catdir( qw( t gantry play ) );
my $ship_dir = File::Spec->catdir( qw( t gantry playship ) );
my $add_loc  = '$self->exoticlocation() . "/strangely_named_add"';
my $edit_loc = '$$self{exlocation}/editor';
my $email    = 'somebody@example.com';

Purge::real_purge_dir( $play_dir );
mkdir $play_dir;

my $bigtop_string = <<"EO_Bigtop_File";
config {
    base_dir        `$play_dir`;
    engine          MP20;
    template_engine TT;
    Control         Gantry { }
}
app Apps::Checkbook {
    authors   `Somebody Somewhere` => `$email`;
    config {
        DB     app_db => no_accessor;
        DBName someone;
    }
    sequence payee_seq {}
    sequence trans_seq {}
    table payee {
        sequence payee_seq;
        field id   { is int, primary_key, assign_by_sequence; }
        field name {
            is                     varchar;
            label                  Name;
            html_form_type         text;
            html_form_display_size 20;
        }
    }
    table trans {
        sequence trans_seq;
        field id { is int, primary_key, assign_by_sequence; }
        field status {
            is                     int; 
            label                  `Status2`;
            html_form_type         text;
            html_form_display_size 2;
        }
        field cleared {
            is                     boolean;
            label                  Cleared;
            html_form_type         select;
            html_form_options      Yes => 1, No => 0;
        }
        field trans_date {
            is                     date;
            label                  `Trans Date`;
            html_form_type         text;
            html_form_display_size 10;
            date_select_text       Select;
        }
        field amount {
            is                     int; 
            label                  Amount;
            html_form_type         text;
            html_form_display_size 10;
        }
        field payee_payor {
            is                     int; 
            refers_to              payee;
            label                  `Paid To/Rec'v'd From`;
            html_form_type         select;
        }
        field descr {
            is                     varchar;
            label                  Descr;
            html_form_type         textarea;
            html_form_rows         3;
            html_form_cols         60;
            html_form_optional     1;
        }
    }
    controller PayeeOr {
        no_gen            1;
        uses              SomePackage::SomeModule, Test::More;
        controls_table    payee;
        text_description `Payee/Payor`;
        method do_main is main_listing {
            title             Payees;
            cols              name;
            header_options    Add => `$add_loc`;
            row_options       Edit, Delete;
        }
        method form is AutoCRUD_form {
            form_name         payee;
            fields            name;
            extra_keys
                legend => `\$self->path_info =~ /edit/i ? 'Edit' : 'Add'`;
        }
    }
    controller Trans {
        uses             SomePackage::SomeModule;
        controls_table   trans;
        text_description Transactions;
        method do_main is main_listing {
            title             Transactions;
            cols              status, trans_date, amount, payee_payor;
            header_options    Add;
            row_options       Edit, Delete;
        }
        method form is AutoCRUD_form {
            form_name         trans;
            all_fields_but    id;
            extra_keys
                legend     => `\$self->path_info =~ /edit/i ? 'Edit' : 'Add'`,
                javascript => `\$self->calendar_month_js( 'trans' )`,
                extraneous => `'uninteresting'`;
        }
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
        create        => 'create',
        build_list    => [ 'Control', ],
    }
);

dir_only_contains_ok(
    $play_dir,
    [
        qw(
            Apps-Checkbook
            Apps-Checkbook/lib
            Apps-Checkbook/lib/Apps
            Apps-Checkbook/lib/Apps/Checkbook.pm
            Apps-Checkbook/lib/Apps/GENCheckbook.pm
            Apps-Checkbook/lib/Apps/Checkbook
            Apps-Checkbook/lib/Apps/Checkbook/Trans.pm
            Apps-Checkbook/lib/Apps/Checkbook/GEN
            Apps-Checkbook/lib/Apps/Checkbook/GEN/Trans.pm
            Apps-Checkbook/t
            Apps-Checkbook/t/01_use.t
            Apps-Checkbook/t/02_pod.t
            Apps-Checkbook/t/03_podcover.t
            Apps-Checkbook/t/10_run.t
        )
    ],
    'controller level no_gen honored'
);

use lib 't';
use Purge;
Purge::real_purge_dir( $play_dir );

#---------------------------------------------------------------------
# App level no_gen (should do nothing)
#---------------------------------------------------------------------
$bigtop_string = <<"EO_Another_Bigtop";
config {
    base_dir        `$play_dir`;
    engine          MP20;
    template_engine TT;
    Control         Gantry { }
}
app Apps::Checkbook {
    no_gen    1;
    authors   `Somebody Somewhere` => `$email`;
    config {
        DB     app_db => no_accessor;
        DBName someone;
    }
    sequence payee_seq {}
    sequence trans_seq {}
    table payee {
        sequence payee_seq;
        field id   { is int, primary_key, assign_by_sequence; }
        field name {
            is                     varchar;
            label                  Name;
            html_form_type         text;
            html_form_display_size 20;
        }
    }
    table trans {
        sequence trans_seq;
        field id { is int, primary_key, assign_by_sequence; }
        field status {
            is                     int; 
            label                  `Status2`;
            html_form_type         text;
            html_form_display_size 2;
        }
    }
    controller PayeeOr {
        uses              SomePackage::SomeModule, Test::More;
        controls_table    payee;
        text_description `Payee/Payor`;
        method do_main is main_listing {
            title             Payees;
            cols              name;
            header_options    Add => `$add_loc`;
            row_options       Edit, Delete;
        }
        method form is AutoCRUD_form {
            form_name         payee;
            fields            name;
            extra_keys
                legend => `\$self->path_info =~ /edit/i ? 'Edit' : 'Add'`;
        }
    }
    controller Trans {
        uses             SomePackage::SomeModule;
        controls_table   trans;
        text_description Transactions;
        method do_main is main_listing {
            title             Transactions;
            cols              status, trans_date, amount, payee_payor;
            header_options    Add;
            row_options       Edit, Delete;
        }
        method form is AutoCRUD_form {
            form_name         trans;
            all_fields_but    id;
            extra_keys
                legend     => `\$self->path_info =~ /edit/i ? 'Edit' : 'Add'`,
                javascript => `\$self->calendar_month_js( 'trans' )`,
                extraneous => `'uninteresting'`;
        }
    }
}
EO_Another_Bigtop

warning_like {
    Bigtop::Parser->gen_from_string(
        {
            bigtop_string => $bigtop_string,
            create        => 'create',
            build_list    => [ 'Control', ],
        }
    );
} qr/skipping generation/, 'warning for app level no_gen';

ok( is_missing( $play_dir ), 'app level no_gen honored' );

sub is_missing {
    my $candidate = shift;

    return ( -d $candidate ) ? 0 : 1;
}
