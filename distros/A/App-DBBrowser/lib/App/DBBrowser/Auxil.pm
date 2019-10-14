package # hide from PAUSE
App::DBBrowser::Auxil;

use warnings;
use strict;
use 5.010001;

use Scalar::Util qw( looks_like_number );

use JSON qw( decode_json );

use Term::Choose            qw();
use Term::Choose::LineFold  qw( line_fold print_columns );
use Term::Choose::Screen    qw( clear_screen );
use Term::Choose::Util      qw( insert_sep get_term_width get_term_height unicode_sprintf);
use Term::Form              qw();


sub new {
    my ( $class, $info, $options, $data ) = @_;
    bless {
        i => $info,
        o => $options,
        d => $data
    }, $class;
}


sub get_stmt {
    my ( $sf, $sql, $stmt_type, $used_for ) = @_;
    my $in = $used_for eq 'print' ? ' ' : '';
    my $table = $sql->{table};
    my @tmp;
    if ( $stmt_type eq 'Drop_table' ) {
        @tmp = ( "DROP TABLE $table" );
    }
    elsif ( $stmt_type eq 'Drop_view' ) {
        @tmp = ( "DROP VIEW $table" );
    }
    elsif ( $stmt_type eq 'Create_table' ) {
        @tmp = ( sprintf "CREATE TABLE $table (%s)", join ', ', @{$sql->{create_table_cols}} );
    }
    elsif ( $stmt_type eq 'Create_view' ) {
        @tmp = ( sprintf "CREATE VIEW $table AS " . $sql->{view_select_stmt} );
    }
    elsif ( $stmt_type eq 'Select' ) {
        @tmp = ( "SELECT" . $sql->{distinct_stmt} . $sf->__select_cols( $sql ) );
        push @tmp, " FROM " . $table;
        push @tmp, $in . $sql->{where_stmt}    if $sql->{where_stmt};
        push @tmp, $in . $sql->{group_by_stmt} if $sql->{group_by_stmt};
        push @tmp, $in . $sql->{having_stmt}   if $sql->{having_stmt};
        push @tmp, $in . $sql->{order_by_stmt} if $sql->{order_by_stmt};
        push @tmp, $in . $sql->{limit_stmt}    if $sql->{limit_stmt};
        push @tmp, $in . $sql->{offset_stmt}   if $sql->{offset_stmt};
    }
    elsif ( $stmt_type eq 'Delete' ) {
        @tmp = ( "DELETE FROM " . $table );
        push @tmp, $in . $sql->{where_stmt} if $sql->{where_stmt};
    }
    elsif ( $stmt_type eq 'Update' ) {
        @tmp = ( "UPDATE " . $table );
        push @tmp, $in . $sql->{set_stmt}   if $sql->{set_stmt};
        push @tmp, $in . $sql->{where_stmt} if $sql->{where_stmt};
    }
    elsif ( $stmt_type eq 'Insert' ) {
        @tmp = ( sprintf "INSERT INTO $table (%s)", join ', ', @{$sql->{insert_into_cols}} );
        if ( $used_for eq 'prepare' ) {
            push @tmp, sprintf " VALUES(%s)", join( ', ', ( '?' ) x @{$sql->{insert_into_cols}} );
        }
        else {
            push @tmp, "  VALUES(";
            my $arg_rows = $sf->insert_into_args_info_format( $sql, ' ' x 4 );
            push @tmp, @$arg_rows;
            push @tmp, "  )";
        }
    }
    elsif ( $stmt_type eq 'Join' ) {
        @tmp = map { $in . $_ } split /(?=\s(?:INNER|LEFT|RIGHT|FULL|CROSS)\sJOIN)/, $sql->{stmt};
        $tmp[0] =~ s/^\s//;
    }
    elsif ( $stmt_type eq 'Union' ) {
        @tmp = $used_for eq 'print' ? "SELECT * FROM (" : "(";
        my $count = 0;
        for my $ref ( @{$sql->{subselect_data}} ) {
            ++$count;
            my $str = $in x 2 . "SELECT " . join( ', ', @{$ref->[1]} );
            $str .= " FROM " . $ref->[0];
            if ( $count < @{$sql->{subselect_data}} ) {
                $str .= " UNION ALL ";
            }
            push @tmp, $str;
        }
        push @tmp, ")";
    }
    if ( $used_for eq 'prepare' ) {
        return join '', @tmp;
    }
    else {
        return join( "\n", @tmp ) . "\n";
    }
}


