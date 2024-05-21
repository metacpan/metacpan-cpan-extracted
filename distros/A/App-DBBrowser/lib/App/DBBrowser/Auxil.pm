package # hide from PAUSE
App::DBBrowser::Auxil;

use warnings;
use strict;
use 5.014;

use Scalar::Util qw( looks_like_number );

use JSON::MaybeXS qw( decode_json );

use Term::Choose            qw();
use Term::Choose::Constants qw( WIDTH_CURSOR );
use Term::Choose::LineFold  qw( line_fold print_columns );
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
        ctes => $sql->{ctes} // [],
    };
    # reset/initialize:
    delete @{$sql}{ keys %$sql }; # not "$sql = {}" so $sql is still pointing to the outer $sql
    my @string = qw( distinct_stmt set_stmt where_stmt group_by_stmt having_stmt order_by_stmt limit_stmt offset_stmt );
    my @array  = qw( group_by_cols aggr_cols selected_cols set_args
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
    my ( $sf, $used_for, $stmt, $indent ) = @_;
    if ( $used_for eq 'print' ) {
        my $term_w = get_term_width();
        if ( $^O ne 'MSWin32' && $^O ne 'cygwin' ) {
            $term_w += WIDTH_CURSOR;
        }
        my $in = ' ' x $sf->{o}{G}{base_indent};
        my %tabs = ( init_tab => $in x $indent, subseq_tab => $in x ( $indent + 1 ) );
        return line_fold( $stmt, $term_w, { %tabs, join => 0 } );
    }
    else {
        return $stmt;
    }
}


sub __cte_stmts {
    my ( $sf, $ctes, $used_for, $indent1 ) = @_;
    #if ( ! $ctes || ! @$ctes ) {
    #    return wantarray ? () : '';
    #}
    my $with = "WITH";
    for my $cte ( @$ctes ) {
        $with .= " RECURSIVE" and last if $cte->{is_recursive};
    }
    my @tmp = ( $with );
    for my $cte ( @$ctes ) {
        push @tmp, $sf->__stmt_fold( $used_for, sprintf( '%s AS (%s),', $cte->{full_name}, $cte->{query} ), $indent1 );
    }
    $tmp[-1] =~ s/,\z//;
    push @tmp, " ";
    return join "\n", @tmp;
}


