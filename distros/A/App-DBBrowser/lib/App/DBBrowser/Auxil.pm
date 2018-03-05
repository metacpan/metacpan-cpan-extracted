package # hide from PAUSE
App::DBBrowser::Auxil;

use warnings;
use strict;
use 5.008003;

our $VERSION = '2.003';

use Encode qw( encode );

use Encode::Locale  qw();
use JSON            qw( decode_json );
use List::MoreUtils qw( any );

use Term::Choose           qw( choose );
use Term::Choose::LineFold qw( line_fold );
use Term::Choose::Util     qw( term_width );

use if $^O eq 'MSWin32', 'Win32::Console::ANSI';


sub new {
    my ( $class, $info, $opt ) = @_;
    bless { i => $info, o => $opt }, $class;
}


sub print_sql {
    my ( $sf, $sql, $stmt_typeS ) = @_;
    my $table = $sql->{table};
    my $str = '';
    for my $stmt_type ( @$stmt_typeS ) {
        if ( $stmt_type eq 'Create_table' ) {
            my @cols = defined $sql->{create_table_cols} ? @{$sql->{create_table_cols}} : @{$sql->{insert_into_cols}};
            $str .= "CREATE TABLE $table (";
            if ( @cols ) {
                $str .= " " . join( ', ',  map { defined $_ ? $_ : '' } @cols ) . " ";
            }
            $str .= ")\n";
        }
        if ( $stmt_type eq 'Insert' ) {
            my @cols = @{$sql->{insert_into_cols}};
            $str .= "INSERT INTO $table (";
            if ( @cols ) {
                $str .= " " . join( ', ', map { defined $_ ? $_ : '' } @cols ) . " " ;
            }
            $str .= ")\n";
            $str .= "  VALUES(\n";
            my $val_indent = 4;
            my $max = 9;
            if ( @{$sql->{insert_into_args}} > $max ) {
                for my $insert_row ( @{$sql->{insert_into_args}}[ 0 .. $max - 3 ] ) {
                    $str .= ( ' ' x $val_indent ) . join( ', ', map { defined $_ ? $_ : '' } @$insert_row ) . "\n";
                }
                $str .= sprintf "%s...\n",       ' ' x $val_indent;
                $str .= sprintf "%s[%d rows]\n", ' ' x $val_indent, scalar @{$sql->{insert_into_args}};
            }
            else {
                for my $insert_row ( @{$sql->{insert_into_args}} ) {
                    $str .= ( ' ' x $val_indent ) . join( ', ', map { defined $_ ? $_ : '' } @$insert_row ) . "\n";
                }
            }
            $str .= "  )\n";
        }
        if ( $stmt_type =~ /^(?:Select|Delete|Update)\z/ ) {
            my %type_sql = (
                Select => "SELECT",
                Delete => "DELETE",
                Update => "UPDATE",
            );
            my $cols_sql;
            if ( $stmt_type eq 'Select' ) {
                if ( $sql->{select_type} eq '*' ) {
                    $cols_sql = ' *';
                }
                elsif ( $sql->{select_type} eq 'chosen_cols' ) {
                    $cols_sql = ' ' . join( ', ', @{$sql->{chosen_cols}} );
                }
                elsif ( @{$sql->{aggr_cols}} || @{$sql->{group_by_cols}} ) {
                    $cols_sql = ' ' . join( ', ', @{$sql->{group_by_cols}}, @{$sql->{aggr_cols}} );
                }
                else {
                    $cols_sql = ' *';
                }
            }
            $str .= $type_sql{$stmt_type};
            $str .= $sql->{distinct_stmt}                   if $sql->{distinct_stmt};
            $str .= $cols_sql                        . "\n" if $cols_sql;
            $str .= " FROM"                                 if $stmt_type eq 'Select' || $stmt_type eq 'Delete';
            $str .= ' '      . $table                . "\n";
            $str .= ' '      . $sql->{set_stmt}      . "\n" if $sql->{set_stmt};
            $str .= ' '      . $sql->{where_stmt}    . "\n" if $sql->{where_stmt};
            $str .= ' '      . $sql->{group_by_stmt} . "\n" if $sql->{group_by_stmt};
            $str .= ' '      . $sql->{having_stmt}   . "\n" if $sql->{having_stmt};
            $str .= ' '      . $sql->{order_by_stmt} . "\n" if $sql->{order_by_stmt};
            $str .= ' '      . $sql->{limit_stmt}    . "\n" if $sql->{limit_stmt};
            $str .= ' '      . $sql->{offset_stmt}   . "\n" if $sql->{offset_stmt};
        }
    }
    for my $val ( @{$sql->{set_args}}, @{$sql->{where_args}}, @{$sql->{having_args}} ) {
        $str =~ s/\?/$val/;
    }
    $str .= "\n";
    #return $str if defined wantarray;
    print $sf->{i}{clear_screen};
    print line_fold( $str, term_width() - 2, '', ' ' x $sf->{i}{stmt_init_tab} );
}


sub quote_table {
    my ( $sf, $dbh, $td ) = @_;
    my @idx = $sf->{o}{G}{qualified_table_name} ? ( 0 .. 2 ) : ( 2 );
    if ( $sf->{o}{G}{quote_identifiers} ) {
        return $dbh->quote_identifier( @{$td}[@idx] );
    }
    return join( $sf->{i}{sep_char}, grep { defined && length } @{$td}[@idx] );
}


sub quote_col_qualified {
    my ( $sf, $dbh, $cd ) = @_;
    if ( $sf->{o}{G}{quote_identifiers} ) {
        return $dbh->quote_identifier( @$cd );
    }
    return join( $sf->{i}{sep_char}, grep { defined && length } @$cd );
}


sub quote_simple_many {
    my ( $sf, $dbh, $list ) = @_;
    if ( $sf->{o}{G}{quote_identifiers} ) {
        return [ map { $dbh->quote_identifier( $_ ) } @$list ];
    }
    return [ @$list ];
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
    my @strg_keys = ( qw( distinct_stmt set_stmt where_stmt group_by_stmt having_stmt order_by_stmt limit_stmt ) );
    my @list_keys = ( qw( chosen_cols set_args aggr_cols where_args group_by_cols having_args insert_into_cols insert_into_args ) );
    @{$sql}{@strg_keys} = ( '' ) x  @strg_keys;
    @{$sql}{@list_keys} = map{ [] } @list_keys;
    $sql->{modified_cols} = []; #
    for my $y ( keys %$backup ) {
        $sql->{$y} = $backup->{$y};
    }
    $sql->{select_type} = '*';
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
    return {} if ! -f encode( 'locale_fs', $file );
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
