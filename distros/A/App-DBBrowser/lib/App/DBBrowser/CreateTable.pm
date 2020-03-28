package # hide from PAUSE
App::DBBrowser::CreateTable;

use warnings;
use strict;
use 5.010001;

use Encode         qw( decode );
use File::Basename qw( basename );

use List::MoreUtils   qw( none any duplicates );
#use SQL::Type::Guess qw();                 # required

use Term::Choose       qw();
use Term::Choose::Util qw( insert_sep );
use Term::Form         qw();

use App::DBBrowser::Auxil;
use App::DBBrowser::DB;
use App::DBBrowser::GetContent;
#use App::DBBrowser::DropTable;             # required
#use App::DBBrowser::Subqueries;            # required
#use App::DBBrowser::Table::WriteAccess;    # required


sub new {
    my ( $class, $info, $options, $data ) = @_;
    bless {
        i => $info,
        o => $options,
        d => $data
    }, $class;
}


sub create_view {
    my ( $sf ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    require App::DBBrowser::Subqueries;
    my $sq = App::DBBrowser::Subqueries->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $tf = Term::Form->new( $sf->{i}{tf_default} );
    my $sql = {};
    $ax->reset_sql( $sql );
    $sf->{i}{stmt_types} = [ 'Create_view' ];

    SELECT_STMT: while ( 1 ) {
        $sql->{table} = '';
        $sql->{view_select_stmt} = '?';
        $ax->print_sql( $sql );
        my $select_statment = $sq->choose_subquery( $sql );
        if ( ! defined $select_statment ) {
            return;
        }
        if ( $select_statment =~ s/^([\s(]+)(?=SELECT\s)//i ) {
            my $count = $1 =~ tr/(//;
            while ( $count-- ) {
                $select_statment =~ s/\s*\)\s*\z//;
            }
        }
        $sql->{view_select_stmt} = $select_statment;
        $ax->print_sql( $sql );

        VIEW_NAME: while ( 1 ) {
            $sql->{table} = '?';
            $ax->print_sql( $sql );
            # Readline
            my $view = $tf->readline( 'View name: ' . $sf->{o}{create}{view_name_prefix} );
            if ( ! length $view ) {
                next SELECT_STMT;
            }
            $view = $sf->{o}{create}{view_name_prefix} . $view;
            $sql->{table} = $ax->quote_table( [ undef, $sf->{d}{schema}, $view, 'VIEW' ] );
            if ( none { $sql->{table} eq $ax->quote_table( $sf->{d}{tables_info}{$_} ) } keys %{$sf->{d}{tables_info}} ) {
                my $ok_create_view = $sf->__create( $sql, 'view' );
                if ( ! defined $ok_create_view ) {
                    next SELECT_STMT;
                }
                elsif( ! $ok_create_view ) {
                    return;
                }
                return 1;
            }
            $ax->print_sql( $sql );
            my $prompt = "$sql->{table} already exists.";
            my $chosen = $tc->choose(
                [ undef, '  New name' ],
                { %{$sf->{i}{lyt_v}}, prompt => $prompt }
            );
            if ( ! defined $chosen ) {
                return;
            }
            next VIEW_NAME;
        }
    }
}


sub create_table {
    my ( $sf ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $gc = App::DBBrowser::GetContent->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $sql = {};
    $sql->{table} = '';
    $ax->reset_sql( $sql );
    my $skip_to = '';

    CREATE_TABLE: while ( 1 ) {
        $sf->{i}{stmt_types} = [ 'Create_table', 'Insert' ];
        # first use of {stmt_types} in get_content/from_col_by_col
        my $ok = $gc->get_content( $sql, $skip_to );
        if ( ! $ok ) {
            return;
        }
        $skip_to = '';
        my $count_table_name_loop = 0;

        TABLE_NAME: while ( 1 ) {
            my $no_default_table_name;
            if ( $count_table_name_loop > 1 ) {
                $no_default_table_name = 1;
            }
            my $ok_table_name = $sf->__set_table_name( $sql, $no_default_table_name ); # first time print_sql
            if ( ! $ok_table_name ) {
                $skip_to = 'FILTER';
                next CREATE_TABLE;
            }

            SET_COLUMNS: while ( 1 ) {
                my $ok_columns = $sf->__set_columns( $sql );
                if ( ! $ok_columns ) {
                    $sql->{table} = '';
                    if ( exists $sf->{i}{ct}{shifted_header} ) {
                        unshift @{$sql->{insert_into_args}}, delete $sf->{i}{ct}{shifted_header};
                    }
                    $count_table_name_loop++;
                    next TABLE_NAME;
                }
                $count_table_name_loop = 0;
                my $ok_create_table = $sf->__create( $sql, 'table' );
                if ( ! defined $ok_create_table ) {
                    if ( exists $sf->{i}{ct}{shifted_header} ) {
                        unshift @{$sql->{insert_into_args}}, delete $sf->{i}{ct}{shifted_header};
                    }
                    next SET_COLUMNS;
                }
                if ( ! $ok_create_table ) {
                    return;
                }
                if ( @{$sql->{insert_into_args}} ) {
                    my $ok_insert = $sf->__insert_data( $sql );
                    if ( ! $ok_insert ) {
                        require App::DBBrowser::DropTable;
                        my $dt = App::DBBrowser::DropTable->new( $sf->{i}, $sf->{o}, $sf->{d} );
                        my $drop_ok = $dt->__drop( $sql, 'table' );
                        if ( ! $drop_ok ) {
                            return;
                        }
                        $sf->{i}{stmt_types} = [ 'Create_table', 'Insert' ];
                        if ( exists $sf->{i}{ct}{shifted_header} ) {
                            unshift @{$sql->{insert_into_args}}, delete $sf->{i}{ct}{shifted_header};
                        }
                        next SET_COLUMNS;
                    }
                }
                my $file_fs = $sf->{i}{gc}{file_fs};
                my $sheet_count;
                if ( exists $sf->{i}{S_R}{$file_fs}{sheet_count} ) {
                    $sheet_count = $sf->{i}{S_R}{$file_fs}{sheet_count};
                }
                if ( defined $sheet_count && $sheet_count > 1 ) {
                    $skip_to = 'PARSE';
                    next CREATE_TABLE;
                }
                return 1;
            }
        }
    }
}


sub __create {
    my ( $sf, $sql, $type ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    $sf->{i}{occupied_term_height} = 5;
    $ax->print_sql( $sql );
    my ( $no, $yes ) = ( '- NO', '- YES' );
    my $prompt = "Create $type $sql->{table}";
    if ( @{$sql->{insert_into_args}} ) {
        my $row_count = @{$sql->{insert_into_args}};
        $prompt .= "\nInsert " . insert_sep( $row_count, $sf->{o}{G}{thsd_sep} ) . " row";
        $prompt .= "s" if @{$sql->{insert_into_args}} > 1;
    }
    # Choose
    my $create_table_ok = $tc->choose(
        [ undef, $yes, $no ],
        { %{$sf->{i}{lyt_v}}, prompt => $prompt, undef => '  <=' }
    );
    if ( ! defined $create_table_ok ) {
        return;
    }
    if ( $create_table_ok eq $no ) {
        return 0;
    }
    my $stmt = $ax->get_stmt( $sql, 'Create_' . $type, 'prepare' );
    $sql->{create_table_cols} = [];
    if ( ! eval { $sf->{d}{dbh}->do( $stmt ); 1 } ) {
        $ax->print_error_message( $@ );
        return;
    };
    return 1;
}


sub __insert_data {
    my ( $sf, $sql ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $sth = $sf->{d}{dbh}->prepare( "SELECT * FROM " . $sql->{table} . " LIMIT 0" );
    if ( $sf->{i}{driver} ne 'SQLite' ) {
        $sth->execute();
    }
    my @columns = @{$sth->{NAME}};
    if ( length $sf->{col_auto} ) {
        shift @columns;
    }
    $sql->{insert_into_cols} = $ax->quote_simple_many( \@columns );
    $sf->{i}{occupied_term_height} = 1;
    $ax->print_sql( $sql );
    require App::DBBrowser::Table::WriteAccess;
    my $tw = App::DBBrowser::Table::WriteAccess->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $commit_ok = $tw->commit_sql( $sql );
    return $commit_ok;
}


sub __set_table_name {
    my ( $sf, $sql, $no_default_table_name ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $tf = Term::Form->new( $sf->{i}{tf_default} );
    my $table;
    my $c = 0;

    while ( 1 ) {
        my $info;
        if ( $sf->{i}{gc}{source_type} eq 'file' ) {
            my $file_fs = $sf->{i}{gc}{file_fs};
            my $file_name = basename decode( 'locale_fs', $file_fs );
            $info = sprintf "File: '%s'", $file_name;
            my $sheet_name = $sf->{i}{S_R}{$file_fs}{sheet_name};
            if ( defined $sheet_name && length $sheet_name ) {
                if ( $sf->{i}{S_R}{$file_fs}{sheet_count} > 1 ) {
                    $sf->{i}{ct}{default_table_name} = $sheet_name;
                }
                else {
                    $file_name =~ s/\.[^.]{1,4}\z//;
                    $sf->{i}{ct}{default_table_name} = $file_name . '_' . $sheet_name;
                }
            }
            else {
                ( $sf->{i}{ct}{default_table_name} = $file_name ) =~ s/\.[^.]{1,4}\z//;
            }
            $sf->{i}{ct}{default_table_name} =~ s/ /_/g;
        }
        $sf->{i}{occupied_term_height} = 1;
        $sf->{i}{occupied_term_height} += 1 if $info;
        $ax->print_sql( $sql );
        # Readline
        $table = $tf->readline( 'Table name: ',
            { info => $info, default => $no_default_table_name ? undef : $sf->{i}{ct}{default_table_name} }
        );
        if ( ! length $table ) {
            return;
        }
        $sf->{i}{ct}{default_table_name} = $table;
        $sql->{table} = $ax->quote_table( [ undef, $sf->{d}{schema}, $table ] );
        if ( none { $sql->{table} eq $ax->quote_table( $sf->{d}{tables_info}{$_} ) } keys %{$sf->{d}{tables_info}} ) {
            return 1;
        }
        $sf->{i}{occupied_term_height} = 3;
        $ax->print_sql( $sql );
        my $prompt = "Table $sql->{table} already exists.";
        my $chosen = $tc->choose(
            [ undef, '  New name' ],
            { %{$sf->{i}{lyt_v}}, prompt => $prompt }
        );
        if ( ! defined $chosen ) {
            return;
        }
    }
}


sub __set_columns {
    my ( $sf, $sql ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    if ( exists $sf->{i}{ct}{shifted_header} ) {
        delete $sf->{i}{ct}{shifted_header};
    }

    HEADER_ROW: while ( 1 ) {
        if ( exists $sf->{i}{ct}{shifted_header} ) {
            unshift @{$sql->{insert_into_args}}, delete $sf->{i}{ct}{shifted_header};
        }
        $sql->{create_table_cols} = [];
        $sql->{insert_into_cols}  = [];
        my $header_row = $sf->__header_row( $sql );
        if ( ! $header_row ) {
            return;
        }

        AI_COL: while ( 1 ) {
            $sql->{create_table_cols} = [ @$header_row ];  # not quoted
            $sql->{insert_into_cols}  = [ @$header_row ];  # not quoted
            my $continue = $sf->__autoincrement_column( $sql);
            if ( ! $continue ) {
                next HEADER_ROW;
            }
            my @bu_create_table_cols = @{$sql->{create_table_cols}};
            $sf->{i}{occupied_term_height} = 11 + @{$sql->{create_table_cols}}; #

            COL_NAMES: while ( 1 ) {
                my $ok_names = $sf->__column_names( $sql );
                if ( ! $ok_names ) {
                    $sql->{create_table_cols} = [ @bu_create_table_cols ];
                    next AI_COL if $sf->{col_auto};
                    next HEADER_ROW;
                }
                if ( any { ! length } @{$sql->{create_table_cols}} ) {
                    # Choose
                    $tc->choose(
                        [ 'Column with no name!' ],
                        { prompt => 'Continue with ENTER' }
                    );
                    next COL_NAMES;
                }
                my @duplicates = duplicates map { lc } @{$sql->{create_table_cols}};
                if ( @duplicates ) {
                    # Choose
                    $tc->choose(
                        [ 'Duplicate column name!' ],
                        { prompt => 'Continue with ENTER' }
                    );
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
    $sf->{i}{occupied_term_height} = undef;
    return 1;
}


sub __header_row {
    my ( $sf, $sql ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my ( $first_row,        $user_input        ) = ( '- YES',                   '- NO'                   );
    my ( $first_row_edited, $user_input_edited ) = ( '- YES, edited as before', '- NO, edited as before' );                 #
    my @pre = ( undef );
    my $menu = [ @pre, $first_row, $user_input ];
    my $prev_edited_header;                                                                                                 #
    if ( exists $sf->{i}{ct}{prev_header_info} ) {                                                                          #
        ( my $prev_orig_header, $prev_edited_header, my $header_is_first_data_row ) = @{$sf->{i}{ct}{prev_header_info}};    #
        if ( $header_is_first_data_row ) {                                                                                  #
            my $add_to_menu = 1;                                                                                            #
            for my $i ( 0 .. $#$prev_orig_header ) {                                                                        #
                if ( $prev_orig_header->[$i] ne $sql->{insert_into_args}[0][$i] ) {                                         #
                    $add_to_menu = 0;                                                                                       #
                    last;                                                                                                   #
                }                                                                                                           #
            }                                                                                                               #
            if ( $add_to_menu ) {                                                                                           #
                splice @$menu, 2, 0, $first_row_edited;                                                                     #
            }                                                                                                               #
        }                                                                                                                   #
        else {                                                                                                              #
            if ( @$prev_orig_header == @{$sql->{insert_into_args}[0]} ) {                                                   #
                push @$menu, $user_input_edited;                                                                            #
            }                                                                                                               #
        }                                                                                                                   #
    }                                                                                                                       #
    my $header_row;
    $sf->{i}{occupied_term_height} = 4;
    $ax->print_sql( $sql );
    # Choose
    my $chosen = $tc->choose(
        $menu,
        { %{$sf->{i}{lyt_v}}, prompt => 'Use the first Data Row as the Table Header:', undef => '  <=' }
    );
    if ( ! defined $chosen ) {
        return;
    }
    elsif ( $chosen eq $first_row ) {
        $sf->{i}{ct}{shifted_header} = shift @{$sql->{insert_into_args}};
        $header_row = [ @{$sf->{i}{ct}{shifted_header}} ];
    }
    elsif ( $chosen eq $first_row_edited ) {                                #
        $sf->{i}{ct}{shifted_header} = shift @{$sql->{insert_into_args}};   #
        $header_row = $prev_edited_header;                                  #
    }                                                                       #
    elsif ( $chosen eq $user_input_edited ) {                               #
        $header_row = $prev_edited_header;                                  #
    }                                                                       #
    else {
        my $c = 0;
        $header_row = $sf->__generic_header_row( scalar @{$sql->{insert_into_args}->[0]} );
    }
    return $header_row;
}


sub __autoincrement_column {
    my ( $sf, $sql ) = @_;
    my $plui = App::DBBrowser::DB->new( $sf->{i}, $sf->{o} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    $sf->{col_auto} = '';
    if ( $sf->{constraint_auto} = $plui->primary_key_autoincrement_constraint( $sf->{d}{dbh} ) ) {
        $sf->{col_auto} = $sf->{o}{create}{autoincrement_col_name};
    }
    if ( $sf->{col_auto} ) {
        my ( $no, $yes ) = ( '- NO ', '- YES' );
        $sf->{i}{occupied_term_height} = 4;
        $ax->print_sql( $sql );
        # Choose
        my $chosen = $tc->choose(
            [ undef, $yes, $no  ],
            { %{$sf->{i}{lyt_v}}, prompt => 'Add an AUTO INCREMENT column:', undef => '  <='  }
        );
        if ( ! defined $chosen ) {
            return;
        }
        elsif ( $chosen eq $no ) {
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
    my $tf = Term::Form->new( $sf->{i}{tf_default} );
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $col_number = 0;
    my $db = $sf->{d}{db};
    my $fields = [ map { [ ++$col_number, defined $_ ? "$_" : '' ] } @{$sql->{create_table_cols}} ];
    $sf->{i}{occupied_term_height} = 3 + @{$sql->{create_table_cols}};
    $ax->print_sql( $sql );
    # Fill_form
    my $form = $tf->fill_form(
        $fields,
        { prompt => 'Edit column names:', auto_up => 2, confirm => $sf->{i}{confirm}, back => $sf->{i}{back} . '   ' }
    );
    if ( ! defined $form ) {
        return;
    }
    my ( $orig_header, $header_is_first_data_row );                                                     #
    if ( exists $sf->{i}{ct}{shifted_header} ) {                                                        #
        $orig_header = [ @{$sf->{i}{ct}{shifted_header}} ];                                             #
        $header_is_first_data_row = 1;                                                                  #
    }                                                                                                   #
    else {                                                                                              #
        $orig_header = $sf->__generic_header_row( scalar @{$sql->{insert_into_args}->[0]} );            #
        $header_is_first_data_row = 0;                                                                  #
    }                                                                                                   #
    my $edited_header = [ map { $_->[1] } @$form ];                                                     #
    if ( length $sf->{col_auto} ) {                                                                     #
        shift @$edited_header;                                                                          #
    }                                                                                                   #
    my $diff_between_orig_and_edited_header = 0;                                                        #
    for my $i ( 0 .. $#$orig_header ) {                                                                 #
        if ( $orig_header->[$i] ne $edited_header->[$i] ) {                                             #
            $diff_between_orig_and_edited_header = 1;                                                   #
            last;                                                                                       #
        }                                                                                               #
    }                                                                                                   #
    if ( $diff_between_orig_and_edited_header ) {                                                       #
        $sf->{i}{ct}{prev_header_info} = [ $orig_header, $edited_header, $header_is_first_data_row ];   #
    }                                                                                                   #
    elsif ( exists $sf->{i}{ct}{prev_header_info} ) {                                                   #
        delete $sf->{i}{ct}{prev_header_info};                                                          #
    }                                                                                                   #
    $sql->{create_table_cols} = [ map { $_->[1] } @$form ]; # not quoted
    if ( length $sf->{col_auto} ) {
        $sf->{col_auto} = $sql->{create_table_cols}[0];
    }
    return 1;
}

sub __generic_header_row {
    my ( $sf, $col_count ) = @_;
    my $c = 0;
    return [ map { 'c' . $c++ } 1 .. $col_count ];
}

sub __data_types {
    my ( $sf, $sql ) = @_;
    my $tf = Term::Form->new( $sf->{i}{tf_default} );
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $unquoted_table_cols = [ @{$sql->{create_table_cols}} ];
    $sql->{create_table_cols} = $ax->quote_simple_many( $sql->{create_table_cols} ); # now quoted
    $sql->{insert_into_cols} = [ @{$sql->{create_table_cols}} ];
    if ( length $sf->{col_auto} ) {
        shift @{$sql->{insert_into_cols}};
    }
    my $data_types;
    my $fields;
    if ( $sf->{o}{create}{data_type_guessing} ) {
        $sf->{i}{occupied_term_height} = 1;
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
    $sf->{i}{occupied_term_height} = 3 + @$fields; # prompt, back, confirm and fiels
    $ax->print_sql( $sql );
    # Fill_form
    my $col_name_and_type = $tf->fill_form(
        $fields,
        { prompt => 'Column data types:', auto_up => 2, read_only => $read_only, confirm => $sf->{i}{confirm},
        back => $sf->{i}{back} . '   ' }
    );
    if ( ! $col_name_and_type ) {
        return;
    }
    else {
        no warnings 'uninitialized';
        $sql->{create_table_cols} = [ map { join ' ', @$_ }  @$col_name_and_type ];
    }
    return 1;
}


sub __guess_data_type {
    my ( $sf, $sql ) = @_;
    require SQL::Type::Guess;
    my $g = SQL::Type::Guess->new();
    my $header = $sql->{insert_into_cols}; #
    my $table  = $sql->{insert_into_args};
    my @aoh;
    for my $row ( @$table ) {
        push @aoh, {
            map { $header->[$_] => $row->[$_] } 0 .. $#{$row}
        };
    }
    $g->guess( @aoh );
    my $tmp = $g->column_type;
    return { map { $_ => uc( $tmp->{$_} ) } keys %$tmp };
}




1;

__END__
