
# Brenton Chapin
use 5.6.0;

package DBIx::Perform;

use strict;
use warnings;
use POSIX;
use Carp;
use Curses;    # to get KEY_*
use DBIx::Perform::DButils;
use DBIx::Perform::UserInterface;
use DBIx::Perform::SimpleList;
use DBIx::Perform::Instruct;
use base 'Exporter';
use Data::Dumper;

our $VERSION = '0.695';

use constant 'KEY_DEL' => '330';

use vars qw(@EXPORT_OK $DB $STH $STHDONE $MASTER_STH $MASTER_STHDONE );

@EXPORT_OK = qw(run);

# debug: set (unset) in runtime env
$::TRACE      = $ENV{TRACE};
$::TRACE_DATA = $ENV{TRACE_DATA};

our $GlobalUi   = new DBIx::Perform::UserInterface;
#our $MasterList = new DBIx::Perform::SimpleList;

#our $RowList	= new DBIx::Perform::SimpleList;
our $RowList = undef;
our $DB;

our $extern_name;    #name of executable with external C functions

#FIX this is off with respect to UserInterface
our %INSERT_RECALL = (
    Pg       => \&Pg_refetch,
    Informix => \&Informix_refetch,
    Oracle   => \&Oracle_refetch,
);

our %Tag_screens = ();

# 	--- runtime subs ---

sub run {
    my $fname = shift;
    $extern_name = shift;

    # can't vouch for any other than yml
    my $file_hash = $GlobalUi->parse_yml_file($fname);    # xml file
         #my $file_hash	= $GlobalUi->parse_xml_file ($fname);  # xml file
         #my $file_hash	= $GlobalUi->parse_per_file ($fname);  # per file

    $DB = DBIx::Perform::DButils::open_db( $file_hash->{'db'} );

    register_button_handlers();

    $RowList = $GlobalUi->get_current_rowlist;

    $GlobalUi->run;
}

sub register_button_handlers {

    # register the button handlers
    $GlobalUi->register_button_handler( 'query',    \&querymode );
    $GlobalUi->register_button_handler( 'next',     \&do_next );
    $GlobalUi->register_button_handler( 'previous', \&do_previous );
    $GlobalUi->register_button_handler( 'view',     \&do_view );
    $GlobalUi->register_button_handler( 'add',      \&addmode );
    $GlobalUi->register_button_handler( 'update',   \&updatemode );
    $GlobalUi->register_button_handler( 'remove',   \&removemode );
    $GlobalUi->register_button_handler( 'table',    \&do_table );
    $GlobalUi->register_button_handler( 'screen',   \&do_screen );
    $GlobalUi->register_button_handler( 'current',  \&do_current );
    $GlobalUi->register_button_handler( 'master',   \&do_master );
    $GlobalUi->register_button_handler( 'detail',   \&do_detail );
    $GlobalUi->register_button_handler( 'output',   \&do_output );
    $GlobalUi->register_button_handler( 'no',       \&do_no );
    $GlobalUi->register_button_handler( 'yes',      \&do_yes );
    $GlobalUi->register_button_handler( 'exit',     \&doquit );
}

sub clear_textfields {

    warn "TRACE: entering clear_textfields\n" if $::TRACE;

    my $fl = $GlobalUi->get_field_list;

#    my $app = $GlobalUi->{app_object};

    $fl->reset;
    while ( my $fo = $fl->iterate_list ) {
        my $tag = $fo->get_field_tag;
        $fo->set_value('');
        $GlobalUi->set_screen_value( $tag, '' );

#        my $scrns = get_screen_from_tag($ft);
#        foreach my $scrn (@$scrns) {
#	    my $form = $GlobalUi->get_current_form;
#            my $subform = $form->getSubform('DBForm');
#            $subform->getWidget($ft)->setField( 'VALUE', '' );
#        }

    }
    warn "TRACE: leaving clear_textfields\n" if $::TRACE;
}

sub clear_table_textfields {
    my $mode = shift;

    warn "TRACE: entering clear_textfields\n" if $::TRACE;

    my $fl = $GlobalUi->get_field_list;
    my $cur_tab = $GlobalUi->get_current_table_name;
    my $app = $GlobalUi->{app_object};
    my $joins_by_tag = $app->{joins_by_tag};

    return if $mode eq 'update';

    $fl->reset;
    while ( my $fo = $fl->iterate_list ) {
        my ( $tag, $table, $col ) = $fo->get_names;
	if ( $cur_tab eq $table ) {

	    next if ! $fo->allows_focus( $mode );

	    next if $mode eq 'query'				
	      && !defined $fo->{queryclear}
              && $joins_by_tag->{$tag};

            next if $mode eq 'add'
              && $joins_by_tag->{$tag};

	    $fo->set_value('');
	    $GlobalUi->set_screen_value( $tag, '' );
	}
    }
    warn "TRACE: leaving clear_textfields\n" if $::TRACE;
}

#Clears the fields belonging to the detail table and not the master.
#Don't use "queryclear" attribute here.  Believe this is supposed to work
#as if queryclear is false for all the fields.
sub clear_detail_textfields {
    my $mastertbl = shift;
    my $detailtbl = shift;
    my $app = $GlobalUi->{app_object};
    my $joins_by_tag = $app->{joins_by_tag};
    my $fl = $GlobalUi->get_field_list;
    my %master;

    $fl->reset;
    while ( my $fo = $fl->iterate_list ) {
        my ( $tag, $table, $col ) = $fo->get_names;
        if ($joins_by_tag->{$tag}) {
            $master{$tag} = 1 if $table eq $mastertbl;
#            $detail{$tag} = 1 if $table eq $detailtbl;
        }       
    }
    
    $fl->reset;
    while ( my $fo = $fl->iterate_list ) {
        my ( $tag, $table, $col ) = $fo->get_names;
        if ($table eq $detailtbl && !$master{$tag}) {
	    $fo->set_value('');
	    $GlobalUi->set_screen_value( $tag, '' );
        } else {
	    my $val = $GlobalUi->get_screen_value( $tag );
	    $fo->set_value($val);
        }
    }
}


# If there are no rows, it sets DONTSWITCH and statusbars a message.
#  Returns true if no rows.
# Added check for "deletedrow", which is true if the user has deleted
# the current row.
sub check_rows_and_advise {
    my $form = shift;
    my $app  = $GlobalUi->{app_object};

    if ($app->{deletedrow}) {
        $GlobalUi->display_error('th47w');
        $form->setField( 'DONTSWITCH', 1 );
        return 1;
    }
    if ( $RowList->is_empty ) {
        my $m = $GlobalUi->{error_messages}->{'th15.'};
        $GlobalUi->display_error($m);
        $form->setField( 'DONTSWITCH', 1 );
        return 1;
    }
    if (my $row_status = refresh_row(1, 1)) {
        if ($row_status == 2) {
            $GlobalUi->display_error('so35.');
        } else {
            $GlobalUi->display_error('so34.');
        }
        return 1;
    }
    return undef;
}

sub goto_screen {
    my $dest_screen = shift;
    my $app         = $GlobalUi->{app_object};

    my $fn = $app->getField('form_name');
    return 0 if ( $fn eq $dest_screen );

    #save status of source form
    my $form   = $app->getForm($fn);
    my $wid    = $form->getWidget('ModeButtons');
    my $button = $wid->getField('VALUE');
    $wid = $form->getWidget('InfoMsg');
    my $info_msg = $wid->getField('VALUE');
    $wid = $form->getWidget('ModeName');
    my $name = $wid->getField('VALUE');
    $wid = $form->getWidget('ModeLabel');
    my $label = $wid->getField('VALUE');
    my $focus = $form->getField('FOCUSED');

    $form->setField( 'EXIT',     1 );
    $app->setField( 'form_name', $dest_screen );
    warn "goto_screen: button = :$button:\n" if $::TRACE;

    #copy saved status into destination form
    $form = $app->getForm($dest_screen);
    $GlobalUi->{form_object} = $form;
    $wid = $form->getWidget('ModeButtons');
    $wid->setField( 'VALUE', $button );
    $wid = $form->getWidget('InfoMsg');
    $wid->setField( 'VALUE', $info_msg );
    $wid = $form->getWidget('ModeName');
    $wid->setField( 'VALUE', $name );
    $wid = $form->getWidget('ModeLabel');
    $wid->setField( 'X',        length $name );
    $wid->setField( 'VALUE',    $label );
    $wid->setField( 'COLUMNS',  length $label );
    $form->setField( 'FOCUSED', $focus );
    my $tbln = $GlobalUi->{current_table_number};
    $GlobalUi->update_table($tbln);

    $GlobalUi->clear_display_error;
    return 1;
}

sub goto_screen1 {
    my $rv = goto_screen('Run0');

    return $rv;
}

sub next_screen {
    my $app = $GlobalUi->{app_object};

    my ( $cf, $cfa );
    $cf  = $app->getField('form_name');
    $cfa = $app->getField('form_names');
    my ($cfn) = $cf =~ /^Run(\d+)/;
    $cfn++;
    $cfn = 0 if ( $cfn >= @$cfa );
    $cf = "Run$cfn";
    return goto_screen($cf);
}

sub do_screen {
    my $app = $GlobalUi->{app_object};

#    $GlobalUi->clear_comment_and_error_display;
    $GlobalUi->clear_display_comment;

    my $cf   = $app->getField('form_name');
    my $form = $app->getForm($cf);
#    $GlobalUi->update_info_message( $form, 'screen' );
    next_screen();

    $GlobalUi->clear_display_error;
    $cf   = $app->getField('form_name');
    $form = $app->getForm($cf);
    my $row = $RowList->current_row;
    display_row( $form, $row );
    $GlobalUi->set_field_bounds_on_screen;
    $form->setField( 'DONTSWITCH', 1 );
}

sub do_current {
    refresh_row();
}

sub refresh_row {
    my $suppress_msg  = shift;
    my $test_only     = shift;
    my $driver        = $DB->{'Driver'}->{'Name'};
    my $form          = $GlobalUi->{form_object};
    my $current_table = $GlobalUi->get_current_table_name;
    my $row;
    my $sth;
#    $GlobalUi->update_info_message( $form, 'current' );
    $form->setField( 'DONTSWITCH', 1 );

    my $refetcher = $INSERT_RECALL{$driver} || \&Default_refetch;
    if ( defined($refetcher) ) {
        $row =
          &$refetcher( $sth, $current_table, (), ());
    }
    my $changed = 0;
    if ( defined($row) ) {
        my $cur_row = $RowList->current_row;
        for (my $idx = $#$row; $idx >= 0; $idx--) {
            my $valdb = $row->[$idx];
            next if !defined $valdb; #skip if not in current table
            my $valmem = $cur_row->[$idx];
            next if !defined $valmem;
            if ($valdb ne $valmem) {
                $cur_row->[$idx] = $row->[$idx] if !$test_only;
#warn "diff on $idx\n";
#warn "$valdb:\n";
#warn "$valmem:\n";
                $changed = 1;
            }
        }
        return $changed if $test_only;
        if ($changed) {
            my $subform = $form->getSubform('DBForm') || $form;
            display_row( $subform, $cur_row );
            unless ($suppress_msg) {
                my $msg = $GlobalUi->{error_messages}->{'ro54.'};
                $GlobalUi->display_status($msg);
            }
        } else {
            unless ($suppress_msg) {
                $GlobalUi->clear_display_error;
            }
        }
    } else {
        $changed = 2;
    }
    return $changed;
}



# unsupported buttons

sub do_view {
    my $form = $GlobalUi->{form_object};
    $form->setField( 'DONTSWITCH', 1 );
    my $m = $GlobalUi->{error_messages}->{'th26d'};
    $GlobalUi->display_error($m);

    return undef;
}

sub do_output {
    my $form = $GlobalUi->{form_object};
#    $GlobalUi->update_info_message( $form, 'output' );
    $form->setField( 'DONTSWITCH', 1 );
    $GlobalUi->clear_comment_and_error_display;
    my $m = $GlobalUi->{error_messages}->{'th26d'};
    $GlobalUi->display_error($m);

    return undef;
}

# implemented buttons

