package # hide from PAUSE
App::DBBrowser::CreateTable;

use warnings;
use strict;
use 5.008003;

use File::Basename qw( basename );
use List::Util     qw( none any );

#use SQL::Type::Guess  qw(); # required

use Term::Choose       qw( choose );
use Term::Choose::Util qw( choose_a_number insert_sep );
use Term::Form         qw();
use Term::TablePrint   qw( print_table );

use App::DBBrowser::Auxil;
use App::DBBrowser::DB;
use App::DBBrowser::GetContent;
use App::DBBrowser::Opt;
use App::DBBrowser::Table::WriteAccess;


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
        { %{$sf->{i}{lyt_v_clear}}, prompt => $prompt, undef => '  <=' }
    );
    if ( ! defined $table || ! length $table ) {
        return;
    }
    $table =~ s/\-\s//;
    $sql->{table} = $ax->quote_table( $sf->{d}{tables_info}{$table} );
    my $Drop_table = 'Drop_table';
    $ax->print_sql( $sql, [ $Drop_table ] );
    $prompt = 'Choose:';
    # Choose
    my $ok = choose( #
        [ undef, $sf->{i}{_confirm} . ' Stmt'],
        { %{$sf->{i}{lyt_stmt_v}}, prompt => $prompt }
    );
    if ( ! $ok ) {
        return;
    }
    $ax->print_sql( $sql, [ $Drop_table ], 'Computing: ... ' );
    my $sth = $sf->{d}{dbh}->prepare( "SELECT * FROM " . $sql->{table} );
    $sth->execute();
    my $col_names = $sth->{NAME}; # mysql: $sth->{NAME} before fetchall_arrayref
    my $all_arrayref = $sth->fetchall_arrayref;
    my $row_count = @$all_arrayref;
    unshift @$all_arrayref, $col_names;
    if ( @$all_arrayref > 1 ) {
        my $prompt_pt = sprintf "DROP TABLE %s     (on last look at the table)\n", $sql->{table};
        print_table( $all_arrayref, { %{$sf->{o}{table}}, grid => 2, prompt => $prompt_pt, max_rows => 0, keep_header => 1 } ); #
    }
    $prompt = sprintf 'DROP TABLE %s  (%s %s)', $sql->{table}, insert_sep( $row_count, $sf->{o}{G}{thsd_sep} ), $row_count == 1 ? 'row' : 'rows';
    $prompt .= "\n\nCONFIRM:";
    # Choose
    my $choice = choose( #
        [ undef, 'YES' ],
        { %{$sf->{i}{lyt_m}}, prompt => $prompt, undef => 'NO', clear_screen => 1 }
    );
    $ax->print_sql( $sql, [ $Drop_table ] );
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
    my $gc = App::DBBrowser::GetContent->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $sql = {};
    $ax->reset_sql( $sql );
    my @cu_keys = ( qw/create_table_plain create_table_form_file create_table_form_copy settings/ );
    my %cu = ( create_table_plain      => '- plain',
               create_table_form_copy  => '- Copy & Paste',
               create_table_form_file  => '- From File',
               settings                => '  Settings'
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
            { %{$sf->{i}{lyt_v_clear}}, index => 1, default => $old_idx, prompt => $prompt, undef => '  <=' }
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
        if ( $custom eq $cu{create_table_form_copy} ) {
            push @$stmt_typeS, 'Insert';
            my $ok = $gc->from_copy_and_paste( $sql, $stmt_typeS );
            if ( ! $ok ) {
                next MENU;
            }
        }
        elsif ( $custom eq $cu{create_table_form_file} ) {
            push @$stmt_typeS, 'Insert';
            my $file_name = $gc->from_file( $sql, $stmt_typeS );
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
        my $plui = App::DBBrowser::DB->new( $sf->{i}, $sf->{o} );
        if ( $sf->{constraint_auto} = $plui->primary_key_autoincrement_constraint( $sf->{d}{dbh} ) ) {
            $sf->{col_auto} = $sf->{o}{create}{autoincrement_col_name};
        }
        else {
            $sf->{col_auto} = '';
        }
        my $ok_columns = $sf->__set_columns( $sql, $stmt_typeS );
        if ( ! $ok_columns ) {
            next MENU;
        }
        if ( any { ! length } @{$sql->{create_table_cols}} ) {
            die "Column with no name!";
        }
        # quote col names
        $sql->{create_table_cols} = $ax->quote_simple_many( $sql->{create_table_cols} );
        $sql->{insert_into_cols} = [ @{$sql->{create_table_cols}} ];
        if ( $sf->{col_auto} ) {
            shift @{$sql->{insert_into_cols}};
        }
        $ax->print_sql( $sql, $stmt_typeS );
        if ( $custom eq $cu{create_table_plain} ) {
            push @$stmt_typeS, 'Insert';
            my $ok = $gc->from_col_by_col( $sql, $stmt_typeS );
            if ( ! $ok ) {
                pop @$stmt_typeS;
            }
        }
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
        if ( $stmt_typeS->[-1] eq 'Insert' ) {
            $stmt_typeS = [ $stmt_typeS->[-1] ];
            my $sth = $sf->{d}{dbh}->prepare( "SELECT * FROM $qt_table LIMIT 0" );
            $sth->execute() if $sf->{d}{driver} ne 'SQLite';
            my @columns = @{$sth->{NAME}};
            if ( length $sf->{col_auto} ) {
                shift @columns;
            }
            $sql->{insert_into_cols} = $ax->quote_simple_many( \@columns );
            my $tw = App::DBBrowser::Table::WriteAccess->new( $sf->{i}, $sf->{o}, $sf->{d} );
            my $commit_ok = $tw->commit_sql( $sql, $stmt_typeS );
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
        $ax->print_sql( $sql, $stmt_typeS );
        my $trs = Term::Form->new( 'tn' );
        my $info;
        my $default;
        if ( defined $sf->{d}{file_name} ) {
            my $file = basename delete $sf->{d}{file_name};
            $info = sprintf "\nFile: '%s'", $file;
            ( $default = $file ) =~ s/\.[^.]{1,4}\z//;
        }
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
    $sql->{create_table_cols} = [];
    $sql->{insert_into_cols}  = [];
    $ax->print_sql( $sql, $stmt_typeS );
    if ( ! @{$sql->{insert_into_args}} ) {
        my $col_count = choose_a_number( 3,
            { small_on_top => 1, confirm => 'Confirm', mouse => $sf->{o}{table}{mouse},
              back => 'Back', name => 'Number of columns: ', clear_screen => 0 }
        );
        if ( ! $col_count ) {
            return;
        }
        $sql->{create_table_cols} = [ map { 'c' . $_ } 1 .. $col_count ]; # not quoted
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
        elsif ( $choice eq $first_row ) {
            $sql->{create_table_cols} = shift @{$sql->{insert_into_args}}; # not quoted
        }
        else {
            my $c = 0;
            $sql->{create_table_cols} = [ map { 'c' . ++$c } @{$sql->{insert_into_args}->[0]} ]; # not quoted
        }
    }
    $sql->{insert_into_cols} = [ @{$sql->{create_table_cols}} ];
    if ( $sf->{col_auto} ) {
        my ( $skip, $add ) = ( '- Skip', '- Add AI column' );
        $ax->print_sql( $sql, $stmt_typeS );
        # Choose
        my $choice = choose(
            [ undef, $skip, $add  ],
            { %{$sf->{i}{lyt_stmt_v}}, prompt => 'Auto increment column:' }
        );
        if ( ! defined $choice ) {
            return;
        }
        elsif ( $choice eq $skip ) {
            $sf->{col_auto} = '';
        }
    }
    my $c = 0;
    my $fields = [ map { [ ++$c, defined $_ ? "$_" : '' ] } @{$sql->{create_table_cols}} ];
    if ( length $sf->{col_auto} ) {
        unshift @$fields, [ 'ai', $sf->{col_auto} ];
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
    $sql->{create_table_cols} = [ map { $_->[1] } @$form ]; # not quoted
    $sql->{insert_into_cols} = [ @{$sql->{create_table_cols}} ];
    if ( length $sf->{col_auto} ) {
        my $auto_col = shift @{$sql->{insert_into_cols}};
        $sf->{col_auto} = $auto_col; # the user could have changed or removed the name
    }
    $ax->print_sql( $sql, $stmt_typeS );
    return 1;
}


sub __set_data_types {
    my ( $sf, $sql, $stmt_typeS ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $data_types;
    my $fields;
    if ( $sf->{o}{create}{data_type_guessing} ) {
        $ax->print_sql( $sql, $stmt_typeS, 'Guessing data types ... ' );
        $data_types = $sf->__guess_data_type( $sql );
    }
    if ( defined $data_types ) {
        $fields = [ map { [ $_, $data_types->{$_} ] } @{$sql->{insert_into_cols}} ];
    }
    else {
        $fields = [ map { [ $_, '' ] } @{$sql->{insert_into_cols}} ];
    }
    my $read_only = [];
    if ( length $sf->{col_auto} ) {
        unshift @$fields, [ $ax->quote_col_qualified( [ $sf->{col_auto} ] ), $sf->{constraint_auto} ];
        $read_only = [ 0 ];
    }
    my $trs = Term::Form->new( 'cols' );
    $ax->print_sql( $sql, $stmt_typeS );
    # Fill_form
    my $col_name_and_type = $trs->fill_form( # look
        $fields,
        { prompt => 'Data types:', auto_up => 2, read_only => $read_only,
          confirm => '  CONFIRM', back => '  BACK   ' }
    );
    if ( ! $col_name_and_type ) {
        return;
    }
    {
        no warnings 'uninitialized';
        $sql->{create_table_cols} = [ map { join ' ', @$_ }  @$col_name_and_type ];
    }
    return 1;
}


sub __guess_data_type {
    my ( $sf, $sql ) = @_;
    require SQL::Type::Guess;
    my $header = $sql->{insert_into_cols};
    my $table  = $sql->{insert_into_args};
    my @aoh;
    for my $row ( @$table ) {
        push @aoh, {
            map { $header->[$_] => $row->[$_] } 0 .. $#{$row}
        };
    }
    my $g = SQL::Type::Guess->new();
    $g->guess( @aoh );
    my $tmp = $g->column_type;
    return { map { $_ => uc( $tmp->{$_} ) } keys %$tmp };
}



1;

__END__
