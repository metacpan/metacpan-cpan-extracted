package # hide from PAUSE
App::DBBrowser::CreateDropAttach::CreateTable;

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
#use App::DBBrowser::CreateDropAttach::DropTable;   # required
#use App::DBBrowser::Table::CommitWriteSQL          # required
use App::DBBrowser::DB;
use App::DBBrowser::GetContent;
#use App::DBBrowser::Subqueries;                    # required


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
        my $select_statment = $sq->choose_subquery( $sql );
        $ax->print_sql_info( $ax->get_sql_info( $sql ) );
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

        VIEW_NAME: while ( 1 ) {
            $sql->{table} = '?';
            my $info = $ax->get_sql_info( $sql );
            # Readline
            my $view = $tf->readline(
                'View name: ' . $sf->{o}{create}{view_name_prefix},
                { info => $info }
            );
            $ax->print_sql_info( $info );
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
            my $prompt = "$sql->{table} already exists.";
            $info = $ax->get_sql_info( $sql );
            my $chosen = $tc->choose(
                [ undef, '  New name' ],
                { %{$sf->{i}{lyt_v}}, info => $info, prompt => $prompt }
            );
            $ax->print_sql_info( $info );
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
    my $count_table_name_loop = 0;

    GET_CONTENT: while ( 1 ) {
        $sf->{i}{stmt_types} = [ 'Create_table', 'Insert' ];
        # first use of {stmt_types} in get_content/from_col_by_col
        my $ok = $gc->get_content( $sql, $skip_to );
        if ( ! $ok ) {
            return;
        }
        $skip_to = '';

        my $sheet_count = 1;
        my $file_fs = $sf->{i}{gc}{file_fs};
        if ( exists $sf->{i}{ss}{$file_fs}{sheet_count} ) {
            $sheet_count = $sf->{i}{ss}{$file_fs}{sheet_count};
        }
        my $table_name = ''; # table_name memory

        GET_TABLE_NAME: while ( 1 ) {
            $table_name = $sf->__get_table_name( $sql, $table_name, $count_table_name_loop ); # first time print_sql
            if ( ! $table_name ) {
                if ( $sf->{o}{insert}{enable_input_filter} ) {
                    $skip_to = 'FILTER';
                }
                elsif ( $sheet_count > 1 ) {
                    $skip_to = 'PARSE';
                }
                else {
                    $skip_to = 'GET_DATA';
                }
                $count_table_name_loop = 0;
                next GET_CONTENT;
            }
            my $bu_first_row = [ @{$sql->{insert_into_args}[0]} ];
            my $orig_row_count = @{$sql->{insert_into_args}};

            GET_COLUMN_NAMES: while ( 1 ) {
                if ( $orig_row_count - 1 == @{$sql->{insert_into_args}} ) {
                    unshift @{$sql->{insert_into_args}}, $bu_first_row;
                }
                $sql->{create_table_cols} = [];
                $sql->{insert_into_cols}  = [];
                my $header_row = $sf->__get_column_names( $sql );
                if ( ! $header_row ) {
                    $sql->{table} = '';
                    if ( $orig_row_count - 1 == @{$sql->{insert_into_args}[0]} ) {
                        unshift @{$sql->{insert_into_args}}, $bu_first_row;
                    }
                    $count_table_name_loop++;
                    next GET_TABLE_NAME;
                }
                $count_table_name_loop = 0;

                AUTO_INCREMENT: while( 1 ) {
                    $sql->{create_table_cols} = [ @$header_row ];  # not quoted
                    $sql->{insert_into_cols}  = [ @$header_row ];  # not quoted
                    my $continue = $sf->__autoincrement_column( $sql);
                    if ( ! $continue ) {
                        next GET_COLUMN_NAMES;
                    }
                    my @bu_orig_create_table_cols = @{$sql->{create_table_cols}};
                    my $column_names = []; # column_names memory

                    EDIT_COLUMN_NAMES: while( 1 ) {
                        $column_names = $sf->__edit_column_names( $sql, $column_names );
                        if ( ! $column_names ) {
                            $sql->{create_table_cols} = [ @bu_orig_create_table_cols ];
                            next AUTO_INCREMENT if $sf->{col_auto};
                            next GET_COLUMN_NAMES;
                        }
                        if ( any { ! length } @{$sql->{create_table_cols}} ) {
                            # Choose
                            $tc->choose(
                                [ 'Column with no name!' ],
                                { prompt => 'Continue with ENTER', keep => 1 }
                            );
                            next EDIT_COLUMN_NAMES;
                        }
                        my @duplicates = duplicates map { lc } @{$sql->{create_table_cols}};
                        if ( @duplicates ) {
                            # Choose
                            $tc->choose(
                                [ 'Duplicate column name!' ],
                                { prompt => 'Continue with ENTER', keep => 1 }
                            );
                            next EDIT_COLUMN_NAMES;
                        }
                        my @bu_edited_create_table_cols = @{$sql->{create_table_cols}};
                        my $data_types = {}; # data_types memory

                        EDIT_COLUMN_TYPES: while( 1 ) {
                            $data_types = $sf->__edit_column_types( $sql, $data_types );
                            if ( ! $data_types ) {
                                $sql->{create_table_cols} = [ @bu_orig_create_table_cols ];
                                next EDIT_COLUMN_NAMES;
                            }

                            # CREATE_TABLE
                            my $ok_create_table = $sf->__create( $sql, 'table' );
                            if ( ! defined $ok_create_table ) {
                                $sql->{create_table_cols} = [ @bu_edited_create_table_cols ];
                                $sql->{insert_into_cols}  = [];
                                next EDIT_COLUMN_TYPES;
                            }
                            if ( ! $ok_create_table ) {
                                return;
                            }
                            if ( @{$sql->{insert_into_args}} ) {

                                # INSERT_DATA
                                my $ok_insert = $sf->__insert_data( $sql );
                                if ( ! $ok_insert ) {
                                    require App::DBBrowser::CreateDropAttach::DropTable;
                                    my $dt = App::DBBrowser::CreateDropAttach::DropTable->new( $sf->{i}, $sf->{o}, $sf->{d} );
                                    my $drop_ok = $dt->__drop( $sql, 'table' );
                                    if ( ! $drop_ok ) {
                                        return;
                                    }
                                    $sf->{i}{stmt_types} = [ 'Create_table', 'Insert' ];
                                    next GET_COLUMN_NAMES;
                                }
                            }
                            if ( $sheet_count > 1 ) {
                                $skip_to = 'PARSE';
                            }
                            else {
                                $skip_to = 'GET_DATA';
                            }
                            next GET_CONTENT;
                        }
                    }
                }
            }
        }
    }
}


