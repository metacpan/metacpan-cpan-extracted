package # hide from PAUSE
App::DBBrowser::Auxil;

use warnings;
use strict;
use 5.016;

use Encode       qw( decode );
use Scalar::Util qw( looks_like_number );
#use Storable     qw();  # required


use DBI::Const::GetInfoType;
use JSON::MaybeXS            qw( decode_json );
use List::MoreUtils          qw( none );

use Term::Choose            qw();
use Term::Choose::Constants qw( EXTRA_W );
use Term::Choose::LineFold  qw( line_fold );
use Term::Choose::Screen    qw( clear_screen );
use Term::Choose::Util      qw( insert_sep get_term_width get_term_height unicode_sprintf );
use Term::Form::ReadLine    qw();


sub new {
    my ( $class, $info, $options, $d ) = @_;
    bless {
        i => $info,
        o => $options,
        d => $d
    }, $class;
}


sub reset_sql {
    my ( $sf, $sql ) = @_;
    # preserve base data: table name, column names and data types:
    my $backup = {
        table => $sql->{table} // '',
        columns => $sql->{columns} // [],
        data_types => $sql->{data_types} // {},
    };
    # reset:
    delete @{$sql}{ keys %$sql }; # not "$sql = {}" so $sql is still pointing to the outer $sql
    # initialize:
    my @string = qw( distinct_stmt set_stmt where_stmt having_stmt order_by_stmt limit_stmt offset_stmt );
    my @array  = qw( group_by_cols selected_cols set_args order_by_cols
                     ct_column_definitions ct_table_constraints ct_table_options
                     insert_col_names insert_args );
    my @hash   = qw( alias );
    @{$sql}{@string} = ( '' ) x  @string;
    @{$sql}{@array}  = map{ [] } @array;
    @{$sql}{@hash}   = map{ {} } @hash;
    for my $y ( keys %$backup ) {
        $sql->{$y} = $backup->{$y};
    }
}


sub __stmt_fold {
    my ( $sf, $term_w, $used_for, $stmt, $indent ) = @_;
    if ( $used_for eq 'print' ) {
        my $in = ' ' x $sf->{o}{G}{base_indent};
        my %tabs = ( init_tab => $in x $indent, subseq_tab => $in x ( $indent + 1 ) );
        return line_fold( $stmt, { width => $term_w, %tabs, join => 0 } );
    }
    else {
        return $stmt;
    }
}


sub __select_cols {
    my ( $sf, $sql ) = @_;
    my @cols;
    if ( @{$sql->{selected_cols}} ) {
        @cols = @{$sql->{selected_cols}};
    }
    elsif ( keys %{$sql->{alias}} && ! $sql->{aggregate_mode} ) {
        @cols = @{$sql->{columns}};
        # use column names and not * if columns have aliases (join)
        # unless aggregate_mode (columns are aggregate functions and group by columns) ##
    }
    if ( ! @cols ) {
        return "" if $sql->{aggregate_mode};
        return " *";
    }
    elsif ( ! keys %{$sql->{alias}} ) {
        return ' ' . join ', ', @cols;
    }
    else {
        return ' ' . join ', ', map { length $sql->{alias}{$_} ? "$_ AS $sql->{alias}{$_}" : $_ } @cols;
    }
}


sub __group_by_stmt {
    my ( $sf, $sql ) = @_;
    my $aliases = $sf->{o}{alias}{use_in_group_by} ? $sql->{alias} : {};
    return "GROUP BY " . join ', ', map { length $aliases->{$_} ? $aliases->{$_} : $_ } @{$sql->{group_by_cols}};
}