sub get_stmt {
    my ( $sf, $sql, $stmt_type, $used_for ) = @_;
    my $in = ' ' x $sf->{o}{G}{base_indent};
    my $indent0 = 0;
    my $indent1 = 1;
    my $indent2 = 2;
    my $qt_table = $sql->{table};
    my @tmp;
    if ( @{$sql->{ctes}} ) {
        push @tmp, $sf->__cte_stmts( $sql->{ctes}, $used_for, $indent1 );
    }
    if ( $sql->{case_stmt} ) {
        @tmp = ();
        # only for print info (it has to be here because 'when' uses the add_condition method).
        # When the case expression is completed, it is appended to the corresponding substmt and these case keys are deleted.
        push @tmp, $sf->__stmt_fold( $used_for, $sql->{case_info}, $indent0 ) if $sql->{case_info};
        push @tmp, $sf->__stmt_fold( $used_for, $sql->{case_stmt}, $indent0 );
        push @tmp, $sf->__stmt_fold( $used_for, $sql->{when_stmt}, $indent0 ) if $sql->{when_stmt};
    }
    elsif ( $stmt_type eq 'Drop_Table' ) {
        @tmp = ( $sf->__stmt_fold( $used_for, "DROP TABLE $qt_table", $indent0 ) );
    }
    elsif ( $stmt_type eq 'Drop_View' ) {
        @tmp = ( $sf->__stmt_fold( $used_for, "DROP VIEW $qt_table", $indent0 ) );
    }
    elsif ( $stmt_type eq 'Create_Table' ) {
        my $stmt = sprintf "CREATE TABLE $qt_table (%s)", join ', ', @{$sql->{ct_column_definitions}}, @{$sql->{ct_table_constraints}};
        if ( @{$sql->{ct_table_options}} ) {
            $stmt .= ' ' . join ', ', @{$sql->{ct_table_options}};
        }
        @tmp = ( $sf->__stmt_fold( $used_for, $stmt, $indent0 ) );
    }
    elsif ( $stmt_type eq 'Create_View' ) {
        @tmp = ( $sf->__stmt_fold( $used_for, "CREATE VIEW $qt_table", $indent0 ) );
        push @tmp, $sf->__stmt_fold( $used_for, "AS " . $sql->{view_select_stmt}, $indent1 );
    }
    elsif ( $stmt_type eq 'Select' ) {
        push @tmp, $sf->__stmt_fold( $used_for, "SELECT" . $sql->{distinct_stmt} . $sf->__select_cols( $sql ), $indent0 );
        #@tmp = ( $sf->__stmt_fold( $used_for, "SELECT" . $sql->{distinct_stmt} . $sf->__select_cols( $sql ), $indent0 ) );
        push @tmp, $sf->__stmt_fold( $used_for, "FROM " . $qt_table,   $indent1 );
        push @tmp, $sf->__stmt_fold( $used_for, $sql->{where_stmt},    $indent2 ) if $sql->{where_stmt};
        push @tmp, $sf->__stmt_fold( $used_for, $sql->{group_by_stmt}, $indent2 ) if $sql->{group_by_stmt};
        push @tmp, $sf->__stmt_fold( $used_for, $sql->{having_stmt},   $indent2 ) if $sql->{having_stmt};
        push @tmp, $sf->__stmt_fold( $used_for, $sql->{order_by_stmt}, $indent2 ) if $sql->{order_by_stmt};
        if ( $sql->{limit_stmt} =~ /^LIMIT\s/ ) {
            push @tmp, $sf->__stmt_fold( $used_for, $sql->{limit_stmt},  $indent2 );
            push @tmp, $sf->__stmt_fold( $used_for, $sql->{offset_stmt}, $indent2 ) if $sql->{offset_stmt};
        }
        else {
            push @tmp, $sf->__stmt_fold( $used_for, $sql->{offset_stmt}, $indent2 ) if $sql->{offset_stmt};
            push @tmp, $sf->__stmt_fold( $used_for, $sql->{limit_stmt},  $indent2 ) if $sql->{limit_stmt};
        }
    }
    elsif ( $stmt_type eq 'Delete' ) {
        @tmp = ( $sf->__stmt_fold( $used_for, "DELETE FROM " . $qt_table, $indent0 ) );
        push @tmp, $sf->__stmt_fold( $used_for, $sql->{where_stmt}, $indent1 ) if $sql->{where_stmt};
    }
    elsif ( $stmt_type eq 'Update' ) {
        @tmp = ( $sf->__stmt_fold( $used_for, "UPDATE " . $qt_table, $indent0 ) );
        push @tmp, $sf->__stmt_fold( $used_for, $sql->{set_stmt},   $indent1 ) if $sql->{set_stmt};
        push @tmp, $sf->__stmt_fold( $used_for, $sql->{where_stmt}, $indent1 ) if $sql->{where_stmt};
    }
    elsif ( $stmt_type eq 'Insert' ) {
        my $columns = join ', ', map { $_ // '' } @{$sql->{insert_col_names}};
        my $placeholders = join ', ', ( '?' ) x @{$sql->{insert_col_names}};
        my $stmt = "INSERT INTO $sql->{table} ($columns) VALUES($placeholders)";
        @tmp = ( $sf->__stmt_fold( $used_for, $stmt, $indent0 ) );
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
            push @tmp, $sf->__stmt_fold( $used_for, $select_from . $master_data->{table}, $indent0 );
            for my $slave_data ( @join_data ) {
                my $sub_stmt = join ' ', grep { length } @{$slave_data}{ qw(join_type table condition) };
                push @tmp, $sf->__stmt_fold( $used_for, $sub_stmt, $indent1 );
            }
        }
        else {
            push @tmp, $sf->__stmt_fold( $used_for, $select_from, $indent0 );
        }
    }
    elsif ( $stmt_type eq 'Union' ) {
        if ( $used_for eq 'prepare' ) {
            @tmp = ();
            # prepare: this stmt is used as table in the select stmt
            # no ctes, they are added in the select stmt
            push @tmp, $sf->__stmt_fold( $used_for, "(", $indent0 ); ##
        }
        else {
            push @tmp, $sf->__stmt_fold( $used_for, "SELECT * FROM (", $indent0 ); ##
        }
        if ( @{$sql->{subselect_stmts}//[]} ) {
            my $extra = 0;
            for my $stmt ( @{$sql->{subselect_stmts}} ) {
                $extra-- if $stmt eq ")" && $extra;
                push @tmp, $sf->__stmt_fold( $used_for, $stmt, $indent1 + $extra );
                $extra++ if $stmt eq "(";
            }
        }
        push @tmp, $sf->__stmt_fold( $used_for, ")", $indent0 );
    }
    my $print_stmt = join( "\n", @tmp );
    $print_stmt .= "\n" if $used_for eq 'print'; ##
    return $print_stmt;
}


sub info_format_insert_args {
    my ( $sf, $sql, $indent ) = @_;
    my $term_h = get_term_height();
    my $term_w = get_term_width();
    if ( $^O ne 'MSWin32' && $^O ne 'cygwin' ) {
        $term_w += WIDTH_CURSOR;
    }
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
            push @$tmp, $sf->__prepare_table_row( $row, $indent, $term_w );
        }
        push @$tmp, $indent . '[...]';
        for my $row ( @{$sql->{insert_args}}[ $begin_idx_part_2 .. $end___idx_part_2 ] ) {
            push @$tmp, $sf->__prepare_table_row( $row, $indent, $term_w );
        }
        my $row_count = scalar( @{$sql->{insert_args}} );
        push @$tmp, $indent . '[' . insert_sep( $row_count, $sf->{i}{info_thsd_sep} ) . ' rows]';
    }
    else {
        for my $row ( @{$sql->{insert_args}} ) {
            push @$tmp, $sf->__prepare_table_row( $row, $indent, $term_w );
        }
    }
    return $tmp;
}