sub find_best_screen_for_table {
# On Perform forms that have 2+ tables and 2+ screens,
# sperform may change screens when the user changes tables.
# It is not clear what logic sperform uses to pick a screen.
# It could be "1st screen with a field that is associated with only
# that table (not joined to any other table)".  Or it could be
# "screen with the most fields associated with that table".
# Other heuristics can be devised that produce the same results
# as observed in sperform.
    my $ctbl = shift;
    my %first_scr;
    my $fl = $GlobalUi->get_field_list;
    $fl->reset;
    while (my $fo = $fl->iterate_list) {
        my ($tag, $tbl, $col) = $fo->get_names;
        my $scrs = get_screen_from_tag($tag);
        my $scr = @$scrs[0];
#warn "$tag  $tbl.$col  $scr\n";
        if ($tbl eq $ctbl) {
            if (!defined $first_scr{$tag} || $scr < $first_scr{$tag}) {
                $first_scr{$tag} = $scr;
            }
        } else {
            $first_scr{$tag} = -1;    
        }
    }
    my $fscr = 9999;
    foreach my $scr (values %first_scr) {
        $fscr = $scr if $scr >= 0 && $scr < $fscr;
    }
    $fscr = 0 if $fscr == 9999;
    return $fscr;
}

# returns list of field_tags used by a table
sub table_fields {
    my $ctbl = shift;

    my %tables = ( "$ctbl" => 1 );
    my %tags;
    my $more;
    my $fl = $GlobalUi->get_field_list;
    do {
        $more = 0;
        $fl->reset;
        while (my $fo = $fl->iterate_list) {
            my ($tag, $tbl, $col) = $fo->get_names;
            if ($tables{"$tbl"} || $tags{"$tag"}) {
                $more = 1 if (!defined $tags{"$tag"}
			      || !defined $tables{"$tbl"});
                $tables{"$tbl"} = 1;
                $tags{"$tag"} = 1;
                my $lookup = $fo->{lookup_hash};
                if ($lookup) {
                    foreach my $lu (values %$lookup) {
                        foreach my $lu2 (keys %$lu) {
                            $tags{"$lu2"} = 0;
                        }
                    }
                }
            }
        }
    } while ($more);
#warn "fields used by table $ctbl =\n" . join ("\n", keys %tags) . "\n";
    return %tags;
}

sub do_table {
    warn "TRACE: entering do_table\n" if $::TRACE;

    my $form   = $GlobalUi->get_current_form;
    my @tables = @{ $GlobalUi->{attribute_table_names} };

    warn "Attribute tables: @tables" if $::TRACE_DATA;

#    $GlobalUi->update_info_message( $form, 'table' );
    $GlobalUi->clear_comment_and_error_display;
    $form->setField( 'DONTSWITCH', 1 );

    $GlobalUi->increment_global_tablelist;
    $GlobalUi->increment_global_rowlist;

    my $tbl = $GlobalUi->get_current_table_name;
table_fields($tbl);
    my $scr = find_best_screen_for_table($tbl);
    goto_screen("Run$scr");

    # toggle the brackets around a field on the screen
    $form   = $GlobalUi->get_current_form;
    my $subform = $form->getSubform('DBForm');
    $subform->setField('editmode', 'query');
    $GlobalUi->set_field_bounds_on_screen;

    $RowList = $GlobalUi->get_current_rowlist;
#    display_row( $form, $RowList->current_row );

    warn "TRACE: leaving do_table\n" if $::TRACE;
}

sub doquit {
    my $key  = shift;
    my $form = shift;
    my $app  = $GlobalUi->{app_object};

    $form->setField( 'EXIT', 1 );
    $app->setField( 'EXIT',  1 );
    extern_exit();
    system 'clear';
    exit;
}

sub do_yes {
    my $key  = shift;
    my $form = shift;

    do_remove( $key, $form );

    do_no( $key, $form);
}

sub do_no {
    my $key  = shift;
    my $form = shift;

    warn "TRACE: entering do_no\n" if $::TRACE;
    $GlobalUi->change_focus_to_button( $form, 'perform' );
#    $GlobalUi->update_info_message( $form, 'remove' );
    my $wid    = $form->getWidget('ModeButtons');
    $wid->setField('VALUE', 6);  #'6' is the "Remove" button
}

# called from button_push with the top-level form.
sub changemode {
    my $mode        = shift;
    my $mode_resume = shift;

    my $app = $GlobalUi->{app_object};

    #my $fn = $app->getField('form_name');
    #my $form = $app->getForm($fn);
    my $form = $GlobalUi->get_current_form;

    my $subform = $form->getSubform('DBForm') || $form;
    my $fl = $GlobalUi->get_field_list;

    my $table = $GlobalUi->get_current_table_name;
    my @taborder =
      DBIx::Perform::Forms::temp_generate_taborder( $table, $mode );

    clear_table_textfields($mode);

    # change the UI mode
    $GlobalUi->change_mode_display( $form, $mode );
#    $GlobalUi->update_info_message( $form, $mode );

    my $scr = find_best_screen_for_table($table);
    if (goto_screen("Run$scr")) {
#    if ( goto_screen1() ) {
        $app->setField( 'resume_command', $mode_resume );
        return 1;
    }

    my $actkey = trigger_ctrl_blk( 'before', $mode, $table );
    return if $actkey eq "\cC";

    $app->{fresh} = 1;

    $GlobalUi->{focus} = $taborder[0];

    $subform->setField( 'TABORDER', \@taborder );
    $subform->setField( 'FOCUSED',  $taborder[0] );    # first field.
    $subform->setField( 'editmode', $mode );

    return 0;
}

sub querymode {
    warn "TRACE: entering querymode\n" if $::TRACE;

    $GlobalUi->clear_comment_and_error_display;

    warn "TRACE: leaving querymode\n" if $::TRACE;
    return if changemode( 'query', \&querymode_resume );
}

# Called as a resume entry, 'cause we have to force the form into
# the subform since we can't rely on lack of DONTSWITCH to switch there.
sub querymode_resume {
    my ($form) = @_;
    querymode(@_);
    $form->setField( 'FOCUSED', 'DBForm' );
}

sub do_master {
    warn "TRACE: entering do_master\n" if $::TRACE;

    my $app  = $GlobalUi->{app_object};
    my $form = $GlobalUi->get_current_form;

#    $GlobalUi->update_info_message( $form, 'master' );
    $GlobalUi->clear_comment_and_error_display;
    $form->setField( 'DONTSWITCH', 1 );

    my ( $master, $detail );
    my $ct = $GlobalUi->get_current_table_name;
    my ( $m, $d ) = $GlobalUi->get_master_detail_table_names($ct);

    my @masters = @$m;
    $master = $masters[0];
    my @details = @$d;
    $detail = $details[0] || '';

    if ( $ct eq $detail ) {       # switch to master from detail
        if ( my $tb = $GlobalUi->go_to_table($master) ) {

            my $tbl = $GlobalUi->get_current_table_name;
            my $scr = find_best_screen_for_table($tbl);
            goto_screen("Run$scr");

#            $GlobalUi->update_info_message( $form, 'master' );
            $GlobalUi->clear_comment_and_error_display;
            $form->setField( 'DONTSWITCH', 1 );

            # toggle the brackets around a field on the screen
            $GlobalUi->set_field_bounds_on_screen;

            $RowList = $GlobalUi->get_current_rowlist;
            display_row( $form, $RowList->current_row );
            warn "TRACE: leaving do_master\n" if $::TRACE;
            return;
        }
        warn "TRACE: leaving do_master\n" if $::TRACE;
        die "something wrong with do_master";
    }

    $form->setField( 'DONTSWITCH', 1 );
    my $msg = $GlobalUi->{error_messages}->{'no47.'};
    $GlobalUi->display_error($msg);
    warn "TRACE: leaving do_master\n" if $::TRACE;
    return undef;
}

# . switches to the detail table if in a master table
#   and does a query
# . sends a status message if current table isn't a detail

sub do_detail {
    warn "TRACE: entering do_detail\n" if $::TRACE;

    my $app     = $GlobalUi->{app_object};
    my $form    = $GlobalUi->get_current_form;
    my $subform = $form->getSubform('DBForm') || $form;

#    $GlobalUi->update_info_message( $form, 'detail' );
    $GlobalUi->clear_comment_and_error_display;
    $form->setField( 'DONTSWITCH', 1 );

    my $ct = $GlobalUi->get_current_table_name;
    my ( $m, $d ) = $GlobalUi->get_master_detail_table_names($ct);

    my @masters = @$m;
    my @details = @$d;
    my ( $master, $detail );

    if ( $#masters > 0 ) {
        $master = $masters[1];
        $detail = $details[1];
    }
    else {
        $master = $masters[0] || '';
        $detail = $details[0];
    }

    if ( $ct eq $master ) {       # switch to detail from master
	my $master_is_empty = $RowList->is_empty;
        if ( my $tb = $GlobalUi->go_to_table($detail) ) {

            my $tbl = $GlobalUi->get_current_table_name;
            my $scr = find_best_screen_for_table($tbl);
            goto_screen("Run$scr");

#            $GlobalUi->update_info_message( $form, 'master' );
            $GlobalUi->clear_comment_and_error_display;
            $form->setField( 'DONTSWITCH', 1 );

            # toggle the brackets around a field on the screen
            $GlobalUi->set_field_bounds_on_screen;

            $RowList = $GlobalUi->get_current_rowlist;
#            display_row( $form, $RowList->current_row );

            clear_detail_textfields($master, $detail);
	    if ( $master_is_empty ) {
                $GlobalUi->display_error('no11d');
            } else {
                do_query;
            }

            warn "TRACE: leaving do_detail\n" if $::TRACE;
            return;
        }
        warn "TRACE: leaving do_detail\n" if $::TRACE;
        die "something wrong with do_detail";
    }

    $form->setField( 'DONTSWITCH', 1 );
    $GlobalUi->display_error('no48.');
    warn "TRACE: leaving do_detail\n" if $::TRACE;
    return undef;
}

sub do_previous {
    my $key  = shift;
    my $form = shift;
    my $app  = $GlobalUi->{app_object};

#    $GlobalUi->update_info_message( $form, 'previous' );
    $GlobalUi->clear_comment_and_error_display;
    $form->setField( 'DONTSWITCH', 1 );
    $GlobalUi->clear_display_error;

    if ( $RowList->is_empty ) {
        $GlobalUi->display_error('no16.');
        $app->{deletedrow} = 0;
        return;
    }
    if ( $RowList->is_first ) {
        my $row = $RowList->current_row;
        display_row( $form, $row );

        # at the end of the list, switch to "Previous" button
        $form->getWidget('ModeButtons')->setField( 'VALUE', 2 );
        $GlobalUi->display_error('no41.');
#        $GlobalUi->update_info_message( $form, 'previous' );
        return unless $app->{deletedrow};
    }
    my $distance = $app->{'number'};
    $distance = 1 unless $distance;
    $app->{deletedrow} = 0;

    # Perform counts down from the most recent fetch - don't know why
    my $row = $RowList->previous_row($distance);
    display_row( $form, $row );

    if (my $row_status = refresh_row(1, 1)) {
        if ($row_status == 2) {
            $GlobalUi->display_error('so35.');
        } else {
            $GlobalUi->display_error('so34.');
        }
    }
}

sub do_next {
    my $key  = shift;
    my $form = shift;
    my $app  = $GlobalUi->{app_object};

#    $GlobalUi->update_info_message( $form, 'next' );
    $GlobalUi->clear_display_error;
    $form->setField( 'DONTSWITCH', 1 );
    $GlobalUi->clear_display_error;

    if ( $RowList->is_empty ) {
        $GlobalUi->display_error('no16.');
        $app->{deletedrow} = 0;
        return;
    }
    if ( $RowList->is_last ) {
        my $row = $RowList->current_row;
        display_row( $form, $row );

        # at the end of the list, switch to "Next" button
        $form->getWidget('ModeButtons')->setField( 'VALUE', 1 );
        $GlobalUi->display_error('no41.');
#        $GlobalUi->update_info_message( $form, 'next' );
        return unless $app->{deletedrow};
    }
    my $distance = $app->{'number'};
    $distance = 1 unless $distance;
    $distance = 0 if $app->{deletedrow};
    $app->{deletedrow} = 0;

    # Perform counts down from the most recent fetch (up for prev)
    my $row = $RowList->next_row($distance);
    display_row( $form, $row );

    if (my $row_status = refresh_row(1, 1)) {
        if ($row_status == 2) {
            $GlobalUi->display_error('so35.');
        } else {
            $GlobalUi->display_error('so34.');
        }
    }
}