sub __get_table_name {
    my ( $sf, $sql, $table_name, $count_table_name_loop ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $tf = Term::Form->new( $sf->{i}{tf_default} );
    $ax->print_sql_info( $ax->get_sql_info( $sql ) );

    while ( 1 ) {
        my $file_info;
        if ( $sf->{i}{gc}{source_type} eq 'file' ) {
            my $file_fs = $sf->{i}{gc}{file_fs};
            my $file_name = basename decode( 'locale_fs', $file_fs );
            $file_info = sprintf "File: '%s'", $file_name;
            if ( ! length $table_name ) {
                my $sheet_name = $sf->{i}{ss}{$file_fs}{sheet_name};
                if ( defined $sheet_name && length $sheet_name ) {
                    if ( $sf->{i}{ss}{$file_fs}{sheet_count} > 1 ) {
                        $table_name = $sheet_name;
                    }
                    else {
                        $file_name =~ s/\.[^.]{1,4}\z//;
                        $table_name = $file_name . '_' . $sheet_name;
                    }
                }
                else {
                    ( $table_name = $file_name ) =~ s/\.[^.]{1,4}\z//;
                }
                $table_name =~ s/ /_/g;
            }
        }
        $sf->{i}{occupied_term_height} = 2; # readline, trailing empty line
        if ( $file_info ) {
            $sf->{i}{occupied_term_height} += 1;
        }
        if ( $count_table_name_loop > 1 ) {
            $table_name = '';
        }
        my $info = $ax->get_sql_info( $sql ) . ( $file_info ? "\n" . $file_info : '' );
        # Readline
        $table_name = $tf->readline(
            'Table name: ',
            { info => $info, default => $table_name }
        );
        $ax->print_sql_info( $info );
        if ( ! length $table_name ) {
            return;
        }
        $sql->{table} = $ax->quote_table( [ undef, $sf->{d}{schema}, $table_name ] );
        if ( none { $sql->{table} eq $ax->quote_table( $sf->{d}{tables_info}{$_} ) } keys %{$sf->{d}{tables_info}} ) {
            return $table_name;
        }
        $sf->{i}{occupied_term_height} = 4; # prompt, $menu, trailing empty line
        my $prompt = "Table $sql->{table} already exists.";
        my $menu = [ undef, '  New name' ];
        $info = $ax->get_sql_info( $sql );
        # Choose
        my $chosen = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_v}}, info => $info, prompt => $prompt, keep => scalar( @$menu ) }
        );
        $ax->print_sql_info( $info );
        if ( ! defined $chosen ) {
            return;
        }
    }
}