sub __prepare_table_row {
    my ( $sf, $row, $indent, $term_w ) = @_;
    my $list_sep = ', ';
    my $dots = $sf->{i}{dots};
    my $dots_w = print_columns( $dots );
    no warnings 'uninitialized';
    my $row_str = join( $list_sep, map { s/\t/  /g; s/\n/\\n/g; s/\v/\\v/g; $_ } @$row );
    return unicode_sprintf( $indent . $row_str, $term_w, { mark_if_truncated => [ $dots, $dots_w ] } );
}


sub __select_cols {
    my ( $sf, $sql ) = @_;
    my @cols;
    if ( @{$sql->{selected_cols}} ) {
        @cols = @{$sql->{selected_cols}};
    }
    elsif ( @{$sql->{group_by_cols}} || @{$sql->{aggr_cols}} ) {
        @cols = ( @{$sql->{group_by_cols}}, @{$sql->{aggr_cols}} );
    }
    elsif ( keys %{$sql->{alias}} ) {
        @cols = @{$sql->{columns}};
        # use column names and not * if columns have aliases
    }
    if ( ! @cols ) {
        return " *";
    }
    elsif ( ! keys %{$sql->{alias}} ) {
        return ' ' . join ', ', @cols;
    }
    else {
        my @cols_alias;
        for ( @cols ) {
            if ( length $sql->{alias}{$_} ) {
                push @cols_alias, $_ . " AS " . $sql->{alias}{$_};
            }
            else {
                push @cols_alias, $_;
            }
        }
        return ' ' . join ', ', @cols_alias;
    }
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
    if ( $sf->{i}{driver} =~ /^(?:SQLite|mysql|MariaDB|Pg)\z/ ) {
        return " LIMIT $rows";
    }
    elsif ( $sf->{i}{driver} =~ /^(?:Firebird|DB2|Oracle)\z/ ) {
        return " FETCH NEXT $rows ROWS ONLY"
    }
    else {
        return "";
    }
}


