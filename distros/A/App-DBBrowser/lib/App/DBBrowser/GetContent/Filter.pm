package # hide from PAUSE
App::DBBrowser::GetContent::Filter;

use warnings;
use strict;
use 5.010001;

use Term::Choose       qw();
use Term::Choose::Util qw( insert_sep );
use Term::Form         qw();

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
    my ( $sf, $sql, $default_e2n ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $backup = [ map { [ @$_ ] } @{$sql->{insert_into_args}} ];
    my $waiting = 'Working ... ';
    my $confirm          = '    OK';
    my $back             = '    <<';
    my $input_cols       = 'Choose_Cols';
    my $input_rows       = 'Choose_Rows';
    my $input_rows_range = 'Range_Rows';
    my $add_col          = 'Add_Col'; # append_empty_col
    my $empty_to_null    = 'Empty2NULL';
    my $merge_rows       = 'Merge_Rows ';
    my $split_table      = 'Split_Table';
    my $split_col        = 'Split_Col';
    my $replace          = 'Replace';
    my $reparse          = 'ReParse',
    my $cols_to_rows     = 'Cols2Rows';
    my $reset            = 'Reset';
    $sf->{empty_to_null} = $default_e2n;
    $sf->{i}{idx_added_cols} = [];
    my $old_idx = 0;

    FILTER: while ( 1 ) {
        $ax->print_sql( $sql );
        my $choices = [
            undef,    $input_cols, $input_rows,  $input_rows_range, $add_col,   $empty_to_null, $reset,
            $confirm, $replace,    $split_table, $merge_rows,       $split_col, $cols_to_rows,  $reparse,
        ];
        # Choose
        my $idx = $tc->choose(
            $choices,
            { prompt => 'Filter:', layout => 0, order => 0, max_width => 90, index => 1, default => $old_idx,
              undef => $back }
        );
        $ax->print_sql( $sql, $waiting );
        if ( ! $idx ) {
            $sql->{insert_into_args} = [];
            return;
        }
        if ( $sf->{o}{G}{menu_memory} ) {
            if ( $old_idx == $idx && ! $ENV{TC_RESET_AUTO_UP} ) {
                $old_idx = 0;
                next FILTER;
            }
            $old_idx = $idx;
        }
        my $filter = $choices->[$idx];
        if ( $filter eq $reset ) {
            $sql->{insert_into_args} = [ map { [ @$_ ] } @$backup ];
            $sf->{empty_to_null} = $default_e2n;
            next FILTER
        }
        elsif ( $filter eq $confirm ) {
            if ( $sf->{empty_to_null} ) {
                $ax->print_sql( $sql, $waiting );
                no warnings 'uninitialized';
                $sql->{insert_into_args} = [ map { [ map { length ? $_ : undef } @$_ ] } @{$sql->{insert_into_args}} ];
            }
            return 1;
        }
        elsif ( $filter eq $reparse ) {
            return -1;
        }
        elsif ( $filter eq $input_cols  ) {
            $sf->__choose_columns( $sql );
        }
        elsif ( $filter eq $input_rows ) {
            $sf->__choose_rows( $sql, $waiting );
        }
        elsif ( $filter eq $input_rows_range ) {
            $sf->__range_of_rows( $sql, $waiting );
        }
        elsif ( $filter eq $empty_to_null ) {
            $sf->__empty_to_null();
        }
        elsif ( $filter eq $add_col ) {
            $sf->__add_column( $sql );
        }
        elsif ( $filter eq $cols_to_rows ) {
            $sf->__transpose_rows_to_cols( $sql );
        }
        elsif ( $filter eq $merge_rows ) {
            $sf->__merge_rows( $sql, $waiting );
        }
        elsif ( $filter eq $split_table ) {
            $sf->__split_table( $sql, $waiting );
        }
        elsif ( $filter eq $split_col ) {
            $sf->__split_column( $sql, $waiting );
        }
        elsif ( $filter eq $replace ) {
            $sf->__search_and_replace( $sql, $waiting );
        }
    }
}


sub __empty_to_null {
    my ( $sf ) = @_;
    my $tu = Term::Choose::Util->new( $sf->{i}{tcu_default} );
    my $tmp = { empty_to_null => $sf->{empty_to_null} };
    $tu->settings_menu(
        [ [ 'empty_to_null', "  Empty fields to NULL", [ 'NO', 'YES' ] ] ],
        $tmp
    );
    $sf->{empty_to_null} = $tmp->{empty_to_null};
}