sub addmode {
    warn "TRACE: entering addmode\n" if $::TRACE;
    return if changemode( 'add', \&addmode_resume );

    my $form    = $GlobalUi->get_current_form;
    my $subform = $form->getSubform('DBForm') || $form;
    my $fl      = $GlobalUi->get_field_list;

    $GlobalUi->clear_comment_and_error_display;

    # initalize any serial or default fields to screen
    $fl->display_defaults_to_screen($GlobalUi);

    warn "TRACE: leaving addmode\n" if $::TRACE;
}

sub addmode_resume {
    my $subform = shift;
    addmode(@_);
    $subform->setField( 'FOCUSED', 'DBForm' );
}

sub updatemode {
    my $form = $GlobalUi->get_current_form;

#    $GlobalUi->update_info_message( $form, 'update' );
    return if check_rows_and_advise($form);

    return if changemode( 'update', \&updatemode_resume );

    $GlobalUi->clear_comment_and_error_display;

    my $subform = $form->getSubform('DBForm');
    my $fl      = $GlobalUi->get_field_list;

    my $row = $RowList->current_row;

    $fl->reset;
    while ( my $f = $fl->iterate_list ) {
        my ( $ft, $tbl, $col ) = $f->get_names;
        my $w = $subform->getWidget($ft);
        next unless $col;
    }
}

sub updatemode_resume {
    my ($form) = @_;
    updatemode(@_);
    $form->setField( 'FOCUSED', 'DBForm' );
}

# sub edit_control  #replaced with Perform::Instruct::trigger_ctrl_blk

sub removemode {
    my $key  = shift;
    my $form = shift;

    my %info_msgs = %{ $GlobalUi->{info_messages} };
    my %err_msgs  = %{ $GlobalUi->{error_messages} };
    my @buttons   = $GlobalUi->{buttons_yn};
    my $app       = $GlobalUi->{app_object};

#    $GlobalUi->update_info_message( $form, 'remove' );
    $form->setField( 'DONTSWITCH', 1 );
    $GlobalUi->clear_comment_and_error_display;

    return if check_rows_and_advise($form);

    #'before remove' only works on tables.  Don't believe it makes any
    # sense to trigger off a column-- the smallest element that can be
    # removed is 1 row.
    my $table = $GlobalUi->get_current_table_name;
    my $actkey = trigger_ctrl_blk( 'before', 'remove', $table );
    return if $actkey eq "\cC";

    $GlobalUi->switch_buttons( $form );
#    $GlobalUi->update_info_message( $form, 'yes' );
    my $wid    = $form->getWidget('ModeButtons');
    $wid->setField('VALUE', 0);
}

sub do_remove {

    #my $key = shift;
    #my $form = shift;

    warn "TRACE: entering do_remove\n" if $::TRACE;

    my $app  = $GlobalUi->{app_object};
    my $form = $GlobalUi->get_current_form;
#    $GlobalUi->update_info_message( $form, 'remove' );

    return if check_rows_and_advise($form);

    my $table = $GlobalUi->get_current_table_name;

    my $subform = $form->getSubform('DBForm');
    my $fl      = $GlobalUi->get_field_list;

    my @wheres = ();
    my @values = ();

    my $row     = $RowList->current_row;
    my $aliases = $app->{'aliases'};

    my $ralias = $aliases->{"$table.rowid"};
    my $ridx = $RowList->{aliases}->{$ralias};
    my $wheres = "rowid = $$row[$ridx]";
    my $cmd    = "delete from $table where $wheres";

    warn "Remove command:\n$cmd\n" if $::TRACE_DATA;
    my $rc = $DB->do( $cmd, {}, @values );
    if ( !defined $rc ) {
        my $m1 = $GlobalUi->{error_messages}->{'da11r'};
        my $m2 = ": $DBI::errstr";
        $GlobalUi->display_comment($m1);
        $GlobalUi->display_error($m2);
    }
    else {
        $GlobalUi->display_status('ro8d');
        $RowList->remove_row;
        clear_textfields();
        $app->{deletedrow} = 1;
    }
    trigger_ctrl_blk( 'after', 'remove', $table );
    $form->setField( 'DONTSWITCH', 1 );    # in all cases.

    $GlobalUi->change_mode_display( $subform, 'perform' );
    warn "TRACE: exiting do_remove\n" if $::TRACE;
}

sub OnFieldEnter {
    my ( $status_bar, $field_tag, $subform, $key ) = @_;

    warn "TRACE: entering OnFieldEnter\n" if $::TRACE;
    &$status_bar                          if ($status_bar);

    my $app   = $GlobalUi->{app_object};
    my $form  = $GlobalUi->get_current_form;
    my $fl    = $GlobalUi->get_field_list;
    my $table = $GlobalUi->get_current_table_name;


    my $fo = $fl->get_field_object( $table, $field_tag );
    die "undefined field object" unless defined($fo);

    my $mode = $subform->getField('editmode');
    my $widget = $subform->getWidget($field_tag);
    my $val = $fo->get_value;
    $val = '' unless defined $val;
    if (length($val) <= $widget->{CONF}->{COLUMNS} || $mode ne 'query') {
        $widget->{CONF}->{'EXIT'} = 0;

        my $comment = $fo->{comments};
        $comment
          ? $GlobalUi->display_comment($comment)
          : $GlobalUi->clear_display_comment;
    } else {
        $widget->{CONF}->{'EXIT'} = 1;
        $widget->{CONF}->{OVERFLOW} = 1;
    }

    # do any BEFORE control blocks.
    my $actkey = trigger_ctrl_blk_fld( 'before', "edit$mode", $fo );

    bail_out() if ( $actkey eq "\cC" );    # 3 is ASCII code for ctrl-c

    warn "TRACE: leaving OnFieldEnter\n" if $::TRACE;
}

