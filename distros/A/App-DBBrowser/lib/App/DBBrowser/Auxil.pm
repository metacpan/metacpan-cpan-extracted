package # hide from PAUSE
App::DBBrowser::Auxil;

use warnings;
use strict;
use 5.014;

use Scalar::Util qw( looks_like_number );

use JSON::MaybeXS   qw( decode_json );

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
    my ( $sf, $stmt, $term_w, $fold_opt, $values ) = @_;
    if ( defined $term_w ) {
        if ( defined $values ) {
            my $filled = $sf->stmt_placeholder_to_value( $stmt, $values, 0 );
            if ( defined $filled ) {
                $stmt = $filled;
            }
        }
        return line_fold( $stmt, $term_w, { %$fold_opt, join => 0 } ); ##
    }
    else {
        return ' ' . $stmt;
    }
}


sub get_stmt {
    my ( $sf, $sql, $stmt_type, $used_for ) = @_;
    my $term_w;
    my ( $indent0, $indent1, $indent2 );
    my $in = '';
    if ( $used_for eq 'print' ) {
        $term_w = get_term_width();
        if ( $^O ne 'MSWin32' && $^O ne 'cygwin' ) {
            $term_w += WIDTH_CURSOR;
        }
        $in = ' ' x $sf->{o}{G}{base_indent};
        $indent0 = { init_tab => $in x 0, subseq_tab => $in x 1 };
        $indent1 = { init_tab => $in x 1, subseq_tab => $in x 2 };
        $indent2 = { init_tab => $in x 2, subseq_tab => $in x 3 };
    }
    my $qt_table = $sql->{table};
    my @tmp;
    if ( $stmt_type eq 'Drop_table' ) {
        @tmp = ( $sf->__stmt_fold( "DROP TABLE $qt_table", $term_w, $indent0 ) );
    }
    elsif ( $stmt_type eq 'Drop_view' ) {
        @tmp = ( $sf->__stmt_fold( "DROP VIEW $qt_table", $term_w, $indent0 ) );
    }
    elsif ( $stmt_type eq 'Create_table' ) {
        my $stmt = sprintf "CREATE TABLE $qt_table (%s)", join ', ', map { $_ // '' } @{$sql->{create_table_cols}};
        @tmp = ( $sf->__stmt_fold( $stmt, $term_w, $indent0 ) );

    }
    elsif ( $stmt_type eq 'Create_view' ) {
        @tmp = ( $sf->__stmt_fold( "CREATE VIEW $qt_table", $term_w, $indent0 ) );
        push @tmp, $sf->__stmt_fold( "AS " . $sql->{view_select_stmt}, $term_w, $indent1 );
    }
    elsif ( $stmt_type eq 'Select' ) {
        @tmp = ( $sf->__stmt_fold( "SELECT" . $sql->{distinct_stmt} . $sf->__select_cols( $sql ), $term_w, $indent0 ) );
        push @tmp, $sf->__stmt_fold( "FROM " . $qt_table, $term_w, $indent1 );
        push @tmp, $sf->__stmt_fold( $sql->{where_stmt},    $term_w, $indent2, $sql->{where_args}  ) if $sql->{where_stmt};
        push @tmp, $sf->__stmt_fold( $sql->{group_by_stmt}, $term_w, $indent2                      ) if $sql->{group_by_stmt};
        push @tmp, $sf->__stmt_fold( $sql->{having_stmt},   $term_w, $indent2, $sql->{having_args} ) if $sql->{having_stmt};
        push @tmp, $sf->__stmt_fold( $sql->{order_by_stmt}, $term_w, $indent2                      ) if $sql->{order_by_stmt};
        if ( $sf->{i}{driver} =~ /^(?:Firebird|DB2|Oracle)\z/ ) {
            push @tmp, $sf->__stmt_fold( $sql->{offset_stmt},   $term_w, $indent2 ) if $sql->{offset_stmt};
            push @tmp, $sf->__stmt_fold( $sql->{limit_stmt},    $term_w, $indent2 ) if $sql->{limit_stmt};
        }
        else {
            push @tmp, $sf->__stmt_fold( $sql->{limit_stmt},    $term_w, $indent2 ) if $sql->{limit_stmt};
            push @tmp, $sf->__stmt_fold( $sql->{offset_stmt},   $term_w, $indent2 ) if $sql->{offset_stmt};
        }
    }
    elsif ( $stmt_type eq 'Delete' ) {
        @tmp = ( $sf->__stmt_fold( "DELETE FROM " . $qt_table, $term_w, $indent0 ) );
        push @tmp, $sf->__stmt_fold( $sql->{where_stmt}, $term_w, $indent1, $sql->{where_args} ) if $sql->{where_stmt};
    }
    elsif ( $stmt_type eq 'Update' ) {
        @tmp = ( $sf->__stmt_fold( "UPDATE " . $qt_table, $term_w, $indent0 ) );
        push @tmp, $sf->__stmt_fold( $sql->{set_stmt},   $term_w, $indent1, $sql->{set_args} )   if $sql->{set_stmt};
        push @tmp, $sf->__stmt_fold( $sql->{where_stmt}, $term_w, $indent1, $sql->{where_args} ) if $sql->{where_stmt};
    }
    elsif ( $stmt_type eq 'Insert' ) {
        my $stmt = sprintf "INSERT INTO $sql->{table} (%s)", join ', ', map { $_ // '' } @{$sql->{insert_into_cols}};
        @tmp = ( $sf->__stmt_fold( $stmt, $term_w, $indent0 ) );
        if ( $used_for eq 'prepare' ) {
            push @tmp, sprintf " VALUES(%s)", join( ', ', ( '?' ) x @{$sql->{insert_into_cols}} );
        }
        else {
            push @tmp, $sf->__stmt_fold( "VALUES(", $term_w, $indent1 );
            my $arg_rows = $sf->info_format_insert_args( $sql, $indent2->{init_tab} );
            push @tmp, @$arg_rows;
            push @tmp, $sf->__stmt_fold( ")", $term_w, $indent1 );
        }
    }
    elsif ( $stmt_type eq 'Join' ) {
        my @joins = split /(?=\s(?:INNER|LEFT|RIGHT|FULL|CROSS)\sJOIN)/, $sql->{stmt};
        @tmp = ( $sf->__stmt_fold( shift @joins, $term_w, $indent0 ) );
        push @tmp, map { s/^\s//; $sf->__stmt_fold( $_, $term_w, $indent1 ) } @joins;
    }
    elsif ( $stmt_type eq 'Union' ) {
        @tmp = $used_for eq 'print' ? $sf->__stmt_fold( "SELECT * FROM (", $term_w, $indent0 ) : "(";
        my $count = 0;
        for my $ref ( @{$sql->{subselect_data}} ) {
            ++$count;
            my $stmt = "SELECT " . join( ', ', @{$ref->[1]} );
            $stmt .= " FROM " . $ref->[0];
            if ( $count < @{$sql->{subselect_data}} ) {
                $stmt .= " UNION ALL";
            }
            push @tmp, $sf->__stmt_fold( $stmt, $term_w, $indent1 );
        }
        push @tmp, $sf->__stmt_fold( ")", $term_w, $indent0 );
    }
    if ( $used_for eq 'prepare' ) {
        my $prepare_stmt = join '', @tmp;
        $prepare_stmt =~ s/^\s//;
        return $prepare_stmt;
    }
    else {
        my $print_stmt = join( "\n", @tmp ) . "\n";
        return $print_stmt;
    }
}


sub info_format_insert_args {
    my ( $sf, $sql, $indent ) = @_;
    my $term_h = get_term_height();
    my $term_w = get_term_width();
    if ( $^O ne 'MSWin32' && $^O ne 'cygwin' ) {
        $term_w += WIDTH_CURSOR;
    }
    my $row_count = @{$sql->{insert_into_args}};
    if ( $row_count == 0 ) {
        return [];
    }
    my $avail_h = $term_h - ( @{$sql->{insert_into_args}[0]} + 12 );
    if ( $avail_h < $term_h / 3.5 ) { ##
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
        for my $row ( @{$sql->{insert_into_args}}[ $begin_idx_part_1 .. $end___idx_part_1 ] ) {
            push @$tmp, $sf->__prepare_table_row( $row, $indent, $term_w );
        }
        push @$tmp, $indent . '[...]';
        for my $row ( @{$sql->{insert_into_args}}[ $begin_idx_part_2 .. $end___idx_part_2 ] ) {
            push @$tmp, $sf->__prepare_table_row( $row, $indent, $term_w );
        }
        my $row_count = scalar( @{$sql->{insert_into_args}} );
        push @$tmp, $indent . '[' . insert_sep( $row_count, $sf->{i}{info_thsd_sep} ) . ' rows]';
    }
    else {
        for my $row ( @{$sql->{insert_into_args}} ) {
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
    my @cols = @{$sql->{selected_cols}} ? @{$sql->{selected_cols}} : ( @{$sql->{group_by_cols}}, @{$sql->{aggr_cols}} );
    if ( ! @cols ) {
        if ( $sf->{d}{special_table} eq 'join' ) {
            # join: use qualified col names in the prepare stmt (different cols could have the same name)
            return ' ' . join ', ', @{$sql->{cols}};
        }
        else {
            return " *";
        }
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


sub stmt_placeholder_to_value {
    my ( $sf, $stmt, $values, $quote_values ) = @_;
    if ( ! @$values ) {
        return $stmt;
    }
    my $rx_placeholder = qr/(?<=(?:,|\s|\())\?(?=(?:,|\s|\)|$))/;
    for my $value ( @$values ) {
        my $value_copy;
        if ( $quote_values && $value && ! looks_like_number $value ) {
            $value_copy = $sf->{d}{dbh}->quote( $value );
        }
        else {
            $value_copy = $value;
        }
        $stmt =~ s/$rx_placeholder/$value_copy/;
    }
    if ( $stmt =~ $rx_placeholder ) {
        return;
    }
    return $stmt;
}


sub alias {
    my ( $sf, $sql, $type, $identifier, $default ) = @_;
    my $term_w = get_term_width();
    my $tmp_info;
    if ( $identifier eq '' ) { # Union
        $identifier .= 'UNION Alias: ';
    }
    elsif ( print_columns( $identifier . ' AS ' ) > $term_w / 3 ) {
        $tmp_info = 'Alias: ' . "\n" . $identifier;
        $identifier = 'AS ';
    }
    else {
        $tmp_info = 'Alias: ';
        $identifier .= ' AS ';
    }
    my $alias;
    if ( $sf->{o}{alias}{$type} ) {
        my $tr = Term::Form::ReadLine->new( $sf->{i}{tr_default} );
        my $info = $sf->get_sql_info( $sql ) . "\n" . $tmp_info;
        # Readline
        $alias = $tr->readline(
            $identifier,
            { info => $info }
        );
        $sf->print_sql_info( $info );
    }
    if ( ! length $alias ) {
        $alias = $default;
    }
    if ( $sf->{i}{driver} eq 'Pg' && ! $sf->{o}{G}{quote_identifiers} ) {
        return lc $alias;
    }
    return $alias;
}


sub quote_table {
    my ( $sf, $table_info ) = @_;
    my @idx;
    # 0 = catalog
    # 1 = schema
    # 2 = table_name
    # 3 = table_type
    if ( $sf->{o}{G}{qualified_table_name} || $sf->{d}{db_attached} ) {
        # If a SQLite database has databases attached, the fully qualified table name is used in SQL code regardless of
        # the setting of the option 'qualified_table_name' because attached databases could have tables with the same
        # name.
        @idx = ( 1, 2 );
        #@idx = ( 0, 1, 2 ); with catalog
    }
    else {
        @idx = ( 2 );
    }
    if ( $sf->{o}{G}{quote_identifiers} ) {
        return $sf->{d}{dbh}->quote_identifier( @{$table_info}[@idx] );
    }
    else {
        # if @idx with catalog (0,1,2): write code which handles catalog (see `quote_identifier`).
        return join( '.', grep { length } @{$table_info}[@idx] );
    }
}


sub quote_col_qualified {
    my ( $sf, $col_identifier_parts ) = @_;
    if ( $sf->{o}{G}{quote_identifiers} ) {
        return $sf->{d}{dbh}->quote_identifier( @$col_identifier_parts );
    }
    else {
        return join( '.', grep { length } @$col_identifier_parts );
    }
}


sub quote_cols {
    my ( $sf, $list ) = @_;
    if ( $sf->{o}{G}{quote_identifiers} ) {
        return [ map { $sf->{d}{dbh}->quote_identifier( $_ ) } @$list ];
    }
    else {
        return [ @$list ];
    }
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
    map { delete $sql->{$_} } keys %$sql; # not $sql = {} so $sql is still pointing to the outer $sql
    my @string = qw( distinct_stmt set_stmt where_stmt group_by_stmt having_stmt order_by_stmt limit_stmt offset_stmt );
    my @array  = qw( cols group_by_cols aggr_cols
                     selected_cols
                     set_args where_args having_args
                     insert_into_cols insert_into_args
                     create_table_cols );
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


sub tables_column_names_and_types { # db
    my ( $sf, $table_keys ) = @_;
    my ( $col_names, $col_types );
    for my $table_k ( @$table_keys ) {
        if ( ! eval {
            my $sth = $sf->{d}{dbh}->prepare( "SELECT * FROM " . $sf->quote_table( $sf->{d}{tables_info}{$table_k} ) . $sf->sql_limit( 0 ) );
            $sth->execute() if $sf->{i}{driver} ne 'SQLite';
            $col_names->{$table_k} //= $sth->{NAME};
            $col_types->{$table_k} //= $sth->{TYPE};
            1 }
        ) {
            $sf->print_error_message( $@ );
        }
    }
    return $col_names, $col_types;
}


sub column_names {
    my ( $sf, $qt_table ) = @_;
    my $sth = $sf->{d}{dbh}->prepare( "SELECT * FROM " . $qt_table . $sf->sql_limit( 0 ) );
    $sth->execute() if $sf->{i}{driver} ne 'SQLite';
    return [ @{$sth->{NAME}} ];
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
    return $ref;
}





1;

__END__
