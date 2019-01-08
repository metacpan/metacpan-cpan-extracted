package # hide from PAUSE
App::DBBrowser::Auxil;

use warnings;
use strict;
use 5.008003;

use Encode       qw( encode );
use Scalar::Util qw( looks_like_number );

use Encode::Locale qw();
use JSON           qw( decode_json );

use Term::Choose            qw( choose );
use Term::Choose::Constants qw( :screen );
use Term::Choose::LineFold  qw( line_fold );
use Term::Choose::Util      qw( term_width insert_sep );
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
    elsif ( $stmt_type eq 'Create_table' ) {
        @tmp = ( sprintf "CREATE TABLE $table (%s)", join ', ', @{$sql->{create_table_cols}} );
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
            my $row_in = ' '  x 4;
            my $max = 9;
            push @tmp, "  VALUES(";
            if ( @{$sql->{insert_into_args}} > $max ) {
                for my $row ( @{$sql->{insert_into_args}}[ 0 .. $max - 3 ] ) {
                    push @tmp, $row_in . join ', ', map { defined $_ ? $_ : '' } @$row;
                }
                push @tmp, $row_in . '...';
                my $row_count = scalar( @{$sql->{insert_into_args}} );
                push @tmp, $row_in . '[' . insert_sep( $row_count, $sf->{o}{G}{thsd_sep} ) . ' rows]';
            }
            else {
                for my $row ( @{$sql->{insert_into_args}} ) {
                    push @tmp, $row_in . join ', ', map { defined $_ ? $_ : '' } @$row;
                }
            }
            push @tmp, "  )";
        }
    }
    if ( $used_for eq 'prepare' ) {
        return join '', @tmp;
    }
    else {
        return join( "\n", @tmp ) . "\n";
    }
}


sub __select_cols {
    my ( $sf, $sql ) = @_;
    my @combined_cols;
    if ( ! keys %{$sql->{alias}} ) {
        @combined_cols = ( @{$sql->{chosen_cols}} );
    }
    else {
        for ( @{$sql->{chosen_cols}} ) {
            if ( exists $sql->{alias}{$_} && defined  $sql->{alias}{$_} && length $sql->{alias}{$_} ) {
                push @combined_cols, $_ . " AS " . $sql->{alias}{$_};
            }
            else {
                push @combined_cols, $_;
            }
        }
    }
    if ( ! @combined_cols ) {
        if ( $sf->{i}{multi_tbl} eq 'join' ) {
             return ' ' . join ', ', @{$sql->{cols}};
        }
        elsif ( @{$sql->{group_by_cols}} || @{$sql->{aggr_cols}} ) {
            return ' ' . join ', ', @{$sql->{group_by_cols}}, @{$sql->{aggr_cols}};
        }
        else {
            return " *";
        }
    }
    return ' ' . join ', ', @combined_cols;
}


sub print_sql {
    my ( $sf, $sql, $stmt_typeS, $waiting ) = @_;
    return if ! defined $stmt_typeS;
    my $str = '';
    for my $stmt_type ( @$stmt_typeS ) {
         $str .= $sf->get_stmt( $sql, $stmt_type, 'print' );
    }
    my $filled = $sf->stmt_placeholder_to_value( $str, [ @{$sql->{set_args}}, @{$sql->{where_args}}, @{$sql->{having_args}} ] );
    $str = $filled if defined $filled;
    $str .= "\n";
    print $sf->{i}{clear_screen};
    print line_fold( $str, term_width() - 2, '', ' ' x $sf->{i}{stmt_init_tab} );
    if ( defined $waiting ) {
        local $| = 1;
        print HIDE_CURSOR;
        print $waiting;
    }
}


sub column_names_and_types {
    my ( $sf, $tables ) = @_;
    my ( $col_names, $col_types );
    for my $table ( @$tables ) {
        my $sth = $sf->{d}{dbh}->prepare( "SELECT * FROM " . $sf->quote_table( $sf->{d}{tables_info}{$table} ) . " LIMIT 0" );
        $sth->execute() if $sf->{d}{driver} ne 'SQLite';
        $col_names->{$table} ||= $sth->{NAME};
        $col_types->{$table} ||= $sth->{TYPE};
    }
    return $col_names, $col_types;
}