sub OnFieldExit {
    my ( $field_tag, $subform, $key ) = @_;

    my $widget = $subform->getWidget($field_tag);
    my $ovf = $widget->{CONF}->{OVERFLOW} || 0;
    return if $subform->getField('EXIT') && !$ovf;
    warn "TRACE: entering OnFieldExit\n" if $::TRACE;

    my $app    = $GlobalUi->{app_object};
    my $form   = $GlobalUi->get_current_form;
    my $fl     = $GlobalUi->get_field_list;
    my $table  = $GlobalUi->get_current_table_name;
    my $fo     = $fl->get_field_object( $table, $field_tag );
    my $mode   = $subform->getField('editmode');

    # erase comments and error messages
    $GlobalUi->clear_comment_and_error_display;

    if ( $key eq "\cp" ) {
        my $aliases = $app->{'aliases'};
        my $row     = $RowList->current_row;
        my ( $tag, $tbl, $col ) = $fo->get_names;
        my $tnc   = "$tbl.$col";
        my $alias = $aliases->{$tnc};
#        my $val = $row->{$alias};
        my $idx = $RowList->{aliases}->{$alias};
        my $val = $row->[$idx];
        my ( $pos, $rc );
#warn "ctrl-p: $tag = $val\n";
        ( $val, $rc ) = $fo->format_value_for_display( $val );
        $fo->set_value($val);
        $GlobalUi->set_screen_value( $tag, $val );
    }

    if ($mode eq 'query' && length($fo->get_value) > $fo->{size} || $ovf ) {
        my $wid = $form->getWidget('Comment');
        my $val = $GlobalUi->get_screen_value($field_tag);
        $wid->setField( 'VALUE', $val );
        my $cursorpos = $widget->getField( 'CURSORPOS' );
        $wid->{CONF}->{CURSORPOS} = $cursorpos;
        my $mwh = $form->{MWH};
        $wid->setField( 'NAME', $fo->{field_tag} );
        $wid->{CONF}->{FOCUSSWITCH} = "\t\n\cp\cw\cc\ck\c[\cf\cb";
        $wid->{CONF}->{FOCUSSWITCH_MACROKEYS} = [ KEY_UP, KEY_DOWN, KEY_DEL ];
        $wid->{CONF}->{EXIT} = 0;
        $wid->draw($mwh);
        $key = $wid->execute($mwh);
        $val = $wid->getField( 'VALUE' );
        $wid->setField( 'NAME', '');
        $widget->{CONF}->{OVERFLOW} = 0;
        $fo->set_value($val);
        $GlobalUi->set_screen_value( $field_tag, $val );
    }
    $widget->setField( 'CURSORPOS', 0 );
    if ($mode ne "query" && !$GlobalUi->{newfocus}) {
        my $good = 1;
        my $val = $GlobalUi->get_screen_value($field_tag);
        $good = 0 if ($fo->validate_input($val, $mode) < 0);
        if ($good) {
            if ($fo->is_any_numeric_db_type) {
                if (!$fo->is_number($val) && $val ne '') {
                    $GlobalUi->display_error('er11d');
                    $good =  0;
                }
            }
            if ($good) {
                $val = $fo->get_value;
                my ($junk, $rc) = $fo->format_value_for_display($val);
                $good = !$rc;
                $GlobalUi->display_error('er11d') if (!$good); 
            }
            if ($good) {
                $good = 0 if (!verify_joins($table, $field_tag));
            }
        }
        if (!$good) {
            $GlobalUi->{newfocus} = $GlobalUi->{focus}
        }
    }

    trigger_lookup($field_tag);

    my $actkey = trigger_ctrl_blk_fld( 'after', "edit$mode", $fo );
    my $value = $fo->get_value;

    $key = $actkey if !defined $key || $actkey ne "\c0";
    warn "key: [" . unpack( 'U*', $key ) . "]\n" if $::TRACE;

    $subform->setField( 'DONTSWITCH', 0 );
    if (
        $key    eq "\t"    # advance to the next field
        || $key eq "\n" 
        || $key eq KEY_DOWN || $key eq KEY_RIGHT
      )
    {

        #	$GlobalUi->clear_comment_and_error_display;
        return;
    }

    my $dontswitch = 1;

    if ( $key eq "\c[" ) {
	return if $GlobalUi->{newfocus};
        $actkey = trigger_ctrl_blk( 'after', "edit$mode", $table );
	return if $GlobalUi->{newfocus};
        my $wid = $form->getWidget('ModeButtons');
        my $mode =
          lc( ( $wid->getField('NAMES') )->[ $wid->getField('VALUE') ] );
        my $modesubs = $GlobalUi->{mode_subs};
        my $sub      = $modesubs->{$mode};       # mode subroutine

        if ( $sub && ref($sub) eq 'CODE' ) {
            $dontswitch = 0;                     # let the sub decide.
            &$sub( $field_tag, $widget, $subform )
              ;                                  # call the mode "do_add" etc..
        }
        else {
            beep();
        }
    }
    elsif ( $key eq "\cw" ) {
        $GlobalUi->display_help_screen(1);
        $GlobalUi->{'newfocus'} = $GlobalUi->{'focus'}
          unless $GlobalUi->{'newfocus'};
        return;
    }
    elsif ( $key eq "\cC" || $key eq KEY_DEL )                      # Ctrl-C
    {
        bail_out();
    }
    elsif ($key eq "\cK"
        || $key eq KEY_UP
        || $key eq KEY_LEFT
        || $key eq KEY_BACKSPACE
        || $key eq KEY_STAB )
    {
        my $ct   = $GlobalUi->get_current_table_name;
#        my $mode = $subform->getField('editmode');

        my @taborder =
          DBIx::Perform::Forms::temp_generate_taborder( $ct, $mode );
        my %taborder = map { ( $taborder[$_], $_ ) } ( 0 .. $#taborder );
        my $i = $taborder{ $GlobalUi->{'focus'} };
        $i = ( $i <= 0 ) ? $#taborder : $i - 1;

        $subform->setField( 'FOCUSED', $taborder[$i] );
        $GlobalUi->{'newfocus'} = $taborder[$i]
          unless $GlobalUi->{'newfocus'};

#        $GlobalUi->clear_comment_and_error_display;

        return;
    }
    elsif ( $key eq "\cF" ) {
        my $ct   = $GlobalUi->get_current_table_name;
#        my $mode = $subform->getField('editmode');
        my @taborder =
          DBIx::Perform::Forms::temp_generate_taborder( $ct, $mode );
        my %taborder  = map { ( $taborder[$_], $_ ) } ( 0 .. $#taborder );
        my $i         = $taborder{ $GlobalUi->{'focus'} };
        my $w         = $subform->getWidget( $taborder[$i] );
        my $y_cur     = $w->getField('Y');
        my $y         = $y_cur;
        my $screenpad = 0;
        my $limit     = @taborder + 0;
        do {
            $i = ( $i >= $#taborder ) ? 0 : $i + 1;
            my ( $cf, $cfa, $cfn );
            $cf  = $app->getField('form_name');
            $cfa = $app->getField('form_names');
            ($cfn) = $cf =~ /^Run(\d+)/;
            my $limit2 = @$cfa + 0;
            do {
                $w = $subform->getWidget( $taborder[$i] );
                unless ( defined $w ) {
                    $cfn++;
                    $cfn = 0 if ( $cfn >= @$cfa );
                    $cf = "Run$cfn";
                    my $form = $app->getForm($cf);
                    $subform = $form->getSubform('DBForm');
                    $screenpad += $y_cur + 1;
                }
                $limit2--;
            } while ( !( defined $w ) && $limit2 >= 0 );
            $limit--;
            $y = $w->getField('Y') + $screenpad;
        } while ( $y <= $y_cur && $limit >= 0 );
        $i = $taborder{ $GlobalUi->{'focus'} } unless $limit >= 0;
        $GlobalUi->{'newfocus'} = $taborder[$i]
          unless $GlobalUi->{'newfocus'};
    }
    elsif ( $key eq "\cB" ) {
        my $ct   = $GlobalUi->get_current_table_name;
#        my $mode = $subform->getField('editmode');
        my @taborder =
          DBIx::Perform::Forms::temp_generate_taborder( $ct, $mode );
        my %taborder  = map { ( $taborder[$_], $_ ) } ( 0 .. $#taborder );
        my $i         = $taborder{ $GlobalUi->{'focus'} };
        my $w         = $subform->getWidget( $taborder[$i] );
        my $y_cur     = $w->getField('Y');
        my $y         = $y_cur;
        my $screenpad = 0;
        my $limit     = @taborder + 0;
        do {
            $i = ( $i <= 0 ) ? $#taborder : $i - 1;
            my ( $cf, $cfa, $cfn );
            $cf  = $app->getField('form_name');
            $cfa = $app->getField('form_names');
            ($cfn) = $cf =~ /^Run(\d+)/;
            my $limit2 = @$cfa + 0;
            do {
                $w = $subform->getWidget( $taborder[$i] );
                unless ( defined $w ) {
                    $cfn--;
                    $cfn = $#$cfa if ( $cfn < 0 );
                    $cf = "Run$cfn";
                    my $form = $app->getForm($cf);
                    $subform = $form->getSubform('DBForm');
                    $screenpad -= 256;    #FIX -- can't guarantee < 256 lines
                }
                $limit2--;
            } while ( !( defined $w ) && $limit2 >= 0 );
            $limit--;
            $y = $w->getField('Y') + $screenpad;
        } while ( $y >= $y_cur && $limit >= 0 );
        $i = $taborder{ $GlobalUi->{'focus'} } unless $limit >= 0;
        $GlobalUi->{'newfocus'} = $taborder[$i]
          unless $GlobalUi->{'newfocus'};
    }

    if ($dontswitch) {
        $subform->setField( 'DONTSWITCH', 1 );
    }

    warn "TRACE: leaving OnFieldExit\n" if $::TRACE;
}

sub bail_out {
    warn "TRACE: entering bail_out\n" if $::TRACE;
    my $app     = $GlobalUi->{app_object};
    my $form    = $GlobalUi->get_current_form;
    my $subform = $form->getSubform('DBForm');

    # Bailing out of Query, Add, Update or Modify.
    # Re-display the row as it was, if any.
    if ( $RowList->not_empty ) {
        display_row( $subform, $RowList->current_row );
    }
#    else {
#        clear_textfields();
#    }

    # Back to top menu
    $GlobalUi->clear_comment_and_error_display;

    $form->setField( 'DONTSWITCH', 0 );
    $subform->setField( 'EXIT',    1 );

    my $wname = $subform->getField('FOCUSED');
    my $wid   = $subform->getWidget($wname);
    $wid->{CONF}->{'EXIT'} = 1;
    $GlobalUi->change_mode_display( $subform, 'perform' );
}

#if the given field joins columns, and one of those other than the given
#table.column has "*", then must do a query.
#If the result of the query is that the current value is not in that
#other table.column, then the input must be rejected and the cursor
#kept in the field.
sub verify_joins {
    my $t = shift;
    my $f = shift;
warn "TRACE: entering verify_joins for field $f, table $t\n" if $::TRACE;
    my $fl  = $GlobalUi->get_field_list;
    my $fos = $fl->get_fields_by_field_tag($f);
    for (my $i = $#$fos; $i >= 0; $i--) {
        if ($$fos[$i]->{verify}) {
            my $dt = $$fos[$i]->{table_name};
	    return 1 if $dt eq $t;
            my $dc = $$fos[$i]->{column_name};
            return verify_join($f, $dt, $dc);
        }
        my $luh = $$fos[$i]->{lookup_hash};
        foreach my $n (keys %$luh) {
            my $lus = $luh->{$n};
            foreach my $lu (keys %$lus) {
                if ($lus->{$lu}->{verify}) {
                    my $dt = $lus->{$lu}->{join_table};
                    my $dc = $lus->{$lu}->{join_column};
                    return verify_join($f, $dt, $dc);
                }
            }
        }
    }
    return 1;
}

sub verify_join {
    my ($f, $dt, $dc) = @_;

    my $val = $GlobalUi->get_screen_value($f);
    my $query = "select $dt.$dc from $dt"
              . "\nwhere $dt.$dc = ?";
warn "verify_join\n$query\n$val\n" if $::TRACE;

    my $sth = $DB->prepare($query);
    warn "$DBI::errstr\n" unless $sth;
    $sth->execute(($val));
    my $ref = $sth->fetchrow_array;
    return 1 if $ref;
    my $m = sprintf($GlobalUi->{error_messages}->{'th55e'}, $dt);
    $GlobalUi->display_error($m);
#    $GlobalUi->display_error(" This is an invalid value --"
#       . " it does not exist in \"$dt\" table ");
    return 0;
}

sub verify_composite_joins {
    my $app = $GlobalUi->{app_object};
    my $instrs = $app->getField('instrs');
    my $composites = $instrs->{COMPOSITES};

    if (defined $composites) {
        my $current_tbl = $GlobalUi->get_current_table_name;
        my $fl          = $GlobalUi->get_field_list;
        foreach my $co (@$composites) {
            if (   $co->{TBL1} eq $current_tbl
                || $co->{TBL2} eq $current_tbl) {
                my $tbln = 1;
                $tbln = 2 if $co->{VFY2} eq '*';
                my $tbl = $co->{"TBL$tbln"};

                my %wheres;
                my $col;
                for (my $i = 0; $i < @{$co->{COLS1}}; $i++ ) {
                    $col = $co->{"COLS$tbln"}[$i];
                    my $flds = $fl->get_fields_by_table_and_column($tbl, $col);
                    my $val =
                      $GlobalUi->get_screen_value($$flds[0]->{field_tag});
                    $wheres{"$tbl.$col = ?"} = $val;
                }

                my $query = "select $tbl.$col\nfrom $tbl\nwhere\n"
                  . join ("\nand ", keys %wheres);
warn "verify_composite_joins:\n$query\n"
     . join (", ", values %wheres) . "\n" if $::TRACE;

                my $ref = 0;
                my $sth = $DB->prepare($query);
                warn "$DBI::errstr\n" unless $sth;
                $sth->execute(values %wheres) if $sth;
                $ref = $sth->fetchrow_array if $sth;
                return 1 if $ref;

                my $m = sprintf($GlobalUi->{error_messages}->{'in61e'}, $tbl);
                $GlobalUi->display_error($m);
#                $GlobalUi->display_error(" Invalid value -- its composite "
#                  . "value does not exist in \"$tbl\" table ");
                return 0;
            }
        }       
    }
    return 1;
}

# this sub is for debugging only
#sub temp_which_subform_are_we_in
#{
#    my $sf = shift;
#    my $app	= $GlobalUi->{app_object};
#    my ($cfn, $cfa);
#    $cfa = $app->getField('form_names');
#    for ($cfn = 0; $cfn < @$cfa; $cfn++) {
#        my $cf = "Run$cfn";
#        my $form = $app->getForm($cf);
#        my $subform = $form->getSubform('DBForm');
#        return $cfn if ($subform == $sf);
#    }
#    return -1;
#}

#sub temp_get_screen_from_tag
#{
#    my $tag = shift;
#    my $app = $GlobalUi->{app_object};
#
#    my ($cfn, $cfa);
#    $cfa = $app->getField('form_names');
#    for ($cfn = 0; $cfn < @$cfa; $cfn++) {
#        my $cf = "Run$cfn";
#        my $form = $app->getForm($cf);
#        my $subform = $form->getSubform('DBForm');
#        return $cfn if (defined $subform->getWidget($tag));
#    }
#    return -1;
#}


sub get_screen_from_tag {
    my $tag = shift;

    unless ( defined $Tag_screens{$tag} ) {
        my @scrns = ();
        my $app   = $GlobalUi->{app_object};
        my ( $cfn, $cfa );
        $cfa = $app->getField('form_names');
        for ( $cfn = 0 ; $cfn < @$cfa ; $cfn++ ) {
            my $cf      = "Run$cfn";
            my $form    = $app->getForm($cf);
            my $subform = $form->getSubform('DBForm');
            if ( defined $subform->getWidget($tag) ) {
                push @scrns, $cfn;
            }
        }
        $Tag_screens{$tag} = \@scrns;
    }
    return $Tag_screens{$tag};
}

#sub get_value_from_tag {
#    my $field_tag = shift;
#
#    my $fl    = $GlobalUi->get_field_list;
#    my $fo = get_field_object_from_tag($field_tag);
#    my $rv;
#    $rv = $fo->get_value if defined $fo;
##warn "get_value_from_tag: $rv field = :$field_tag:\n";
#    return $rv;
#}

sub get_field_object_from_tag {
    my $ft = shift;
    my $fl = $GlobalUi->get_field_list;

    $fl->reset;
    while ( my $fo = $fl->iterate_list ) {
        if ( $fo->{field_tag} eq $ft ) {
            return $fo;
        }
    }
    return undef;
}

#Lookups always go with a join.  Given a line in a .per script:
#  f1 = t1.c1 lookup f2 = t2.c2 joining t2.c1
#We fill f2 with t2.c2 from those rows of t2 in which t1.c1 = t2.c1
#We fill immediately whenever the value in f1 changes.
#Not certain what should happen if c1 has duplicate values.
#active_tabcol = t1.c1,  join_table = t2, join_column = t2.c1
sub trigger_lookup {
    my $trigger_tag = shift;
    warn "TRACE: entering trigger_lookup for $trigger_tag\n" if $::TRACE;
    my $app = $GlobalUi->{app_object};
    my $tval = $GlobalUi->get_screen_value($trigger_tag);
    my $fl   = $GlobalUi->get_field_list;
    my $fos = $fl->get_fields_by_field_tag($trigger_tag);

    my %compcol;
    my $composites;
    my $instrs = $app->getField('instrs');
    $composites = $instrs->{COMPOSITES} if $instrs;
    if ($composites) {
        for (my $i = $#$composites; $i >= 0; $i--) {
            my $cst = @$composites[$i];
            for (my $j = 2; $j > 0; $j--) {
                my $tbl = $cst->{"TBL$j"};
                my $cols = $cst->{"COLS$j"};
                for (my $k = $#$cols; $k >= 0; $k--) {
                    my $col = $$cols[$k];
                    $compcol{"$tbl.$col"} = $i;
                }
            }
        }
    }


    foreach my $f1o (@$fos) { 
        my ( $f1, $t1, $c1 ) = $f1o->get_names;
        my $tnc  = "$t1.$c1";

        $fl->reset;
        while ( my $fo = $fl->iterate_list ) {
            my ( $tag, $tbl, $col ) = $fo->get_names;

            if ( defined $fo->{active_tabcol} 
                 && $fo->{active_tabcol} eq $tnc ) {
                my $val;
                my $t2 = $fo->{join_table};
                my $c2 = $fo->{join_column};
                if ( defined $tval && $tval ne '' ) {
                    my %tbls;
                    $tbls{$t1} = 1;
                    $tbls{$t2} = 1;
                    $tbls{$tbl} = 1;
                    my $cm = $c2;
                    $cm = $c1 if $t1 eq $tbl;
                    my $query =
                        "select $col from $tbl"
                      . "\nwhere $cm = ?";
#                        "select $tbl.$col from " . join (', ', keys %tbls)
#                      . " where $tnc = $t2.$c2"
#                      . " and $tnc = ?";
                    my $sth = $DB->prepare($query);
                    warn "$DBI::errstr\n" unless $sth;
                    $sth->execute(($tval)) if $sth;
                    $val = $sth->fetchrow_array;
                    warn "query = $query\nval = $tval\n" if $::TRACE;
                    warn "tag = :$tag: result of query = :$val:\n"
                        if defined $val && $::TRACE;
                }
                else {
                    $val = '';
                }
                $fo->set_value($val);
                $app->{redraw_subform} = 1;
                my ( $pos, $rc );
                ( $val, $rc ) = $fo->format_value_for_display( $val );
                $GlobalUi->set_screen_value( $tag, $val );
            }

        }

        if ($composites) {
#Seems it should be possible to handle composites with much less code
#than this.
            my $idx = $compcol{"$tnc"};
            if (defined $idx && $idx >= 0) {
                my $cst = @$composites[$idx];
                $compcol{"$tnc"} = -1;

                my $v = 0;
                $v = 1 if $cst->{VFY1};
                $v = 2 if $cst->{VFY2};
                $v = $cst->{TBL1} eq $GlobalUi->get_current_table_name?2:1
                    if !$v;
                my $cjtbl = $cst->{"TBL$v"};

                my $query;
                $fl->reset;
                while ( my $fo = $fl->iterate_list ) {
                    my ( $tag, $tbl, $col ) = $fo->get_names;
                    if ($tbl eq $cjtbl && !$compcol{"$tbl.$col"}) {
                        my $cols = $cst->{"COLS$v"};
                        $query = "select $col from $tbl\nwhere "
                               . join(" = ?\nand ", @$cols);
                        $query .= " = ?";
                        my $good = 1;
                        my @cjvals = ();
                        for (my $i = 0; $i <= $#$cols; $i++) {
                            if ($col eq $$cols[$i]) {
                                $good = 0;
                                last;
                            }
                            my $cjfs =  $fl->get_fields_by_table_and_column(
                                             $cjtbl, $$cols[$i]);
                            my $cjtag = $$cjfs[0]->{field_tag};
                            my $val = $GlobalUi->get_screen_value($cjtag);
                            if (!defined $val || $val eq '') {
                                $good = 0;
                                last;
                            }
                            push @cjvals, $val;
                        }
                        if ($good) {
                            my $sth = $DB->prepare($query);
                            warn "$DBI::errstr\n" unless $sth;
                            $sth->execute(@cjvals);
                            my $val = $sth->fetchrow_array;
if ($::TRACE) {
warn "composite join query =\n$query\n";
warn "vals = " . join (", ", @cjvals) . "\n";
warn "query result = $val\n";
}
                            $fo->set_value($val);
                            $app->{redraw_subform} = 1;
                            my ( $pos, $rc );
                            ( $val, $rc )
                              = $fo->format_value_for_display( $val );
                            $GlobalUi->set_screen_value( $tag, $val );
                        }
                    }
                }
            }
        }


    }
}

#Complicated queries are tricky to get right.  A perfectly valid query
# may be unacceptably slow.  Given 3 tables, t1, t2, and t3, each with
# columns mca, mcb, ca, cb where mca and mcb are "matching columns"
# (t1.mca = t2.mca) and t1.ca is unrelated to t2.ca and so on, we
# want every row from t1, with 1 matching row (if any) from t2 and t3.
# We have to use some means of getting just 1 row from t2 and t3 per row
# from t1.  Speaking of just t1 and t2, an inner join will leave out a row
# from t1 if no rows in t2 match that row.  An outer join will have 2 or
# more rows in the results if more than 1 row of t2 matches a single row
# of t1.  So, neither delivered the desired results.  (Just why sperform
# works that way is another question that doesn't seem to have a good
# answer.)  An answer to this problem was to use a function that would
# return just one row of t2 per row of t1, such as "min".  The query then
# became:
#
# select min(t2.ca) aa, min(t2.cb) ab, t1.ca ac, t1.cb ad
# from t1, outer t2 where t1.mca = t2.mca
# group by t1.ca, t1.cb
#
# This worked except when t1 had duplicate rows.  However, when t3 is
# thrown in the mix, and we join the tables with a relation between t2
# and t3, then we have trouble.  The query below might be extremely slow,
# taking many hours to run:
#
# select min(t2.ca) aa, min(t2.cb) ab, t1.c2 ac, t1.c3 ad,
#        min(t3.ca) ae, min(t3.cb) af, t1.mca ag, min(t2.mcb) ah
#   from t1, outer t2, t3 where t1.mca = t2.mca and t2.mcb = t3.mcb
#   group by t1.c2, t1.c3, t1.mca
#
# As long as all the joins are between t1 and the other tables, the query
# is fast.  To handle the situation when they're not, needed to work out
# another query formulation.  Doing it in 2 queries with a temporary table
# works:
#
# select min(t2.ca) aa, min(t2.cb) ab, t1.ca ac, t1.cb ad,
#        t1.mca ae, min(t2.mcb) af
#   from t1, outer t2 where t1.mca = t2.mca
#   group by t1.ca, t1.cb into temp tmpperl;
# select tmpperl.aa aa, tmpperl.ab ab, tmpperl.ac ac, tmpperl.ad ad,
#        tmpperl.ae ae, min(t3.ca) af, min(t3.cb) ag
#   from tmpperl, outer t3
#   where tmpperl.af = t3.mcb

# Take 6:  Query is still not good enough.
# At least 2 problems:  
# 1. The minimum value of each column may be in different rows,
# and if min is used on more than one col, we want everything to be from
# the same row.
# 2. In a lookup, the form may ask for the same column in more than one place,
# with different conditions.

# Take 7:  The query strategy had to change some more.
# The strategy used in take5 could get columns from different rows of
# joined tables, because all it did was get the minimum of each column
# regardless of what rows the minimums of any other columns came from.
# This version replaces the single query for those minimums with 2.
# The 1st of the 2 queries gets only the minimum rowid.  Then the 2nd does
# not use minimum at all but instead gets the rest of the columns from
# the joined table with "where joined.rowid = pf_tmpx.row_id".

#Make a graph of all the joins.
#  (Each node represents a table, and each edge represents a join.)
sub compute_joins {
    my (%joins, %tags);
    my $fl = $GlobalUi->get_field_list;
    $fl->reset;
    while ( my $fo = $fl->iterate_list ) {
        my ( $tag, $tbl, $col ) = $fo->get_names;
#get joins in lookups
        if ($fo->{active_tabcol}) {
            my $t2 = $fo->{join_table};
            my $c2 = $fo->{join_column};
            my ( $t1, $c1 ) = $fo->{active_tabcol} =~ /(\w+)\.(\w+)/;
            if ($t1 ne $t2) {
                $joins{$t1}->{$t2}->{"$c1 $c2 $tag"} = 1;
                $joins{$t2}->{$t1}->{"$c2 $c1 $tag"} = 1;
            }
        }
#get all other joins
        if ( defined $tags{$tag} ) {
            foreach my $jtag (keys %{$tags{$tag}}) {
                my ( $t1, $c1 ) = $jtag =~ /(\w+)\.(\w+)/;
                if ($t1 ne $tbl) {
                    $joins{$t1}->{$tbl}->{"$c1 $col"} = 1;
                    $joins{$tbl}->{$t1}->{"$col $c1"} = 1;
                }
            }
        }
        $tags{$tag}->{"$tbl.$col"} = 1;
    }
    return %joins;
}

sub get_query_conditions {
    my $qtbl = shift;
    my %wheres;

    my $fl = $GlobalUi->get_field_list;
    $fl->reset;
    while ( my $fo = $fl->iterate_list ) {
        next if $fo->{displayonly};
        my ( $tag, $tbl, $col ) = $fo->get_names;
        if ($qtbl eq $tbl) {
            my $val = $GlobalUi->get_screen_value($tag);
            $val = $fo->get_value if $fo->{right};
            if ( defined $val && $val ne '') {
                my ( $wexpr, $wv ) = query_condition( $tbl, $col, $val );
                $wheres{$wexpr} = \@$wv;
            }
        }
    }
    return %wheres;
}

#input is an array of "tbl.col" strings.
#output is an array of "tbl.col alias" strings.
sub append_aliases {
    my %tncs = @_;
#warn "TRACE: entering append_alias\n";
    my $fl      = $GlobalUi->get_field_list;
    my $app     = $GlobalUi->{app_object};
    my $aliases = $app->{aliases};
    my %hash;

    my $ctbl    = $GlobalUi->get_current_table_name;
    my %fields  = table_fields($ctbl);

    my %aliased;
    foreach my $tnc (keys %tncs) {
#warn "getting alias for $tnc\n";
        if (! $hash{$tnc}) {
            my ($t, $c) = $tnc =~ /(\w+)\.(\w+)/;
            my $flds = $fl->get_fields_by_table_and_column($t, $c);
            my $alias = $aliases->{$tnc};
            if (@$flds > 1) {
                my $i;
                for ($i = 0; $i < @$flds; $i++) {
                    my $fo = @$flds[$i];
                    my ( $tag, $tbl, $col ) = $fo->get_names;
                    if (defined $fields{"$tag"}) {
                        $alias = $aliases->{"$tnc $tag"};
                        $aliased{"$tnc $alias"} = 1;
                    }
                }
            } else {
                $aliased{"$tnc $alias"} = 1;
            }
            $hash{$tnc} = 1;
        }
    }    
#warn "TRACE: leaving append_alias\n";
    return %aliased;
}

#input is a "table" and an array of "col" strings.
#output is an array of "tbl.col alias" strings.
sub prepend_table_name {
    my $tbl = shift;
    my %cs = @_;
    my %tncs;

    foreach my $c (keys %cs) {
        $tncs{"$tbl.$c"} = 1;
    }
    return %tncs;
}

our $stmptn = 1;             #temp table number, for queries
our $stmptlun = 1;           #temp table number for lookups, for queries

#sub do_query_take7 {
sub create_query {
#    my ( $field, $widget, $subform ) = @_;
    my $TMPTBL       = "pf_tmp";
    my (%tbl_visit, %tbl_prev_visit, %tbl_cur_visit, %tbl_next_visit);
    my ($tmptn, $tmptlun) = ($stmptn, $stmptlun);
    my $more;
    my $current_tbl = $GlobalUi->get_current_table_name;
    my $app         = $GlobalUi->{app_object};
    my $query;
    my @queries = ();
    my $sth;

    $app->{deletedrow} = 0;
    generate_query_aliases();
    my $aliases = $app->{'aliases'};
    my %joins = compute_joins;

#warn Data::Dumper->Dump([%lookups], ['lookups']);


#first query    
    my %wheres = get_query_conditions($current_tbl);
    my $fl = $GlobalUi->get_field_list;
    my @colsa = $fl->get_columns($current_tbl);
    my %cols;
    map { $cols{$_} = 1; } @colsa;
    $cols{rowid} = 1;

    my %tncs = prepend_table_name($current_tbl, %cols);
    my %selects = append_aliases(%tncs);


    $query = "select\n" . join (",\n", keys %selects)
           . "\nfrom $current_tbl";
    my $query_wheres = "";
    $query_wheres = "\nwhere\n" . join ("\nand ", keys %wheres) if %wheres;
    my $query_count = "select count(*) from $current_tbl";
    $query .= $query_wheres;
    $query_count .= $query_wheres;

    my @vals;
    foreach my $val (values %wheres) {
        push @vals, @$val;
    }


    my @tables = ("$TMPTBL$tmptn");
    my %tblsintmp;
    $tblsintmp{$current_tbl} = 1;
    my @outertbls = keys %{$joins{$current_tbl}};
    $more = @outertbls;



#Starting with $current_table, follow the joins as in a breadth first search.
#The number of queries needed is 1 + 2x the depth of the search + lookups.
    while ($more) {
        $query .= "\ninto temp $TMPTBL$tmptn";

#do the query for the rowid, and put the results into a temporary table
warn "$query;\n" if $::TRACE;

        push @queries, $query;



        my %tmpcols = ();
        my %groupbys = ();
        foreach my $tnc (keys %tncs) {
            my $alias = $aliases->{$tnc};
            $tmpcols{"$alias $alias"} = 1;
            $groupbys{"$alias"} = 1;
        }
        %groupbys = prepend_table_name("$TMPTBL$tmptn", %groupbys);

        %selects = prepend_table_name("$TMPTBL$tmptn", %tmpcols);
        foreach my $tbl (@outertbls) {
            my $alias = $aliases->{"$tbl.rowid"};
            $tmpcols{"$alias $alias"} = 1;
            $selects{"min($tbl.rowid) $alias"} = 1;
        }

        @tables = ("$TMPTBL$tmptn");
        my %wheres = ();
        my %tblslookedup = ();
        my %tblsjoined = ();
        foreach my $t1 (@outertbls) {
            foreach my $t2 (keys %{$joins{$t1}}) {
               if ($tblsintmp{$t2}) { 
                   my $joincols = $joins{$t1}->{$t2};
                   foreach my $join (keys %$joincols) {
                       my ($c1, $c2, $junk, $tag)
                           = $join =~ /(\w+) (\w+)( (\w+))?/;
                       my $alias = $aliases->{"$t2.$c2"};
                       if (! $tag) {
                           $tblsjoined{$t1} = 1;
                           $wheres{"$t1.$c1 = $TMPTBL$tmptn.$alias"} = 1;
                       }
                   }
               } 
            }
        }

# Deal with lookups.  Could be prettier, but works.
# To limit the number of queries, the first lookup to a new table is done
# without creating another temporary table. 
        my %wheres2;
        my %whereslu;
        my %selects2;
        my @lookuptbls;
        foreach my $t1 (@outertbls) {
            foreach my $t2 (keys %{$joins{$t1}}) {
               if ($tblsintmp{$t2} || $tblsintmp{$t1}) { 
                   my $joincols = $joins{$t1}->{$t2};
                   foreach my $join (keys %$joincols) {
                       my ($c1, $c2, $junk, $tag)
                           = $join =~ /(\w+) (\w+)( (\w+))?/;
                       my $alias = $aliases->{"$t2.$c2"};
                       if ($tag) {
                           my $fo = get_field_object_from_tag($tag);
                           my ($lutag, $lutbl, $lucol) = $fo->get_names;
                           my $aliaslu = $aliases->{"$lutbl.$lucol $lutag"};
#warn "lookup $lutbl.$lucol $aliaslu where $t1.$c1 = $t2.$c2\n";

                           my $alias1 = $alias;
                           my $lucol2 = $c1;
                           if ($lutbl eq $t2) {
                               next unless $tblsintmp{$t1};
                               $lucol2 = $c2;
                               $alias1 = $aliases->{"$t1.$c1"};
                           } else {
                               next unless $tblsintmp{$t2};
                           }
                           if (! $tblslookedup{$t1}) {
# first lookup joining a new table, no need for another temporary.
                               $tblslookedup{$t1} = "$t2.$c2";
#                               $wheres{"$t1.$c1 = $TMPTBL$tmptn.$alias1"} = 1;
                               $whereslu{"$t1.$c1 = $TMPTBL$tmptn.$alias1"} = 1;
                           } else {
# table has been joined in a previous lookup, therefore make a query
# into a separate temporary table, and join that temporary table.
                               my $aliaslu2 = $aliases->{"$lutbl.$lucol2"};
                               $query = "select\n$lutbl.$lucol $aliaslu"
                                      . ",\n$lutbl.$lucol2 $aliaslu2";


#speeds up queries in cases where the looked up table has many rows
# by limiting the number of rows fetched to <= number in the main query.
                               foreach my $cond (keys %wheres) {
                                   if ($cond =~ /^$lutbl\./) {
                                       if ($query !~ /$TMPTBL$tmptn/) {
                                           $cond =~ /= (\w+\.(\w+))$/;
                                           $query .= ",\nmin($1) $2"
                                                   . "\nfrom $lutbl,"
                                                   . " $TMPTBL$tmptn"
                                                   . "\nwhere"
                                                   . "\n$cond";
                                       } else {
                                           $query .= "\nand $cond";
                                       }
                                   }
                               }
                               if ($query =~ /from $lutbl/) {
                                   $query .= "\ngroup by"
                                           . "\n$lutbl.$lucol,"
                                           . "\n$lutbl.$lucol2";
                               } else {
                                   $query .= "\nfrom $lutbl";
                               }



                               $query .= "\ninto temp "
                                       . "${TMPTBL}lu$tmptlun";
warn "$query;\n" if $::TRACE;
                               push @queries, $query;
                               $selects{"min(${TMPTBL}lu$tmptlun.rowid)"
                                              . " zlu$tmptlun"} = 1;
                               push @lookuptbls, "${TMPTBL}lu$tmptlun";
                               $whereslu{"${TMPTBL}lu$tmptlun.$aliaslu2"
                                       . " = $TMPTBL$tmptn.$alias1"} = 1;
                               my $tn = $tmptn + 1;
                               $selects2{$aliaslu} =
                                   "${TMPTBL}lu$tmptlun.$aliaslu $aliaslu";
                               $wheres2{"${TMPTBL}lu$tmptlun.rowid"
                                       . " = $TMPTBL$tn.zlu$tmptlun"} = 1;
                               $tmptlun++;
                           }
                       }
                   }
               } 
            }
        }
        %wheres = (%wheres, %whereslu);

        

        push @tables, @lookuptbls;
        push @tables, @outertbls;
        $query = "select\n" . join (",\n", keys %selects)
               . "\nfrom\n" . join (",\nouter ", @tables)
               . "\nwhere\n" . join ("\nand ", keys %wheres)
               . "\ngroup by\n" . join (",\n", keys %groupbys);
        $tmptn++;
        $query .= "\ninto temp $TMPTBL$tmptn";

warn "$query;\n" if $::TRACE;
        push @queries, $query;

#the query for the rows matching the rowids fetched in the previous
#query, which will put the results into a temporary table


        $more = 0;
        %wheres = %wheres2;
        @tables = ("$TMPTBL$tmptn");
        push @tables, @lookuptbls;
        push @tables, @outertbls;
        %selects = prepend_table_name("$TMPTBL$tmptn", %tmpcols);
        foreach my $t1 (@outertbls) {
            @colsa = $fl->get_columns($t1);
            for (my $i = 0; $i < @colsa; $i++) {
                if (defined $tblslookedup{$t1}
                    && $tblslookedup{$t1} eq "$t1.$colsa[$i]") {
                    splice (@colsa, $i, 1);
                    $i--;
                }
            }

            %cols = ();
            map { $cols{$_} = 1; } @colsa;
#warn "---> cols:\n" . join ("\n", keys %cols) . "\n";
            my %newtncs = prepend_table_name($t1, %cols);
            %tncs = (%tncs, %newtncs);
            %newtncs = append_aliases(%newtncs);
            %selects = (%selects, %newtncs);
            my $alias = $aliases->{"$t1.rowid"};
            $wheres{"$TMPTBL$tmptn.$alias = $t1.rowid"} = 1;
            $tblsintmp{$t1} = 1;
        }

#change some of the tables, for lookups
        foreach my $sel (keys %selects) {
            my ($alias) = $sel =~ / (\w+)$/;
            if ($selects2{$alias}) {
                delete $selects{$sel};
                $selects{$selects2{$alias}} = 1;
            }
        }

        my @newoutertbls;
        foreach my $t1 (keys %tblsjoined) {
            foreach my $t2 (keys %{$joins{$t1}}) {
               unless ($tblsintmp{$t2}) {
                   $more = 1;
                   push @newoutertbls, $t2;
               }
            }
        }
        @outertbls = @newoutertbls;



        $query = "select\n" . join (",\n", keys %selects)
               . "\nfrom\n" . join (",\nouter ", @tables)
               . "\nwhere\n" . join ("\nand ", keys %wheres);

        $tmptn++;

    }

    my $tn = $tmptn - 1;
    if ($tn > $stmptn) {
        my $alias = $aliases->{"$current_tbl.rowid"};
        $query .= "\norder by $TMPTBL$tn.$alias";
#    } else {
#        $query .= "\norder by $current_tbl.rowid";
    }
    push  @queries, $query;

warn "$query\n" if $::TRACE;
warn "values for 1st query:\n" . join ("\n", @vals) . "\n" if $::TRACE;

# compute indexes with final query
    $query =~ s/\nfrom (.|\n)*$//;
    $query =~ s/^select\n//;
    my %ialiases;
    my $i = 0;
    while ($query =~ s/\w+\.\w+ (\w+),?\n?//) {
        $ialiases{$1} = $i;
        $i++;
    }
    %{$RowList->{aliases}} = %ialiases;


    return ($tmptn, $tmptlun, $query_count, \@queries, \@vals);
}


sub do_query {
    my ($tmptn, $tmptlun, $query_count, $qref, $vref) = create_query;
    my @queries = @$qref;
    my @vals = @$vref;
    my $TMPTBL       = "pf_tmp";

warn "values for 1st query:\n" . join ("\n", @vals) . "\n" if $::TRACE;
#execute the queries

    my $err = $GlobalUi->{error_messages};
    $GlobalUi->display_status( $err->{'se09.'} );
    Curses::refresh(curscr);

    my $errmsg;
    for (my $i = 0; $i < $#queries; $i++) {
        my $sth = $DB->prepare($queries[$i]);
        if ($sth) {
            my $result;
            if ($i == 0 && @vals) {
                $result = $sth->execute(@vals);
            } else {
                $result = $sth->execute;
            }
            if (!defined $result) {
                $errmsg = $DBI::errstr;
                last;
            }
        }
        else {
            $errmsg = $DBI::errstr; # =~ /SQL:[^:]*:\s*(.*)/;
#            warn "ERROR:\n$DBI::errstr\noccurred after\n$queries[$i]\n";
            last;
        }
        $GlobalUi->display_status( $err->{'se10.'} );
        Curses::refresh(curscr);
    }

    my $form    = $GlobalUi->get_current_form;
    my $subform = $form->getSubform('DBForm') || $form;
    execute_query( $subform, $query_count, $queries[$#queries], \@vals );

# drop temporary tables
    my @drops;
    my $tn = $tmptn - 1;
    while ($tn >= $stmptn) {
        push @drops, "drop table $TMPTBL$tn";
        $tn--;
    }
    for (my $i = $tmptlun; $i >= $stmptlun ; $i--) {
        push @drops, "drop table ${TMPTBL}lu$i";
    }

    for (my $i = $#drops; $i >= 0; $i--) {
        my $sth = $DB->prepare($drops[$i]);
        if ($sth) {
            $sth->execute;
        }
#        else {
#            warn "ERROR:\n$DBI::errstr\noccurred after\n$drops[$i]\n";
#        }
    } 

    $stmptn = $tmptn;
    $stmptlun = $tmptlun;

    $GlobalUi->display_error($errmsg) if $errmsg;
warn "leaving do_query\n" if $::TRACE;
}

sub query_condition {
    my ( $tbl, $col, $val ) = @_;
    my $err = $GlobalUi->{error_messages};

    #warn "parms = :$tbl:$col:$val:\n";
    # Determine what kind of comparison should be done

    my $op    = '=';
    my $cval  = $val;
    my @cvals = ();

    if ( $val eq '=' ) { $op = 'is null'; $cval = undef; }
    elsif ( $val =~ /^\s*(<<|>>)(.*?)$/ ) {
        $cval = query_condition_minmax($tbl, $col, $val);
    }
    elsif ( $val =~ /^\s*(([<>][<=>]?)|!?=)(.*?)$/ ) {
        $op   = $1;
        $cval = $3;
    }
    elsif ( $val =~ /^(.+?):(.+)$/ ) {
        $op = "between ? and ";
        push( @cvals, $1 );
        $cval = $2;
    }
    elsif ( $val =~ /^(.+?)\|(.+)$/ ) {    # might should use in ($1,$2)
        $op = "= ? or $col = ";
        push( @cvals, $1 );
        $cval = $2;
    }
    # SQL wildcard characters
    elsif ( $val =~ /[*%?]/ ) { $cval =~ tr/*?/%_/; $op = 'like'; }

    my $where = "$tbl.$col $op" . ( defined($cval) ? ' ?' : '' );
    push( @cvals, $cval ) if defined($cval);
    return ( $where, \@cvals );
}

#To handle min/max, do a query, then add
# the results to the where clause.  Ex, if asking for '>>' from
# table and column 't.c', then the query here is:
# select max(t.c) from t
# If the result of that query is '41', then we add this to the wheres:
# t.c = 41
sub query_condition_minmax {
    my $tbl = shift;
    my $col = shift;
    my $qc  = shift;

    my $mm = 'max';
    $mm = 'min' if $qc =~ /<</;

    my $query = "select $mm($tbl.$col) from $tbl";

    my $sth = $DB->prepare($query);
    if ($sth) {
        $sth->execute;
    }
    else {
        warn "$DBI::errstr\n";
    }
    my $ref = $sth->fetchrow_array;
warn "query condition min/max is $ref\n" if $::TRACE;
    return $ref;
}

sub execute_query {
    my $subform       = shift;
    my $query_count   = shift;
    my $query         = shift;
    my $vals          = shift;
    my $app           = $GlobalUi->{app_object};
    my $current_table = $GlobalUi->get_current_table_name;
    my $err           = $GlobalUi->{error_messages};

warn "entering execute_query\n" if $::TRACE;
    $GlobalUi->display_status( $err->{'se11.'} );
    Curses::refresh(curscr);

    # update row list
    my $row = $RowList->stuff_list( $DB, $query_count, $query, $vals );
    my $size = $RowList->list_size;

    # Print outcome of query to status bar
    if    ( $size == 0 ) { $GlobalUi->display_status('no11d'); }
    elsif ( $size == 1 ) { $GlobalUi->display_status('1_8d'); }
    else {
        my $msg = sprintf($err->{'ro7d'}, $size);
        $GlobalUi->display_status($msg);
    }

    #execute any instructions triggered after a query
    trigger_ctrl_blk( 'after', 'query', $current_table );

    # display the first table
    display_row( $subform, $row );

    # change focus to the user interface
    $GlobalUi->change_mode_display( $subform, 'perform' );

    warn "TRACE: leaving execute_query\n" if $::TRACE;
    return  $size;
}

sub next_alias {
    my $i = shift;
    my $reserved_words =
        'ada|add|all|and|any|are|asc|avg|bit|bor|day|dec'
      . '|end|eqv|for|get|iif|imp|int|key|lag|map|max|min'
      . '|mod|mtd|new|non|not|off|old|out|pad|qtd|ref|row'
      . '|set|sql|sum|top|use|var|wtd|xor|yes|ytd';
    my $alias;
        do {
            $alias =
                chr( $i / ( 26 * 26 ) + ord('a') )
              . chr( ( $i / 26 ) % 26 + ord('a') )
              . chr( $i % 26 + ord('a') );
            $i++;
        } while ( $alias =~ /$reserved_words/ );
    return ($alias, $i);
}

sub generate_query_aliases {
    my $app = $GlobalUi->{app_object};

    my $fl = $GlobalUi->get_field_list;
    $fl->reset;
    my $i = 0;
    my $j = 0; #(25 * 10) + 9;
    my $alias;
    my %aliases;

    while ( my $fo = $fl->iterate_list ) {
        next if $fo->{displayonly};
        ($alias, $i) = next_alias($i);
        my ( $tag, $tbl, $col ) = $fo->get_names;
	if (defined $fo->{subscript_floor} && defined $aliases{"$tbl.$col"}) {
	    $i--;
	    $alias = $aliases{"$tbl.$col"};
	}
        $aliases{"$tbl.$col"} = $alias;
        $aliases{"$tbl.$col $tag"} = $alias;
        if (defined $fo->{join_table}) {
            $tbl = $fo->{join_table};
            $col = $fo->{join_column};
            unless (defined $aliases{"$tbl.$col $tag"}) {
                ($alias, $i) = next_alias($i);
                $aliases{"$tbl.$col $tag"} = $alias;
                $aliases{"$tbl.$col"} = $alias;
            }
        }
        unless (defined $aliases{"$tbl.rowid"}) {
            $alias = 'z'
              . chr( $j / 10 + ord('0') )
              . chr( $j % 10 + ord('0') );
            $j++;
            $aliases{"$tbl.rowid"} = $alias;
        }
    }
#warn Data::Dumper->Dump([%aliases], ['aliases']);
    $app->{aliases} = \%aliases;
}

sub do_subscript {
    my ($fo, $str) = @_;
    my $min = $fo->{subscript_floor}-1;
    my $max = $fo->{subscript_ceiling}-1;
    my $tag = $fo->get_field_tag;
    my $v = $GlobalUi->get_screen_value($tag);
    $str = '' if !defined $str;
    $v   = '' if !defined $v;
    my @chars = split //, $str;
    my @vcs   = split //, $v;
    my $max2 = $min + length $v;
    $max = $max2 if $max > $max2;
    my $i = $max;
    if ($v ne '') {
        for (; $i >= $min; $i--) {
            $chars[$i] = $vcs[$i-$min];
        }
    }
    for ($i = $max; $i >= 0; $i--) {
	$chars[$i] = ' ' if !defined $chars[$i] || $chars[$i] eq '';
    }
    $str = join ('', @chars);
    $str =~ s/\s+$//;
#warn ":$v: is $min to $max of str =\n:$str:\n";
    return $str;
}

sub do_add {
    my ( $field, $widget, $subform ) = @_;

    warn "TRACE: entering do_add\n" if $::TRACE;

    my $app           = $GlobalUi->{app_object};
    my $current_table = $GlobalUi->get_current_table_name;
    my $driver        = $DB->{'Driver'}->{'Name'};
    my $fl            = $GlobalUi->get_field_list;
    my $fo            = $fl->get_field_object( $current_table, $field );

    my ( %ca, $row, $msg );
    $GlobalUi->change_mode_display( $subform, 'add' );
    $GlobalUi->update_subform($subform);

    # First test the input of the current field

    my $v = $fo->get_value;
    my $rc = $fo->validate_input( $v, 'add' );
    return if $rc != 0;

    generate_query_aliases();

    return if !verify_composite_joins();

    my %vals;
    # test the subform as a whole
    $fl->reset;
    while ( $fo = $fl->iterate_list ) {
        my ( $tag, $tbl, $col ) = $fo->get_names;
        next if $tbl ne $current_table;    # FIX: single table adds...?

        my $v = $fo->get_value;
        next if $fo->is_serial || defined( $fo->{displayonly} );

 	# special handling for subscript attribute
        if (   defined $fo->{subscript_floor}) {
	    $vals{$col} = do_subscript($fo, $vals{$col});
            next;
        }
	else {
	    $rc = $fo->format_value_for_database( 'add', undef );
	    my $v2 = $fo->get_value;
	}
	return $rc if $rc != 0;

        # add col and val for the sql add

	if (defined $v) {
            $ca{$col} = $v if $v ne '';
	}
    }

    foreach my $col (keys %vals) {
        $ca{$col} = $vals{$col} if $vals{$col} ne '';
    }

    # insert to db

    my ( $serial_val, $serial_fo, $serial_col );
    undef $rc;

    my $holders = join ', ', map { "?" } keys %ca;
    my $cols = join ', ', keys %ca;

    my $cmd = "insert into $current_table ($cols) values ($holders)";
    my $sth = $DB->prepare($cmd);

    if ($sth) {
        $rc = $sth->execute(values %ca);
    }
    else {
        my $m = $GlobalUi->{error_messages}->{'ad21e'};
        $GlobalUi->display_error($m);
    }
    if ( $driver eq "Informix" ) {
        $serial_fo  = $fl->get_serial_field;       # returns one field or undef
        $serial_col = $serial_fo->{column_name};
        $serial_val = $sth->{ix_sqlerrd}[1];       # get db supplied value

        if ( defined($serial_val) && defined($serial_col) ) {

            $serial_fo->set_value($serial_val);
            $GlobalUi->set_screen_value( $serial_col, $serial_val );
        }
    }
    else { warn "$driver serial values not currently supported"; }

    if ( !defined $rc ) {
        my $m = ": $DBI::errstr";
        $GlobalUi->display_comment('db16e');
        $GlobalUi->display_error($m);
        $GlobalUi->change_mode_display( $subform, 'add' );
        return;
    }

    # refreshes the values on the screen after add
    my $refetcher = $INSERT_RECALL{$driver} || \&Default_refetch;
    if ( defined($refetcher) ) {
        $row = &$refetcher( $sth, $current_table );
    }
    if ( defined($row) ) {
        $RowList->add_row($row);
        display_row( $subform, $RowList->current_row );
        $msg = $GlobalUi->{error_messages}->{'ro6d'};
        $GlobalUi->display_status($msg);
        trigger_ctrl_blk( 'after', 'add', $current_table );
    }
    else {
        $msg = $GlobalUi->{error_messages}->{'fa39e'};
        $GlobalUi->display_error($msg);
    }
    $subform->setField( 'EXIT', 1 );    # back to menu
    $GlobalUi->change_mode_display( $subform, 'perform' );

    warn "TRACE: leaving do_add\n" if $::TRACE;
    return undef;
}

sub do_update {
    my $field   = shift;
    my $widget  = shift;
    my $subform = shift;

    return if !verify_composite_joins();

    my $app       = $GlobalUi->{app_object};
    my $form      = $GlobalUi->{form_object};
    my $fl        = $GlobalUi->get_field_list;
    my $table     = $GlobalUi->get_current_table_name;
#    my $singleton = undef;

    my %wheres = ();
    my %upds   = ();

    my $aliases      = $app->{'aliases'};
    my %aliased_upds = ();
    my $cur_row      = $RowList->current_row;

    $GlobalUi->change_mode_display( $form, 'update' );
    $GlobalUi->update_subform($subform);
    $GlobalUi->change_mode_display( $subform, 'update' );

    my %vals;
    my %sstags;
    $fl->reset;
    while ( my $fo = $fl->iterate_list ) {
        my ( $tag, $tbl, $col ) = $fo->get_names;
        next if $tbl ne $table;    # guess...

        # reexamine the placement of this test
        next if !( $fo->allows_focus('update') );

        my $tnc   = "$tbl.$col";
        my $alias = $aliases->{$tnc};
#        next unless defined $cur_row->{$alias};
        my $idx   = $RowList->{aliases}->{$alias};
#warn "do_upd: $tnc -> $alias -> $idx\n" if $::TRACE;
        my $fv = $cur_row->[$idx];
#        next unless defined $fv;
        $fv = '' unless defined $fv;
#warn "do_upd: field val = $fv\n" if $::TRACE;

        # get value from field
        my $v  = $fo->get_value;
        my $rc = 0;

#        my $rc = $fo->validate_input( $v, 'update' );
#        return if $rc != 0;

#        # special handling for subscript attribute
        if (   defined $fo->{subscript_floor}) {
	    $vals{$tnc} = do_subscript($fo, $vals{$tnc});
            push @{$sstags{$tnc}}, $tag;
            next;
        }
        else {
            $rc = $fo->format_value_for_database( 'update', undef );
        }
        return $rc if $rc != 0;

        # add col and val for the sql add

#        my $fv = $cur_row->{$alias} if defined $alias;

#warn "$tag $col $alias\n:$v:\n:$fv:\n";
        if ( $v ne $fv ) {
            $upds{$col}           = $v;
            $aliased_upds{$alias} = $v;
        }

    }
#    $fl->print_list;

#strings composed of substrings
    foreach my $tnc (keys %vals) {
        my $alias = $aliases->{$tnc};
        my ($col) = $tnc =~ /\.(\w+)/;
        my $idx = $RowList->{aliases}->{$alias};
        my $fv = $cur_row->[$idx];
        my $v = $vals{$tnc};
#warn "$tnc = :$v:$fv\n";
        my $dv = defined $v ? 1 : 0;
        my $dfv = defined $fv ? 1 : 0;
        if (($dv && $dfv && $v ne $fv)
	    || ($dv ^ $dfv) ) {
            $upds{$col}           = $v;
            $aliased_upds{$alias} = $v;
            foreach my $tag (@{$sstags{$tnc}}) {
                $alias = $aliases->{"$tnc $tag"};
#warn "alias of $tag $tnc is $alias\n";
                $aliased_upds{$alias} = $v;
            }
        }
    } 

    my @updcols = keys(%upds);
    if ( @updcols == 0 ) {
        $GlobalUi->display_status('no14d');
        $GlobalUi->change_mode_display( $form, 'update' );
        return;
    }
    my @updvals;
    for (my $i = 0; $i <= $#updcols; $i++) {
	if ($upds{$updcols[$i]} eq '') {
	    $updcols[$i] .= ' = NULL';
        } else {
	    push @updvals, $upds{$updcols[$i]};
	    $updcols[$i] .= ' = ?';
	}
    }
    my $sets = join( ', ', @updcols);
    warn "updcols: [@updcols]" if $::TRACE_DATA;

    my $ralias = $aliases->{"$table.rowid"};
#    my @wherevals = ( $cur_row->{$ralias} );
    my $ridx = $RowList->{aliases}->{$ralias};
    my @wherevals = ( $cur_row->[$ridx] );
    my $cmd       = "update $table set $sets where rowid = ?";
    warn "cmd: [$cmd]"       if $::TRACE_DATA;
    warn "ud: [@updvals]"    if $::TRACE_DATA;
    warn "whv: [@wherevals]" if $::TRACE_DATA;

    my $rc = $DB->do( $cmd, {}, @updvals, @wherevals );
    if ( !defined $rc ) {

        # display DB error string
        my $m1 = $GlobalUi->{error_messages}->{'db16e'};
        my $m2 = ": $DBI::errstr";
        $GlobalUi->display_comment($m1);
        $GlobalUi->display_error($m2);
        $GlobalUi->change_mode_display( $form, 'update' );
        return;
    }
    else {

        # refreshes the values on the screen after update
        my $driver        = $DB->{'Driver'}->{'Name'};
        my $refetcher = $INSERT_RECALL{$driver} || \&Default_refetch;
        my $sth;
        my $row;
        if ( defined($refetcher) ) {
            $row =
              &$refetcher( $sth, $table );
        }

        my $m = $GlobalUi->{error_messages}->{'ro10d'};
        $m = ( 0 + $rc ) . " " . $m;
        $GlobalUi->display_status($m);

        # Since the new value is now in, change the where value...
        my $tmp = $RowList->current_row;

        map { $tmp->[$RowList->{aliases}->{$_}] = $aliased_upds{$_}; }
          keys %aliased_upds;
        for (my $i = $#$row; $i >= 0; $i--) {
            $tmp->[$i] = $row->[$i] if defined $row->[$i];
        }
        trigger_ctrl_blk( 'after', 'update', $table );
        display_row( $subform, $RowList->current_row );
    }
    $subform->setField( 'EXIT', 1 );    # back to menu
    $GlobalUi->change_mode_display( $subform, 'perform' );
}

sub display_row {
    my $form = shift;
    my $row  = shift;

    warn "TRACE: entering display_row\n" if $::TRACE;

#warn Data::Dumper->Dump([$row], ['row']);
    return if !$row;
    my $app     = $GlobalUi->{app_object};
    return if $app->{deletedrow};

    my $subform    = $form->getSubform('DBForm') || $form;
    my %table_hash = ();
    my %field_hash = ();
    my @ofs;
    my $aliases = $app->{aliases};
    my $sl      = $GlobalUi->get_field_list;

    my %ft = table_fields($GlobalUi->get_current_table_name);

    $sl->reset;
    while ( my $fo = $sl->iterate_list ) {
        my ( $tag, $table, $col ) = $fo->get_names;
        next if !defined $ft{$tag};
        my $tnc = "$table.$col";

        @ofs = ();
#        if ( defined $table ) {
            push @ofs, $tnc;
            if ( ! $table_hash{$table} ) {
                $table_hash{$table} = 1;
                push @ofs, $table;
            }
#        }
        push @ofs, $col;
        trigger_ctrl_blk( 'before', 'display', @ofs );

        my $alias = $aliases->{$tnc};
        my $alias2 = $aliases->{"$tnc $tag"} || '';
        my $idx;
        if ($alias2) {
            $idx = $RowList->{aliases}->{$alias2};
        }
        if ((!$alias2 || !defined $idx) && $alias) {
            $idx = $RowList->{aliases}->{$alias};
        }
#warn "index = $idx\n" if defined $idx;
        my $val;
        $val = $row->[$idx] if defined $idx;
        if ( !defined $field_hash{$tag} || defined $val ) {
	    $val = '' if !defined $val;
            $field_hash{$tag} = $val;

            my $pos = 0;
            my $rc;
#my $warnstr = "display: $tag $table.$col";
#$warnstr .= " $alias" if defined $alias;
#$warnstr .= " $alias2\n" if defined $alias2;
#my $tmp = $fo->{type} || '';
#$warnstr .= "$tmp";
#$tmp = $fo->{db_type} || '';
#$warnstr .= " $tmp";
#$tmp = $fo->{display_only_type} || '';
#$warnstr .= " $tmp\n";
#$warnstr .= "$val:\n" if defined $val;
#warn $warnstr;
            ( $val, $rc ) = $fo->format_value_for_display( $val );
            $GlobalUi->set_screen_value( $tag, $val );

            @ofs = ();
            push @ofs, $tnc if defined $table;
            push @ofs, $col;
            trigger_ctrl_blk( 'after', 'display', @ofs );
        }
    }

    $sl->reset;
    while ( my $fo = $sl->iterate_list ) {
        my $tag = $fo->{field_tag};
        my $val = $field_hash{$tag};
#        $fo->set_value($val) if defined $val;
        $fo->{value} = $val if defined $val;
    }

    $app->{fresh} = 1;
    @ofs = keys %table_hash;
    trigger_ctrl_blk( 'after', 'display', @ofs );

    warn "TRACE: leaving display_row\n" if $::TRACE;
}

#  Post-Add/Update refetch functions:
sub Pg_refetch {
    my $sth   = shift;
    my $table = shift;

    my $oid = $sth->{'pg_oid_status'};
    my $row = $DB->selectrow_hashref("select * from $table where oid='$oid'");
    return $row;
}

sub Informix_refetch {
    my $sth    = shift;    # statement handle
    my $table  = shift;    # table to query
#    my $cols   = shift;    # columns to query
#    my $vals   = shift;    # values to query
#    my $fld    = shift;    # serial field name
#    my $serial = shift;    # serial field value

    warn "entering Informix_refetch\ntable = $table\n" if $::TRACE;

    my $aliases = $GlobalUi->{app_object}->{aliases};
    create_query if !$RowList->{aliases};
    my $rowid   = $sth->{ix_sqlerrd}[5];
    if (! $rowid) {
        my $alias = $aliases->{"$table.rowid"};
        my $cur_row = $RowList->current_row;
        my $idx = $RowList->{aliases}->{$alias};
        $rowid = $cur_row->[$idx];
    }
    my %selects;
    foreach my $tnct ( keys %$aliases ) {
        my ($tnc, $t) = $tnct =~ /^((\w+)\.\w+)/;
        my $alias = $aliases->{$tnct};
        $selects{"$tnc $alias"} = 1 if ( $t eq $table );
    }
    my $select = join (",\n", keys %selects);

    my ( $lsth, $query, $row );
    $query = "SELECT\n$select\nFROM $table WHERE rowid = $rowid";
    warn "refetch query =\n$query\n" if $::TRACE;
    $lsth = $DB->prepare($query);
    if ($lsth) {
        my $row_hash = $DB->selectrow_hashref( $query, {} );
        foreach my $alias (keys %$row_hash) {
            my $idx = $RowList->{aliases}->{$alias};
            $row->[$idx] = $row_hash->{$alias} if defined $idx;
        }
    }

    return $row if defined($row);
    return undef;
}

# not tested
sub Oracle_refetch {
    my $sth   = shift;    # statement handle; ignored.
    my $table = shift;    # table to query
    my $cols  = shift;    # columns to query
    my $vals  = shift;    # values to query

    my $wheres = join ' AND ', map { "$_ = ?" } @$cols;
    my $query = "SELECT * FROM $table WHERE $wheres";

    # prepare is skipped in selectrow_hashref for Oracle?
    $sth = $DB->prepare($query);
    my $row = $DB->selectrow_hashref( $query, {}, @$vals );

    return $row;
}

# When we don't know how to get the row-ID or similar marker, just query
# on all the values we know...
sub Default_refetch {
    my $sth   = shift;    # statement handle; ignored.
    my $table = shift;
    my $cols  = shift;    # columns to query
    my $vals  = shift;    # values to query

    my $wheres = join ' AND ', map { "$_ = ?" } @$cols;
    my $query  = "SELECT * FROM $table WHERE $wheres";
    my $row    = $DB->selectrow_hashref( $query, {}, @$vals );
    return $row;
}

# What a kludge...  required by Curses::Application
package main;

1;
__DATA__
%forms = ( DummyDef => {} );


__END__


# need to update the pod once the features are in place


=head1 NAME

DBIx::Perform - Informix Perform(tm) emulator

=head1 SYNOPSIS

On the shell command line: 

=over

export DB_CLASS=[Pg|mysql|whatever] DB_USER=usename DB_PASSWORD=pwd

[$install-bin-path/]generate dbname tablename  > per-file-name.per

[$install-bin-path/]perform per-file-name.per  (or pps-file-name.pps)

=back

Or in perl, with the above environment settings:

=over

  DBIx::Perform::run ($filename_or_description_string);

=back

=head1 ABSTRACT

Emulates the Informix Perform character-terminal-based database query
and update utility.  

=head1 DESCRIPTION

The filename given to the I<perform> command may be a Perform
specification (.per) file.  The call to the I<run> function may be a
filename of a .per file or of a file pre-digested by the
DBIx::Perform::DigestPer class (extension .pps).  [Using
pre-digested files does not appreciably speed things up, so this
feature is not highly recommended.]

The argument to the I<run> function may also be a string holding the
contents of a .per or .pps file, or a hash ref with the contents of a
.pps file (keys db, screen, tables, attrs).

The database named in the screen spec may be a DBI connect argument, or
just a database name.  In that case, the database type is taken from
environment variable DB_CLASS.  The username and password are taken from
DB_USER and DB_PASSWORD, respectively.

Supports the following features of Informix's Perform:

 Field Attributes: COLOR, NOENTRY, NOUPDATE, DEFAULT, UPSHIFT, DOWNSHIFT,
		   INCLUDE, COMMENTS, NOCOMPARE.
	NOCOMPARE is an addition of ours for a hack of updating a
	sequence's next value in Postgres.  A field marked NOCOMPARE
	is never included in the WHERE clause in an Update.

 2-table Master/Detail  (though no query in detail mode)

 VERY simple control blocks (nextfield= and let f1 = f2 op f3-or-constant)
 
=head1  COMMANDS

The first letter of each item on the button menu can be pressed.

Q = query.  Enter values to match in fields to match.  Field values
	may start with >, >=, <, <=, contain val1:val2 or val1|val2
	or end with * (for wildcard suffix).  Value of the "=" sign 
	matches a null value.  The ESC key queries; Ctrl-C aborts.

A = add.  Enter values for the row to add.  ESC or Ctrl-C when done.

U = update.  Edit row values.  ESC or Ctrl-C when done.  

R = remove.  NO CONFIRMATION!  BE CAREFUL USING THIS!

E = exit.

M / D = Master / Detail screen when a MASTER OF relationship exists between
	two tables.


=head1  REQUIREMENTS

Curses Curses::Application Curses::Forms Curses::Widgets

DBI  and DBD::whatever

Note: For the B<generate> function / script to work, the DBD driver
must implement the I<column_info> method.

=head1   ENVIRONMENT VARIABLES

DB_CLASS	this goes into the DBI connect string.  NOTE: knows how
		to prefix database names for Pg and mysql but not much else.

DB_USER		User name for DBI->connect.

DB_PASSWORD	Corresponding.

BGCOLOR		One of eight Curses-known colors for form background
    		(default value is 'black').

FIELDBGCOLOR	Default field background color (default is 'blue').
    		Fields' background colors may be individually overridden
		by the "color" attribute of the field.

Note, any field whose background matches the form background gets
displayed with brackets around it:   [field_here] .

=head1	FUNDING CREDIT

Development of DBIx::Perform was generously funded by Telecom
Engineering Associates of San Carlos, CA, a full-service 2-way radio
and telephony services company primarily serving public-sector
organizations in the SF Bay Area.  On the web at
http://www.tcomeng.com/ .  (do I sound like Frank Tavares yet?)

=head1 AUTHOR

Eric C. Weaver  E<lt>weav@sigma.netE<gt> 
Brenton Chapin  E<lt>chapinb@acm.orgE<gt>

=head1 COPYRIGHT AND LICENSE and other legal stuff

Copyright 2003 by Eric C. Weaver and 
Daryl D. Jones, Inc. (a California corporation).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

INFORMIX and probably PERFORM is/are trademark(s) of
IBM these days.

=cut
