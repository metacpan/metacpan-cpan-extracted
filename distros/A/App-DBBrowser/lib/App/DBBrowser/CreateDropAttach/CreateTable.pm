package # hide from PAUSE
App::DBBrowser::CreateDropAttach::CreateTable;

use warnings;
use strict;
use 5.014;

use Encode         qw( decode );
use File::Basename qw( basename );

use List::MoreUtils   qw( none any duplicates );
#use SQL::Type::Guess qw();                 # required

use Term::Choose         qw();
use Term::Choose::Util   qw( insert_sep );
use Term::Form           qw();
use Term::Form::ReadLine qw();

use App::DBBrowser::Auxil;
use App::DBBrowser::GetContent;
use App::DBBrowser::Opt::Set;
use App::DBBrowser::Subquery;
use App::DBBrowser::Table::CommitWriteSQL;


sub new {
    my ( $class, $info, $options, $d ) = @_;
    bless {
        i => $info,
        o => $options,
        d => $d
    }, $class;
}


sub create_view {
    my ( $sf ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $sq = App::DBBrowser::Subquery->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $tr = Term::Form::ReadLine->new( $sf->{i}{tr_default} );
    my $sql = {};
    $ax->reset_sql( $sql );
    $sf->{d}{stmt_types} = [ 'Create_View' ];

    SELECT_STMT: while ( 1 ) {
        $sql->{table} = '';
        $sql->{view_select_stmt} = '?';
        my $select_statment = $sq->subquery( $sql );
        $ax->print_sql_info( $ax->get_sql_info( $sql ) );
        if ( ! defined $select_statment ) {
            return;
        }
        $sql->{view_select_stmt} = $select_statment =~ s/^\((.+)\)\z/$1/r;

        VIEW_NAME: while ( 1 ) {
            $sql->{table} = '?';
            my $info = $ax->get_sql_info( $sql );
            # Readline
            my $view = $tr->readline(
                'View name: ' . $sf->{o}{create}{view_name_prefix},
                { info => $info, history => [] }
            );
            $ax->print_sql_info( $info );
            if ( ! length $view ) {
                next SELECT_STMT;
            }
            $view = $sf->{o}{create}{view_name_prefix} . $view;
            $sql->{table} = $ax->qq_table( [ undef, $sf->{d}{schema}, $view, 'VIEW' ] );
            if ( none { $sql->{table} eq $ax->qq_table( $sf->{d}{tables_info}{$_} ) } keys %{$sf->{d}{tables_info}} ) {
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
    my $count_table_name_loop = 0;
    my $goto_filter = 0;
    my $source = {};

    GET_CONTENT: while ( 1 ) {
        $sf->{d}{stmt_types} = [ 'Create_Table', 'Insert' ];
        # first use of {stmt_types} in get_content/from_col_by_col
        my $ok = $gc->get_content( $sql, $source, $goto_filter );
        if ( ! $ok ) {
            return;
        }
        if ( ! @{$sql->{insert_args}[0]} ) {
            # Choose
            $tc->choose(
                [ 'No columns!' ],
                { prompt => 'Continue with ENTER', keep => 1 }
            );
            return;
        }
        my $tablename_default = '';

        GET_TABLE_NAME: while ( 1 ) {
            $tablename_default = $sf->__set_table_name( $sql, $source, $tablename_default, $count_table_name_loop ); # first time print_sql_info
            if ( ! $tablename_default ) {
                $count_table_name_loop = 0;
                $goto_filter = 1;
                next GET_CONTENT;
            }
            my $bu_first_row = [ @{$sql->{insert_args}[0]} ];
            my $orig_row_count = @{$sql->{insert_args}};

            GET_COLUMN_NAMES: while ( 1 ) {
                if ( $orig_row_count - 1 == @{$sql->{insert_args}} ) {
                    unshift @{$sql->{insert_args}}, $bu_first_row;
                }
                $sql->{ct_column_definitions} = [];
                $sql->{insert_col_names}  = [];
                my $header_row = $sf->__get_column_names( $sql );
                if ( ! defined $header_row ) {
                    $sql->{table} = '';
                    $count_table_name_loop++;
                    next GET_TABLE_NAME;
                }
                if ( ! @{$sql->{insert_args}} ) {
                    $sf->{d}{stmt_types} = [ 'Create_Table' ];
                }
                $count_table_name_loop = 0;

                AUTO_INCREMENT: while( 1 ) {
                    $sql->{ct_column_definitions} = [ @$header_row ];  # not quoted
                    $sql->{insert_col_names}  = [ @$header_row ];      # not quoted
                    $sf->{auto_increment} = 0;
                    if ( $sf->{o}{create}{option_ai_column_enabled} && $sf->__primary_key_autoincrement_constraint() ) {
                        my $return = $sf->__autoincrement_column( $sql);
                        if ( ! defined $return ) {
                            next GET_COLUMN_NAMES;
                        }
                    }
                    my @unquoted_ct_column_definitions = @{$sql->{ct_column_definitions}};
                    my @unquoted_insert_col_names = @{$sql->{insert_col_names}};
                    my $column_names = []; # column_names memory

                    EDIT_COLUMN_NAMES: while( 1 ) {
                        $column_names = $sf->__edit_column_names( $sql, $column_names );  # now quoted
                        if ( ! defined $column_names ) {
                            next AUTO_INCREMENT if $sf->{auto_increment};
                            next GET_COLUMN_NAMES;
                        }
                        if ( any { ! length } @{$sql->{ct_column_definitions}} ) {
                            # Choose
                            $tc->choose(
                                [ 'Column with no name!' ],
                                { prompt => 'Continue with ENTER', keep => 1 }
                            );
                            next EDIT_COLUMN_NAMES;
                        }
                        my @duplicates = duplicates map { lc } @{$sql->{ct_column_definitions}};
                        if ( @duplicates ) {
                            # Choose
                            $tc->choose(
                                [ 'Duplicate column name!' ],
                                { prompt => 'Continue with ENTER', keep => 1 }
                            );
                            next EDIT_COLUMN_NAMES;
                        }
                        my @unedited_ct_column_definitions = @{$sql->{ct_column_definitions}};
                        my $data_types = {}; # data_types memory

                        EDIT_COLUMN_TYPES: while( 1 ) {
                            $data_types = $sf->__edit_column_types( $sql, $data_types );
                            if ( ! $data_types ) {
                                $sql->{ct_column_definitions} = [ @unquoted_ct_column_definitions ];
                                $sql->{insert_col_names} = [ @unquoted_insert_col_names ];
                                next EDIT_COLUMN_NAMES;
                            }
                            # CREATE_TABLE
                            my $ok_create_table = $sf->__create( $sql, 'table' );
                            if ( ! defined $ok_create_table ) {
                                $sql->{ct_column_definitions} = [ @unedited_ct_column_definitions ];
                                next EDIT_COLUMN_TYPES;
                            }
                            elsif ( ! $ok_create_table ) {
                                return;
                            }
                            elsif ( @{$sql->{insert_args}} ) {
                                # INSERT_DATA
                                my $ok_insert = $sf->__insert_data( $sql );
                                if ( ! $ok_insert ) {
                                   return;
                                }
                            }
                            return 1;
                        }
                    }
                }
            }
        }
    }
}


sub __set_table_name {
    my ( $sf, $sql, $source, $tablename_default, $count_table_name_loop ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $tr = Term::Form::ReadLine->new( $sf->{i}{tr_default} );
    $ax->print_sql_info( $ax->get_sql_info( $sql ) );

    while ( 1 ) {
        my $file_info;
        if ( $source->{source_type} eq 'file' ) {
            my $file_fs = $source->{file_fs};
            my $file_name = basename decode( 'locale_fs', $file_fs );
            $file_info = sprintf "File: '%s'", $file_name;
            if ( ! length $tablename_default ) {
                if ( length $source->{sheet_name} ) {
                    $file_name =~ s/\.[^.]{1,4}\z//;
                    $tablename_default = $file_name . '_' . $source->{sheet_name};
                }
                else {
                    $tablename_default = $file_name =~ s/\.[^.]{1,4}\z//r;
                }
                $tablename_default =~ s/ /_/g;
            }
        }
        if ( $count_table_name_loop > 1 ) { # to avoid infinite loop when going back with `ENTER`
            $tablename_default = '';
        }
        my $info = $ax->get_sql_info( $sql ) . ( $file_info ? "\n" . $file_info : '' );
        # Readline
        my $table_name = $tr->readline(
            'Table name: ',
            { info => $info, default => $tablename_default, history => [] }
        );
        $ax->print_sql_info( $info );
        if ( ! length $table_name ) {
            return;
        }
        $sql->{table} = $ax->qq_table( [ undef, $sf->{d}{schema}, $table_name ] );
        if ( none { $sql->{table} eq $ax->qq_table( $sf->{d}{tables_info}{$_} ) } keys %{$sf->{d}{tables_info}} ) {
            return $table_name;
        }
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
        $tablename_default = $tablename_default ? $table_name : '';
        $count_table_name_loop++;
    }
}


sub __get_column_names {
    my ( $sf, $sql ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my ( $first_row, $user_input ) = ( '- YES', '- NO' );
    my $hidden = 'Use the first Data Row as the Table Header:';
    my @pre = ( $hidden, undef );
    my $menu = [ @pre, $first_row, $user_input ];

    while ( 1 ) {
        my $info = $ax->get_sql_info( $sql );
        # Choose
        my $idx = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_v}}, info => $info, prompt => '', index => 1, default => 1, undef => '  <=',
            keep => scalar( @$menu ) }
        );
        $ax->print_sql_info( $info );
        if ( ! defined $idx || ! defined $menu->[$idx] ) {
            return;
        }
        my $header_row;
        if ( $menu->[$idx] eq $hidden ) {
            my $opt_set = App::DBBrowser::Opt::Set->new( $sf->{i}, $sf->{o} );
            $opt_set->set_options( 'create' );
            next;
        }
        elsif ( $menu->[$idx] eq $first_row ) {
            $header_row = shift @{$sql->{insert_args}};
            $header_row = [ map { defined ? "$_" : '' } @$header_row ];
        }
        else {
            $header_row = [ ( '' ) x @{$sql->{insert_args}[0]} ];
        }
        return $header_row;
    }
}


sub __autoincrement_column {
    my ( $sf, $sql ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my ( $no, $yes ) = ( '- NO ', '- YES' );
    my $menu = [ undef, $yes, $no  ];
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
        $sf->{auto_increment} = 0;
    }
    else {
        my $auto_increment_column_name = $sf->{o}{create}{default_ai_column_name} // 'Id'; ##
        unshift @{$sql->{ct_column_definitions}}, $auto_increment_column_name;
        $sf->{auto_increment} = 1;
    }
    return 1;
}


sub __primary_key_autoincrement_constraint {
    # provide "primary_key_autoincrement_constraint" only if also "first_col_is_autoincrement" is available
    my ( $sf ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $driver = $sf->{i}{driver};
    if ( $driver eq 'SQLite' ) {
        return "INTEGER PRIMARY KEY";
    }
    if ( $driver =~ /^(?:mysql|MariaDB)\z/ ) {
        return "INT NOT NULL AUTO_INCREMENT PRIMARY KEY";
        # mysql: NOT NULL added automatically with AUTO_INCREMENT
    }
    if ( $driver eq 'Pg' ) {
        my $pg_major_version = $ax->major_server_version();
        if ( $pg_major_version >= 10 ) {
            # since PostgreSQL version 10
            return "INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY";
        }
        else {
            return "SERIAL PRIMARY KEY";
        }
    }
    if ( $driver eq 'Firebird' ) {
        my $firebird_major_version = $ax->major_server_version();
        if ( $firebird_major_version >= 4 ) {
            return "INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY";
        }
        elsif ( $firebird_major_version >= 3 ) {
            return "INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY";
        }
    }
    if ( $driver eq 'DB2' ) {
        return "INT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY";
    }
    if ( $driver eq 'Oracle' ) {
        my $ora_major_server_version = $ax->major_server_version();
        if ( $ora_major_server_version >= 12 ) {
            return "NUMBER GENERATED ALWAYS AS IDENTITY";   # Oracle 12c or greater
        }
    }
}


sub __edit_column_names {
    my ( $sf, $sql, $column_names ) = @_;
    my $tf = Term::Form->new( $sf->{i}{tf_default} );
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $col_number = 0;
    my $fields;
    if ( @$column_names ) {
        $fields = [ map { [ ++$col_number, $_ ] } @$column_names ];
    }
    else {
        $fields = [ map { [ ++$col_number, $_ ] } @{$sql->{ct_column_definitions}} ];
    }
    my $info = $ax->get_sql_info( $sql );
    # Fill_form
    my $form = $tf->fill_form(
        $fields,
        { info => $info, prompt => 'Edit column names:', confirm => $sf->{i}{confirm}, back => $sf->{i}{back} . '   ' }
    );
    $ax->print_sql_info( $info );
    if ( ! defined $form ) {
        return;
    }
    $column_names = [ map { $_->[1] } @$form ];
    $sql->{ct_column_definitions} = $ax->quote_cols( $column_names ); # now quoted
    $sql->{insert_col_names} = [ @{$sql->{ct_column_definitions}} ];  # now quoted
    if ( $sf->{auto_increment} ) {
        shift @{$sql->{insert_col_names}};
    }
    $sql->{ct_table_constraints} = [];
    $sql->{ct_table_options} = [];
    return $column_names;
}


sub __edit_column_types {
    my ( $sf, $sql, $data_types ) = @_;
    my $tf = Term::Form->new( $sf->{i}{tf_default} );
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $fields;
    if ( ! %$data_types && $sf->{o}{create}{data_type_guessing} ) {
        $ax->print_sql_info( $ax->get_sql_info( $sql ), 'Column data types: guessing ... ' );
        require SQL::Type::Guess;
        my $g = SQL::Type::Guess->new();
        my $header = $sql->{insert_col_names}; #
        my $table  = $sql->{insert_args};
        my @aoh;
        for my $row ( @$table ) {
            push @aoh, {
                map { $header->[$_] => $row->[$_] } 0 .. $#$header
            };
        }
        $g->guess( @aoh );
        my $tmp = $g->column_type;
        $data_types = { map { $_ => uc( $tmp->{$_} ) } keys %$tmp };
    }
    if ( defined $data_types ) {
        $fields = [ map { [ $_, $data_types->{$_} ] } @{$sql->{insert_col_names}} ];
    }
    else {
        $fields = [ map { [ $_, '' ] } @{$sql->{insert_col_names}} ];
    }
    my $read_only = []; ##
    if ( $sf->{auto_increment} ) {
        unshift @$fields, [ $sql->{ct_column_definitions}[0], $sf->__primary_key_autoincrement_constraint() ];
        $read_only = [ 0 ];
    }
    if ( $sf->{i}{driver} =~ /^(?:Pg|Firebird|Informix|Oracle)\z/ ) {
        for my $field ( @$fields ) {
            if ( defined $field->[1] && $field->[1] eq 'DATETIME' ) {
                $field->[1] = 'TIMESTAMP'                 if $sf->{i}{driver} =~ /^(?:Pg|Firebird)\z/;
                $field->[1] = 'DATE'                      if $sf->{i}{driver} eq 'Oracle';
                $field->[1] = 'DATETIME YEAR TO FRACTION' if $sf->{i}{driver} eq 'Informix';
                # Informix: DATETIME largest_qualifier TO smallest_qualifier
            }
        }
    }
    my $constraint_rows = $sf->{o}{create}{table_constraint_rows};
    my $tbl_option_rows = $sf->{o}{create}{table_option_rows};
    my $skip = ' ';
    if ( $constraint_rows ) {
        push @$fields, [ $skip ];
        for my $i ( 0 .. $constraint_rows - 1 ) {
            push @$fields, [ 'Constraint', $sql->{ct_table_constraints}[$i] // '' ];
        }
    }
    if ( $tbl_option_rows ) {
        push @$fields, [ $skip ];
        for my $i ( 0 .. $tbl_option_rows - 1 ) {
            push @$fields, [ 'Tbl Option', $sql->{ct_table_options}[$i] // '' ];
        }
    }
    my $info = $ax->get_sql_info( $sql );
    # Fill_form
    my $filled_form = $tf->fill_form(
        $fields,
        { info => $info, prompt => 'Column data types:', read_only => $read_only,
          confirm => $sf->{i}{confirm}, back => $sf->{i}{back} . '   ' }
    );
    $ax->print_sql_info( $info );
    if ( ! $filled_form ) {
        return;
    }
    if ( $tbl_option_rows ) {
        $sql->{ct_table_options} = [
            grep { length } map { $_->[1] } splice @$filled_form, -$tbl_option_rows, $tbl_option_rows
        ];
        pop @$filled_form;
    }
    if ( $constraint_rows ) {
        $sql->{ct_table_constraints} = [
            grep { length } map { $_->[1] } splice @$filled_form, -$constraint_rows, $constraint_rows
        ];
        pop @$filled_form;
    }
    $sql->{ct_column_definitions} = [
        map { length $_->[1] ? join ' ', @$_ : $_->[0] }  @$filled_form
    ];
    $data_types = { map { $_->[0] => $_->[1] } @$filled_form };
    return $data_types;
}


sub __create {
    my ( $sf, $sql, $type ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my ( $no, $yes ) = ( '- NO', '- YES' );
    my $menu = [ undef, $yes, $no ]; ##
    my $prompt = "Create $type $sql->{table}";
    if ( @{$sql->{insert_args}} ) {
        my $row_count = @{$sql->{insert_args}};
        $prompt .= "\nInsert " . insert_sep( $row_count, $sf->{i}{info_thsd_sep} ) . " row";
        if ( @{$sql->{insert_args}} > 1 ) {
            $prompt .= "s";
        }
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
    my $stmt = $ax->get_stmt( $sql, 'Create_' . ucfirst( $type ), 'prepare' );
    # don't reset `$sql->{ct_column_definitions}` and `$sf->{d}{stmt_types}`:
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
    my $cs = App::DBBrowser::Table::CommitWriteSQL->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $commit_ok = $cs->commit_sql( $sql );
    return $commit_ok;
}



1;

__END__
