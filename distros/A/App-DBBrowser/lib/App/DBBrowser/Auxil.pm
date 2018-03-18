package # hide from PAUSE
App::DBBrowser::Auxil;

use warnings;
use strict;
use 5.008003;

our $VERSION = '2.006';

use Encode qw( encode );

use Encode::Locale  qw();
use JSON            qw( decode_json );
use List::MoreUtils qw( any );

use Term::Choose           qw( choose );
use Term::Choose::LineFold qw( line_fold );
use Term::Choose::Util     qw( term_width );
use Term::Form             qw();

use if $^O eq 'MSWin32', 'Win32::Console::ANSI';


sub new {
    my ( $class, $info, $opt ) = @_;
    bless { i => $info, o => $opt }, $class;
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


sub print_sql {
    my ( $sf, $sql, $stmt_typeS, $tmp ) = @_;
    $tmp = {} if ! defined $tmp;
    my $p_sql = {};
    for my $key ( keys %$sql ) {
        $p_sql->{$key} = exists $tmp->{$key} ? $tmp->{$key} : $sql->{$key}; #
    }
    my $table = $p_sql->{table};
    my $str = '';
    for my $stmt_type ( @$stmt_typeS ) {
        if ( $stmt_type eq 'Create_table' ) {
            my @cols = defined $p_sql->{create_table_cols} ? @{$p_sql->{create_table_cols}} : @{$p_sql->{insert_into_cols}};
            $str .= "CREATE TABLE $table (";
            if ( @cols ) {
                $str .= join( ', ',  map { defined $_ ? $_ : '' } @cols );
            }
            $str .= ")\n";
        }
        if ( $stmt_type eq 'Insert' ) {
            my @cols = @{$p_sql->{insert_into_cols}};
            $str .= "INSERT INTO $table (";
            if ( @cols ) {
                $str .= join( ', ', map { defined $_ ? $_ : '' } @cols );
            }
            $str .= ")\n";
            $str .= "  VALUES(\n";
            my $val_indent = 4;
            my $max = 9;
            if ( @{$p_sql->{insert_into_args}} > $max ) {
                for my $insert_row ( @{$p_sql->{insert_into_args}}[ 0 .. $max - 3 ] ) {
                    $str .= ( ' ' x $val_indent ) . join( ', ', map { defined $_ ? $_ : '' } @$insert_row ) . "\n";
                }
                $str .= sprintf "%s...\n",       ' ' x $val_indent;
                $str .= sprintf "%s[%d rows]\n", ' ' x $val_indent, scalar @{$p_sql->{insert_into_args}};
            }
            else {
                for my $insert_row ( @{$p_sql->{insert_into_args}} ) {
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
                if ( $p_sql->{select_type} eq '*' ) {
                    $cols_sql = ' *';
                }
                elsif ( $p_sql->{select_type} eq 'chosen_cols' ) {
                    $cols_sql = ' ' . $sf->__cols_as_string( $p_sql, 'chosen_cols' );
                }
                elsif ( @{$p_sql->{aggr_cols}} || @{$p_sql->{group_by_cols}} ) {
                    $cols_sql = ' ' . $sf->__cols_as_string( $p_sql, 'aggr_and_group_by_cols' ); ##
                }
                else {
                    $cols_sql = ' *';
                }
            }
            $str .= $type_sql{$stmt_type};
            $str .= $p_sql->{distinct_stmt}                   if $p_sql->{distinct_stmt};
            $str .= $cols_sql                          . "\n" if $cols_sql;
            $str .= " FROM"                                   if $stmt_type eq 'Select' || $stmt_type eq 'Delete';
            $str .= ' '      . $table                  . "\n";
            $str .= ' '      . $p_sql->{set_stmt}      . "\n" if $p_sql->{set_stmt};
            $str .= ' '      . $p_sql->{where_stmt}    . "\n" if $p_sql->{where_stmt};
            $str .= ' '      . $p_sql->{group_by_stmt} . "\n" if $p_sql->{group_by_stmt};
            $str .= ' '      . $p_sql->{having_stmt}   . "\n" if $p_sql->{having_stmt};
            $str .= ' '      . $p_sql->{order_by_stmt} . "\n" if $p_sql->{order_by_stmt};
            $str .= ' '      . $p_sql->{limit_stmt}    . "\n" if $p_sql->{limit_stmt};
            $str .= ' '      . $p_sql->{offset_stmt}   . "\n" if $p_sql->{offset_stmt};
        }
    }
    for my $val ( @{$p_sql->{select_sq_args}}, @{$p_sql->{set_args}}, @{$p_sql->{where_args}}, @{$p_sql->{having_args}} ) {
        $str =~ s/\?/$val/;
    }
    $str .= "\n";
    print $sf->{i}{clear_screen};
    print line_fold( $str, term_width() - 2, '', ' ' x $sf->{i}{stmt_init_tab} );
}


sub __cols_as_string {
    my ( $sf, $p_sql, $select_type ) = @_;
    if ( ! keys %{$p_sql->{alias}} ) {
        return join( ', ', @{$p_sql->{chosen_cols}} ) if $select_type eq 'chosen_cols';
        return join( ', ', @{$p_sql->{group_by_cols}}, @{$p_sql->{aggr_cols}} );
    }
    my @tmp;
    if ( $select_type eq 'chosen_cols' ) {
        my $i = 0;
        for ( @{$p_sql->{chosen_cols}} ) {
            my $filled = $_;
            while ( $filled =~ /\?/ ) {
                $filled =~ s/\?/$p_sql->{select_sq_args}[$i++]/;
            }
            if ( exists $p_sql->{alias}{$filled} && defined  $p_sql->{alias}{$filled} && length $p_sql->{alias}{$filled} ) {
                push @tmp, $_ . " AS " . $p_sql->{alias}{$filled};
            }
            else {
                push @tmp, $_;
            }
        }
        return join( ', ', @tmp );
    }
    else {
        push @tmp, @{$p_sql->{group_by_cols}};
        for ( @{$p_sql->{aggr_cols}} ) {
            if ( exists $p_sql->{alias}{$_} && defined  $p_sql->{alias}{$_} && length $p_sql->{alias}{$_} ) {
                push @tmp, $_ . " AS " . $p_sql->{alias}{$_};
            }
            else {
                push @tmp, $_;
            }
        }
        return join( ', ', @tmp );
    }
}


sub __alias {
    my ( $sf, $dbh, $raw, $default ) = @_;
    my $alias;
    if ( $sf->{o}{G}{alias} ) {
        my $tf = Term::Form->new();
        $alias = $tf->readline( $raw . " AS " );
    }
    if ( ! defined $alias || ! length $alias ) {
        $alias = $default;
    }
    return $alias;
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
    my @string = qw( distinct_stmt set_stmt where_stmt group_by_stmt having_stmt order_by_stmt limit_stmt offset_stmt );
    my @array  = qw(       chosen_cols      aggr_cols      group_by_cols
                      orig_chosen_cols orig_aggr_cols orig_group_by_cols  modified_cols
                      select_sq_args set_args where_args having_args
                      insert_into_cols insert_into_args );
    my @hash   = qw( alias );
    @{$sql}{@string} = ( '' ) x  @string;
    @{$sql}{@array}  = map{ [] } @array;
    @{$sql}{@hash}   = map{ {} } @hash;
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