sub cte_stmts {
    my ( $sf, $used_for, $indent1 ) = @_;
    if ( ! @{$sf->{d}{cte_history}//[]} ) {
        return;
    }
    if ( length( $sf->{d}{main_info} ) && $used_for eq 'print' ) { ##
        # else the cte definitions would be printed twice if a cte is used inside a cte.
        return;
    }
    my $ctes = $sf->{d}{cte_history};
    my $with = "WITH";
    for my $cte ( @$ctes ) {
        $with .= " RECURSIVE" and last if $cte->{is_recursive};
    }
    my $term_w = get_term_width() + EXTRA_W;
    my @tmp = ( $with );
    for my $cte ( @$ctes ) {
        push @tmp, $sf->__stmt_fold( $term_w, $used_for, sprintf( '%s AS (%s),', $cte->{full_name}, $cte->{query} ), $indent1 );
    }
    $tmp[-1] =~ s/,\z//;
    push @tmp, " ";
    return join "\n", @tmp;
}


sub get_stmt {
    my ( $sf, $sql, $stmt_type, $used_for ) = @_;
    my $term_w = get_term_width() + EXTRA_W;
    my $in = ' ' x $sf->{o}{G}{base_indent};
    my $indent0 = 0;
    my $indent1 = 1;
    my $indent2 = 2;
    my $table = $sql->{table};
    my @tmp;
    my $ctes = $sf->cte_stmts( $used_for, $indent1 );
    if ( defined $ctes ) {
        push @tmp, $ctes;
    }
    if ( $stmt_type eq 'Drop_Table' ) {
        @tmp = ( $sf->__stmt_fold( $term_w, $used_for, "DROP TABLE $table", $indent0 ) );
    }
    elsif ( $stmt_type eq 'Drop_View' ) {
        @tmp = ( $sf->__stmt_fold( $term_w, $used_for, "DROP VIEW $table", $indent0 ) );
    }
    elsif ( $stmt_type eq 'Create_Table' ) {
        my $stmt = sprintf "CREATE TABLE $table (%s)", join ', ', @{$sql->{ct_column_definitions}}, @{$sql->{ct_table_constraints}};
        if ( @{$sql->{ct_table_options}} ) {
            $stmt .= ' ' . join ', ', @{$sql->{ct_table_options}};
        }
        @tmp = ( $sf->__stmt_fold( $term_w, $used_for, $stmt, $indent0 ) );
    }
    elsif ( $stmt_type eq 'Create_View' ) {
        @tmp = ( $sf->__stmt_fold( $term_w, $used_for, "CREATE VIEW $table", $indent0 ) );
        push @tmp, $sf->__stmt_fold( $term_w, $used_for, "AS " . $sql->{view_select_stmt}, $indent1 );
    }
    elsif ( $stmt_type eq 'Select' ) {
        push @tmp, $sf->__stmt_fold( $term_w, $used_for, "SELECT" . $sql->{distinct_stmt} . $sf->__select_cols( $sql ), $indent0 );
        push @tmp, $sf->__stmt_fold( $term_w, $used_for, "FROM " . $table,   $indent1 );
        push @tmp, $sf->__stmt_fold( $term_w, $used_for, $sql->{where_stmt},    $indent2 )        if $sql->{where_stmt};
        push @tmp, $sf->__stmt_fold( $term_w, $used_for, $sf->__group_by_stmt( $sql ), $indent2 ) if @{$sql->{group_by_cols}};
        push @tmp, $sf->__stmt_fold( $term_w, $used_for, $sql->{having_stmt},   $indent2 )        if $sql->{having_stmt};
        push @tmp, $sf->__stmt_fold( $term_w, $used_for, $sql->{order_by_stmt}, $indent2 )        if $sql->{order_by_stmt};
        if ( $sql->{limit_stmt} =~ /^LIMIT\b/ ) {
            push @tmp, $sf->__stmt_fold( $term_w, $used_for, $sql->{limit_stmt},  $indent2 );
            push @tmp, $sf->__stmt_fold( $term_w, $used_for, $sql->{offset_stmt}, $indent2 ) if $sql->{offset_stmt};
        }
        else {
            push @tmp, $sf->__stmt_fold( $term_w, $used_for, $sql->{offset_stmt}, $indent2 ) if $sql->{offset_stmt};
            push @tmp, $sf->__stmt_fold( $term_w, $used_for, $sql->{limit_stmt},  $indent2 ) if $sql->{limit_stmt};
        }
    }
    elsif ( $stmt_type eq 'Delete' ) {
        push @tmp, $sf->__stmt_fold( $term_w, $used_for, "DELETE FROM " . $table, $indent0 );
        push @tmp, $sf->__stmt_fold( $term_w, $used_for, $sql->{where_stmt}, $indent1 ) if $sql->{where_stmt};
    }
    elsif ( $stmt_type eq 'Update' ) {
        push @tmp, $sf->__stmt_fold( $term_w, $used_for, "UPDATE " . $table, $indent0 );
        push @tmp, $sf->__stmt_fold( $term_w, $used_for, $sql->{set_stmt},   $indent1 ) if $sql->{set_stmt};
        push @tmp, $sf->__stmt_fold( $term_w, $used_for, $sql->{where_stmt}, $indent1 ) if $sql->{where_stmt};
    }
    elsif ( $stmt_type eq 'Insert' ) {
        my $columns = join ', ', map { $_ // '' } @{$sql->{insert_col_names}};
        my $placeholders = join ', ', ( '?' ) x @{$sql->{insert_col_names}};
        my $stmt = "INSERT INTO $sql->{table} ($columns) VALUES($placeholders)";
        @tmp = ( $sf->__stmt_fold( $term_w, $used_for, $stmt, $indent0 ) );
        if ( $used_for eq 'print' ) {
            my $arg_rows = $sf->info_format_insert_args( $sql, $in x 2 );
            push @tmp, @$arg_rows;
        }
    }
    elsif ( $stmt_type eq 'Join' ) {
        my $select_from;
        if ( $used_for eq 'prepare' ) {
            @tmp = ();
            # prepare: this stmt is used as table in the select stmt
            # no ctes, they are added in the select stmt
            $select_from = "";
        }
        else {
            $select_from = "SELECT * FROM ";
       }
        my @join_data = @{$sql->{join_data}//[]};
        if ( @join_data ) {
            my $master_data = shift @join_data;
            push @tmp, $sf->__stmt_fold( $term_w, $used_for, $select_from . $master_data->{table}, $indent0 );
            if ( @join_data ) {
                my $last_table = pop @join_data;
                for my $slave_data ( @join_data ) {
                    my $sub_stmt = join ' ', grep { length } @{$slave_data}{ qw(join_type table condition) };
                    push @tmp, $sf->__stmt_fold( $term_w, $used_for, $sub_stmt, $indent1 );
                }
                my $sub_stmt = join ' ', grep { length } @{$last_table}{ qw(join_type table condition) }, $sql->{on_stmt};
                push @tmp, $sf->__stmt_fold( $term_w, $used_for, $sub_stmt, $indent1 );     # either condition or on_stmt
            }
        }
        else {
            push @tmp, $sf->__stmt_fold( $term_w, $used_for, $select_from, $indent0 );
        }
    }
    elsif ( $stmt_type eq 'Union' ) {
        if ( $used_for eq 'prepare' ) {
            @tmp = ();
            # prepare: this stmt is used as a table in the select stmt
            # @tmp = (): no ctes, they are added in the select stmt
            push @tmp, "(";
            if ( @{$sql->{subselect_stmts}//[]} ) {
                my $extra = 0;
                for my $stmt ( @{$sql->{subselect_stmts}} ) {
                    $extra-- if $stmt eq ")" && $extra;
                    my $indent = $in x ( 1 + $extra );
                    push @tmp, $indent . $stmt;
                    $extra++ if $stmt eq "(";
                }
            }
            push @tmp, ")";
        }
        else {
            push @tmp, $sf->__stmt_fold( $term_w, $used_for, "SELECT *", $indent0 ); ##
            push @tmp, $sf->__stmt_fold( $term_w, $used_for, "FROM ()", $indent1 ); ##
            if ( @{$sql->{subselect_stmts}//[]} ) {
                push @tmp, ' ';
                my $extra = 0;
                for my $stmt ( @{$sql->{subselect_stmts}} ) {
                    $extra-- if $stmt eq ")" && $extra;
                    push @tmp, $sf->__stmt_fold( $term_w, $used_for, $stmt, $indent0 + $extra );
                    $extra++ if $stmt eq "(";
                }
            }
        }
    }
    my $stmt = join( "\n", @tmp );
    if ( $used_for eq 'print' ) {
        if ( length $sf->{d}{main_info} ) {
            my $sq_indent = $in;
            $stmt =~ s/(^|\n)/$1$sq_indent/gs;
            $stmt = $sf->{d}{main_info} . "\n" . $stmt;
        }
        $stmt .= "\n" ;
    }
    return $stmt;
}


sub info_format_insert_args {
    my ( $sf, $sql, $indent ) = @_;
    my $term_h = get_term_height();
    my $term_w = get_term_width() + EXTRA_W;
    my $row_count = @{$sql->{insert_args}};
    if ( $row_count == 0 ) {
        return [];
    }
    my $col_count = 0; ##
    if ( $sf->{d}{stmt_types}[0] && $sf->{d}{stmt_types}[0] eq 'Create_Table' ) {
        $col_count = @{$sql->{insert_args}[0]//[]};
        #$col_count = @{$sql->{ct_column_definitions//[]}};
        $col_count += 1 + $sf->{o}{create}{table_constraint_rows} if $sf->{o}{create}{table_constraint_rows};
        $col_count += 1 + $sf->{o}{create}{table_option_rows}     if $sf->{o}{create}{table_option_rows};
        $col_count += 12;
        if ( $col_count < 22 ) {
            $col_count = 22;
        }
    }
    else {
        $col_count = 22;
    }
    my $avail_h = $term_h - $col_count;
    if ( $avail_h < $term_h / 3.5 ) {
        $avail_h = int $term_h / 3.5;
    }
    if ( $avail_h < 5) {
        $avail_h = 5;
    }
    my $tmp = [];
    if ( $row_count > $avail_h ) {
        $avail_h -= 2; # for "[...]" + "[count rows]"
        my $count_part_1 = int( $avail_h / 1.5 );
        my $count_part_2 = $avail_h - $count_part_1;
        my $begin_idx_part_1 = 0;
        my $end___idx_part_1 = $count_part_1 - 1;
        my $begin_idx_part_2 = $row_count - $count_part_2;
        my $end___idx_part_2 = $row_count - 1;
        for my $row ( @{$sql->{insert_args}}[ $begin_idx_part_1 .. $end___idx_part_1 ] ) {
            push @$tmp, $sf->__prepare_data_row( $row, $indent, $term_w );
        }
        push @$tmp, $indent . '[...]';
        for my $row ( @{$sql->{insert_args}}[ $begin_idx_part_2 .. $end___idx_part_2 ] ) {
            push @$tmp, $sf->__prepare_data_row( $row, $indent, $term_w );
        }
        my $row_count = scalar( @{$sql->{insert_args}} );
        push @$tmp, $indent . '[' . insert_sep( $row_count, $sf->{i}{info_thsd_sep} ) . ' rows]';
    }
    else {
        for my $row ( @{$sql->{insert_args}} ) {
            push @$tmp, $sf->__prepare_data_row( $row, $indent, $term_w );
        }
    }
    return $tmp;
}


sub __prepare_data_row {
    my ( $sf, $row, $indent, $term_w ) = @_;
    my $list_sep = ', ';
    no warnings 'uninitialized';
    my $row_str = join( $list_sep, map { s/\t/  /g; s/\n/\\n/g; s/\v/\\v/g; $_ } @$row );
    return unicode_sprintf( $indent . $row_str, $term_w, { suffix_on_truncate => $sf->{i}{dots} } );
}


sub print_sql_info {
    my ( $sf, $info, $waiting ) = @_;
    if ( ! defined $info ) {
        return;
    }
    print clear_screen();
    print $info, "\n";
    if ( defined $waiting ) {
        print $waiting . "\r";
    }
}


sub get_sql_info {
    my ( $sf, $sql ) = @_;
    my $stmt = '';
    for my $stmt_type ( @{$sf->{d}{stmt_types}} ) {
        $stmt .= $sf->get_stmt( $sql, $stmt_type, 'print' );
    }
    return $stmt;
}


sub sql_limit {
    my ( $sf, $rows ) = @_;
    my $driver = $sf->{i}{driver}; # Use driver so that dbms remains optional.
    if ( $driver =~ /^(?:SQLite|mysql|MariaDB|Pg|DuckDB)\z/ ) {
        return " LIMIT $rows";
    }
    elsif ( $driver =~ /^(?:Firebird|DB2|Oracle)\z/ ) {
        return " FETCH NEXT $rows ROWS ONLY"
    }
    else {
        return "";
    }
}
#sub sql_limit {
#    my ( $sf, $rows ) = @_;
#    my $dbms = $sf->{i}{dbms};
#    if ( $dbms =~ /^(?:SQLite|mysql|MariaDB|Pg|DuckDB)\z/ ) {
#        return " LIMIT $rows";
#    }
#    elsif ( $dbms =~ /^(?:Firebird|DB2|Oracle)\z/ ) {
#        return " FETCH NEXT $rows ROWS ONLY"
#    }
#    elsif ( $dbms eq 'MSSQL' ) {
#        return " OFFSET 0 ROWS FETCH NEXT $rows ROWS ONLY"
#    }
#    else {
#        return "";
#    }
#}



sub column_names_and_types {
    my ( $sf, $table ) = @_;
    my $driver = $sf->{i}{driver};
    # without `LIMIT 0` slower with big tables: mysql, MariaDB and Pg
    # no difference with SQLite, Firebird, DB2 and Informix
    my $column_names = [];
    my $column_types = [];
    if ( ! eval {
        my $stmt = '';
        my $ctes = $sf->cte_stmts( 'prepare', 0 );
        if ( defined $ctes ) {
            $stmt = $ctes;
        }
        $stmt .= "SELECT * FROM " . $table . $sf->sql_limit( 0 );
        my $sth = $sf->{d}{dbh}->prepare( $stmt );
        if ( $driver eq 'SQLite' ) {
            $column_names = [ @{$sth->{NAME}} ];
            if ( $sf->{d}{dbh}{sqlite_see_if_its_a_number} ) {
                $column_types = [];
            }
            else {
                my $rx_numeric = 'INTEGER|INT$|DOUBLE|REAL|NUM|FLOAT|DEC|BOOL|BIT|MONEY';
                $column_types = [ map { ! $_ || $_ =~ /$rx_numeric/i ? 2 : 1 } @{$sth->{TYPE}} ];
            }
        }
        #elsif ( $driver eq 'DuckDB' ) {
        #    $sth->execute();
        #    $column_names = [ map { decode('UTF-8', $_) } @{$sth->{NAME}} ];
        #    $column_types = [ @{$sth->{TYPE}} ];
        #}
        else {
            $sth->execute();
            $column_names = [ @{$sth->{NAME}} ];
            $column_types = [ @{$sth->{TYPE}} ];
        }
        1 }
    ) {
        $sf->print_error_message( $@ );
        return;
    }
    $column_names = $sf->quote_cols( $column_names );
    return $column_names, $column_types;
}


sub is_numeric {
    my ( $sf, $sql, $col ) = @_;
    return -1 if ! length $sql->{data_types}{$col};
    return  1 if $sql->{data_types}{$col} >= 2 && $sql->{data_types}{$col} <= 8;
    return  0;
}


sub pg_column_to_text {
    my ( $sf, $sql, $col ) = @_;
    return $col if ! $sf->{o}{G}{pg_autocast};
    return $col if defined $sql->{data_types}{$col} && ( $sql->{data_types}{$col} == 1 || $sql->{data_types}{$col} == 12 );
    return $col if $col =~ /^(?:CONCAT|LEFT|LOWER|LPAD|LTRIM|REPLACE|REVERSE|RIGHT|RPAD|RTRIM|SUBSTRING|SUBSTR|TRIM|UPPER|TO_CHAR)\(/;
    return $col . "::text";
}


sub table_alias {
    my ( $sf, $sql, $type, $table, $default ) = @_;
    #
    # Aliases mandatory:
    # JOIN talbes
    # Derived Tables: mysql, MariaDB, Pg
    #
    my $bu_default_table_alias_count = $sf->{d}{default_table_alias_count};
    my $auto_default = 't' . ++$sf->{d}{default_table_alias_count};
    $default //= $auto_default;
    my $alias = $sf->alias( $sql, $type, $table, $default );
    if ( ! length $alias ) {
        $sf->{d}{default_table_alias_count} = $bu_default_table_alias_count;
        return;
    }
    if ( $alias ne $sf->quote_alias( $auto_default ) ) {
        $sf->{d}{default_table_alias_count} = $bu_default_table_alias_count;
    }
    if ( none { $_ eq $alias } @{$sf->{d}{table_aliases}{$table}} ) {
        push @{$sf->{d}{table_aliases}{$table}}, $alias;
    }
    return $alias;
}


sub alias {
    my ( $sf, $sql, $type, $identifier, $default ) = @_;
    # 0 = NO
    # 1 = AUTO
    # 2 = ASK
    # 3 = ASK/AUTO
    my $alias;
    if ( $sf->{o}{alias}{$type} == 0 ) {
        return;
    }
    elsif ( $sf->{o}{alias}{$type} == 1 ) {
        $alias = $default;
    }
    elsif ( $sf->{o}{alias}{$type} == 2 || $sf->{o}{alias}{$type} == 3 ) {
        my $tr = Term::Form::ReadLine->new( $sf->{i}{tr_default} );
        my $info = $sf->get_sql_info( $sql );
        $info .= $identifier =~ /^\n/ ? $identifier : "\n$identifier"; # case
        # Readline
        $alias = $tr->readline(
            'as ',
            #{ info => $info, history => [ 'a' .. 'z' ] }
            { info => $info, history => [ 'a' .. 'z' ], default => $sql->{alias}{$identifier} } ##
        );
        $sf->print_sql_info( $info );
        if ( $sf->{o}{alias}{$type} == 3 && ! length $alias ) {
            $alias = $default;
        }
    }
    if ( length $alias ) {
        $alias = $sf->quote_alias( $alias );
        return $alias;
    }
    return;
}


sub qualified_identifier {
    my ( $sf, @id ) = @_;
#    my $catalog = ( @id >= 3 ) ? shift @id : undef;        # catalog not used (if used, uncomment also catalog_location and catalog_name_sep)
    my $qualified_id = join '.', grep { defined } @id;
#    if ( $catalog ) {
#        if ( $qualified_id ) {
#            $qualified_id = ( $sf->{d}{catalog_location} == 2 )
#                ? $qualified_id . $sf->{d}{catalog_name_sep} . $catalog
#                : $catalog   . $sf->{d}{catalog_name_sep} . $qualified_id;
#        } else {
#            $qualified_id = $catalog;
#        }
#    }
    return $qualified_id;
}


sub __quote_identifiers {
    my ( $sf, @identifier ) = @_;
    my $quote = $sf->{d}{identifier_quote_char};
    for ( @identifier ) {
        if ( ! defined ) {
            next;
        }
        $_ =~ s/$quote/$quote$quote/g;
        $_ = qq{$quote$_$quote};
    }
    return @identifier;
}


sub qq_table {
    my ( $sf, $table_info ) = @_;
    my $dbms = $sf->{i}{dbms};
    # 0 = catalog, 1 = schema, 2 = table_name, 3 = table_type
    my @idx;
    if ( $sf->{d}{db_attached} ) {
        # If a SQLite database has databases attached, the fully qualified table name is used in SQL code regardless of
        # the setting of the option 'qualified_table_name' because attached databases could have tables with the same
        # name.
        if ( $dbms eq 'SQLite' ) {
            @idx = ( 1, 2 );
        }
        elsif ( $dbms eq 'DuckDB' ) {
            @idx = ( 0, 2 );
        }
        #@idx = ( 0, 1, 2 ); # both
    }
    elsif ( $sf->{o}{G}{qualified_table_name} ) {
        @idx = ( 1, 2 );
    }
    else {
        @idx = ( 2 );
    }
    if ( $sf->{o}{G}{quote_tables} ) {
        return $sf->qualified_identifier( $sf->__quote_identifiers( @{$table_info}[ @idx ] ) );
    }
    else {
        return $sf->qualified_identifier( @{$table_info}[@idx] );
    }
}


sub quote_table {
    my ( $sf, $table ) = @_;
    if ( $sf->{o}{G}{quote_tables} ) {
        ( $table ) = $sf->__quote_identifiers( $table );
    }
    return $table;
}


sub quote_column {
    my ( $sf, $column ) = @_;
    if ( $sf->{o}{G}{quote_columns} ) {
        ( $column ) = $sf->__quote_identifiers( $column );
    }
    return $column;
}


sub quote_cols {
    my ( $sf, $cols ) = @_;
    if ( $sf->{o}{G}{quote_columns} ) {
        $cols = [ $sf->__quote_identifiers( @$cols ) ];
    }
    return $cols;
}


sub quote_alias { ##
    my ( $sf, $alias ) = @_;
    #if ( $sf->{o}{G}{quote_aliases} ) {
    if ( $sf->{o}{G}{quote_columns} ) {
        ( $alias ) = $sf->__quote_identifiers( $alias );
    }
    return $alias;
}


sub unquote_identifier {
    my ( $sf, $identifier ) = @_;
    my $qc = quotemeta( $sf->{d}{identifier_quote_char} );
    $identifier =~ s/$qc(?=(?:$qc$qc)*(?:[^$qc]|\z))//g;
    return $identifier;
}


sub quote_if_not_numeric {
    my ( $sf, $value ) = @_;
    if ( looks_like_number $value ) {
        return $value;
    }
    else {
        return $sf->{d}{dbh}->quote( $value );
    }
}


sub unquote_constant {
    my ( $sf, $constant ) = @_;
    return if ! defined $constant;
    if ( $constant =~ /^'(.*)'\z/ ) {
        $constant = $1;
        if ( $sf->{i}{dbms} =~ /^(?:mysql|MariaDB)\z/ ) {
            $constant =~ s/\\(.)/$1/g;
        }
        else {
            $constant =~ s/''/'/g;
            #$constant =~ s/'(?=(?:'')*(?:[^']|\z))//g;
        }
    }
    return $constant;
}


sub regex_quoted_literal {
    my ( $sf ) = @_;
    if ( $sf->{i}{dbms} =~ /^(?:mysql|MariaDB)\z/ ) {
        return qr/(?<!')'(?:[^\\']|\\'|\\\\)*'(?!')/;
    }
    else {
        return qr/(?<!')'(?:[^']|'')*'(?!')/;
    }
}


sub regex_quoted_identifier {
    my ( $sf ) = @_;
    my $iqc = $sf->{d}{identifier_quote_char};
    return "$iqc(?:[^$iqc]|$iqc$iqc)+$iqc";
}


sub normalize_space_in_stmt {
    my ( $sf, $stmt ) = @_;
    my $quoted_literal = $sf->regex_quoted_literal();
    my $iqc = $sf->{d}{identifier_quote_char};
    my $quoted_identifier = $sf->regex_quoted_identifier();
    my $split_rx = qr/ ( $quoted_identifier | $quoted_literal ) /x;
    $stmt =~ s/^\s+|\s+\z//g;
    $stmt = join '', map {
        if ( ! /^[$iqc']/ ) { s/\s+/ /g; s|\(\s|(|; s|\s\)|)| };
        $_
    } split $split_rx, $stmt;
    return $stmt;
}


sub major_server_version {
    my ( $sf ) = @_;
    my $dbms = $sf->{i}{dbms};
    my $dbh = $sf->{d}{dbh};
    my $major_server_version;
    if ( $dbms eq 'Firebird' ) {
        eval {
            my ( $firebird_version ) = $dbh->selectrow_array( "SELECT RDB\$GET_CONTEXT('SYSTEM', 'ENGINE_VERSION') FROM RDB\$DATABASE" );
            ( $major_server_version  ) = $firebird_version =~ /^(\d+)\./;
        };
        return $major_server_version // 3;
    }
    else {
        my $database_version  = $dbh->get_info( $GetInfoType{SQL_DBMS_VER} );
        ( $major_server_version ) = $database_version =~ /^v?(\d+)\D/i;
        if ( $dbms eq 'Pg' ) {
            return $major_server_version // 10;
        }
        elsif ( $dbms eq 'Oracle' ) {
            return $major_server_version // 12;
        }
        elsif ( $dbms eq 'MSSQL' ) {
            return $major_server_version // 16;
        }
    }
}


sub clone_data {
    my ( $sf, $data ) = @_;
    require Storable;
    return Storable::dclone( $data );
}


sub format_list {
    my ( $sf, $list ) = @_;
    return    if ! defined $list;
    return '' if ! @$list;
    my $sep = ', ';
    my $formated_list = join( $sep, @$list );
    $formated_list =~ s/$sep(?=$list->[-1]\z)/ or /;
    return $formated_list;
}


sub print_error_message {
    my ( $sf, $message, $info ) = @_;
    utf8::decode( $message );
    chomp( $message );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    $tc->choose(
        [ 'Press ENTER to continue' ],
        { prompt => $message, info => $info }
    );
}


sub write_json {
    my ( $sf, $file_fs, $ref ) = @_;
    if ( ! defined $ref ) { ##
        #open my $fh, '>', $file_fs or die "$file_fs: $!";
        #print $fh;
        #close $fh;
        return;
    }
    my $json = JSON::MaybeXS->new->utf8->pretty->canonical->encode( $ref );
    open my $fh, '>', $file_fs or die "$file_fs: $!";
    print $fh $json;
    close $fh;
}


sub read_json {
    my ( $sf, $file_fs ) = @_;
    if ( ! defined $file_fs || ! -f $file_fs ) {
        return;
    }
    open my $fh, '<', $file_fs or die "$file_fs: $!";
    my $json = do { local $/; <$fh> };
    close $fh;
    my $ref;
    if ( ! eval {
        $ref = decode_json( $json ) if $json;
        1 }
    ) {
        die "In '$file_fs':\n$@";
    }
    return $ref;
}





1;

__END__
