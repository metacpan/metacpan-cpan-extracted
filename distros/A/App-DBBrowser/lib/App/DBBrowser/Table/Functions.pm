package # hide from PAUSE
App::DBBrowser::Table::Functions;

use warnings;
use strict;
use 5.008003;

use List::MoreUtils qw( first_index );

use Term::Choose       qw( choose );
use Term::Choose::Util qw( choose_a_number );

use App::DBBrowser::Auxil;
use App::DBBrowser::DB;


sub new {
    my ( $class, $info, $options, $data ) = @_;
    bless {
        i => $info,
        o => $options,
        d => $data
    }, $class;
}


sub col_function {
    my ( $sf, $sql, $stmt_type ) = @_;
    my $ax  = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my @functions = ( qw( Epoch_to_Date Bit_Length Truncate Char_Length Epoch_to_DateTime ) );
    if ( @{$sql->{group_by_cols}} + @{$sql->{aggr_cols}} + @{$sql->{chosen_cols}} == 0 ) {
        @{$sql->{chosen_cols}} = @{$sql->{cols}};
    }
    for my $col_type ( qw( chosen_cols aggr_cols group_by_cols ) ) {
        my $col_type_orig = 'orig_' . $col_type;
        if ( @{$sql->{$col_type}} && ! @{$sql->{$col_type_orig}} ) {
            @{$sql->{$col_type_orig}} = @{$sql->{$col_type}};
        }
    }
    my $changed = 0;

    COL_SCALAR_FUNC: while ( 1 ) {
        my $default = 0;
        my @pre = ( undef, $sf->{i}{_confirm} );
        my @cols = ( @{$sql->{group_by_cols}}, @{$sql->{aggr_cols}}, @{$sql->{chosen_cols}} );
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
            return 1; # return $tmp
        }
        ( my $qt_col = $choices->[$idx] ) =~ s/^\-\s//;
        $idx -= @pre;
        my $cols_type;
        if ( $idx <= $#{$sql->{group_by_cols}} ) {
            $cols_type = 'group_by_cols';
        }
        elsif ( $idx <= @{$sql->{group_by_cols}} + $#{$sql->{aggr_cols}} ) {
            $idx -= @{$sql->{group_by_cols}};
            $cols_type = 'aggr_cols';
        }
        else {
            $idx -= @{$sql->{group_by_cols}} + @{$sql->{aggr_cols}};
            $cols_type = 'chosen_cols';
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
        my $alias = $ax->alias( 'functions', 'AS: ', undef, $col_with_func );
        #if ( defined $alias && length $alias ) {
            $sql->{alias}{$col_with_func} = $ax->quote_col_qualified( [ $alias ] );
        #}
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
    my $plui = App::DBBrowser::DB->new( $sf->{i}, $sf->{o} );
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
            $quote_f = $plui->epoch_to_datetime( $qt_col, $div );
        }
        else {
            $quote_f = $plui->epoch_to_date( $qt_col, $div );
        }
    }
    elsif ( $func eq 'Truncate' ) {
        my $info = "TRUNC $qt_col";
        my $name = "Decimal places: ";
        my $precision = choose_a_number( 2,
            { info => $info, name => $name, small_on_top => 1, mouse => $sf->{o}{table}{mouse}, clear_screen => 0 }
        );
        return if ! defined $precision;
        $quote_f = $plui->truncate( $qt_col, $precision );
    }
    elsif ( $func eq 'Bit_Length' ) {
        $quote_f = $plui->bit_length( $qt_col );
    }
    elsif ( $func eq 'Char_Length' ) {
        $quote_f = $plui->char_length( $qt_col );
    }
    return $quote_f;
}





1;


__END__
