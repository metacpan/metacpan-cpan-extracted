package # hide from PAUSE
App::DBBrowser::GetContent::Filter;

use warnings;
use strict;
use 5.010001;

use Term::Choose           qw();
use Term::Choose::LineFold qw( line_fold );
use Term::Choose::Util     qw( insert_sep get_term_width );
use Term::Choose::Screen   qw( clear_to_end_of_line );
use Term::Form             qw();

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
    my $confirm       = '     OK';
    my $back          = '     <<';
    my $reset         = '    RESET';
    my $reparse       = '   REPARSE';
    my $choose_cols   = 'Choose_Cols';
    my $choose_rows   = 'Choose_Rows';
    my $range_rows    = 'Range_Rows';
    my $row_groups    = 'Row_Groups';
    my $remove_cell   = 'Remove_Cell';
    my $insert_cell   = 'Insert_Cell';
    my $append_col    = 'Append_Col';
    my $split_column  = 'Split_Column';
    my $s_and_replace = 'S_&_Replace';
    my $split_table   = 'Split_Table';
    my $merge_rows    = 'Merge_Rows';
    my $cols_to_rows  = 'Cols_to_Rows';
    my $empty_to_null = 'Empty_2_NULL';
    $sf->{empty_to_null} = $default_e2n;
    $sf->{i}{idx_added_cols} = [];
    my $old_idx = 0;

    FILTER: while ( 1 ) {
        $ax->print_sql( $sql );
        my $choices = [
            undef,    $choose_cols,   $choose_rows, $range_rows, $row_groups,
            $confirm, $remove_cell,   $insert_cell, $append_col, $split_column,
            $reset,   $s_and_replace, $split_table, $merge_rows, $cols_to_rows,
            $reparse, $empty_to_null,
        ];
        # Choose
        my $idx = $tc->choose(
            $choices,
            { prompt => 'Filter:', layout => 0, order => 0, max_width => 78, index => 1, default => $old_idx,
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
        elsif ( $filter eq $choose_cols  ) {
            $sf->__choose_columns( $sql, $filter, $waiting );
        }
        elsif ( $filter eq $choose_rows ) {
            $sf->__choose_rows( $sql, $filter, $waiting );
        }
        elsif ( $filter eq $range_rows ) {
            $sf->__range_of_rows( $sql, $filter, $waiting );
        }
        elsif ( $filter eq $row_groups ) {
            $sf->__row_groups( $sql, $filter, $waiting );
        }
        elsif ( $filter eq $remove_cell ) {
            $sf->__remove_cell( $sql, $filter, $waiting );
        }
        elsif ( $filter eq $insert_cell ) {
            $sf->__insert_cell( $sql, $filter, $waiting );
        }
        elsif ( $filter eq $append_col ) {
            $sf->__append_col( $sql, $filter, $waiting );
        }
        elsif ( $filter eq $split_column ) {
            $sf->__split_column( $sql, $filter, $waiting );
        }
        elsif ( $filter eq $s_and_replace ) {
            $sf->__search_and_replace( $sql, $filter, $waiting );
        }
        elsif ( $filter eq $split_table ) {
            $sf->__split_table( $sql, $filter, $waiting );
        }
        elsif ( $filter eq $merge_rows ) {
            $sf->__merge_rows( $sql, $filter, $waiting );
        }
        elsif ( $filter eq $cols_to_rows ) {
            $sf->__transpose_rows_to_cols( $sql, $filter, $waiting );
        }
        elsif ( $filter eq $empty_to_null ) {
            $sf->__empty_to_null();
        }
    }
}


sub __choose_columns {
    my ( $sf, $sql, $filter, $waiting ) = @_;
    my $tu = Term::Choose::Util->new( $sf->{i}{tcu_default} );
    $sf->__print_filters_info( $sql, $filter, $waiting );
    my $aoa = $sql->{insert_into_args};
    my $empty_cells_of_col_count =  $sf->__count_empty_cells_of_cols( $aoa );
    my $header = $sf->__prepare_header( $aoa, $empty_cells_of_col_count );
    my $mark = $sf->__prepare_mark( $aoa, $empty_cells_of_col_count );
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
    my ( $sf, $sql, $filter, $waiting ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    $sf->__print_filters_info( $sql, $filter, $waiting );
    my $aoa = $sql->{insert_into_args};
    $sql->{insert_into_args} = []; # $sql->{insert_into_args} refers to a new new empty array - this doesn't delete $aoa
    my @pre = ( undef, $sf->{i}{ok} );
    my @stringified_rows;
    {
        no warnings 'uninitialized';
        @stringified_rows = map { join ',', @$_ } @$aoa;
    }

    while ( 1 ) {
        # Choose
        my @idx = $tc->choose(
            [ @pre, @stringified_rows ],
            { %{$sf->{i}{lyt_v}}, prompt => 'Choose rows:', meta_items => [ 0 .. $#pre ], include_highlighted => 2,
                index => 1, undef => '<<' }
        );
        $sf->__print_filters_info( $sql, $filter, $waiting );
        if ( ! $idx[0] ) {
            $sql->{insert_into_args} = $aoa;
            return;
        }
        if ( $idx[0] == $#pre ) {
            shift @idx;
            for my $i ( @idx ) {
                my $idx = $i - @pre;
                push @{$sql->{insert_into_args}}, $aoa->[$idx];
            }
            $sf->__print_filters_info( $sql, $filter, $waiting );
            if ( ! @{$sql->{insert_into_args}} ) {
                $sql->{insert_into_args} = $aoa;
            }
            return;
        }
        for my $i ( @idx ) {
            my $idx = $i - @pre;
            push @{$sql->{insert_into_args}}, $aoa->[$idx];
        }
        $sf->__print_filters_info( $sql, $filter, $waiting );
    }
}

sub __range_of_rows {
    my ( $sf, $sql, $filter, $waiting ) = @_;
    $sf->__print_filters_info( $sql, $filter, $waiting );
    my $aoa = $sql->{insert_into_args};
    # Choose
    my ( $idx_first_row, $idx_last_row ) = $sf->__choose_range( $sql, $filter, $waiting );
    if ( ! defined $idx_first_row || ! defined $idx_last_row ) {
        return;
    }
    $sql->{insert_into_args} = [ @{$aoa}[$idx_first_row .. $idx_last_row] ];
    return;
}

sub __row_groups {
    my ( $sf, $sql, $filter, $waiting ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    $sf->__print_filters_info( $sql, $filter, $waiting );
    my $aoa = $sql->{insert_into_args};
    my %group; # group rows by the number of cols
    for my $row_idx ( 0 .. $#$aoa ) {
        my $col_count = scalar @{$aoa->[$row_idx]};
        push @{$group{$col_count}}, $row_idx;
    }
    # sort keys by group size
    my @keys_sorted = sort { scalar( @{$group{$b}} ) <=> scalar( @{$group{$a}} ) } keys %group;
    $sf->__print_filters_info( $sql, $filter, $waiting );
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
        return;
    }
    else {
        my $row_idxs = $group{ $keys_sorted[$idx-@pre] };
        $sql->{insert_into_args} = [ @{$aoa}[@$row_idxs] ];
        $sf->__print_filters_info( $sql, $filter, $waiting );
        return;
    }
}

sub __remove_cell {
    my ( $sf, $sql, $filter, $waiting ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $aoa = $sql->{insert_into_args};

    while ( 1 ) {
        $sf->__print_filters_info( $sql, $filter, $waiting );
        my $prompt = "Row:";
        # Choose
        my $row_idx = $sf->__choose_a_row_idx( $aoa, $prompt );
        if ( ! defined $row_idx ) {
            return;
        }
        $sf->__print_filters_info( $sql, $filter, $waiting );
        my $str_old_row = _stringify_row( $aoa->[$row_idx] );
        my $term_w = get_term_width();
        my $label = 'Row: ';
        $prompt = line_fold(
            $label . "$str_old_row\nCell:", $term_w,
            { subseq_tab => ' ' x length $label }
        );
        # Choose
        my $col_idx = $sf->__choose_a_column_idx( [ @{$aoa->[$row_idx]} ], $prompt );
        if ( ! defined $col_idx ) {
            next;
        }
        #splice( @{$aoa->[$row_idx]}, $col_idx, 1 );
        #$sql->{insert_into_args} = $aoa;
        #return;
        $sf->__print_filters_info( $sql, $filter, $waiting );
        my $init_tab = 4;
        $label = 'Old row: ';
        $prompt = line_fold(
            $label . $str_old_row, $term_w,
            { init_tab => ' ' x $init_tab, subseq_tab => ' ' x ( $init_tab + length $label ) }
        );
        my @row = @{$aoa->[$row_idx]};
        splice( @row, $col_idx, 1 );
        my $str_new_row = _stringify_row( \@row );
        $label = 'New row: ';
        $prompt .= "\n";
        $prompt .= line_fold(
            $label . $str_new_row, $term_w,
            { init_tab => ' ' x $init_tab, subseq_tab => ' ' x ( $init_tab + length $label ) }
        );
        $prompt .= "\nConfirm:";
        # Choose
        my $ok = $tc->choose(
            [ undef, '- YES' ],
            { prompt => $prompt, index => 1, undef => '- NO', layout => 3 }
        );
        if ( ! $ok ) {
            next;
        }
        $aoa->[$row_idx] = \@row;
        $sql->{insert_into_args} = $aoa;
        return;
    }
}

sub _stringify_row {
    my ( $row ) = @_;
    no warnings 'uninitialized';
    my $stringified_row = '"' . join( '", "', @$row ) . '"';
    return $stringified_row;
}

sub __insert_cell {
    my ( $sf, $sql, $filter, $waiting ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $tf = Term::Form->new( $sf->{i}{tf_default} );
    my $aoa = $sql->{insert_into_args};

    while ( 1 ) {
        $sf->__print_filters_info( $sql, $filter, $waiting );
        my $prompt = "Row:";
        # Choose
        my $row_idx = $sf->__choose_a_row_idx( $aoa, $prompt );
        if ( ! defined $row_idx ) {
            return;
        }
        $sf->__print_filters_info( $sql, $filter, $waiting );
        $prompt = "Insert Cell before:";
        # Choose
        my $col_idx = $sf->__choose_a_column_idx( [ @{$aoa->[$row_idx]}, 'END_of_Row' ], $prompt );
        if ( ! defined $col_idx ) {
            next;
        }
        $sf->__print_filters_info( $sql, $filter, $waiting );
        my @row = @{$aoa->[$row_idx]};
        splice( @row, $col_idx, 0, '<*>' );
        my $str_row_with_placeholder = _stringify_row( \@row );
        $str_row_with_placeholder =~ s/"<\*>"/<*>/;
        my $term_w = get_term_width();
        my $label = 'Row: ';
        my $info = line_fold(
            $label . $str_row_with_placeholder, $term_w,
            { subseq_tab => ' ' x length $label }
        );
        $prompt = "<*>: ";
        # Readline
        my $cell = $tf->readline( $prompt, { info => $info } );
        #splice( @{$aoa->[$row_idx]}, $col_idx, 0, $cell );
        #$sql->{insert_into_args} = $aoa;
        #return;
        $sf->__print_filters_info( $sql, $filter, $waiting );
        splice( @row, $col_idx, 1 );
        my $str_old_row = _stringify_row( \@row );
        my $init_tab = 4;
        $label = 'Old row: ';
        $prompt = line_fold(
            $label . $str_old_row, $term_w,
            { init_tab => ' ' x $init_tab, subseq_tab => ' ' x ( $init_tab + length $label ) }
        );
        splice( @row, $col_idx, 0, $cell );
        my $str_new_row = _stringify_row( \@row );
        $label = 'New row: ';
        $prompt .= "\n";
        $prompt .= line_fold(
            $label . $str_new_row, $term_w,
            { init_tab => ' ' x $init_tab, subseq_tab => ' ' x ( $init_tab + length $label ) }
        );
        $prompt .= "\nConfirm:";
        # Choose
        my $ok = $tc->choose(
            [ undef, '- YES' ],
            { prompt => $prompt, index => 1, undef => '- NO', layout => 3 }
        );
        if ( ! $ok ) {
            next;
        }
        $aoa->[$row_idx] = \@row;
        $sql->{insert_into_args} = $aoa;
        return;
    }
}

sub __append_col {
    my ( $sf, $sql, $filter, $waiting ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    $sf->__print_filters_info( $sql, $filter, $waiting );
    my $aoa = $sql->{insert_into_args};
    my $prompt = 'Append an empty Column?';
    my $ok = $tc->choose(
        [ undef, '- YES' ],
        { prompt => $prompt, index => 1, undef => '- NO', layout => 3 }
    );
    if ( $ok ) {
        my $new_last_idx = $#{$aoa->[0]} + 1;
        for my $row ( @$aoa ) {
            $#$row = $new_last_idx;
        }
        $aoa->[0][$new_last_idx] = 'col' . ( $new_last_idx + 1 );
        push @{$sf->{i}{idx_added_cols}}, $new_last_idx;
        $sql->{insert_into_args} = $aoa;
    }
    return;
}

sub __split_column {
    my ( $sf, $sql, $filter, $waiting ) = @_;
    my $aoa = $sql->{insert_into_args};
    $sf->__print_filters_info( $sql, $filter, $waiting );
    my $empty_cells_of_col_count =  $sf->__count_empty_cells_of_cols( $aoa );
    my $header = $sf->__prepare_header( $aoa, $empty_cells_of_col_count );
    # Choose
    my $idx = $sf->__choose_a_column_idx( $header, 'Choose a column:' );
    if ( ! defined $idx ) {
        return;
    }
    $sf->__print_filters_info( $sql, $filter, $waiting );
    my $tf = Term::Form->new( $sf->{i}{tf_default} );
    # Readline
    my $sep = $tf->readline( 'Separator: ' );
    if ( ! defined $sep ) {
        return;
    }
    $sf->__print_filters_info( $sql, $filter, $waiting );
    # Readline
    my $left_trim = $tf->readline( 'Left trim: ', '\s+' );
    if ( ! defined $left_trim ) {
        return;
    }
    $sf->__print_filters_info( $sql, $filter, $waiting );
    # Readline
    my $right_trim = $tf->readline( 'Right trim: ', '\s+' );
    if ( ! defined $right_trim ) {
        return;
    }
    $sf->__print_filters_info( $sql, $filter, $waiting );

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
    my ( $sf, $sql, $filter, $waiting ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $tu = Term::Choose::Util->new( $sf->{i}{tcu_default} );
    $sf->__print_filters_info( $sql, $filter, $waiting );

    SEARCH_AND_REPLACE: while ( 1 ) {
        my $mods = [ 'g', 'i', 'e', 'e' ];
        my $chosen_mods = [];
        my $info_fmt = "s/%s/%s/%s;\n";
        my @bu;

        MODIFIERS: while ( 1 ) {
            $sf->__print_filters_info( $sql, $filter, $waiting );
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
        $sf->__print_filters_info( $sql, $filter, $waiting );
        my $insensitive = ( grep( $_ eq 'i', @$chosen_mods ) )[0] || '';
        my $globally    = ( grep( $_ eq 'g', @$chosen_mods ) )[0] || '';
        my @e_s = grep { $_ eq 'e' } @$chosen_mods;
        my $mods_str = join '', $insensitive, $globally, @e_s;
        my $info = sprintf $info_fmt, '', '', $mods_str;
        my $tf = Term::Form->new( $sf->{i}{tf_default} );
        # Readline
        my $pattern = $tf->readline( 'Pattern: ',
            { info => $info }
        );
        if ( ! defined $pattern ) {
            next SEARCH_AND_REPLACE;
        }
        $sf->__print_filters_info( $sql, $filter, $waiting );
        $info = sprintf $info_fmt, $pattern, '', $mods_str;
        my $c; # counter available in the replacement
        # Readline
        my $replacement = $tf->readline( 'Replacement: ',
            { info => $info }
        );
        if ( ! defined $replacement ) {
            next SEARCH_AND_REPLACE;
        }
        $sf->__print_filters_info( $sql, $filter, $waiting );
        $info = sprintf $info_fmt, $pattern, $replacement, $mods_str;
        my $aoa = $sql->{insert_into_args};
        my $empty_cells_of_col_count =  $sf->__count_empty_cells_of_cols( $aoa ); ##
        my $header = $sf->__prepare_header( $aoa, $empty_cells_of_col_count );
        # Choose
        my $col_idx = $tu->choose_a_subset(
            $header,
            { current_selection_label => 'Columns: ', info => $info, layout => 0, all_by_default => 1,
              index => 1, confirm => $sf->{i}{ok}, back => '<<' }
        );
        if ( ! defined $col_idx ) {
            next SEARCH_AND_REPLACE;
        }
        $sf->__print_filters_info( $sql, $filter, $waiting );
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

sub __split_table {
    my ( $sf, $sql, $filter, $waiting ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $tu = Term::Choose::Util->new( $sf->{i}{tcu_default} );
    $sf->__print_filters_info( $sql, $filter, $waiting );
    my $aoa = $sql->{insert_into_args};
    # Choose
    my $col_count = $tu->choose_a_number(
        length( scalar @{$aoa->[0]} ),
        { current_selection_label => 'Number columns new table: ', small_first => 1 }
    );
    if ( ! defined $col_count ) {
        return;
    }
    $sf->__print_filters_info( $sql, $filter, $waiting );
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

sub __merge_rows {
    my ( $sf, $sql, $filter, $waiting ) = @_;
    $sf->__print_filters_info( $sql, $filter, $waiting );
    # Choose
    my ( $idx_first_row, $idx_last_row ) = $sf->__choose_range( $sql, $waiting );
    if ( ! defined $idx_first_row || ! defined $idx_last_row ) {
        return;
    }
    $sf->__print_filters_info( $sql, $filter, $waiting );
    my $aoa = $sql->{insert_into_args};
    my $first = 0;
    my $last = 1;
    my @rows_to_merge = @{$aoa}[ $idx_first_row .. $idx_last_row ];
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
    splice @$aoa, $idx_first_row, ( $idx_last_row - $idx_first_row + 1 ), $merged; # modifies $aoa
    $sql->{insert_into_args} = $aoa;
    return;
}

sub __transpose_rows_to_cols {
    my ( $sf, $sql, $filter, $waiting ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    $sf->__print_filters_info( $sql, $filter, $waiting );
    my $aoa = $sql->{insert_into_args};
    my $prompt = 'Transpose columns to rows?';
    my $ok = $tc->choose(
        [ undef, '- YES' ],
        { prompt => $prompt, index => 1, undef => '- NO', layout => 3 }
    );
    if ( $ok ) {
        my $tmp_aoa = [];
        for my $row ( 0 .. $#$aoa ) {
            for my $col ( 0 .. $#{$aoa->[$row]} ) {
                $tmp_aoa->[$col][$row] = $aoa->[$row][$col];
            }
        }
        $sql->{insert_into_args} = $tmp_aoa;
    }
    return;
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



sub __print_filters_info {
    my ( $sf, $sql, $filter, $waiting ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    $ax->print_sql( $sql, $waiting );
    print "\r" . clear_to_end_of_line();
    print "Filter \"$filter\"\n";
}

sub __count_empty_cells_of_cols {
    my ( $sf, $aoa ) = @_;
    my $row_count = @$aoa;
    my $col_count = @{$aoa->[0]};
    my $empty_cells_of_col_count = [ ( 0 ) x $col_count ];
    COL: for my $col_idx ( 0 .. $col_count - 1 ) {
        for my $row_idx ( 0 .. $row_count - 1 ) {
            if ( length $aoa->[$row_idx][$col_idx] ) {
                next COL;
            }
            ++$empty_cells_of_col_count->[$col_idx];
        }
    }
    return $empty_cells_of_col_count;
}

sub __prepare_header {
    my ( $sf, $aoa, $empty_cells_of_col_count ) = @_;
    my $row_count = @$aoa;
    my $col_count = @{$aoa->[0]};
    my $header = [];
    for my $col_idx ( 0 .. $col_count - 1 ) {
        if ( $empty_cells_of_col_count->[$col_idx] == $row_count ) {
            $header->[$col_idx] = '--';
        }
        else {
            if ( length $aoa->[0][$col_idx] ) {
                $header->[$col_idx] = $aoa->[0][$col_idx];
            }
            else {
                $header->[$col_idx] = 'tmp_' . ( $col_idx + 1 );
            }
        }
    }
    return $header;
}

sub __prepare_mark {
    my ( $sf, $aoa, $empty_cells_of_col_count ) = @_;
    my $row_count = @$aoa;
    my $col_count = @{$aoa->[0]};
    my $mark = [];
    for my $col_idx ( 0 .. $col_count - 1 ) {
        if ( $empty_cells_of_col_count->[$col_idx] < $row_count ) {
            push @$mark, $col_idx;
        }
    }
    if ( @$mark == $col_count ) {
        $mark = undef; # no preselect if all cols have entries
    }
    return $mark;
}

sub __choose_a_column_idx {
    my ( $sf, $columns, $prompt ) = @_;
    my $tu = Term::Choose->new( $sf->{i}{tc_default} );
    my @pre = ( undef );
    # Choose
    my $col_idx = $tu->choose(
        [ @pre, map { defined $_ ? $_ : '' } @$columns ],
        { layout => 0, order => 0, index => 1, undef => '<<', prompt => $prompt, empty => '--' } #
    );
    if ( ! $col_idx ) {
        return;
    }
    return $col_idx - @pre;
}

sub __choose_a_row_idx {
    my ( $sf, $aoa, $prompt ) = @_;
    my $tu = Term::Choose->new( $sf->{i}{tc_default} );
    my @stringified_rows;
    {
        no warnings 'uninitialized';
        @stringified_rows = map { join ',', @$_ } @$aoa;
    }
    my @pre = ( undef );
    # Choose
    my $row_idx = $tu->choose(
        [ @pre, @stringified_rows ],
        { layout => 3, index => 1, undef => '<<', prompt => $prompt }
    );
    if ( ! $row_idx ) {
        return;
    }
    return $row_idx - @pre;
}

sub __choose_range {
    my ( $sf, $sql, $filter, $waiting ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $aoa = $sql->{insert_into_args};
    # Choose
    my $idx_first_row = $sf->__choose_a_row_idx( $aoa, "Choose FIRST ROW:" );
    if ( ! defined $idx_first_row ) {
        return;
    }
    $sf->__print_filters_info( $sql, $filter, $waiting );
    # Choose
    my $idx_last_row = $sf->__choose_a_row_idx( [ @{$aoa}[$idx_first_row .. $#$aoa] ], "Choose LAST ROW:" );
    if ( ! defined $idx_last_row ) {
        return;
    }
    return $idx_first_row, $idx_last_row + $idx_first_row;
    #my $marker = '> ';
    #$aoa->[$idx_first_row][0] = $marker . $aoa->[$idx_first_row][0];
    #my $idx_last_row = $sf->__choose_a_row_idx( $aoa, "Choose LAST ROW:" );
    #$aoa->[$idx_first_row][0] =~ s/^\Q$marker\E//;
    #if ( ! defined $idx_last_row ) {
    #    return;
    #}
    #if ( $idx_last_row < $idx_first_row ) {
    #    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    #    $sf->__print_filters_info( $sql, $filter, $waiting );
    #    # Choose
    #    $tc->choose(
    #        [ "Last row ($idx_last_row) is less than First row ($idx_first_row)!" ],
    #        { prompt => 'Press ENTER' }
    #    );
    #    return;
    #}
    #return $idx_first_row, $idx_last_row;
}












1;


__END__
