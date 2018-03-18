package # hide from PAUSE
App::DBBrowser::Table::Functions;

use warnings;
use strict;
use 5.008003;
no warnings 'utf8';

our $VERSION = '2.006';

use List::MoreUtils qw( first_index );

use Term::Choose       qw( choose );
use Term::Choose::Util qw( choose_a_number );

use App::DBBrowser::Auxil;
use App::DBBrowser::DB;


sub new {
    my ( $class, $info, $opt ) = @_;
    bless { i => $info, o => $opt }, $class;
}


sub col_function {
    my ( $sf, $dbh, $sql, $stmt_type ) = @_;
    my $ax  = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o} );
    my @functions = ( qw( Epoch_to_Date Bit_Length Truncate Char_Length Epoch_to_DateTime ) );
    my $cols_type = '';
    if ( $sql->{select_type} eq '*' ) {
        @{$sql->{chosen_cols}} = @{$sql->{cols}};
        $cols_type = 'chosen_cols';
    }
    elsif ( $sql->{select_type} eq 'chosen_cols' ) {
        $cols_type = 'chosen_cols';
    }
    if ( $cols_type eq 'chosen_cols' ) {
        if ( ! @{$sql->{orig_chosen_cols}} ) {
            @{$sql->{orig_chosen_cols}} = @{$sql->{'chosen_cols'}};
        }
    }
    else {
        if ( @{$sql->{aggr_cols}} && ! @{$sql->{orig_aggr_cols}} ) {
            @{$sql->{orig_aggr_cols}} = @{$sql->{'aggr_cols'}};
        }
        if ( @{$sql->{group_by_cols}} && ! @{$sql->{orig_group_by_cols}} ) {
            @{$sql->{orig_group_by_cols}} = @{$sql->{'group_by_cols'}};
        }
    }
    my $changed = 0;

    COL_SCALAR_FUNC: while ( 1 ) {
        my $default = 0;
        my @pre = ( undef, $sf->{i}{_confirm} );
        my @cols;
        if ( $cols_type eq 'chosen_cols' ) {
            @cols = @{$sql->{chosen_cols}};
        }
        else {
            @cols = ( @{$sql->{aggr_cols}}, @{$sql->{group_by_cols}} );
        }
        my $choices = [ @pre, map( "- $_", @cols ) ];
        $ax->print_sql( $sql, [ $stmt_type ] );
        # Choose
        my $idx = choose(
            $choices,
            { %{$sf->{i}{lyt_stmt_v}}, index => 1, default => $default }
        );
        if ( ! defined $idx || ! defined $choices->[$idx] ) {
            return;
        }
        if ( $choices->[$idx] eq $sf->{i}{_confirm} ) {
            if ( ! $changed ) {
                return;
            }
            $sql->{select_type} = 'chosen_cols' if $sql->{select_type} eq '*'; # makes the changes visible
            return 1; # return $tmp
        }
        ( my $qt_col = $choices->[$idx] ) =~ s/^\-\s//;
        $idx -= @pre;
        if ( $cols_type ne 'chosen_cols' ) {
            if ( $idx - @{$sql->{aggr_cols}} >= 0 ) { # chosen a "group by" col
                $idx -= @{$sql->{aggr_cols}};
                $cols_type = 'group_by_cols';
            }
            else {
                $cols_type = 'aggr_cols';
            }
        }
        # reset col to original, if __col_function is called on a already modified col:
        if ( $sql->{$cols_type}[$idx] ne $sql->{'orig_' . $cols_type}[$idx] ) {
            if ( $cols_type ne 'aggr_cols' ) {
                my $i = first_index { $sql->{$cols_type}[$idx] eq $_ } @{$sql->{modified_cols}};
                splice( @{$sql->{modified_cols}}, $i, 1 );
            }
            $sql->{$cols_type}[$idx] = $sql->{'orig_' . $cols_type}[$idx];
            if ( $cols_type eq 'group_by_cols' ) {
                $sql->{group_by_stmt} = " GROUP BY " . join( ', ', @{$sql->{$cols_type}} );
            }
            $changed++;
            next COL_SCALAR_FUNC;
        }
        $ax->print_sql( $sql, [ $stmt_type ] );
        # Choose
        my $function = choose(
            [ undef, map( "  $_", @functions ) ],
            { %{$sf->{i}{lyt_stmt_v}} }
        );
        if ( ! defined $function ) {
            next COL_SCALAR_FUNC;
        }
        $function =~ s/^\s\s//;
        $ax->print_sql( $sql, [ $stmt_type ] );
        my $col_with_func = $sf->__prepare_col_func( $function, $qt_col );
        if ( ! defined $col_with_func ) {
            next COL_SCALAR_FUNC;
        }
        # modify columns:
        $sql->{$cols_type}[$idx] = $col_with_func;
        my $alias = $ax->__alias( $dbh, $col_with_func );
        if ( defined $alias && length $alias ) {
            $sql->{alias}{$col_with_func} = $ax->quote_col_qualified( $dbh, [ $alias ] );
        }
        if ( $cols_type eq 'group_by_cols' ) {
            $sql->{group_by_stmt} = " GROUP BY " . join( ', ', @{$sql->{group_by_cols}} );
        }
        if ( $cols_type ne 'aggr_cols' ) {
            # $sql->{modified_cols}: make the modified columns available in WHERE and ORDER BY
            # skip aggregate functions because aggregate are not allowed in WHERE clauses
            # no problem for ORDER BY because it doesn't use the $sql->{modified_cols} in aggregate mode
            push @{$sql->{modified_cols}}, $col_with_func;
        }
        $changed++;
        next COL_SCALAR_FUNC;
    }
}


sub __prepare_col_func {
    my ( $sf, $func, $qt_col ) = @_;
    my $obj_db = App::DBBrowser::DB->new( $sf->{i}, $sf->{o} );
    my $quote_f;
    if ( $func =~ /^Epoch_to_Date(?:Time)?\z/ ) {
        my $prompt = $func eq 'Epoch_to_Date' ? 'DATE' : 'DATETIME';
        $prompt .= "($qt_col)\nInterval:";
        my ( $microseconds, $milliseconds, $seconds ) = (
            '  ****************   Micro-Second',
            '  *************      Milli-Second',
            '  **********               Second' );
        my $choices = [ undef, $microseconds, $milliseconds, $seconds ];
        # Choose
        my $interval = choose(
            $choices,
            { %{$sf->{i}{lyt_stmt_v}}, prompt => $prompt }
        );
        return if ! defined $interval;
        my $div = $interval eq $microseconds ? 1000000 :
                  $interval eq $milliseconds ? 1000 : 1;
        if ( $func eq 'Epoch_to_DateTime' ) {
            $quote_f = $obj_db->epoch_to_datetime( $qt_col, $div );
        }
        else {
            $quote_f = $obj_db->epoch_to_date( $qt_col, $div );
        }
    }
    elsif ( $func eq 'Truncate' ) {
        my $info = "TRUNC $qt_col";
        my $name = "Decimal places: ";
        my $precision = choose_a_number( 2,
            { info => $info, name => $name, small => 1, mouse => $sf->{o}{table}{mouse}, clear_screen => 0 }
        );
        return if ! defined $precision;
        $quote_f = $obj_db->truncate( $qt_col, $precision );
    }
    elsif ( $func eq 'Bit_Length' ) {
        $quote_f = $obj_db->bit_length( $qt_col );
    }
    elsif ( $func eq 'Char_Length' ) {
        $quote_f = $obj_db->char_length( $qt_col );
    }
    return $quote_f;
}





1;


__END__