sub insert_into_args_info_format {
    my ( $sf, $sql, $indent ) = @_;
    my $max = get_term_height() - ( $sf->{i}{occupied_rows} // 14 );
    if ( $max < 5 ) {
        $max = 5;
    }
    my $begin = int( $max / 1.5 );
    my $end = $max - $begin;
    $begin--;
    $end--;
    my $last_i = $#{$sql->{insert_into_args}};
    my $tmp = [];
    my $term_w = get_term_width();
    if ( @{$sql->{insert_into_args}} > $max ) {
        for my $row ( @{$sql->{insert_into_args}}[ 0 .. $begin ] ) {
            push @$tmp, _prepare_table_row( $row, $indent, $term_w );
        }
        push @$tmp, $indent . '[...]';
        for my $row ( @{$sql->{insert_into_args}}[ $last_i - $end .. $last_i ] ) {
            push @$tmp, _prepare_table_row( $row, $indent, $term_w );
        }
        my $row_count = scalar( @{$sql->{insert_into_args}} );
        push @$tmp, $indent . '[' . insert_sep( $row_count, $sf->{o}{G}{thsd_sep} ) . ' rows]';
    }
    else {
        for my $row ( @{$sql->{insert_into_args}} ) {
            push @$tmp, _prepare_table_row( $row, $indent, $term_w );
        }
    }
    return $tmp;
}

sub _prepare_table_row {
    my ( $row, $indent, $term_w ) = @_;
    my $list_sep = ', ';
    no warnings 'uninitialized';
    return unicode_sprintf( $indent . join( $list_sep, map { s/\n/[NL]/g; $_ } @$row ), $term_w, 0, 1 );
}


sub __select_cols {
    my ( $sf, $sql ) = @_;
    my @cols = @{$sql->{select_cols}} ? @{$sql->{select_cols}} : ( @{$sql->{group_by_cols}}, @{$sql->{aggr_cols}} );
    if ( ! @cols ) {
        if ( $sf->{i}{special_table} eq 'join' ) {
            # join: use qualified col names in the prepare stmt (diff cols could have the same name)
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
            if ( exists $sql->{alias}{$_} && defined  $sql->{alias}{$_} && length $sql->{alias}{$_} ) {
                push @cols_alias, $_ . " AS " . $sql->{alias}{$_};
            }
            else {
                push @cols_alias, $_;
            }
        }
        return ' ' . join ', ', @cols_alias;
    }
}


sub print_sql {
    my ( $sf, $sql, $waiting ) = @_;
    my $str = '';
    for my $stmt_type ( @{$sf->{i}{stmt_types}} ) {
         $str .= $sf->get_stmt( $sql, $stmt_type, 'print' );
    }
    my $filled = $sf->stmt_placeholder_to_value(
        $str,
        [ @{$sql->{set_args}||[]}, @{$sql->{where_args}||[]}, @{$sql->{having_args}||[]} ] # join and union: ||[]
    );
    if ( defined $filled ) {
        $str = $filled
    }
    $str .= "\n";
    $str = line_fold( $str, get_term_width(), { init_tab => '', subseq => ' ' x 4 } );
    if ( defined wantarray ) {
        return $str;
    }
    print clear_screen();
    print $str;
    if ( defined $waiting ) {
        print $waiting;
    }
}


sub stmt_placeholder_to_value {
    my ( $sf, $stmt, $args, $quote ) = @_;
    if ( ! @$args ) {
        return $stmt;
    }
    my $rx_placeholder = qr/(?<=(?:,|\s|\())\?(?=(?:,|\s|\)|$))/;
    for my $arg ( @$args ) {
        my $arg_copy;
        if ( $quote && $arg && ! looks_like_number $arg ) {
            $arg_copy = $sf->{d}{dbh}->quote( $arg );
        }
        else {
            $arg_copy = $arg;
        }
        $stmt =~ s/$rx_placeholder/$arg_copy/;
    }
    if ( $stmt =~ $rx_placeholder ) {
        return;
    }
    return $stmt;
}


sub alias {
    my ( $sf, $type, $identifier, $default ) = @_;
    my $term_w = get_term_width();
    my $info;
    if ( $identifier eq '' ) { # Union
        $identifier .= 'UNION Alias: ';
    }
    elsif ( print_columns( $identifier . ' AS ' ) > $term_w / 3 ) {
        $info = 'Alias: ' . "\n" . $identifier;
        $identifier = 'AS ';
    }
    else {
        $info = 'Alias: ';
        $identifier .= ' AS ';
    }
    my $alias;
    if ( $sf->{o}{alias}{$type} ) {
        my $tf = Term::Form->new( $sf->{i}{tf_default} );
        # Readline
        $alias = $tf->readline( $identifier,
            { info => $info }
        );
    }
    if ( ! defined $alias || ! length $alias ) {
        $alias = $default;
    }
    if ( $sf->{i}{driver} eq 'Pg' && ! $sf->{o}{G}{quote_identifiers} ) {
        return lc $alias;
    }
    return $alias;
}


sub quote_table {
    my ( $sf, $td ) = @_;
    my @idx = $sf->{o}{G}{qualified_table_name} ? ( 0 .. 2 ) : ( 2 );
    if ( $sf->{o}{G}{quote_identifiers} ) {
        return $sf->{d}{dbh}->quote_identifier( @{$td}[@idx] );
    }
    return join( $sf->{i}{sep_char}, grep { defined && length } @{$td}[@idx] );
}


sub quote_col_qualified {
    my ( $sf, $cd ) = @_;
    if ( $sf->{o}{G}{quote_identifiers} ) {
        return $sf->{d}{dbh}->quote_identifier( @$cd );
    }
    return join( $sf->{i}{sep_char}, grep { defined && length } @$cd );
}


sub quote_simple_many {
    my ( $sf, $list ) = @_;
    if ( $sf->{o}{G}{quote_identifiers} ) {
        return [ map { $sf->{d}{dbh}->quote_identifier( $_ ) } @$list ];
    }
    return [ @$list ];
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
                     select_cols
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
    my ( $sf, $message, $title ) = @_;
    my $info;
    $info = "$title:" if $title; #
    utf8::decode( $message );
    chomp( $message );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    $tc->choose(
        [ 'Press ENTER to continue' ],
        { prompt => $message, info => $info }
    );
}


sub column_names_and_types { # db
    my ( $sf, $tables ) = @_;
    my ( $col_names, $col_types );
    for my $table ( @$tables ) {
        if ( ! eval {
            my $sth = $sf->{d}{dbh}->prepare( "SELECT * FROM " . $sf->quote_table( $sf->{d}{tables_info}{$table} ) . " LIMIT 0" );
            $sth->execute() if $sf->{i}{driver} ne 'SQLite';
            $col_names->{$table} ||= $sth->{NAME};
            $col_types->{$table} ||= $sth->{TYPE};
            1 }
        ) {
            $sf->print_error_message( $@, 'Column names and types' );
        }
    }
    return $col_names, $col_types;
}


sub write_json {
    my ( $sf, $file_fs, $h_ref ) = @_;
    if ( ! defined $h_ref || ! keys %$h_ref ) {
        open my $fh, '>', $file_fs or die "$file_fs: $!";
        print $fh;
        close $fh;
        return;
    }
    my $json = JSON->new->utf8( 1 )->pretty->canonical->encode( $h_ref );
    open my $fh, '>', $file_fs or die "$file_fs: $!";
    print $fh $json;
    close $fh;
}


sub read_json {
    my ( $sf, $file_fs ) = @_;
    if ( ! defined $file_fs || ! -e $file_fs ) {
        return {};
    }
    open my $fh, '<', $file_fs or die "$file_fs: $!";
    my $json = do { local $/; <$fh> };
    close $fh;
    my $h_ref = {};
    if ( ! eval {
        $h_ref = decode_json( $json ) if $json;
        1 }
    ) {
        die "In '$file_fs':\n$@";
    }
    return $h_ref;
}






1;

__END__
