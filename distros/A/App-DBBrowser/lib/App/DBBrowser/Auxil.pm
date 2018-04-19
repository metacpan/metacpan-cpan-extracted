package # hide from PAUSE
App::DBBrowser::Auxil;

use warnings;
use strict;
use 5.008003;

our $VERSION = '2.013';

use Encode qw( encode );

use Encode::Locale qw();
use JSON           qw( decode_json );

use Term::Choose           qw( choose );
use Term::Choose::LineFold qw( line_fold );
use Term::Choose::Util     qw( term_width );
use Term::Form             qw();

use if $^O eq 'MSWin32', 'Win32::Console::ANSI';


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
                push @tmp, $row_in . '[' . scalar( @{$sql->{insert_into_args}} ) . ' rows]';
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
    my @tmp;
    if ( ! keys %{$sql->{alias}} ) {
        @tmp = ( @{$sql->{group_by_cols}}, @{$sql->{aggr_cols}}, @{$sql->{chosen_cols}} );
    }
    else {
        push @tmp, @{$sql->{group_by_cols}};
        for ( @{$sql->{aggr_cols}}, @{$sql->{chosen_cols}} ) {
            if ( exists $sql->{alias}{$_} && defined  $sql->{alias}{$_} && length $sql->{alias}{$_} ) {
                push @tmp, $_ . " AS " . $sql->{alias}{$_};
            }
            else {
                push @tmp, $_;
            }
        }
    }
    if ( ! @tmp ) {
        if ( $sf->{i}{multi_tbl} eq 'join' ) {
             return ' ' . join ', ', @{$sql->{cols}};
        }
        return " *";
    }
    return ' ' . join ', ', @tmp;
}


sub print_sql {
    my ( $sf, $sql, $stmt_typeS, $tmp ) = @_; ###
    return if ! defined $stmt_typeS;
    $tmp = {} if ! defined $tmp;
    my $pr_sql = { %$sql };
    for my $key ( keys %$tmp ) {
        $pr_sql->{$key} = exists $tmp->{$key} ? $tmp->{$key} : $sql->{$key}; #
    }
    my $str = '';
    for my $stmt_type ( @$stmt_typeS ) {
         $str .= $sf->get_stmt( $pr_sql, $stmt_type, 'print' );
    }
    my $filled = $sf->fill_stmt( $str, [ @{$pr_sql->{set_args}}, @{$pr_sql->{where_args}}, @{$pr_sql->{having_args}} ] );
    $str = $filled if defined $filled;
    $str .= "\n";
    print $sf->{i}{clear_screen};
    print line_fold( $str, term_width() - 2, '', ' ' x $sf->{i}{stmt_init_tab} );
}


sub fill_stmt {
    my ( $sf, $stmt, $args, $quote ) = @_;
    my $rx_placeholder = qr/(?<=(?:,|\s|\())\?(?=(?:,|\s|\)|$))/;
    for my $arg ( @$args ) {
        $arg = $sf->{d}{dbh}->quote( $arg ) if $quote;
        $stmt =~ s/$rx_placeholder/$arg/;
    }
    if ( $stmt !~ $rx_placeholder ) {
        return $stmt;
    }
    return;
}


sub alias {
    my ( $sf, $raw, $default ) = @_;
    my $alias;
    if ( $sf->{o}{G}{alias} ) {
        my $tf = Term::Form->new();
        $alias = $tf->readline( " AS ", { info => $raw } );
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


sub print_error_message {
    my ( $sf, $message, $title ) = @_;
    print "$title:\n" if $title;
    utf8::decode( $message );
    print $message;
    choose(
        [ 'Press ENTER to continue' ],
        { %{$sf->{i}{lyt_m}}, prompt => '' }
    );
}


sub reset_sql {
    my ( $sf, $sql ) = @_;
    my $backup = {};
    for my $y ( qw( db schema table cols ) ) {
        $backup->{$y} = $sql->{$y} if exists $sql->{$y};
    }
    map { delete $sql->{$_} } keys %$sql; # not $sql = {} so $sql is still pointing to the outer $sql
    my @string = qw( distinct_stmt set_stmt where_stmt group_by_stmt having_stmt order_by_stmt limit_stmt offset_stmt );
    my @array  = qw(       chosen_cols      aggr_cols      group_by_cols
                      orig_chosen_cols orig_aggr_cols orig_group_by_cols  modified_cols
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


sub write_json {
    my ( $sf, $file, $h_ref ) = @_;
    if ( ! defined $h_ref || ! keys %$h_ref ) {
        open my $fh, '>', encode( 'locale_fs', $file ) or die $!;
        print $fh;
        close $fh;
        return;
    }
    my $json = JSON->new->utf8( 1 )->pretty->canonical->encode( $h_ref );
    open my $fh, '>', encode( 'locale_fs', $file ) or die $!;
    print $fh $json;
    close $fh;
}


sub read_json {
    my ( $sf, $file ) = @_;
    if ( ! -e $file ) {
        return {};
    }
    open my $fh, '<', encode( 'locale_fs', $file ) or die $!;
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