sub column_names_and_types {
    my ( $sf, $qt_table, $ctes ) = @_;
    # without `LIMIT 0` slower with big tables: mysql, MariaDB and Pg
    # no difference with SQLite, Firebird, DB2 and Informix
    my $column_names = [];
    my $column_types = [];
    if ( ! eval {
        my $stmt = '';
        if ( defined $ctes && @$ctes ) {
            $stmt = $sf->__cte_stmts( $ctes, 'prepare', 0 );
        }
        $stmt .= "SELECT * FROM " . $qt_table . $sf->sql_limit( 0 );
        my $sth = $sf->{d}{dbh}->prepare( $stmt );
        if ( $sf->{i}{driver} eq 'SQLite' ) {
            my $rx_numeric = 'INT|DOUBLE|REAL|NUM|FLOAT|DEC|BOOL|BIT|MONEY';
            $column_names = [ @{$sth->{NAME}} ];
            $column_types = [ map { ! $_ || $_ =~ /$rx_numeric/i ? 2 : 1 } @{$sth->{TYPE}} ];
        }
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
    return $column_names, $column_types;
}


sub column_type_is_numeric {
    my ( $sf, $sql, $qt_col ) = @_;
    my $is_numeric = 0;
    if ( ! length $sql->{data_types}{$qt_col} || ( $sql->{data_types}{$qt_col} >= 2 && $sql->{data_types}{$qt_col} <= 8 ) ) {
        $is_numeric = 1;
    }
    return $is_numeric;
}


sub alias {
    # Aliases mandatory:
    # JOIN talbes
    # Derived Tables: mysql, MariaDB, Pg
    #
    my ( $sf, $sql, $type, $identifier, $default ) = @_;
    my $prompt = 'as ';
    my $alias;
    # 0 = NO
    # 1 = AUTO
    # 2 = ASK
    # 3 = ASK/AUTO
    if ( $sf->{o}{alias}{$type} == 0 ) {
        return;
    }
    elsif ( $sf->{o}{alias}{$type} == 1 ) {
        return $default;
    }
    elsif ( $sf->{o}{alias}{$type} == 2 || $sf->{o}{alias}{$type} == 3 ) {
        my $tr = Term::Form::ReadLine->new( $sf->{i}{tr_default} );
        my $info = $sf->get_sql_info( $sql );
        if ( length $identifier ) {
            if ( $identifier =~ /^\n/ ) {
                $info .= $identifier;
            }
            else {
                $info .= "\n" . $identifier;
            }
        }
        # Readline
        $alias = $tr->readline(
            $prompt,
            { info => $info, history => [ 'a' .. 'z' ] }
        );
        $sf->print_sql_info( $info );
        if ( $sf->{o}{alias}{$type} == 3 && ! length $alias ) {
            $alias = $default;
        }
        return $alias;
    }
}


sub __qualify_identifier {
    my ( $sf, @id ) = @_;
#    my $catalog = ( @id >= 3 ) ? shift @id : undef;        # catalog not used (if used, uncomment also catalog_location and catalog_name_sep)
    my $quoted_id = join '.', grep { defined } @id;
#    if ( $catalog ) {
#        if ( $quoted_id ) {
#            $quoted_id = ( $sf->{d}{catalog_location} == 2 )
#                ? $quoted_id . $sf->{d}{catalog_name_sep} . $catalog
#                : $catalog   . $sf->{d}{catalog_name_sep} . $quoted_id;
#        } else {
#            $quoted_id = $catalog;
#        }
#    }
    return $quoted_id;
}

sub __quote_identifier {
    my ( $sf, $type, @id ) = @_;
    if ( $sf->{o}{G}{'quote_' . $type} ) {
        my $quote = $sf->{d}{identifier_quote_char};
        for ( @id ) {
            if ( ! defined ) {
                next;
            }
            s/$quote/$quote$quote/g;
            $_ = qq{$quote$_$quote};
        }
    }
    return @id;
}


sub quote_table {
    my ( $sf, $table_info ) = @_;
    my @idx;
    # 0 = catalog, 1 = schema, 2 = table_name, 3 = table_type
    if ( $sf->{o}{G}{qualified_table_name} || ( $sf->{d}{db_attached} && ! defined $sf->{d}{schema} ) ) {
        # If a SQLite database has databases attached, the fully qualified table name is used in SQL code regardless of
        # the setting of the option 'qualified_table_name' because attached databases could have tables with the same
        # name.
        @idx = ( 1, 2 );
        #@idx = ( 0, 1, 2 ); with catalog
    }
    else {
        @idx = ( 2 );
    }
    return $sf->__qualify_identifier( $sf->__quote_identifier( 'tables', @{$table_info}[@idx] ) );
}


sub quote_column {
    my ( $sf, @id ) = @_;
    if ( @id == 2 ) { # join: table_alias.column_name
        return $sf->__qualify_identifier(
            $sf->__quote_identifier( 'aliases', shift @id ), $sf->__quote_identifier( 'columns', shift @id ) ##
        );
    }
    else {
        return $sf->__qualify_identifier( $sf->__quote_identifier( 'columns', @id ) );
    }
}


sub quote_cols {
    my ( $sf, $cols ) = @_;
    return [ map { $sf->__qualify_identifier( $sf->__quote_identifier( 'columns', $_ ) ) } @$cols ];
}


sub quote_alias {
    my ( $sf, @id ) = @_;
    return $sf->__qualify_identifier( $sf->__quote_identifier( 'aliases', @id ) );
}


sub unquote_identifier {
    my ( $sf, $identifier ) = @_;
    my $qc = quotemeta( $sf->{d}{identifier_quote_char} );
    $identifier =~ s/$qc(?=(?:$qc$qc)*(?:[^$qc]|\z))//g;
    return $identifier;
}


sub quote_constant {
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
        if ( $sf->{i}{driver} =~ /^(?:mysql|MariaDB)\z/ ) {
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
    if ( $sf->{i}{driver} =~ /^(?:mysql|MariaDB)\z/ ) {
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
    my $driver = $sf->{i}{driver};
    my $major_server_version;
    if ( $driver eq 'Pg' ) {
        eval {
            my ( $pg_version ) = $sf->{d}{dbh}->selectrow_array( "SELECT version()" );
            ( $major_server_version ) = $pg_version =~ /^\S+\s+(\d+)\./;
        };
    }
    elsif ( $driver eq 'Firebird' ) {
        eval {
            my ( $firebird_version ) = $sf->{d}{dbh}->selectrow_array( "SELECT RDB\$GET_CONTEXT('SYSTEM', 'ENGINE_VERSION') FROM RDB\$DATABASE" );
            ( $major_server_version  ) = $firebird_version =~ /^(\d+)\./;
        };
    }
    elsif ( $driver eq 'Oracle' ) {
        eval {
            my $ora_server_version = $sf->{d}{dbh}->func( 'ora_server_version' );
            $major_server_version = $ora_server_version->[0];
      };
    }
    return $major_server_version // 1;
}


sub clone_data {
    my ( $sf, $data ) = @_;
    require Storable;
    return Storable::dclone( $data );
}


sub print_error_message {
    my ( $sf, $message ) = @_;
    utf8::decode( $message );
    chomp( $message );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    $tc->choose(
        [ 'Press ENTER to continue' ],
        { prompt => $message }
    );
}


sub write_json {
    my ( $sf, $file_fs, $ref ) = @_;
    if ( ! defined $ref ) {
        open my $fh, '>', $file_fs or die "$file_fs: $!";
        print $fh;
        close $fh;
        return;
    }
    my $json = JSON::MaybeXS->new->utf8->pretty->canonical->encode( $ref );
    open my $fh, '>', $file_fs or die "$file_fs: $!";
    print $fh $json;
    close $fh;
}


sub read_json {
    my ( $sf, $file_fs ) = @_;
    if ( ! defined $file_fs || ! -e $file_fs ) {
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

############################################################## 2.402  03.01.2024
    if ( $file_fs eq ( $sf->{i}{f_search_and_replace} // '' ) ) {
        my @keys = keys %$ref;
        if ( ref( $ref->{$keys[0]}[0] ) eq 'ARRAY' ) {
            my $tmp;
            for my $key ( @keys ) {
                my $gr = [];
                for my $sr ( @{$ref->{$key}} ) {
                    $sr = { pattern => $sr->[0], replacement => $sr->[1], modifiers => $sr->[2] };
                    push @$gr, $sr;
                }
                $tmp->{$key} = $gr;
            }
            $sf->write_json( $sf->{i}{f_search_and_replace}, $tmp );
            return $tmp;
        }
    }
##############################################################

    return $ref;
}





1;

__END__