sub __get_column_names {
    my ( $sf, $sql ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my ( $first_row, $user_input ) = ( '- YES', '- NO' );
    my @pre = ( undef );
    my $menu = [ @pre, $first_row, $user_input ];
    my $header_row;
    $sf->{i}{occupied_term_height} = @$menu + 2; # + 2 for prompt and empty line
    my $info = $ax->get_sql_info( $sql );
    # Choose
    my $chosen = $tc->choose(
        $menu,
        { %{$sf->{i}{lyt_v}}, info => $info, prompt => 'Use the first Data Row as the Table Header:', undef => '  <=',
          keep => scalar( @$menu ) }
    );
    $ax->print_sql_info( $info );
    if ( ! defined $chosen ) {
        return;
    }
    elsif ( $chosen eq $first_row ) {
        $header_row = shift @{$sql->{insert_into_args}};
    }
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
        my $menu = [ undef, $yes, $no  ];
        $sf->{i}{occupied_term_height} = @$menu + 2; # + 2 for prompt and empty line
        my $info = $ax->get_sql_info( $sql );
        # Choose
        my $chosen = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_v}}, info => $info, prompt => 'Add an AUTO INCREMENT column:', undef => '  <=',
              keep => scalar( @$menu )  }
        );
        $ax->print_sql_info( $info );
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


sub __edit_column_names {
    my ( $sf, $sql, $column_names ) = @_;
    my $tf = Term::Form->new( $sf->{i}{tf_default} );
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $col_number = 0;
    my $db = $sf->{d}{db};
    my $fields;
    if ( @$column_names ) {
        $fields = [ map { [ ++$col_number, defined $_ ? "$_" : '' ] } @$column_names ];
    }
    else {
        $fields = [ map { [ ++$col_number, defined $_ ? "$_" : '' ] } @{$sql->{create_table_cols}} ];
    }
    $sf->{i}{occupied_term_height} = 3 + @{$sql->{create_table_cols}};
    my $info = $ax->get_sql_info( $sql );
    # Fill_form
    my $form = $tf->fill_form(
        $fields,
        { info => $info, prompt => 'Edit column names:', auto_up => 2,
          confirm => $sf->{i}{confirm}, back => $sf->{i}{back} . '   ' }
    );
    $ax->print_sql_info( $info );
    if ( ! defined $form ) {
        return;
    }
    $column_names = $sql->{create_table_cols} = [ map { $_->[1] } @$form ]; # not quoted
    if ( length $sf->{col_auto} ) {
        $sf->{col_auto} = $sql->{create_table_cols}[0];
    }
    return $column_names;
}


