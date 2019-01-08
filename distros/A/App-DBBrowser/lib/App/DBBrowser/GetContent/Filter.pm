package # hide from PAUSE
App::DBBrowser::GetContent::Filter;

use warnings;
use strict;
use 5.008003;

use Term::Choose       qw( choose );
use Term::Choose::Util qw( choose_a_subset insert_sep );

use App::DBBrowser::Auxil;


sub new {
    my ( $class, $info, $options, $data ) = @_;
    my $sf = {
        i => $info,
        o => $options,
        d => $data,
    };
    bless $sf, $class;
}


sub input_filter {
    my ( $sf, $sql, $stmt_typeS ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $stmt_h = Term::Choose->new( $sf->{i}{lyt_stmt_h} );
    my $backup = [ map { [ @$_ ] } @{$sql->{insert_into_args}} ];

    FILTER: while ( 1 ) {
        my @pre = ( undef, $sf->{i}{ok} );
        my $input_cols       = 'Choose Columns';
        my $input_rows       = 'Choose Rows';
        my $input_rows_range = 'A Range of Rows';
        my $cols_to_rows     = 'Cols_to_Rows';
        my $reset            = 'Reset';
        my $choices = [ @pre, $input_cols, $input_rows, $input_rows_range, $cols_to_rows, $reset ];
        my $waiting = 'Working ... ';
        $ax->print_sql( $sql, $stmt_typeS );
        # Choose
        my $filter = $stmt_h->choose(
            $choices,
            { prompt => 'Filter:' }
        );
        $ax->print_sql( $sql, $stmt_typeS, $waiting );
        if ( ! defined $filter ) {
            $sql->{insert_into_args} = [];
            return;
        }
        elsif ( $filter eq $reset ) {
            $sql->{insert_into_args} = [ map { [ @$_ ] } @$backup ];
            next FILTER
        }
        elsif ( $filter eq $sf->{i}{ok} ) {
            return 1;
        }
        elsif ( $filter eq $input_cols  ) {
            $sf->__choose_columns( $sql );
        }
        elsif ( $filter eq $input_rows ) {
            $sf->__choose_rows( $sql, $stmt_typeS, $waiting );
        }
        elsif ( $filter eq $input_rows_range ) {
            $sf->__range_of_rows( $sql, $stmt_typeS, $waiting );
        }
        elsif ( $filter eq $cols_to_rows ) {
            $sf->__transpose_rows_to_cols( $sql );
        }
    }
}


sub __choose_columns {
    my ( $sf, $sql ) = @_;
    my $aoa = $sql->{insert_into_args};
    my $row_count = @$aoa;
    my $col_count = @{$aoa->[0]};
    my @empty = ( 0 ) x $col_count;
    COL: for my $c ( 0 .. $col_count - 1 ) {
        for my $r ( 0 .. $row_count - 1 ) {
            if ( length $aoa->[$r][$c] ) {
                next COL;
            }
            ++$empty[$c];
        }
    }
    my $mark = [ grep { $empty[$_] < $row_count } 0 .. $#empty ];
    if ( @$mark == $col_count ) {
        $mark = undef; # no preselect if all cols have entries
    }
    my $col_idx = choose_a_subset(
        \@{$aoa->[0]},
        { back => '<<', confirm => $sf->{i}{ok}, index => 1, mark => $mark, layout => 0,
            name => 'Cols: ', clear_screen => 0, mouse => $sf->{o}{table}{mouse} } #
    );
    if ( defined $col_idx && @$col_idx ) {
        $sql->{insert_into_args} = [ map { [ @{$_}[@$col_idx] ] } @$aoa ];
    }
    return;
}


sub __choose_rows {
    my ( $sf, $sql, $stmt_typeS, $waiting ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $aoa = $sql->{insert_into_args};
    my %group; # group rows by the number of cols
    for my $row_idx ( 0 .. $#$aoa ) {
        my $col_count = scalar @{$aoa->[$row_idx]};
        push @{$group{$col_count}}, $row_idx;
    }
    # sort keys by group size
    my @keys_sorted = sort { scalar( @{$group{$b}} ) <=> scalar( @{$group{$a}} ) } keys %group;
    my $stmt_v = Term::Choose->new( $sf->{i}{lyt_stmt_v} );
    $sql->{insert_into_args} = []; # refers to a new empty array - this doesn't delete $aoa

    GROUP: while ( 1 ) {
        $ax->print_sql( $sql, $stmt_typeS, $waiting );
        my $row_idxs = [];
        my @choices_rows;
        if ( @keys_sorted == 1 ) {
            $row_idxs = [ 0 .. $#{$aoa} ];
            {
                no warnings 'uninitialized';
                @choices_rows = map { join ',', @$_ } @$aoa;
            }
        }
        else {
            my @choices_groups;
            my $len = length insert_sep( scalar @{$group{$keys_sorted[0]}}, $sf->{o}{G}{thsd_sep} );
            for my $col_count ( @keys_sorted ) {
                my $row_count = scalar @{$group{$col_count}};
                my $row_str = $row_count == 1 ? 'row  has ' : 'rows have';
                my $col_str = $col_count == 1 ? 'column ' : 'columns';
                push @choices_groups, sprintf '  %*s %s %2d %s',
                    $len, insert_sep( $row_count, $sf->{o}{G}{thsd_sep} ), $row_str,
                    $col_count, $col_str;
            }
            my @pre = ( undef );
            # Choose
            my $idx = $stmt_v->choose(
                [ @pre, @choices_groups ],
                { prompt => 'Choose group:', index => 1, undef => $sf->{i}{back_v_no_ok} }
            );
            if ( ! $idx ) {
                $sql->{insert_into_args} = $aoa;
                return;
            }
            $ax->print_sql( $sql, $stmt_typeS, $waiting );
            $row_idxs = $group{ $keys_sorted[$idx-@pre] };
            {
                no warnings 'uninitialized';
                @choices_rows = map { join ',', @$_ } @{$aoa}[@$row_idxs];
            }
        }

        while ( 1 ) {
            my @pre = ( undef, $sf->{i}{ok} );
            # Choose
            my @idx = $stmt_v->choose(
                [ @pre, @choices_rows ],
                { prompt => 'Choose rows:', index => 1, meta_items => [ 0 .. $#pre ],
                  undef => '<<', include_highlighted => 2 }
            );
            $ax->print_sql( $sql, $stmt_typeS );
            if ( ! $idx[0] ) {
                if ( @keys_sorted == 1 ) {
                    $sql->{insert_into_args} = $aoa;
                    return;
                }
                $sql->{insert_into_args} = [];
                next GROUP;
            }
            if ( $idx[0] == $#pre ) {
                shift @idx;
                for my $i ( @idx ) {
                    my $idx = $row_idxs->[$i-@pre];
                    push @{$sql->{insert_into_args}}, $aoa->[$idx];
                }
                $ax->print_sql( $sql, $stmt_typeS );
                if ( ! @{$sql->{insert_into_args}} ) {
                    $sql->{insert_into_args} = [ @{$aoa}[@$row_idxs] ];
                }
                return;
            }
            for my $i ( @idx ) {
                my $idx = $row_idxs->[$i-@pre];
                push @{$sql->{insert_into_args}}, $aoa->[$idx];
            }
            $ax->print_sql( $sql, $stmt_typeS );
        }
    }
}


sub __range_of_rows {
    my ( $sf, $sql, $stmt_typeS, $waiting ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $aoa = $sql->{insert_into_args};
    my $stmt_v = Term::Choose->new( $sf->{i}{lyt_stmt_v} );
    my @pre = ( undef );
    my $choices;
    {
        no warnings 'uninitialized';
        $choices = [ @pre, map { join ',', @$_ } @$aoa ];
    }
    # Choose
    my $first_idx = $stmt_v->choose(
        $choices,
        { prompt => "Choose FIRST ROW:", index => 1, undef => '<<' }
    );
    if ( ! $first_idx ) {
        return;
    }
    my $first_row = $first_idx - @pre;
    $choices->[$first_row + @pre] = '* ' . $choices->[$first_row + @pre];
    $ax->print_sql( $sql, $stmt_typeS );
    # Choose
    my $last_idx = $stmt_v->choose(
        $choices,
        { prompt => "Choose LAST ROW:", default => $first_row, index => 1, undef => '<<' }
    );
    if ( ! $last_idx ) {
        return;
    }
    my $last_row = $last_idx - @pre;
    if ( $last_row < $first_row ) {
        $ax->print_sql( $sql, $stmt_typeS );
        # Choose
        choose(
            [ "Last row ($last_row) is less than First row ($first_row)!" ],
            { %{$sf->{i}{lyt_m}}, prompt => 'Press ENTER' }
        );
        return;
    }
    $sql->{insert_into_args} = [ @{$aoa}[$first_row .. $last_row] ];
    return;
}


sub __transpose_rows_to_cols {
    my ( $sf, $sql ) = @_;
    my $aoa = $sql->{insert_into_args};
    my $tmp_aoa = [];
    for my $row ( 0 .. $#$aoa ) {
        for my $col ( 0 .. $#{$aoa->[$row]} ) {
            $tmp_aoa->[$col][$row] = $aoa->[$row][$col];
        }
    }
    $sql->{insert_into_args} = $tmp_aoa;
    return;
}







1;


__END__
