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


sub __stmt_fold {
    my ( $sf, $used_for, $stmt, $indent ) = @_;
    if ( $used_for eq 'print' ) {
        my $term_w = get_term_width();
        if ( $^O ne 'MSWin32' && $^O ne 'cygwin' ) {
            $term_w += WIDTH_CURSOR;
        }
        my $in = ' ' x $sf->{o}{G}{base_indent};
        my %tabs = ( init_tab => $in x $indent, subseq_tab => $in x ( $indent + 1 ) );
        return line_fold( $stmt, $term_w, { %tabs, join => 0 } ); ##
    }
    else {
        return $stmt;
    }
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


sub get_stmt {
    my ( $sf, $sql, $stmt_type, $used_for ) = @_;
    my $in = ' ' x $sf->{o}{G}{base_indent};
    my $indent0 = 0;
    my $indent1 = 1;
    my $indent2 = 2;
    my $qt_table = $sql->{table};
    my @tmp;
    if ( defined $sf->{d}{ctes} && @{$sf->{d}{ctes}} ) { ##
        #if ( @{$sf->{d}{ctes}} == 1 ) {
        #    my $cte = $sf->{d}{ctes}[0];
        #    push @tmp, $sf->__stmt_fold( $used_for, sprintf( 'WITH %s AS (%s)', $cte->{name}, $cte->{query} ), $indent0 );
        #}
        #else {
            push @tmp, "WITH";
            for my $cte ( @{$sf->{d}{ctes}} ) {
                push @tmp, $sf->__stmt_fold( $used_for, sprintf( '%s AS (%s),', $cte->{name}, $cte->{query} ), $indent1 );
            }
            $tmp[-1] =~ s/,\z//;
        #}
        push @tmp, " ";
    }
    if ( $sql->{case_stmt} ) {
        @tmp = ();
        # only for print info (it has to be here because 'when' uses the __add_condition method).
        # When the case expression is completed, it is appended to the corresponding substmt and these case keys are deleted.
        push @tmp, $sf->__stmt_fold( $used_for, $sql->{case_info}, $indent0 ) if $sql->{case_info};
        push @tmp, $sf->__stmt_fold( $used_for, $sql->{case_stmt}, $indent0 );
        push @tmp, $sf->__stmt_fold( $used_for, $sql->{when_stmt}, $indent0 ) if $sql->{when_stmt};
    }
    elsif ( $stmt_type eq 'Drop_table' ) {
        @tmp = ( $sf->__stmt_fold( $used_for, "DROP TABLE $qt_table", $indent0 ) );
    }
    elsif ( $stmt_type eq 'Drop_view' ) {
        @tmp = ( $sf->__stmt_fold( $used_for, "DROP VIEW $qt_table", $indent0 ) );
    }
    elsif ( $stmt_type eq 'Create_table' ) {
        my $stmt = sprintf "CREATE TABLE $qt_table (%s)", join ', ', map { $_ // '' } @{$sql->{create_table_col_names}};
        @tmp = ( $sf->__stmt_fold( $used_for, $stmt, $indent0 ) );
    }
    elsif ( $stmt_type eq 'Create_view' ) {
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
        my $stmt = sprintf "INSERT INTO $sql->{table} (%s)", join ', ', map { $_ // '' } @{$sql->{insert_col_names}};
        @tmp = ( $sf->__stmt_fold( $used_for, $stmt, $indent0 ) );
        if ( $used_for eq 'prepare' ) {
            push @tmp, sprintf " VALUES(%s)", join( ', ', ( '?' ) x @{$sql->{insert_col_names}} );
        }
        else {
            push @tmp, $sf->__stmt_fold( $used_for, "VALUES(", $indent1 );
            my $arg_rows = $sf->info_format_insert_args( $sql, $in x 2 );
            push @tmp, @$arg_rows;
            push @tmp, $sf->__stmt_fold( $used_for, ")", $indent1 );
        }
    }
    elsif ( $stmt_type eq 'Join' ) {
        my $select_from;
        if ( $used_for eq 'prepare' ) {
            @tmp = ();
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
        #@tmp = ( $sf->__stmt_fold( $used_for, "SELECT * FROM (", $indent0 ) );
        if ( $used_for eq 'prepare' ) {
            @tmp = ();
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
    $print_stmt .= "\n" if $used_for eq 'print'; # ###
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
    my $col_count = @{$sql->{insert_args}[0]//[]};
    if ( $row_count == 0 ) {
        return [];
    }
    my $avail_h = $term_h - ( 12  + ( $col_count < 10 ? 10 : $col_count ) );
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
    my $row_str = join( $list_sep, map { s/\t/  /g; s/\n/[NL]/g; s/\v/[VWS]/g; $_ } @$row );
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
        @cols = @{$sql->{cols}};
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


sub alias {
    # Aliases:
    #   JOIN: mandatory
    #
    #   Subqueries in FROM (Derived Table, UNION):
    #                       mandatory: mysql, MariaDB, Pg
    #                       optional: SQLite, Firebird, DB2, Informix, Oracle
    #
    #   Columns: optional (SQ, functions)

    my ( $sf, $sql, $type, $identifier, $default ) = @_;
    my $prompt = 'as ';
    my $alias;
    if ( $sf->{o}{alias}{$type} ) {
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
    }
    if ( ! length $alias ) {
        $alias = $default;
    }
    return $alias;
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
            $sf->__quote_identifier( 'aliases', shift @id ), $sf->__quote_identifier( 'columns', shift @id )
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


sub backup_href {
    my ( $sf, $href ) = @_;
    my $backup = {};
    for ( keys %$href ) {
        if ( ref $href->{$_} eq 'ARRAY' ) {
            $backup->{$_} = [ @{$href->{$_}} ];
        }
        elsif ( ref $href->{$_} eq 'HASH' ) {
            $backup->{$_} = { %{$href->{$_}} };
        }
        else {
            $backup->{$_} = $href->{$_};
        }
    }
    return $backup;
}


sub reset_sql {
    my ( $sf, $sql ) = @_;
    my $backup = {};
    for my $y ( qw( db schema table cols ) ) {
        $backup->{$y} = $sql->{$y} if exists $sql->{$y};
    }
    map { delete $sql->{$_} } keys %$sql; # not "$sql = {}" so $sql is still pointing to the outer $sql
    my @string = qw( distinct_stmt set_stmt where_stmt group_by_stmt having_stmt order_by_stmt limit_stmt offset_stmt );
    my @array  = qw( cols group_by_cols aggr_cols selected_cols insert_col_names create_table_col_names
                     set_args where_args having_args insert_args );
    my @hash   = qw( alias );
    @{$sql}{@string} = ( '' ) x  @string;
    @{$sql}{@array}  = map{ [] } @array;
    @{$sql}{@hash}   = map{ {} } @hash;
    for my $y ( keys %$backup ) {
        $sql->{$y} = $backup->{$y};
    }
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


sub column_names {
    my ( $sf, $qt_table ) = @_;
    # without `LIMIT 0` slower with big tables: mysql, MariaDB and Pg
    # no difference with SQLite, Firebird, DB2 and Informix
    my $columns;
    if ( ! eval {
        my $stmt = '';
        if ( defined $sf->{d}{ctes} && @{$sf->{d}{ctes}} ) {
            $stmt = "WITH " . join ', ', map { sprintf '%s AS (%s)', $_->{name}, $_->{query} } @{$sf->{d}{ctes}};
            $stmt .= ' ';
        }
        $stmt .= "SELECT * FROM " . $qt_table . $sf->sql_limit( 0 );
        #my $stmt = $sf->get_stmt( $sql, 'Select', 'prepare' ) . $sf->sql_limit( 0 ); #  $sql
        my $sth = $sf->{d}{dbh}->prepare( $stmt );
        if ( $sf->{i}{driver} ne 'SQLite' ) {
            $sth->execute();
        }
        $columns = [ @{$sth->{NAME}} ];
        1 }
    ) {
        $sf->print_error_message( $@ );
    }
    return $columns;
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

############################################################## 2.317  12.03.2023
    if ( $file_fs eq ( $sf->{i}{f_attached_db} // '' ) ) {
        my @keys = keys %$ref;
        if ( ref( $ref->{$keys[0]} ) eq 'ARRAY' ) {
            my $tmp;
            for my $key ( @keys ) {
                for my $ar ( @{$ref->{$key}} ) {
                    $tmp->{$key}{$ar->[1]} = $ar->[0];
                }
            }
            $sf->write_json( $sf->{i}{f_attached_db}, $tmp );
            return $tmp;
        }
        #else {
        #    return $ref;
        #}
    }
##############################################################

################################################################################################# 2.314  03.02.2023
    if ( $file_fs eq ( $sf->{i}{f_subqueries} // '' ) ) {
        my $tmp;
        CONVERT: for my $driver ( keys %$ref ) {
            for my $db ( keys %{$ref->{$driver}} ) {
                last CONVERT if ref( $ref->{$driver}{$db} ) ne 'HASH';
                for my $key ( keys %{$ref->{$driver}{$db}} ) {
                    next if $key ne 'substmt';
                    for my $ref ( @{$ref->{$driver}{$db}{$key}} ) {
                        push @{$tmp->{$driver}{$db}}, { stmt => $ref->[0], name => $ref->[1] };
                    }
                }
            }
        }
        if ( defined $tmp ) {
            $sf->write_json( $sf->{i}{f_subqueries}, $tmp );
            return $tmp;
        }
        #else {
        #    return $ref;
        #}
    }
##################################################################################################

    return $ref;
}





1;

__END__