sub __prepare_header_and_mark {
    my ( $sf, $aoa ) = @_;
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
    my $mark = [];
    my $header = [];
    for my $i ( 0 .. $#empty ) {
        if ( $empty[$i] < $row_count ) {
            push @$mark, $i;
            if ( length $aoa->[0][$i] ) {
                $header->[$i] = $aoa->[0][$i];
            }
            else {
                $header->[$i] = 'tmp_' . ( $i + 1 );
            }
        }
        else {
            $header->[$i] = '--';
        }
    }
    if ( @$mark == $col_count ) {
        $mark = undef; # no preselect if all cols have entries
    }
    return $header, $mark;
}


sub __choose_columns {
    my ( $sf, $sql ) = @_;
    my $tu = Term::Choose::Util->new( $sf->{i}{tcu_default} );
    my $aoa = $sql->{insert_into_args};
    my ( $header, $mark ) = $sf->__prepare_header_and_mark( $aoa );
    # Choose
    my $col_idx = $tu->choose_a_subset(
        $header,
        { current_selection_label => 'Cols: ', layout => 0, order => 0, mark => $mark, all_by_default => 1,
          index => 1, confirm => $sf->{i}{ok}, back => '<<' } # order
    );
    if ( ! defined $col_idx ) {
        return;
    }
    $sql->{insert_into_args} = [ map { [ @{$_}[@$col_idx] ] } @$aoa ];
    return 1;
}


sub __choose_rows {
    my ( $sf, $sql, $waiting ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $aoa = $sql->{insert_into_args};
    my %group; # group rows by the number of cols
    for my $row_idx ( 0 .. $#$aoa ) {
        my $col_count = scalar @{$aoa->[$row_idx]};
        push @{$group{$col_count}}, $row_idx;
    }
    # sort keys by group size
    my @keys_sorted = sort { scalar( @{$group{$b}} ) <=> scalar( @{$group{$a}} ) } keys %group;
    $sql->{insert_into_args} = []; # refers to a new empty array - this doesn't delete $aoa

    GROUP: while ( 1 ) {
        $ax->print_sql( $sql, $waiting );
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
            my $idx = $tc->choose(
                [ @pre, @choices_groups ],
                { %{$sf->{i}{lyt_v}}, prompt => 'Choose group:', index => 1, undef => '  <=' }
            );
            if ( ! $idx ) {
                $sql->{insert_into_args} = $aoa;
                return;
            }
            $ax->print_sql( $sql, $waiting );
            $row_idxs = $group{ $keys_sorted[$idx-@pre] };
            {
                no warnings 'uninitialized';
                @choices_rows = map { join ',', @$_ } @{$aoa}[@$row_idxs];
            }
        }

        while ( 1 ) {
            my @pre = ( undef, $sf->{i}{ok} );
            # Choose
            my @idx = $tc->choose(
                [ @pre, @choices_rows ],
                { %{$sf->{i}{lyt_v}}, prompt => 'Choose rows:', meta_items => [ 0 .. $#pre ], include_highlighted => 2,
                  index => 1, undef => '<<' }
            );
            $ax->print_sql( $sql );
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
                $ax->print_sql( $sql );
                if ( ! @{$sql->{insert_into_args}} ) {
                    $sql->{insert_into_args} = [ @{$aoa}[@$row_idxs] ];
                }
                return;
            }
            for my $i ( @idx ) {
                my $idx = $row_idxs->[$i-@pre];
                push @{$sql->{insert_into_args}}, $aoa->[$idx];
            }
            $ax->print_sql( $sql );
        }
    }
}


sub __range_of_rows {
    my ( $sf, $sql, $waiting ) = @_;
    my $aoa = $sql->{insert_into_args};
    my ( $first_row, $last_row ) = $sf->__choose_range( $sql, $waiting );
    if ( ! defined $first_row || ! defined $last_row ) {
        return;
    }
    $sql->{insert_into_args} = [ @{$aoa}[$first_row .. $last_row] ];
    return;
}