sub __edit_column_types {
    my ( $sf, $sql, $data_types ) = @_;
    my $tf = Term::Form->new( $sf->{i}{tf_default} );
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $unquoted_table_cols = [ @{$sql->{create_table_cols}} ];
    $sql->{create_table_cols} = $ax->quote_simple_many( $sql->{create_table_cols} ); # now quoted
    $sql->{insert_into_cols} = [ @{$sql->{create_table_cols}} ];
    if ( length $sf->{col_auto} ) {
        shift @{$sql->{insert_into_cols}};
    }
    my $fields;
    if ( ! %$data_types && $sf->{o}{create}{data_type_guessing} ) {
        $sf->{i}{occupied_term_height} = 4 + @{$sql->{insert_into_cols}}; # busy string at the height of the prompt
        $ax->print_sql_info( $ax->get_sql_info( $sql ), 'Column data types: guessing ... ' );
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
        $data_types = { map { $_ => uc( $tmp->{$_} ) } keys %$tmp };
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
    $sf->{i}{occupied_term_height} = 3 + @$fields; # prompt, back, confirm and fiels # 4 with trailing empty line
    my $info = $ax->get_sql_info( $sql );
    # Fill_form
    my $col_name_and_type = $tf->fill_form(
        $fields,
        { info => $info, prompt => 'Column data types:', auto_up => 2, read_only => $read_only,
          confirm => $sf->{i}{confirm}, back => $sf->{i}{back} . '   ' }
    );
    $ax->print_sql_info( $info );
    if ( ! $col_name_and_type ) {
        return;
    }
    else {
        no warnings 'uninitialized';
        $sql->{create_table_cols} = [ map { join ' ', @$_ }  @$col_name_and_type ];
    }
    return $data_types;
}


sub __create {
    my ( $sf, $sql, $type ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my ( $no, $yes ) = ( '- NO', '- YES' );
    my $menu = [ undef, $yes, $no ];
    my $prompt = "Create $type $sql->{table}";
    $sf->{i}{occupied_term_height} = @$menu + 2;  # + 2 for prompt and empty line
    if ( @{$sql->{insert_into_args}} ) {
        my $row_count = @{$sql->{insert_into_args}};
        $prompt .= "\nInsert " . insert_sep( $row_count, $sf->{o}{G}{thsd_sep} ) . " row";
        if ( @{$sql->{insert_into_args}} > 1 ) {
            $prompt .= "s";
        }
        $sf->{i}{occupied_term_height} += 1; # second prompt line
    }
    my $info = $ax->get_sql_info( $sql );
    # Choose
    my $create_table_ok = $tc->choose(
        $menu,
        { %{$sf->{i}{lyt_v}}, info => $info, prompt => $prompt, undef => '  <=', keep => scalar( @$menu ) }
    );
    $ax->print_sql_info( $info );
    if ( ! defined $create_table_ok ) {
        return;
    }
    if ( $create_table_ok eq $no ) {
        return 0;
    }
    my $stmt = $ax->get_stmt( $sql, 'Create_' . $type, 'prepare' );
    # don't reset `$sql->{create_table_cols}` and `$sf->{i}{stmt_types}`:
    #    to get a consistent print_sql_info output in CommitSQL
    #    to avoid another confirmation prompt in CommitSQL
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
    require App::DBBrowser::Table::CommitWriteSQL;
    my $cs = App::DBBrowser::Table::CommitWriteSQL->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $commit_ok = $cs->commit_sql( $sql );
    return $commit_ok;
}


sub __generic_header_row {
    my ( $sf, $col_count ) = @_;
    my $c = 0;
    return [ map { 'c' . $c++ } 1 .. $col_count ];
}




1;

__END__
