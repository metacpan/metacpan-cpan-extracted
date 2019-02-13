package # hide from PAUSE
App::DBBrowser::CreateTable;

use warnings;
use strict;
use 5.008003;

use File::Basename qw( basename );

use List::MoreUtils    qw( none any duplicates );
#use SQL::Type::Guess  qw(); # required

use Term::Choose       qw( choose );
use Term::Choose::Util qw( insert_sep );
use Term::Form         qw();
use Term::TablePrint   qw( print_table );

use App::DBBrowser::Auxil;
use App::DBBrowser::DB;
use App::DBBrowser::GetContent;
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
    my $table = choose(
        [ undef, map { "- $_" } sort @{$sf->{d}{user_tables}} ],
        { %{$sf->{i}{lyt_v_clear}}, prompt => $prompt, undef => '  <=' }
    );
    if ( ! defined $table || ! length $table ) {
        return;
    }
    $table =~ s/\-\s//;
    $sql->{table} = $ax->quote_table( $sf->{d}{tables_info}{$table} );
    my $drop_ok = $sf->__drop_table( $sql );
    return $drop_ok;
}


sub __drop_table {
    my ( $sf, $sql ) = @_;
    $sf->{i}{stmt_types} = [ 'Drop_table' ];
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    $ax->print_sql( $sql );
    # Choose
    my $ok = choose(
        [ undef, $sf->{i}{_confirm} . ' Stmt'],
        { %{$sf->{i}{lyt_stmt_v}}, prompt => 'Choose:' }
    );
    if ( ! $ok ) {
        return;
    }
    $ax->print_sql( $sql, 'Computing: ... ' );
    my $sth = $sf->{d}{dbh}->prepare( "SELECT * FROM " . $sql->{table} );
    $sth->execute();
    my $col_names = $sth->{NAME}; # mysql: $sth->{NAME} before fetchall_arrayref
    my $all_arrayref = $sth->fetchall_arrayref;
    my $row_count = @$all_arrayref;
    unshift @$all_arrayref, $col_names;
    my $prompt_pt = sprintf "DROP TABLE %s     (on last look at the table)\n", $sql->{table};
    print_table(
        $all_arrayref,
        { %{$sf->{o}{table}}, grid => 2, prompt => $prompt_pt, max_rows => 0,
        keep_header => 1, table_expand => $sf->{o}{G}{info_expand} }
    );
    my $prompt = sprintf 'DROP TABLE %s  (%s %s)', $sql->{table}, insert_sep( $row_count, $sf->{o}{G}{thsd_sep} ), $row_count == 1 ? 'row' : 'rows';
    $prompt .= "\n\nCONFIRM:";
    # Choose
    my $choice = choose(
        [ undef, 'YES' ],
        { %{$sf->{i}{lyt_m}}, prompt => $prompt, undef => 'NO', clear_screen => 1 }
    );
    $ax->print_sql( $sql );
    if ( defined $choice && $choice eq 'YES' ) {
        my $stmt = $ax->get_stmt( $sql, 'Drop_table', 'prepare' );
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
    my @cu_keys = ( qw/create_table_plain create_table_form_file create_table_form_copy/ );
    my %cu = ( create_table_plain      => '- Plain',
               create_table_form_copy  => '- Copy & Paste',
               create_table_form_file  => '- From File',
    );
    my $old_idx = 0;

    MENU: while ( 1 ) {
        $sql->{table} = '';
        $sql->{insert_into_args} = [];
        $sql->{insert_into_cols} = [];
        $sql->{create_table_cols} = [];
        $sf->{i}{stmt_types} = [ 'Create_table' ];
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
        push @{$sf->{i}{stmt_types}}, 'Insert';
        my $ok_input;
        if ( $custom eq $cu{create_table_plain} ) {
            $ok_input = $gc->from_col_by_col( $sql );
        }
        elsif ( $custom eq $cu{create_table_form_copy} ) {
            $ok_input = $gc->from_copy_and_paste( $sql );
        }
        elsif ( $custom eq $cu{create_table_form_file} ) {
            $ok_input = $gc->from_file( $sql );
        }
        if ( ! $ok_input ) {
            next MENU;
        }
        TABLE: while ( 1 ) {
            my $ok_table_name = $sf->__set_table_name( $sql );
            if ( ! $ok_table_name ) {
                next MENU;
            }
            my $ok_columns = $sf->__set_columns( $sql );
            if ( ! $ok_columns ) {
                $sql->{table} = '';
                next TABLE;
            }
            last TABLE;
        }
        my $ok_create_table = $sf->__create_table( $sql );
        if ( ! $ok_create_table ) {
            next MENU;
        }
        if ( @{$sql->{insert_into_args}} ) {
            my $ok_insert = $sf->__insert_data( $sql );
            if ( ! $ok_insert ) {
                my $drop_ok = $sf->__drop_table( $sql );
                if ( ! $drop_ok ) {
                    return;
                }
            }
        }
        return 1;
    }
}


sub __create_table {
    my ( $sf, $sql ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    $ax->print_sql( $sql );
    # Choose
    my $create_table_ok = choose(
        [ undef, 'YES' ],
        { %{$sf->{i}{lyt_m}}, prompt => "Create table $sql->{table}?", undef => 'NO', index => 1 }
    );
    if ( ! $create_table_ok ) {
        return;
    }
    my $stmt = $ax->get_stmt( $sql, 'Create_table', 'prepare' );
    if ( ! eval { $sf->{d}{dbh}->do( $stmt ); 1 } ) {
        $ax->print_error_message( $@, 'Create table' );
        return;
    };
    delete $sql->{create_table_cols};
    return 1;
}


sub __insert_data {
    my ( $sf, $sql ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    $sf->{i}{stmt_types} = [ 'Insert' ];
    my $sth = $sf->{d}{dbh}->prepare( "SELECT * FROM " . $sql->{table} . " LIMIT 0" );
    if ( $sf->{d}{driver} ne 'SQLite' ) {
        $sth->execute();
    }
    my @columns = @{$sth->{NAME}};
    if ( length $sf->{col_auto} ) {
        shift @columns;
    }
    $sql->{insert_into_cols} = $ax->quote_simple_many( \@columns );
    $ax->print_sql( $sql );
    my $tw = App::DBBrowser::Table::WriteAccess->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $commit_ok = $tw->commit_sql( $sql );
    return $commit_ok;
}


sub __set_table_name {
    my ( $sf, $sql ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $table;
    my $c = 0;

    while ( 1 ) {
        $ax->print_sql( $sql );
        my $trs = Term::Form->new();
        my $info;
        my $default;
        if ( defined $sf->{d}{file_name} ) {
            my $file = basename delete $sf->{d}{file_name};
            $info = sprintf "File: '%s'", $file;
            ( $default = $file ) =~ s/\.[^.]{1,4}\z//;
        }
        if ( defined $sf->{d}{sheet_name} && length $sf->{d}{sheet_name} ) {
            $default .= '_' . delete $sf->{d}{sheet_name};
        }
        if ( defined $default ) {
            $default =~ s/ /_/g;
        }
        # Readline
        $table = $trs->readline( 'Table name: ', { info => $info, default => $default } );
        if ( ! length $table ) {
            return;
        }
        $sql->{table} = $ax->quote_table( [ undef, $sf->{d}{schema}, $table ] );
        if ( none { $sql->{table} eq $ax->quote_table( $sf->{d}{tables_info}{$_} ) } keys %{$sf->{d}{tables_info}} ) {
            return 1;
        }
        $ax->print_sql( $sql );
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
    my ( $sf, $sql ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $row_count = @{$sql->{insert_into_args}};
    my $first_row = $sql->{insert_into_args}[0];

    HEADER_ROW: while ( 1 ) {
        if ( $row_count == 1 + @{$sql->{insert_into_args}} ) {
            unshift @{$sql->{insert_into_args}}, $first_row;
        }
        $sql->{create_table_cols} = [];
        $sql->{insert_into_cols}  = [];
        $ax->print_sql( $sql );
        my $header_row = $sf->__header_row( $sql );
        if ( ! $header_row ) {
            return;
        }

        AI_COL: while ( 1 ) {
            $sql->{create_table_cols} = [ @$header_row ];  # not quoted
            $sql->{insert_into_cols}  = [ @$header_row ];  # not quoted
            $ax->print_sql( $sql );
            my $ok_ai = $sf->__autoincrement_column( $sql);
            if ( ! $ok_ai ) {
                next HEADER_ROW;
            }
            my @bu_cols_with_ai = @{$sql->{create_table_cols}};

            COL_NAMES: while ( 1 ) {
                $ax->print_sql( $sql );
                my $ok_names = $sf->__column_names( $sql );
                if ( ! $ok_names ) {
                    $sql->{create_table_cols} = [ @bu_cols_with_ai ];
                    next AI_COL;
                }
                $ax->print_sql( $sql );
                if ( any { ! length } @{$sql->{create_table_cols}} ) {
                    choose( [ 'Column with no name!' ], { %{$sf->{i}{lyt_m}}, prompt => 'Continue with ENTER' } );
                    next COL_NAMES;
                }
                my @duplicates = duplicates @{$sql->{create_table_cols}};
                if ( @duplicates ) {
                    choose( [ 'Duplicate column name!' ], { %{$sf->{i}{lyt_m}}, prompt => 'Continue with ENTER' } );
                    next COL_NAMES;
                }
                my @bu_cols_with_name = @{$sql->{create_table_cols}};

                DATA_TYPES: while ( 1 ) {
                    my $ok_data_types = $sf->__data_types( $sql );
                    if ( ! $ok_data_types ) {
                        $sql->{create_table_cols} = [ @bu_cols_with_name ];
                        next COL_NAMES;
                    }
                    last DATA_TYPES;
                }
                last COL_NAMES;
            }
            last AI_COL;
        }
        last HEADER_ROW;
    }
    $ax->print_sql( $sql );
    return 1;
}

sub __header_row {
    my ( $sf, $sql ) = @_;
    my $header_row;
    my ( $first_row, $user_input ) = ( '- First row', '- Add row' );
    # Choose
    my $choice = choose(
        [ undef, $first_row, $user_input ],
        { %{$sf->{i}{lyt_stmt_v}}, prompt => 'Header:' }
    );
    if ( ! defined $choice ) {
        return;
    }
    elsif ( $choice eq $first_row ) {
        $header_row = shift @{$sql->{insert_into_args}};
    }
    else {
        for my $col_idx ( @{$sf->{i}{idx_added_cols}||[]} ) {
            $sql->{insert_into_args}->[0][$col_idx] = undef;
        }
        my $c = 0;
        $header_row = [ map { 'c' . ++$c } @{$sql->{insert_into_args}->[0]} ];
    }
    return $header_row;
}

sub __autoincrement_column {
    my ( $sf, $sql ) = @_;
    $sf->{col_auto} = '';
    my $plui = App::DBBrowser::DB->new( $sf->{i}, $sf->{o} );
    if ( $sf->{constraint_auto} = $plui->primary_key_autoincrement_constraint( $sf->{d}{dbh} ) ) {
        $sf->{col_auto} = $sf->{o}{create}{autoincrement_col_name};
    }
    if ( $sf->{col_auto} ) {
        my ( $no, $yes ) = ( '- NO ', '- YES' );
        # Choose
        my $choice = choose(
            [ undef, $yes, $no  ],
            { %{$sf->{i}{lyt_stmt_v}}, prompt => 'Add AUTO INCREMENT column:',  }
        );
        if ( ! defined $choice ) {
            return;
        }
        elsif ( $choice eq $no ) {
            $sf->{col_auto} = '';
        }
        else {
            unshift @{$sql->{create_table_cols}}, $sf->{col_auto};
        }
    }
    return 1;
}

sub __column_names {
    my ( $sf, $sql ) = @_;
    my $col_number = 0;
    my $fields = [ map { [ ++$col_number, defined $_ ? "$_" : '' ] } @{$sql->{create_table_cols}} ];
    my $trs = Term::Form->new( 'cols' );
    # Fill_form
    my $form = $trs->fill_form(
        $fields,
        { prompt => 'Col names:', auto_up => 2, confirm => '  CONFIRM', back => '  BACK   ' }
    );
    if ( ! $form ) {
        return;
    }
    $sql->{create_table_cols} = [ map { $_->[1] } @$form ]; # not quoted
    return 1;
}

sub __data_types {
    my ( $sf, $sql ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    $sql->{create_table_cols} = $ax->quote_simple_many( $sql->{create_table_cols} ); # now quoted
    $sql->{insert_into_cols} = [ @{$sql->{create_table_cols}} ];
    if ( length $sf->{col_auto} ) {
        shift @{$sql->{insert_into_cols}};
    }
    my $data_types;
    my $fields;
    if ( $sf->{o}{create}{data_type_guessing} ) {
        $ax->print_sql( $sql, 'Guessing data types ... ' );
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
    $ax->print_sql( $sql );
    # Fill_form
    my $col_name_and_type = $trs->fill_form(
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
