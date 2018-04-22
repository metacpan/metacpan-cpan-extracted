package # hide from PAUSE
App::DBBrowser::CreateTable;

use warnings;
use strict;
use 5.008003;
no warnings 'utf8';

our $VERSION = '2.014';

use File::Basename qw( basename );
use List::Util     qw( none any );

use Term::Choose       qw( choose );
use Term::Choose::Util qw( choose_a_number );
use Term::Form         qw();
use Term::TablePrint   qw( print_table );

use if $^O eq 'MSWin32', 'Win32::Console::ANSI';

use App::DBBrowser::Auxil;
use App::DBBrowser::DB;
use App::DBBrowser::Opt;
use App::DBBrowser::Table;
#use App::DBBrowser::Table::Insert; # "require"(d)


sub new {
    my ( $class, $info, $options, $data ) = @_;
    bless {
        i => $info,
        o => $options,
        d => $data
    }, $class;
}


sub delete_table {
    my ( $sf ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $sql = {};
    $ax->reset_sql( $sql );
    my $prompt = $sf->{d}{db_string} . "\n" . 'Drop table';
    # Choose
    my $table = choose( #
        [ undef, map { "- $_" } @{$sf->{d}{user_tables}} ],
        { %{$sf->{i}{lyt_3}}, prompt => $prompt }
    );
    if ( ! defined $table || ! length $table ) {
        return;
    }
    $table =~ s/\-\s//;
    $sql->{table} = $ax->quote_table( $sf->{d}{tables_info}{$table} );
    my $Drop_table = 'Drop_table';
    $ax->print_sql( $sql, [ $Drop_table ] );
    my $prompt = 'Choose:';
    # Choose
    my $ok = choose( #
        [ undef, $sf->{i}{_confirm} . ' Stmt'],
        { %{$sf->{i}{lyt_stmt_v}}, prompt => $prompt }
    );
    if ( ! $ok ) {
        return;
    }
    my $sth = $sf->{d}{dbh}->prepare( "SELECT * FROM " . $sql->{table} );
    $sth->execute();
    my $col_names = $sth->{NAME}; # mysql: $sth->{NAME} before fetchall_arrayref
    my $all_arrayref = $sth->fetchall_arrayref;
    my $row_count = @$all_arrayref;
    unshift @$all_arrayref, $col_names;
    if ( @$all_arrayref > 1 ) {
        my $prompt_pt = "Table to be deleted: $sql->{table}\n";
        print_table( $all_arrayref, { %{$sf->{o}{table}}, prompt => $prompt_pt, max_rows => 0, keep_header => 0 } ); #
    }
    $prompt = sprintf 'DROP TABLE %s  (%d %s)', $sql->{table}, $row_count, $row_count == 1 ? 'row' : 'rows';
    $prompt .= "\n\nCONFIRM:";
    # Choose
    my $choice = choose( #
        [ undef, 'YES' ],
        { %{$sf->{i}{lyt_m}}, prompt => $prompt, undef => 'NO', clear_screen => 1 }
    );
    if ( defined $choice && $choice eq 'YES' ) {
        my $stmt = $ax->get_stmt( $sql, $Drop_table, 'prepare' );
        $sf->{d}{dbh}->do( $stmt ) or die "$stmt failed!";
        return 1;
    }
    return;
}


sub create_new_table {
    my ( $sf ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $sql = {};
    $ax->reset_sql( $sql );
    my @cu_keys = ( qw/create_table_plain create_table_form_copy create_table_form_file settings/ );
    my %cu = ( create_table_plain      => '- plain',
               create_table_form_copy  => '- Copy & Paste',
               create_table_form_file  => '- From File',
               settings                => '  SETTINGS'
    );
    my $old_idx = 0;

    MENU: while ( 1 ) {
        $sql->{table} = '';
        $sql->{insert_into_args} = [];
        $sql->{insert_into_cols} = [];
        $sql->{create_table_cols} = [];
        my $stmt_typeS = [ 'Create_table' ];
        my $choices = [ undef, @cu{@cu_keys} ];
        my $prompt = $sf->{d}{db_string} . "\n" . 'Create table';
        # Choose
        $ENV{TC_RESET_AUTO_UP} = 0;
        my $idx = choose(
            $choices,
            { %{$sf->{i}{lyt_3}}, index => 1, default => $old_idx, prompt => $prompt }
        );
        if ( ! defined $idx || ! defined $choices->[$idx] ) {
            return;
        }
        my $custom = $choices->[$idx];
        if ( $sf->{o}{G}{menu_memory} ) {
            if ( $old_idx == $idx && ! $ENV{TC_RESET_AUTO_UP} ) {
                $old_idx = 0;
                next MENU;
            }
            $old_idx = $idx;
        }
        delete $ENV{TC_RESET_AUTO_UP};
        if ( $custom eq $cu{settings} ) {
            my $opt = App::DBBrowser::Opt->new( $sf->{i}, $sf->{o} );
            $opt->config_insert();
            next MENU;
        }
        $sf->{auto_inc_col_name} = $sf->{d}{driver} eq 'SQLite' ? $sf->{o}{create}{auto_inc_col_name} : '';
        if ( $custom eq $cu{create_table_plain} ) {
            $sql->{insert_into_args} = [];
        }
        elsif ( $custom eq $cu{create_table_form_copy} ) {
            push @$stmt_typeS, 'Insert';
            require App::DBBrowser::Table::Insert;
            my $tbl_in = App::DBBrowser::Table::Insert->new( $sf->{i}, $sf->{o}, $sf->{d} );
            my $ok = $tbl_in->from_copy_and_paste( $sql, $stmt_typeS );
            if ( ! $ok ) {
                next MENU;
            }
        }
        elsif ( $custom eq $cu{create_table_form_file} ) {
            push @$stmt_typeS, 'Insert';
            require App::DBBrowser::Table::Insert;
            my $tbl_in = App::DBBrowser::Table::Insert->new( $sf->{i}, $sf->{o}, $sf->{d} );
            my $file_name = $tbl_in->from_file( $sql, $stmt_typeS );
            if ( ! $file_name ) {
                next MENU;
            }
            $sf->{d}{file_name} = $file_name;
        }

        my $ok_table_name = $sf->__set_table_name( $sql, $stmt_typeS );
        if ( ! $ok_table_name ) {
            next MENU;
        }
        $ax->print_sql( $sql, $stmt_typeS );

        my $ok_columns = $sf->__set_columns( $sql, $stmt_typeS );
        if ( ! $ok_columns ) {
            next MENU;
        }
        if ( any { ! length } @{$sql->{insert_into_cols}} ) {
            die "Column with no name!";
        }
        $sql->{insert_into_cols} = $ax->quote_simple_many( $sql->{insert_into_cols} );
        $sql->{create_table_cols} = [ @{$sql->{insert_into_cols}} ];
        $ax->print_sql( $sql, $stmt_typeS );

        my $ok_data_types = $sf->__set_data_types( $sql, $stmt_typeS );
        if ( ! $ok_data_types ) {
            next MENU;
        }

        # Create table
        my $qt_table = $sql->{table};
        $ax->print_sql( $sql, $stmt_typeS );
        # Choose
        my $create_table_ok = choose(
            [ undef, 'YES' ],
            { %{$sf->{i}{lyt_m}}, prompt => "Create table $qt_table?", undef => 'NO', index => 1 }
        );
        if ( ! defined $create_table_ok || ! $create_table_ok ) {
            next MENU;
        }
        my $stmt = $ax->get_stmt( $sql, 'Create_table', 'prepare' );
        $sf->{d}{dbh}->do( $stmt ) or die "$stmt failed!";
        delete $sql->{create_table_cols};
        my $sth = $sf->{d}{dbh}->prepare( "SELECT * FROM $qt_table LIMIT 0" );
        $sth->execute() if $sf->{d}{driver} ne 'SQLite';
        if ( $stmt_typeS->[-1] eq 'Insert' ) {
            $stmt_typeS = [ $stmt_typeS->[-1] ];
            my @columns = @{$sth->{NAME}};
            $sth->finish();
            if ( length $sf->{auto_inc_col_name} ) {
                shift @columns;
            }
            $sql->{insert_into_cols} = $ax->quote_simple_many( \@columns );
            my $tbl = App::DBBrowser::Table->new( $sf->{i}, $sf->{o}, $sf->{d} );
            my $commit_ok = $tbl->commit_sql( $sql, $stmt_typeS );
        }
        return 1;
    }
}


sub __set_table_name {
    my ( $sf, $sql, $stmt_typeS ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $table;
    my $c = 0;

    TABLENAME: while ( 1 ) {
        my $trs = Term::Form->new( 'tn' );
        my $info;
        my $default;
        if ( defined $sf->{d}{file_name} ) {
            my $file = basename delete $sf->{d}{file_name};
            $info = sprintf "File: '%s'\n", $file;
            ( $default = $file ) =~ s/\.[^.]{1,3}\z//;
        }
        $ax->print_sql( $sql, $stmt_typeS );
        # Readline
        $table = $trs->readline( 'Table name: ', { info => $info, default => $default } );
        if ( ! length $table ) {
            return;
        }
        my $tmp_td = [ undef, $sf->{d}{schema}, $table ];
        $sql->{table} = $ax->quote_table( $tmp_td );
        if ( none { $sql->{table} eq $ax->quote_table( $sf->{d}{tables_info}{$_} ) } keys %{$sf->{d}{tables_info}} ) {
            return 1;
        }
        $ax->print_sql( $sql, $stmt_typeS );
        my $prompt = "Table $sql->{table} already exists.";
        my $choice = choose(
            [ undef, 'New name' ],
            { %{$sf->{i}{lyt_stmt_h}}, prompt => $prompt, undef => 'BACK', layout => 3, justify => 0 }
        );
        if ( ! defined $choice ) {
            return;
        }
    }
}


sub __set_columns {
    my ( $sf, $sql, $stmt_typeS ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    if ( ! @{$sql->{insert_into_args}} ) {
        $ax->print_sql( $sql, $stmt_typeS );
        my $col_count = choose_a_number( 3, { small_on_top => 1, confirm => 'Confirm', mouse => $sf->{o}{table}{mouse},
                                            back => 'Back', name => 'Number of columns: ', clear_screen => 0 } );
        if ( ! $col_count ) {
            return;
        }
        $ax->print_sql( $sql, $stmt_typeS );
        my $info = 'Enter column names:';
        my $trs = Term::Form->new();
        my $col_names = $trs->fill_form(
            [ map { [ $_, ] } 1 .. $col_count ],
            { info => $info, confirm => 'OK', back => '<<', auto_up => 2 }
        );
        if ( ! defined $col_names ) {
            return;
        }
        $sql->{insert_into_cols} = [ map { $_->[1] } @$col_names ]; # not quoted
    }
    else {
        my ( $first_row, $user_input ) = ( '- First row', '- Add row' );
        $ax->print_sql( $sql, $stmt_typeS );
        # Choose
        my $choice = choose(
            [ undef, $first_row, $user_input ],
            { %{$sf->{i}{lyt_stmt_v}}, prompt => 'Header:' }
        );
        if ( ! defined $choice ) {
            return;
        }
        if ( $choice eq $first_row ) {
            $sql->{insert_into_cols} = shift @{$sql->{insert_into_args}}; # not quoted
        }
        else {
            my $c = 0;
            $sql->{insert_into_cols} = [ map { 'c' . ++$c } @{$sql->{insert_into_args}->[0]} ]; # not quoted
        }
        $sql->{create_table_cols} = [ @{$sql->{insert_into_cols}} ];
        my $c = 0;
        my $fields = [ map { [ ++$c, defined $_ ? "$_" : '' ] } @{$sql->{insert_into_cols}} ];
        #if ( $sf->{d}{driver} eq 'SQLite' ) {
        if ( length $sf->{auto_inc_col_name} ) {
            unshift @$fields, [ 'ai', $sf->{auto_inc_col_name} ];
        }
        my $trs = Term::Form->new( 'cols' );
        $ax->print_sql( $sql, $stmt_typeS );
        # Fill_form
        my $form = $trs->fill_form(
            $fields,
            { prompt => 'Col names:', auto_up => 2, confirm => '  CONFIRM', back => '  BACK   ' }
        );
        if ( ! $form ) {
            return;
        }
        #if ( $sf->{d}{driver} eq 'SQLite' ) {
        if ( length $sf->{auto_inc_col_name} ) {
            my $auto_col = shift @$form;
            $sf->{auto_inc_col_name} = $auto_col->[1];
        }
        $sql->{insert_into_cols} = [ map { $_->[1] } @$form ]; # not quoted
    }
    return 1;
}


sub __set_data_types {
    my ( $sf, $sql, $stmt_typeS ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $fields = [ map { [ $_, $sf->{o}{create}{default_data_type} ] } @{$sql->{create_table_cols}} ];
    my $read_only = [];
    if ( length $sf->{auto_inc_col_name} ) {
        unshift @$fields, [ $ax->quote_col_qualified( [ $sf->{auto_inc_col_name} ] ), 'INTEGER PRIMARY KEY' ];
        $read_only = [ 0 ];
    }
    my $trs = Term::Form->new( 'cols' );
    $ax->print_sql( $sql, $stmt_typeS );
    # Fill_form
    my $col_name_and_type = $trs->fill_form( # look
        $fields,
        { prompt => 'Data types:', auto_up => 2, read_only => $read_only,
            confirm => 'CONFIRM', back => 'BACK        ' }
    );
    if ( ! $col_name_and_type ) {
        return;
    }
    $sql->{create_table_cols} = [ map { join ' ', @$_ }  @$col_name_and_type ];
    return 1;
}





1;

__END__
