use strict;
use warnings;

use Test::More tests => 4;
use Test::Files;
use Test::Warn;
use File::Spec;
use File::Find;
use Cwd;

use lib 't';

use Bigtop::Parser qw/SQL=Postgres Control=Gantry/;
use Purge;  # exports real_purge_dir and strip_copyright;

my $play_dir   = File::Spec->catdir( qw( t gantry play ) );
my $ship_dir   = File::Spec->catdir( qw( t gantry playship ) );
my $ship_dir_2 = File::Spec->catdir( qw( t gantry playship2 ) );
my $base_module= File::Spec->catfile(
    qw( t gantry play Apps-Checkbook lib Apps Checkbook.pm )
);
my $gen_base_module= File::Spec->catfile(
    qw( t gantry play Apps-Checkbook lib Apps GENCheckbook.pm )
);
my $add_loc    = '$self->exoticlocation() . "/strangely_named_add"';
my $edit_loc   = '$$self{exlocation}/editor';
my $email      = 'somebody@example.com';

Purge::real_purge_dir( $play_dir );
mkdir $play_dir;

SKIP: {

    eval { require Gantry::Plugins::AutoCRUD; };
    my $skip_all = ( $@ ) ? 1 : 0;

    skip "Gantry::Plugins::AutoCRUD not installed", 4 if $skip_all;

#------------------------------------------------------------------------
# Comprehensive test of controller generation for Gantry
#------------------------------------------------------------------------

my $bigtop_string = <<"EO_Bigtop_File";
config {
    base_dir        `$play_dir`;
    engine          MP20;
    plugins         PluginQ;
    template_engine TT;
    Control         Gantry   { full_use 1; }
    SQL             Postgres { no_gen 1; }
    HttpdConf       Gantry   { }
    SiteLook        GantryDefault   { }
}
app Apps::Checkbook {
    authors          `Somebody Somewhere` => `$email`,
                     `Somebody Else`;
    copyright_holder `Somebody Somewhere`;
    license_text     `All rights reserved.`;
    config {
        DB     app_db => no_accessor;
        DBName someone;
    }
    controller is base_controller {
        method do_main is base_links {
            title `Checkbook App`;
        }
        method site_links is links {
        }
        location `/site`;
        skip_test 1;
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
            html_form_raw_html     `<tr><td colspan="2">Hi</td></tr>`;
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
            html_form_constraint   `qr{^1|0\$}`;
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
        field sch_tbl {
            is             int4;
            refers_to      `sch.tbl`;
            html_form_type select;
        }
    }
    controller PayeeOr is CRUD {
        uses              SomePackage::SomeModule, ExportingModule;
        rel_location      payee;
        text_description `Payee/Payor`;
        page_link_label  `Payee/Payor`;
        config {
            importance 1;
        }
        method do_main is main_listing {
            title             Payees;
            cols              name;
            header_options    Add => `$add_loc`;
            row_options
                Tasks => `"/lineitem/main/\$id"`, Edit, `Make Some`, Delete;
            row_option_perms Tasks => update;
        }
        controls_table    payee;
        method my_crud_form is CRUD_form {
            form_name         payee_crud;
            fields            name;
        }
        method _form is CRUD_form {
            form_name default_form;
            fields    name;
        }
        method form is AutoCRUD_form {
            form_name         payee;
            fields            name;
            extra_keys
                legend => `\$self->path_info =~ /edit/i ? 'Edit' : 'Add'`;
        }
        method do_members is stub {}
        method do_nothing is stub {
            no_gen 1;
        }
    }
    controller Trans is AutoCRUD {
        uses             SomePackage::SomeModule => `qw( a_method \$b_scalar )`,
                         SomePackage::OtherModule => ``;
        controls_table   trans;
        text_description Transactions;
        location         `/foreign/location`;
        page_link_label  Transactions;
        config {
            trivia 1 => no_accessor;
        }
        method do_detail is stub {
            extra_args   `\$id`;
        }
        method do_main is main_listing {
            title             Transactions;
            cols              status, cleared, trans_date, amount, payee_payor;
            col_labels        `Status 3`,
                              Cleared,
                              Date => `\$site->location() . '/date_order'`;
            header_options    Add;
            row_options       Edit, Delete;
            order_by          `trans_date DESC`;
            where_terms       cleared => `'t'`, amount => `{ '>', 0 }`;
        }
        method form is AutoCRUD_form {
            all_fields_but    id;
            extra_keys
                legend     => `\$self->path_info =~ /edit/i ? 'Edit' : 'Add'`,
                javascript => `\$self->calendar_month_js( 'trans' )`,
                extraneous => `'uninteresting'`;
        }
    }
    controller Trans::Action is AutoCRUD {
        plugins PluginA;
        controls_table trans;
        rel_location   transaction;
        method form is AutoCRUD_form {
            form_name trans;
            fields    status;
        }
        method controller_config is hashref {
            permissions `crudcr-d-r--`;
        }
    }
    controller NoOp { rel_location none; skip_test 1; plugins PluginB; }
    table sch.tbl {
        field id { is int4, primary_key, auto; }
        field name { is varchar; }
    }
    controller SchTbl is AutoCRUD {
        controls_table `sch.tbl`;
        rel_location   sch_tbl;
        method form is AutoCRUD_form {
            fields    name;
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

warning_like {
    Bigtop::Parser->gen_from_string(
        {
            bigtop_string => $bigtop_string,
            create        => 'create',
            build_list    => [ 'Control', ],
        }
    );
} qr/^form methods should have/, '_form CRUD form name warning';

compare_dirs_filter_ok(
        $play_dir, $ship_dir, \&strip_copyright, 'gantry controls'
);

#------------------------------------------------------------------------
# Regen test - not in create mode
#------------------------------------------------------------------------

my $new_bigtop = <<"EO_Second_Bigtop";
config {
    engine          MP20;
    template_engine TT;
    Control         Gantry { }
}
app Apps::Checkbook {
    authors `Somebody Somewhere` => `somebody\@example.com`;
    sequence payee_seq {}
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
    controller PayeeOr {
        controls_table    payee;
        text_description `Payee/Payor`;
        rel_location      payee;
        method do_main is main_listing {
            title             Payees;
            cols              name;
            header_options    Add;
            row_options       Edit, Delete;
        }
        method form is AutoCRUD_form {
            form_name         payee;
            fields            name;
            extra_keys
                legend => `\$self->path_info =~ /edit/i ? 'Edit' : 'Add'`;
        }
        method do_members is stub {}
    }
}
EO_Second_Bigtop

my $old_cwd = cwd();

my $building_dir = File::Spec->catdir( $play_dir, 'Apps-Checkbook' );

chdir $building_dir;

Bigtop::Parser->gen_from_string(
    {
        bigtop_string => $new_bigtop,
        create        => 0,
        build_list    => [ 'Control', ],
    }
);

chdir $old_cwd;

compare_dirs_filter_ok(
        $play_dir, $ship_dir_2, \&strip_copyright, 'gantry controls - regen'
);

# Note that the regen did not overwrite the stub for PayeeOr, even though
# the bigtop input was different.  Once a stub is written, it is not
# overwritten.

Purge::real_purge_dir( $play_dir );

#------------------------------------------------------------------------
# Rerun of Comprehensive test (1 above) without full gantry use
#------------------------------------------------------------------------

$bigtop_string = <<"EO_No_Full_Use";
config {
    base_dir        `$play_dir`;
    engine          MP20;
    template_engine TT;
    Control         Gantry { full_use 0; }
}
app Apps::Checkbook {
    authors          `Somebody Somewhere` => `$email`;
    copyright_holder `Somebody SomewhereElse`;
    license_text     `All rights reserved.`;
    uses              Some::Module, Some::Other::Module;
    config {
        DB     app_db  => no_accessor;
        DBName someone => no_accessor;
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
            html_form_constraint   `qr{^1|0\$}`;
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
    controller PayeeOr is CRUD {
        uses              SomePackage::SomeModule, ExportingModule;
        controls_table    payee;
        text_description `Payee/Payor`;
        config {
            importance 1;
        }
        method do_main is main_listing {
            title             Payees;
            cols              name;
            header_options    Add => `$add_loc`;
            row_options       Edit, Delete;
        }
        method my_crud_form is CRUD_form {
            form_name         payee_crud;
            fields            name;
        }
        method form is AutoCRUD_form {
            form_name         payee;
            fields            name;
            extra_keys
                legend => `\$self->path_info =~ /edit/i ? 'Edit' : 'Add'`;
        }
        method do_members is stub {}
        method do_nothing is stub {
            no_gen 1;
        }
    }
    controller Trans is AutoCRUD {
        uses             SomePackage::SomeModule => `qw( a_method \$b_scalar )`,
                         SomePackage::OtherModule => ``;
        controls_table   trans;
        text_description Transactions;
        config {
            trivia 1 => no_accessor;
        }
        method do_detail is stub {
            extra_args   `\$id`;
        }
        method do_main is main_listing {
            title             Transactions;
            cols              status, trans_date, amount, payee_payor;
            col_labels        `Status 3`,
                              Date => `\$site->location() . '/date_order'`;
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
    controller Trans::Action is AutoCRUD {
        controls_table trans;
        method form is AutoCRUD_form {
            form_name trans;
            fields    status;
        }
    }
    controller NoOp { }
}
EO_No_Full_Use

mkdir $play_dir;

Bigtop::Parser->gen_from_string(
    {
        bigtop_string => $bigtop_string,
        create        => 1,
        build_list    => [ 'Control', ],
    }
);

my $correct = <<'EO_Correct_Simple_Use';
# NEVER EDIT this file.  It was generated and will be overwritten without
# notice upon regeneration of this application.  You have been warned.
package Apps::GENCheckbook;

use strict;
use warnings;

use Gantry qw{ -TemplateEngine=TT };

use JSON;
use Gantry::Utils::TablePerms;

our @ISA = qw( Gantry );

use Some::Module;
use Some::Other::Module;


#-----------------------------------------------------------------
# $self->namespace() or Apps::Checkbook->namespace()
#-----------------------------------------------------------------
sub namespace {
    return 'Apps::Checkbook';
}

##-----------------------------------------------------------------
## $self->init( $r )
##-----------------------------------------------------------------
#sub init {
#    my ( $self, $r ) = @_;
#
#    # process SUPER's init code
#    $self->SUPER::init( $r );
#
#} # END init


#-----------------------------------------------------------------
# $self->do_main( )
#-----------------------------------------------------------------
sub do_main {
    my ( $self ) = @_;

    $self->stash->view->template( 'main.tt' );
    $self->stash->view->title( 'Checkbook' );

    $self->stash->view->data( { pages => $self->site_links() } );
} # END do_main

#-----------------------------------------------------------------
# $self->site_links( )
#-----------------------------------------------------------------
sub site_links {
    my $self = shift;

    return [
    ];
} # END site_links

1;

=head1 NAME

Apps::GENCheckbook - generated support module for Apps::Checkbook

=head1 SYNOPSIS

In Apps::Checkbook:

    use base 'Apps::GENCheckbook';

=head1 DESCRIPTION

This module was generated by Bigtop (and IS subject to regeneration) to
provide methods in support of the whole Apps::Checkbook
application.

Apps::Checkbook should inherit from this module.

=head1 METHODS

=over 4

=item namespace

=item init

=item do_main

=item site_links


=back

=head1 AUTHOR

Somebody Somewhere, E<lt>somebody@example.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright  Somebody SomewhereElse

All rights reserved.

=cut

EO_Correct_Simple_Use

file_filter_ok(
    $gen_base_module,
    $correct,
    \&strip_copyright,
    'controller with simple use Gantry statement'
);

Purge::real_purge_dir( $play_dir );

} # END of SKIP block