sub __choose_range {
    my ( $sf, $sql, $waiting ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $aoa = $sql->{insert_into_args};
    my @pre = ( undef );
    my $choices;
    {
        no warnings 'uninitialized';
        $choices = [ @pre, map { join ',', @$_ } @$aoa ];
    }
    # Choose
    my $first_idx = $tc->choose(
        $choices,
        { %{$sf->{i}{lyt_v}}, prompt => "Choose FIRST ROW:", index => 1, undef => '<<' }
    );
    if ( ! $first_idx ) {
        return;
    }
    my $first_row = $first_idx - @pre;
    $choices->[$first_row + @pre] = '* ' . $choices->[$first_row + @pre];
    $ax->print_sql( $sql );
    # Choose
    my $last_idx = $tc->choose(
        $choices,
        { %{$sf->{i}{lyt_v}}, prompt => "Choose LAST ROW:", index => 1, default => $first_row, undef => '<<' }
    );
    if ( ! $last_idx ) {
        return;
    }
    my $last_row = $last_idx - @pre;
    if ( $last_row < $first_row ) {
        $ax->print_sql( $sql );
        # Choose
        $tc->choose(
            [ "Last row ($last_row) is less than First row ($first_row)!" ],
            { prompt => 'Press ENTER' }
        );
        return;
    }
    return $first_row, $last_row;
}


sub __add_column {
    my ( $sf, $sql ) = @_;
    my $aoa = $sql->{insert_into_args};
    my $new_last_idx = $#{$aoa->[0]} + 1;
    for my $row ( @$aoa ) {
        $#$row = $new_last_idx;
    }
    $aoa->[0][$new_last_idx] = 'col' . ( $new_last_idx + 1 );
    push @{$sf->{i}{idx_added_cols}}, $new_last_idx;
    $sql->{insert_into_args} = $aoa;
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


sub __merge_rows {
    my ( $sf, $sql, $waiting ) = @_;
    my ( $first_row, $last_row ) = $sf->__choose_range( $sql, $waiting );
    if ( ! defined $first_row || ! defined $last_row ) {
        return;
    }
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    $ax->print_sql( $sql, $waiting );
    my $aoa = $sql->{insert_into_args};
    my $first = 0;
    my $last = 1;
    my @rows_to_merge = @{$aoa}[ $first_row .. $last_row ];
    my $merged = [];
    for my $col ( 0 .. $#{$rows_to_merge[0]} ) {
        my @tmp;
        for my $row ( 0 .. $#rows_to_merge ) {
            next if ! defined $rows_to_merge[$row][$col];
            next if $rows_to_merge[$row][$col] =~ /^\s*\z/;
            $rows_to_merge[$row][$col] =~ s/^\s+|\s+\z//g;
            push @tmp, $rows_to_merge[$row][$col];
        }
        $merged->[$col] = join ' ', @tmp;
    }
    my $col_number = 0;
    my $fields = [ map { [ ++$col_number, defined $_ ? "$_" : '' ] } @$merged ];
    my $tf = Term::Form->new( $sf->{i}{tf_default} );
    # Fill_form
    my $form = $tf->fill_form(
        $fields,
        { prompt => 'Edit result:', auto_up => 2, confirm => $sf->{i}{_confirm}, back => $sf->{i}{_back} . '   ' }
    );
    if ( ! $form ) {
        return;
    }
    $merged = [ map { $_->[1] } @$form ];
    splice @$aoa, $first_row, ( $last_row - $first_row + 1 ), $merged; # modifies $aoa
    $sql->{insert_into_args} = $aoa;
    return;
}


sub __split_table {
    my ( $sf, $sql, $waiting ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $tu = Term::Choose::Util->new( $sf->{i}{tcu_default} );
    my $aoa = $sql->{insert_into_args};
    # Choose
    my $col_count = $tu->choose_a_number(
        length( scalar @{$aoa->[0]} ),
        { current_selection_label => 'Number columns new table: ', small_first => 1 }
    );
    if ( ! defined $col_count ) {
        return;
    }
    if ( @{$aoa->[0]} < $col_count ) {
        $tc->choose(
            [ 'Chosen number bigger than the available columns!' ],
            { prompt => 'Close with ENTER' }
        );
        return;
    }
    if ( @{$aoa->[0]} % $col_count ) {
        $tc->choose(
            [ 'The number of available columns cannot be divided by the chosen number without rest!' ],
            { prompt => 'Close with ENTER' }
        );
        return;
    }
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    $ax->print_sql( $sql, $waiting );
    my $begin = 0;
    my $end   = $col_count - 1;
    my $tmp = [];

    while ( 1 ) {
        for my $row ( @$aoa ) {
            push @$tmp, [ @{$row}[ $begin .. $end ] ];
        }
        $begin = $end + 1;
        if ( $begin > $#{$aoa->[0]} ) {
            last;
        }
        $end = $end + $col_count;
    }
    $sql->{insert_into_args} = $tmp;
}


sub __split_column {
    my ( $sf, $sql, $waiting ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $aoa = $sql->{insert_into_args};
    my ( $header, $mark ) = $sf->__prepare_header_and_mark( $aoa );
    my @pre = ( undef );
    # Choose
    my $idx = $tc->choose(
        [ @pre, @{$header} ],
        { prompt => 'Choose Column:', index => 1 }
    );
    if ( ! $idx ) {
        return;
    }
    $idx -= @pre;
    my $tf = Term::Form->new( $sf->{i}{tf_default} );
    # Readline
    my $sep = $tf->readline( 'Separator: ' );
    if ( ! defined $sep ) {
        return;
    }
    # Readline
    my $left_trim = $tf->readline( 'Left trim: ', '\s+' );
    if ( ! defined $left_trim ) {
        return;
    }
    # Readline
    my $right_trim = $tf->readline( 'Right trim: ', '\s+' );
    if ( ! defined $right_trim ) {
        return;
    }
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    $ax->print_sql( $sql, $waiting );

    for my $row ( @$aoa ) { # modifies $aoa
        my $col = splice @$row, $idx, 1;
        my @split_col = split /$sep/, $col;
        for my $c ( @split_col ) {
            $c =~ s/^$left_trim//   if length $left_trim;
            $c =~ s/$right_trim\z// if length $right_trim;
        }
        splice @$row, $idx, 0, @split_col;
    }
    $sql->{insert_into_args} = $aoa;
}


sub __search_and_replace {
    my ( $sf, $sql, $waiting ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $tu = Term::Choose::Util->new( $sf->{i}{tcu_default} );

    SEARCH_AND_REPLACE: while ( 1 ) {
        my $mods = [ 'g', 'i', 'e', 'e' ];
        my $chosen_mods = [];
        my $info_fmt = "s/%s/%s/%s;\n";
        my @bu;

        MODIFIERS: while ( 1 ) {
            $ax->print_sql( $sql, $waiting );
            my $mods_str = join '', sort { $b cmp $a } @$chosen_mods;
            my $info = sprintf $info_fmt, '', '', $mods_str;
            my @pre = ( undef, $sf->{i}{ok} );
            # Choose
            my @idx = $tc->choose(
                [ @pre, map { "[$_]" } @$mods ],
                { %{$sf->{i}{lyt_h}}, prompt => 'Modifieres: ', info => $info, meta_items => [ 0 .. $#pre ],
                include_highlighted => 2, index => 1 }
            );
            my $last;
            if ( ! $idx[0] ) {
                if ( @bu ) {
                    ( $mods, $chosen_mods ) = @{pop @bu};
                    next MODIFIERS;
                }
                return;
            }
            elsif ( $idx[0] eq $#pre ) {
                $last = shift @idx;
            }
            push @bu, [ [ @$mods ], [ @$chosen_mods ] ];
            for my $i ( reverse @idx ) {
                $i -= @pre;
                push @$chosen_mods, splice @$mods, $i, 1;
            }
            if ( defined $last ) {
                last MODIFIERS;
            }
        }
        my $insensitive = ( grep( $_ eq 'i', @$chosen_mods ) )[0] || '';
        my $globally    = ( grep( $_ eq 'g', @$chosen_mods ) )[0] || '';
        my @e_s = grep { $_ eq 'e' } @$chosen_mods;
        my $mods_str = join '', $insensitive, $globally, @e_s;
        my $info = sprintf $info_fmt, '', '', $mods_str;
        $ax->print_sql( $sql, $waiting );
        my $tf = Term::Form->new( $sf->{i}{tf_default} );
        # Readline
        my $pattern = $tf->readline( 'Pattern: ',
            { info => $info }
        );
        if ( ! defined $pattern ) {
            next SEARCH_AND_REPLACE;
        }
        $info = sprintf $info_fmt, $pattern, '', $mods_str;
        $ax->print_sql( $sql, $waiting );
        my $c; # counter available in the replacement
        # Readline
        my $replacement = $tf->readline( 'Replacement: ',
            { info => $info }
        );
        if ( ! defined $replacement ) {
            next SEARCH_AND_REPLACE;
        }
        $info = sprintf $info_fmt, $pattern, $replacement, $mods_str;
        $ax->print_sql( $sql, $waiting );
        my $aoa = $sql->{insert_into_args};
        my ( $header, $mark ) = $sf->__prepare_header_and_mark( $aoa );
        # Choose
        my $col_idx = $tu->choose_a_subset(
            $header,
            { current_selection_label => 'Columns: ', info => $info, layout => 0, all_by_default => 1,
              index => 1, confirm => $sf->{i}{ok}, back => '<<' }
        );
        if ( ! defined $col_idx ) {
            next SEARCH_AND_REPLACE;
        }
        $ax->print_sql( $sql, $waiting );
        my $regex = $insensitive ? qr/(?${insensitive}:${pattern})/ : qr/${pattern}/;
        my $replacement_code = sub { return $replacement };
        for ( @e_s ) {
            my $recurse = $replacement_code;
            $replacement_code = sub { return eval $recurse->() }; # execute (e) substitution
        }

        for my $row ( @$aoa ) { # modifies $aoa
            for my $i ( @$col_idx ) {
                $c = 0;
                if ( ! defined $row->[$i] ) {
                    next;
                }
                elsif ( $globally ) {
                    $row->[$i] =~ s/$regex/$replacement_code->()/ge;
                }
                else {
                    $row->[$i] =~ s/$regex/$replacement_code->()/e;
                }
            }
        }
        $sql->{insert_into_args} = $aoa;
        return;
    }
}









1;


__END__