sub tables_data {   # in App::DBBrowser::DB no 'quote_table'
    my ( $sf, $schema, $db_attached ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $driver = $sf->{d}{driver};
    my ( $user_tbls, $sys_tbls ) = ( [], [] );
    my $table_data = {};
    my ( $table_schem, $table_name );
    if ( $driver eq 'Pg' ) {
        $table_schem = 'pg_schema';
        $table_name  = 'pg_table';
    }
    else {
        $table_schem = 'TABLE_SCHEM';
        $table_name  = 'TABLE_NAME';
    }
    my @keys = ( 'TABLE_CAT', $table_schem, $table_name, 'TABLE_TYPE' );
    if ( $db_attached ) {
        $schema = undef;
        # More than one schema if a SQLite database has databases attached
    }
    my $sth = $sf->{d}{dbh}->table_info( undef, $schema, undef, undef );
    my $info = $sth->fetchall_arrayref( { map { $_ => 1 } @keys } );
    for my $href ( @$info ) {
        my $table = defined $schema ? $href->{$table_name} : $ax->quote_table( [ @{$href}{@keys} ] );
        if ( $href->{TABLE_TYPE} =~ /SYSTEM/ ) {
            #next if ! $sf->{add_metadata};
            next if $href->{$table_name} eq 'sqlite_temp_master';
            push @$sys_tbls, $table;
        }
        elsif ( $href->{TABLE_TYPE} ne 'INDEX' ) {
        #elsif ( $href->{TABLE_TYPE} eq 'TABLE' || $href->{TABLE_TYPE} eq 'VIEW' || $href->{TABLE_TYPE} eq 'LOCAL TEMPORARY' ) {
            push @$user_tbls, $table;
        }
        $table_data->{$table} = [ @{$href}{@keys} ];
    }
    return $table_data, $user_tbls, $sys_tbls;
}


sub stmt_placeholder_to_value {
    my ( $sf, $stmt, $args, $quote ) = @_;
    if ( ! @$args ) {
        return $stmt;
    }
    my $rx_placeholder = qr/(?<=(?:,|\s|\())\?(?=(?:,|\s|\)|$))/;
    for my $arg ( @$args ) {
        if( $quote && $arg && ! looks_like_number $arg ) {
            $arg = $sf->{d}{dbh}->quote( $arg );
        }
        $stmt =~ s/$rx_placeholder/$arg/;
    }
    if ( $stmt !~ $rx_placeholder ) {
        return $stmt;
    }
}


sub alias {
    my ( $sf, $type, $prompt, $default, $info ) = @_;
    my $alias;
    if ( $sf->{o}{alias}{$type} ) {
        my $tf = Term::Form->new();
        $alias = $tf->readline( $prompt, { info => $info } );
    }
    if ( ! defined $alias || ! length $alias ) {
        $alias = $default;
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
                     chosen_cols
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
    choose(
        [ 'Press ENTER to continue' ],
        { %{$sf->{i}{lyt_m}}, prompt => $message, info => $info }
    );
}


sub write_json {
    my ( $sf, $file, $h_ref ) = @_;
    if ( ! defined $h_ref || ! keys %$h_ref ) {
        open my $fh, '>', encode( 'locale_fs', $file ) or die "$file: $!";
        print $fh;
        close $fh;
        return;
    }
    my $json = JSON->new->utf8( 1 )->pretty->canonical->encode( $h_ref );
    open my $fh, '>', encode( 'locale_fs', $file ) or die "$file: $!";
    print $fh $json;
    close $fh;
}


sub read_json {
    my ( $sf, $file ) = @_;
    if ( ! defined $file || ! -e $file ) {
        return {};
    }
    open my $fh, '<', encode( 'locale_fs', $file ) or die "$file: $!";
    my $json = do { local $/; <$fh> };
    close $fh;
    my $h_ref = {};
    if ( ! eval {
        $h_ref = decode_json( $json ) if $json;
        1 }
    ) {
        die "In '$file':\n$@";
    }
    return $h_ref;
}






1;

__END__
