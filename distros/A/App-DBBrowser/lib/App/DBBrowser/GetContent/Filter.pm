package # hide from PAUSE
App::DBBrowser::GetContent::Filter;

use warnings;
use strict;
use 5.010001;

use List::MoreUtils qw( any );

use Term::Choose           qw();
use Term::Choose::LineFold qw( line_fold print_columns );
use Term::Choose::Util     qw( insert_sep get_term_width get_term_height unicode_sprintf );
use Term::Choose::Screen   qw( clear_screen );
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
    my ( $sf, $sql ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $confirm       = '     OK';
    my $back          = '     <<';
    my $reset         = '    RESET';
    my $reparse       = '   REPARSE';
    my $merge_rows    = 'Merge_Rows';
    my $range_rows    = 'Range_Rows';
    my $row_groups    = 'Row_Groups';
    my $choose_rows   = 'Choose_Rows';
    my $remove_cell   = 'Remove_Cell';
    my $insert_cell   = 'Insert_Cell';
    my $split_table   = 'Split_Table';
    my $split_column  = 'Split_Column';
    my $join_columns  = 'Join_Columns';
    my $fill_up_rows  = 'Fill_up_Rows';
    my $empty_to_null = ' Empty_2_NULL';
    my $choose_cols   = 'Choose_Columns';
    my $append_col    = 'Append_Columns';
    my $cols_to_rows  = 'Columns_to_Rows';
    my $s_and_replace = 'Search_&_Replace';
    $sf->{empty_to_null} = $sf->{o}{insert}{'empty_to_null_' . $sf->{i}{gc}{source_type}};
    my $old_idx = 0;

    FILTER: while ( 1 ) {
        my $skip = ' ';
        my $regex = qr/^\Q$skip\E\z/;
        my $menu = [
            undef,          $choose_cols,   $skip,         $skip,
            $confirm,       $choose_rows,   $range_rows,   $row_groups,
            $reset,         $s_and_replace, $skip,         $skip,
            $reparse,       $remove_cell,   $insert_cell,  $skip,
            $empty_to_null, $join_columns,  $split_column, $append_col,
            $cols_to_rows,  $split_table,   $merge_rows,   $fill_up_rows,
        ];
        my $max_cols = 4;
        my $count_static_rows = 2; # prompt + trailing empty line
        my $info = $sf->__get_filter_info( $sql, $count_static_rows, undef, $menu, $max_cols );
        # Choose
        my $idx = $tc->choose(
            $menu,
            { info => $info, prompt => 'Filter:', layout => 0, order => 0, max_cols => $max_cols, index => 1,
              default => $old_idx, undef => $back, skip_items => $regex, busy_string => $sf->{i}{working},
              keep => $sf->{i}{keep} }
        );
        if ( ! $idx ) {
            $sql->{insert_into_args} = []; #
            return;
        }
        if ( $sf->{o}{G}{menu_memory} ) {
            if ( $old_idx == $idx && ! $ENV{TC_RESET_AUTO_UP} ) {
                $old_idx = 0;
                next FILTER;
            }
            $old_idx = $idx;
        }
        my $filter = $menu->[$idx];
        my $filter_str = sprintf( "Filter: %s", $filter );
        if ( $filter eq $reset ) {
            $sf->__print_filter_info( $sql, $count_static_rows, undef, $menu, $max_cols ); #
            $sql->{insert_into_args} = [ map { [ @$_ ] } @{$sf->{i}{gc}{bu_insert_into_args}} ];
            $sf->{empty_to_null} = $sf->{o}{insert}{'empty_to_null_' . $sf->{i}{gc}{source_type}};
            delete $sf->{i}{prev_chosen_cols};
            next FILTER
        }
        elsif ( $filter eq $confirm ) {
            if ( $sf->{empty_to_null} ) {
                $sf->__print_filter_info( $sql, $count_static_rows, undef, $menu, $max_cols );
                no warnings 'uninitialized';
                $sql->{insert_into_args} = [ map { [ map { length ? $_ : undef } @$_ ] } @{$sql->{insert_into_args}} ];
            }
            return 1;
        }
        elsif ( $filter eq $reparse ) {
            return -1;
        }
        elsif ( $filter eq $choose_cols  ) {
            $sf->__choose_columns( $sql, $filter_str );
        }
        elsif ( $filter eq $choose_rows ) {
            $sf->__choose_rows( $sql, $filter_str );
        }
        elsif ( $filter eq $range_rows ) {
            $sf->__range_of_rows( $sql, $filter_str );
        }
        elsif ( $filter eq $row_groups ) {
            $sf->__row_groups( $sql, $filter_str );
        }
        elsif ( $filter eq $remove_cell ) {
            $sf->__remove_cell( $sql, $filter_str );
        }
        elsif ( $filter eq $insert_cell ) {
            $sf->__insert_cell( $sql, $filter_str );
        }
        elsif ( $filter eq $append_col ) {
            $sf->__append_col( $sql, $filter_str );
        }
        elsif ( $filter eq $split_column ) {
            $sf->__split_column( $sql, $filter_str );
        }
        elsif ( $filter eq $s_and_replace ) {
            require App::DBBrowser::GetContent::Filter::SearchAndReplace;
            my $sr = App::DBBrowser::GetContent::Filter::SearchAndReplace->new( $sf->{i}, $sf->{o}, $sf->{d} );
            $sr->__search_and_replace( $sql, $filter_str );
        }
        elsif ( $filter eq $split_table ) {
            $sf->__split_table( $sql, $filter_str );
        }
        elsif ( $filter eq $merge_rows ) {
            $sf->__merge_rows( $sql, $filter_str );
        }
        elsif ( $filter eq $join_columns ) {
            $sf->__join_columns( $sql, $filter_str );
        }
        elsif ( $filter eq $fill_up_rows ) {
            $sf->__fill_up_rows( $sql, $filter_str );
        }
        elsif ( $filter eq $cols_to_rows ) {
            $sf->__transpose_rows_to_cols( $sql, $filter_str );
        }
        elsif ( $filter eq $empty_to_null ) {
            $sf->__empty_to_null( $sql );
        }
        $sf->{i}{occupied_term_height} = undef;
    }
}


sub __print_filter_info {
    my ( $sf, $sql, $count_static_rows, $pre, $choices, $max_cols ) = @_;
    my $info = $sf->__get_filter_info( $sql, $count_static_rows, $pre, $choices, $max_cols );
    print clear_screen();
    say $info;
    say "";
    print $sf->{i}{working} . "\r";
}


sub __get_filter_info {
    my ( $sf, $sql, $count_static_rows, $pre, $choices, $max_cols ) = @_;
    # $count_static_rows not realy static count - some could be line-folded if too long
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    print $sf->{i}{working} . "\r";
    $sf->{i}{occupied_term_height}  = 1; # "DATA:" prompt
    # ...                                # insert_into_args rows
    $sf->{i}{occupied_term_height} += 1; # empty row
    $sf->{i}{occupied_term_height} += $count_static_rows;
    my $row_count_menu = 0;
    if ( @{$choices//[]} ) {
        if ( ! $max_cols ) {
            my $term_w = get_term_width();
            my $longest = 0;
            my @tmp_cols = map{ ! length $_ ? '--' : $_ } @{$pre//[]}, @$choices;
            for my $col ( @tmp_cols ) {
                my $col_w = print_columns( $col );
                $longest = $col_w if $col_w > $longest;
            }
            my $r = print_columns( join( ' ' x 2, @tmp_cols ) ) / $term_w; ## pad 2
            if ( $r <= 1 ) {
                $row_count_menu = 1;
            }
            elsif ( $longest * 2 + 2 > $term_w ) { ## pad 2
                $row_count_menu = @tmp_cols;
            }
            else {
                my $joined_cols = $longest;
                my $cols_in_a_row = 1;
                while ( $joined_cols < $term_w ) {
                    $joined_cols += 2 + $longest;
                    ++$cols_in_a_row;
                }
                $row_count_menu = int( @tmp_cols / $cols_in_a_row );
                if ( @tmp_cols % $cols_in_a_row ) {
                    $row_count_menu++;
                }
            }
        }
        elsif ( $max_cols == 1 ) {
            $row_count_menu = @{$pre//[]} + @$choices;
        }
        else {
            my $count_items = @{$pre//[]} + @$choices;
            $row_count_menu = int( $count_items / $max_cols );
            if ( $count_items % $max_cols ) {
                $row_count_menu += 1;
            }
        }
    }
    $sf->{i}{occupied_term_height} += $row_count_menu;
#    if ( $sf->{i}{occupied_term_height} + 1 < get_term_height()  ) {
        $sf->{i}{keep} = 1; ##;
#    }
    my $indent = '';
    my $bu_stmt_types = [ @{$sf->{i}{stmt_types}} ];
    $sf->{i}{stmt_types} = [];
    my $rows = $ax->insert_into_args_info_format( $sql, $indent );
    $sf->{i}{stmt_types} = $bu_stmt_types;
    return join( "\n", 'DATA:', @$rows ) . "\n"; # "\n" == empty line after insert_args
}


sub __choose_columns {
    my ( $sf, $sql, $filter_str ) = @_;
    my $tu = Term::Choose::Util->new( $sf->{i}{tcu_default} );
    my $aoa = $sql->{insert_into_args};
    my $empty_cells_of_col_count = $sf->__count_empty_cells_of_cols( $aoa );
    my $header = $sf->__prepare_header( $aoa, $empty_cells_of_col_count );
    my $count_static_rows = 3; # filter_str + cs_label + trailing empty line
    $sf->__print_filter_info( $sql, $count_static_rows, [ '<<', $sf->{i}{ok} ], $header, undef );
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
    my $prev_chosen = $sf->{i}{prev_chosen_cols}{db}{ $sf->{d}{db} } // [];
    if ( @$prev_chosen && @$prev_chosen < @$header ) {
        my $mark2 = [];
        for my $i ( 0 .. $#{$header} ) {
            push @$mark2, $i if any { $_ eq $header->[$i] } @$prev_chosen;
        }
        $mark = $mark2 if @$mark2 == @$prev_chosen;
    }
    my $back = '<<';
    my $info = $sf->__get_filter_info( $sql, $count_static_rows, [ $back, $sf->{i}{ok} ], $header, undef ) . "\n" . $filter_str;
    # Choose
    my $col_idx = $tu->choose_a_subset(
        $header,
        { cs_label => 'Cols: ', layout => 0, order => 0, mark => $mark, all_by_default => 1, index => 1,
          confirm => $sf->{i}{ok}, back => $back, info => $info, keep => $sf->{i}{keep},
          busy_string => $sf->{i}{working} }
    );
    if ( ! defined $col_idx ) {
        return;
    }
    $sf->{i}{prev_chosen_cols}{db}{ $sf->{d}{db} } = [ @{$header}[@$col_idx] ];
    $sql->{insert_into_args} = [ map { [ @{$_}[@$col_idx] ] } @$aoa ];
    return 1;
}


sub __choose_rows {
    my ( $sf, $sql, $filter_str ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $aoa = $sql->{insert_into_args};
    my $count_static_rows = 3; # filter_str, prompt, trailing empty line
    my @pre = ( undef, $sf->{i}{ok} ); # back, confirm
    $sf->__print_filter_info( $sql, $count_static_rows, [ ( ' ' ) x @pre ], [ ( ' ' ) x @$aoa ], 1 ); ##
    my $stringified_rows = [];
    my $mark;
    {
        no warnings 'uninitialized';
        for my $i ( 0 .. $#$aoa ) {
            push @$mark, $i + @pre if length join '', @{$aoa->[$i]};
            push @$stringified_rows, join ',', @{$aoa->[$i]};
        }
    }
    if ( @$mark == @$stringified_rows ) {
        $mark = undef;
    }
    my $prompt = 'Choose rows:';
    $sql->{insert_into_args} = []; # $sql->{insert_into_args} refers to a new empty array - this doesn't delete $aoa

    while ( 1 ) {
        my $info = $sf->__get_filter_info( $sql, $count_static_rows, [ ( ' ' ) x @pre ], [ ( ' ' ) x @$aoa ], 1 ) . "\n" . $filter_str;
        # Choose
        my @idx = $tc->choose(
            [ @pre, @$stringified_rows ],
            { %{$sf->{i}{lyt_v}}, prompt => $prompt, info => $info, meta_items => [ 0 .. $#pre ],
              include_highlighted => 2, index => 1, undef => '<<', busy_string => $sf->{i}{working}, mark => $mark }
        );
        $sf->__print_filter_info( $sql, $count_static_rows, undef );
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
            if ( ! @{$sql->{insert_into_args}} ) {
                $sql->{insert_into_args} = $aoa;
            }
            return 1;
        }
        for my $i ( @idx ) {
            my $idx = $i - @pre;
            push @{$sql->{insert_into_args}}, $aoa->[$idx];
        }
    }
}

sub __range_of_rows {
    my ( $sf, $sql, $filter_str ) = @_;
    my $aoa = $sql->{insert_into_args};
    my $count_static_rows = 3; # filter_str, prompt, trailing empty line
    my $pre_count = 1; # back
    $sql->{insert_into_args} = []; # temporarily: because the rows are the choices
    my $info = $sf->__get_filter_info( $sql, $count_static_rows,  [ ( ' ' ) x $pre_count ], [ ( ' ' ) x @$aoa ], 1 ) . "\n" . $filter_str;
    my $prompt = "Choose first row:";
    # Choose
    my $idx_first_row = $sf->__choose_a_row_idx( $aoa, $info, $prompt );
    if ( ! defined $idx_first_row ) {
        $sql->{insert_into_args} = $aoa;
        return;
    }
    $sql->{insert_into_args} = [ $aoa->[$idx_first_row] ]; # temporarily for the info output
    $info = $sf->__get_filter_info( $sql, $count_static_rows,  [ ( ' ' ) x $pre_count ], [ ( ' ' ) x @$aoa ], 1 ) . "\n" . $filter_str;
    $prompt = "Choose last row:";
    # Choose
    my $idx_last_row = $sf->__choose_a_row_idx( [ @{$aoa}[$idx_first_row .. $#$aoa] ], $info, $prompt );
    if ( ! defined $idx_last_row ) {
        $sql->{insert_into_args} = $aoa;
        return;
    }
    $sf->__print_filter_info( $sql, $count_static_rows,  [ ( ' ' ) x $pre_count ], [ ( ' ' ) x @$aoa ], 1 ); #
    $idx_last_row += $idx_first_row;
    $sql->{insert_into_args} = [ @{$aoa}[$idx_first_row .. $idx_last_row] ];
    return 1;
}


sub __row_groups {
    my ( $sf, $sql, $filter_str ) = @_;
    my $tu = Term::Choose::Util->new( $sf->{i}{tcu_default} );
    my $aoa = $sql->{insert_into_args};
    my %group; # group rows by the number of cols
    for my $row_idx ( 0 .. $#$aoa ) {
        my $col_count = scalar @{$aoa->[$row_idx]};
        push @{$group{$col_count}}, $row_idx;
    }
    # sort keys by group size
    my @keys_sorted = sort { scalar( @{$group{$b}} ) <=> scalar( @{$group{$a}} ) } keys %group;
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
    my $count_static_rows = 6; # filter_str, prompt, 2 x cs_label, cs_end, trailing empty line
    my $pre_count = 2; # back and confirm
    my $info = $sf->__get_filter_info( $sql, $count_static_rows,  [ ( ' ' ) x $pre_count ], [ ( ' ' ) x @choices_groups ], 1 ) . "\n" . $filter_str;
    my $prompt = 'Choose group:';
    # Choose
    my $idxs = $tu->choose_a_subset(
        \@choices_groups,
        { info => $info, prompt => $prompt, layout => 3, index => 1, confirm => $sf->{i}{ok},
          back => '<<', all_by_default => 1, cs_label => "Chosen groups:\n", cs_separator => "\n",
          cs_end => "\n", busy_string => $sf->{i}{working}, keep => $sf->{i}{keep} }
    );
    $sf->__print_filter_info( $sql, $count_static_rows,  [ ( ' ' ) x $pre_count ], [ ( ' ' ) x @choices_groups ], 1 ); #
    if ( ! defined $idxs ) {
        return;
    }
    else {
        my $row_idxs = [];
        for my $idx ( @$idxs ) {
            push @$row_idxs, @{$group{ $keys_sorted[$idx] }};
        }
        $sql->{insert_into_args} = [ @{$aoa}[sort { $a <=> $b } @$row_idxs] ];
        return;
    }
}


sub __remove_cell {
    my ( $sf, $sql, $filter_str ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $aoa = $sql->{insert_into_args};

    while ( 1 ) {
        my $info = $filter_str;
        my $prompt = "Choose row:";
        # Choose
        my $row_idx = $sf->__choose_a_row_idx( $aoa, $info, $prompt );
        if ( ! defined $row_idx ) {
            return;
        }
        my $count_static_rows = 3; # filter_str and prompt, trailing empty line
        $info = $sf->__get_filter_info( $sql, $count_static_rows, [ '<<' ], $aoa->[$row_idx], undef ) . "\n" . $filter_str;
        $prompt = "Choose cell:";
        # Choose
        my $col_idx = $sf->__choose_a_column_idx( [ @{$aoa->[$row_idx]} ], $info, $prompt );
        if ( ! defined $col_idx ) {
            next;
        }
        splice( @{$aoa->[$row_idx]}, $col_idx, 1 );
        $sql->{insert_into_args} = $aoa;
        return;
    }
}

sub _stringify_row { # used only once
    my ( $row ) = @_;
    no warnings 'uninitialized';
    my $stringified_row = '"' . join( '", "', @$row ) . '"';
    return $stringified_row;
}


sub __insert_cell {
    my ( $sf, $sql, $filter_str ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $tf = Term::Form->new( $sf->{i}{tf_default} );
    my $aoa = $sql->{insert_into_args};

    while ( 1 ) {
        my $info = $filter_str;
        my $prompt = "Choose row:";
        # Choose
        my $row_idx = $sf->__choose_a_row_idx( $aoa, $info, $prompt );
        if ( ! defined $row_idx ) {
            return;
        }
        my $cols = [ @{$aoa->[$row_idx]}, 'END_of_Row' ];
        my $count_static_rows = 3; # prompt, filter_str, trailing empty line
        $info = $sf->__get_filter_info( $sql, $count_static_rows, [ '<<' ], $cols, undef ) . "\n" . $filter_str;
        $prompt = "Insert cell before:";
        # Choose
        my $col_idx = $sf->__choose_a_column_idx( $cols, $info, $prompt );
        if ( ! defined $col_idx ) {
            next;
        }
        my @row = @{$aoa->[$row_idx]};
        splice( @row, $col_idx, 0, '<*>' );
        my $str_row_with_placeholder = _stringify_row( \@row );
        $str_row_with_placeholder =~ s/"<\*>"/<*>/;
        my $term_w = get_term_width();
        my $label = 'Row: ';
        my @tmp_info = ( $filter_str );
        push @tmp_info, line_fold(
            $label . $str_row_with_placeholder, $term_w,
            { subseq_tab => ' ' x length $label, join => 0 }
        );
        $count_static_rows = @tmp_info + 2; # tmp_info, readline, trailing empty line
        $info = $sf->__get_filter_info( $sql, $count_static_rows, undef, undef, 1 ). "\n" . join( "\n", @tmp_info );
        $prompt = "<*>: ";
        # Readline
        my $cell = $tf->readline(
            $prompt,
            { info => $info }
        );
        splice( @{$aoa->[$row_idx]}, $col_idx, 0, $cell );
        $sql->{insert_into_args} = $aoa;
        return;
    }
}


sub __fill_up_rows {
    my ( $sf, $sql, $filter_str ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $aoa = $sql->{insert_into_args};
    my $count_static_rows = 3; # filter_str, prompt, trailing empty line
    my $menu = [ undef, '- YES' ]; # back, confirm
    my $info = $sf->__get_filter_info( $sql, $count_static_rows,  undef, [ ( ' ' ) x @$menu ], 1 ) . "\n" . $filter_str;
    my $prompt = 'Fill up shorter rows?';
    my $ok = $tc->choose(
        $menu,
        { info => $info, prompt => $prompt, index => 1, undef => '- NO', layout => 3, keep => $sf->{i}{keep} }
    );
    $sf->__print_filter_info( $sql, $count_static_rows, undef, [ ( ' ' ) x @$menu ], 1 ); #
    if ( ! $ok ) {
        return;
    }
    my $longest_row = 0;
    for my $row ( @$aoa ) {
        my $col_count = scalar @$row;
        if ( $col_count > $longest_row ) {
            $longest_row = $col_count;
        }
    }
    my $last_idx = $longest_row - 1;
    for my $row ( @$aoa ) {
        $#$row = $last_idx;
    }
    $sql->{insert_into_args} = $aoa;
    return;
}


sub __append_col {
    my ( $sf, $sql, $filter_str ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $aoa = $sql->{insert_into_args};
    my $count_static_rows = 3; # filter_str, prompt, trailing empty line
    my $menu = [ undef, '- YES' ]; # back, confirm
    my $info = $sf->__get_filter_info( $sql, $count_static_rows, undef, [ ( ' ' ) x @$menu ], 1 ) . "\n" . $filter_str;
    my $prompt = 'Append an empty column?';
    my $ok = $tc->choose(
        $menu,
        { info => $info, prompt => $prompt, index => 1, undef => '- NO', layout => 3, keep => $sf->{i}{keep} }
    );
    $sf->__print_filter_info( $sql, $count_static_rows,  undef, [ ( ' ' ) x @$menu ], 1 ); #
    if ( $ok ) {
        my $new_last_idx = $#{$aoa->[0]} + 1;
        for my $row ( @$aoa ) {
            $#$row = $new_last_idx;
        }
        $sql->{insert_into_args} = $aoa;
    }
    return;
}

sub __split_column {
    my ( $sf, $sql, $filter_str ) = @_;
    my $tu = Term::Choose::Util->new( $sf->{i}{tcu_default} );
    my $tf = Term::Form->new( $sf->{i}{tf_default} );
    my $aoa = $sql->{insert_into_args};
    my $empty_cells_of_col_count =  $sf->__count_empty_cells_of_cols( $aoa );
    my $header = $sf->__prepare_header( $aoa, $empty_cells_of_col_count );
    my $count_static_rows = 3; # filter_str, prompt, trailing empty line
    my $info = $sf->__get_filter_info( $sql, $count_static_rows, [ '<<' ], $header, undef ) . "\n" . $filter_str;
    my $prompt = 'Choose column:';
    # Choose
    my $idx = $sf->__choose_a_column_idx( $header, $info, $prompt );
    if ( ! defined $idx ) {
        return;
    }
    my $fields = [
        [ 'Pattern', ],
        [ 'Limit', ],
        [ 'Left trim', '\s+' ],
        [ 'Right trim', '\s+' ]
    ];
    $count_static_rows = 3; # filter_str, prompt, trailing empty line
    my $pre_count = 2; # back, confirm
    $info = $sf->__get_filter_info( $sql, $count_static_rows, [ ( ' ' ) x $pre_count ], [ ( ' ' ) x @$fields ], 1 ) . "\n" . $filter_str;
    $prompt = "Split column \"$header->[$idx]\"";
    my $c;
    # Fill_form
    my $form = $tf->fill_form(
        $fields,
        { info => $info, prompt => $prompt, auto_up => 2, confirm => $sf->{i}{confirm}, back => $sf->{i}{back} . '   ',
          keep => $sf->{i}{keep} }
    );
    if ( ! $form ) {
        return;
    }
    $sf->__print_filter_info( $sql, $count_static_rows, undef ); #
    my ( $pattern, $limit, $left_trim, $right_trim ) = map { $_->[1] } @$form;
    $pattern //= '';

    for my $row ( @$aoa ) { # modifies $aoa
        my $col = splice @$row, $idx, 1;
        my @split_col;
        if ( length $limit ) {
            @split_col = split /$pattern/, $col, $limit;
        }
        else {
            @split_col = split /$pattern/, $col;
        }
        for my $c ( @split_col ) {
            $c =~ s/^$left_trim//   if length $left_trim;
            $c =~ s/$right_trim\z// if length $right_trim;
        }
        splice @$row, $idx, 0, @split_col;
    }
    $sql->{insert_into_args} = $aoa;
}


sub __split_table {
    my ( $sf, $sql, $filter_str ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $tu = Term::Choose::Util->new( $sf->{i}{tcu_default} );
    my $aoa = $sql->{insert_into_args};
    my $digits = length( scalar @{$aoa->[0]} );
    my $count_static_rows = 3; # filter_str, prompt, trailing empty line
    my $pre_count = 2; # back confirm
    my $info = $sf->__get_filter_info( $sql, $count_static_rows, [ ( ' ' ) x $pre_count ], [ ( ' ' ) x $digits ], 1 ) . "\n" . $filter_str;
    # Choose
    my $col_count = $tu->choose_a_number(
        $digits,
        { info => $info, cs_label => 'Number columns new table: ', small_first => 1, keep => $sf->{i}{keep} }
    );
    if ( ! defined $col_count ) {
        return;
    }
    $sf->__print_filter_info( $sql, $count_static_rows, [ ( ' ' ) x $pre_count ], [ ( ' ' ) x $digits ], 1 );
    if ( @{$aoa->[0]} < $col_count ) {
        my $info = $sf->__get_filter_info( $sql, $count_static_rows, [ ( ' ' ) x $pre_count ], [ ( ' ' ) x $digits ], 1 ) . "\n" . $filter_str; ##
        $tc->choose(
            [ 'Chosen number bigger than the available columns!' ],
            { info => $info, prompt => 'Close with ENTER', keep => $sf->{i}{keep} }
        );
        return;
    }
    if ( @{$aoa->[0]} % $col_count ) {
        my $info = $sf->__get_filter_info( $sql, $count_static_rows, [ ( ' ' ) x $pre_count ], [ ( ' ' ) x $digits ], 1 ) . "\n" . $filter_str; ##
        $tc->choose(
            [ 'The number of available columns cannot be divided by the chosen number without rest!' ],
            { info => $info, prompt => 'Close with ENTER', keep => $sf->{i}{keep} }
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
    my ( $sf, $sql, $filter_str ) = @_;
    my $tu = Term::Choose::Util->new( $sf->{i}{tcu_default} );
    my $tf = Term::Form->new( $sf->{i}{tf_default} );
    my $aoa = $sql->{insert_into_args};

    my $info = $filter_str;
    print "\r$info"; ##
    my $term_w = get_term_width();
    my @stringified_rows;
    {
        no warnings 'uninitialized';
        @stringified_rows = map {
            my $str_row = join( ',', @$_ );
            if ( print_columns( $str_row ) > $term_w ) {
                unicode_sprintf( $str_row, $term_w, { mark_if_trundated => $sf->{i}{dots}[ $sf->{o}{G}{dots} ] } );
            }
            else {
                $str_row;
            }
        } @$aoa;
    }
    my $prompt = 'Choose rows:';
    # Choose
    my $chosen_idxs = $tu->choose_a_subset(
        \@stringified_rows,
        { cs_separator => "\n", cs_end => "\n", layout => 3, order => 0, all_by_default => 0, prompt => $prompt,
          index => 1, confirm => $sf->{i}{ok}, back => '<<', info => $info, keep => $sf->{i}{keep},
          busy_string => $sf->{i}{working} }
    );
    if ( ! defined $chosen_idxs || ! @$chosen_idxs ) {
        return;
    }
    my $count_static_rows = 3; # filter_str, prompt, trailing empty line
    my $pre_count = 2; # back, confirm
    $sf->__print_filter_info( $sql, $count_static_rows, [ ( ' ' ) x $pre_count ], [ ( ' ' ) x @{$aoa->[$chosen_idxs->[0]]} ], 1 );
    my $merged = [];
    for my $col ( 0 .. $#{$aoa->[$chosen_idxs->[0]]} ) {
        my @tmp;
        for my $row ( @$chosen_idxs ) {
            next if ! defined $aoa->[$row][$col];
            next if $aoa->[$row][$col] =~ /^\s*\z/;
            $aoa->[$row][$col] =~ s/^\s+|\s+\z//g;
            push @tmp, $aoa->[$row][$col];
        }
        $merged->[$col] = join ' ', @tmp;
    }
    my $col_number = 0;
    my $fields = [ map { [ ++$col_number, defined $_ ? "$_" : '' ] } @$merged ];
    $info = $sf->__get_filter_info( $sql, $count_static_rows, [ ( ' ' ) x $pre_count ], [ ( ' ' ) x @{$fields} ], 1 ) . "\n" . $filter_str;
    # Fill_form
    my $form = $tf->fill_form(
        $fields,
        { info => $info, prompt => 'Edit cells of merged rows:', keep => $sf->{i}{keep},
          auto_up => 2, confirm => $sf->{i}{_confirm}, back => $sf->{i}{_back} . '   ' }
    );
    if ( ! $form ) {
        return;
    }
    $sf->__print_filter_info( $sql, $count_static_rows, [ ( ' ' ) x $pre_count ], [ ( ' ' ) x @{$fields} ], 1 ); #
    $merged = [ map { $_->[1] } @$form ];
    my $first_idx = shift @$chosen_idxs;
    $aoa->[$first_idx] = $merged; # modifies $aoa
    for my $idx ( sort { $b <=> $a } @$chosen_idxs ) {
        splice @$aoa, $idx, 1;
    }
    $sql->{insert_into_args} = $aoa;
    return;
}


sub __join_columns {
    my ( $sf, $sql, $filter_str ) = @_;
    my $tu = Term::Choose::Util->new( $sf->{i}{tcu_default} );
    my $tf = Term::Form->new( $sf->{i}{tf_default} );
    my $aoa = $sql->{insert_into_args};
    my $empty_cells_of_col_count =  $sf->__count_empty_cells_of_cols( $aoa );
    my $header = $sf->__prepare_header( $aoa, $empty_cells_of_col_count );
    my $count_static_rows = 3; # filter_str, cs_label, trailing empty line
    my $info = $sf->__get_filter_info( $sql, $count_static_rows, [ '<<', $sf->{i}{ok} ], $header, undef ) . "\n" . $filter_str;
    # Choose
    my $chosen_idxs = $tu->choose_a_subset(
        $header,
        { cs_label => 'Cols: ', layout => 0, order => 0, index => 1, confirm => $sf->{i}{ok}, keep => $sf->{i}{keep},
          back => '<<', info => $info, busy_string => $sf->{i}{working} }
    );
    if ( ! defined $chosen_idxs || ! @$chosen_idxs ) {
        return;
    }
    my @tmp_info = ( $filter_str );
    my $label = 'Cols: ';
    push @tmp_info, line_fold(
        $label . '"' . join( '", "', @{$header}[@$chosen_idxs] ) . '"', get_term_width(),
        { subseq_tab => ' ' x length $label, join => 0 }
    );
    $count_static_rows = @tmp_info + 2; # tmp_info, readline, empty line
    $info = $sf->__get_filter_info( $sql, $count_static_rows, undef, undef, 1 ). "\n" . join( "\n", @tmp_info );
    # Readline
    my $join_char = $tf->readline(
        'Join-string: ',
        { info => $info }
    );
    if ( ! defined $join_char ) {
        return;
    }
    $count_static_rows = 3; # filter_str, prompt, trailing empty line
    my $pre_count = 2; # back, confirm
    $sf->__print_filter_info( $sql, $count_static_rows, [ ( ' ' ) x $pre_count ], [ ( ' ' ) x @{$aoa} ], 1 );
    my $merged = [];
    for my $row ( 0 .. $#{$aoa} ) {
        my @tmp;
        for my $col ( @$chosen_idxs ) {
            next if ! defined $aoa->[$row][$col];
            next if $aoa->[$row][$col] =~ /^\s*\z/;
            $aoa->[$row][$col] =~ s/^\s+|\s+\z//g;
            push @tmp, $aoa->[$row][$col];
        }
        $merged->[$row] = join $join_char, @tmp;
    }
    my $col_number = 0;
    my $fields = [ map { [ ++$col_number, defined $_ ? "$_" : '' ] } @$merged ];
    $info = $sf->__get_filter_info( $sql, $count_static_rows, [ ( ' ' ) x $pre_count ], [ ( ' ' ) x @{$fields} ], 1 ) . "\n" . $filter_str;
    # Fill_form
    my $form = $tf->fill_form(
        $fields,
        { info => $info, prompt => 'Edit cells of joined cols:', auto_up => 2, keep => $sf->{i}{keep},
          confirm => $sf->{i}{_confirm}, back => $sf->{i}{_back} . '   ' }
    );
    if ( ! $form ) {
        return;
    }
    $sf->__print_filter_info( $sql, $count_static_rows, [ ( ' ' ) x $pre_count ], [ ( ' ' ) x @{$fields} ], 1 ); #
    $merged = [ map { $_->[1] } @$form ];
    my $first_idx = shift @$chosen_idxs;
    for my $row ( 0 .. $#{$aoa} ) { # modifies $aoa
        $aoa->[$row][$first_idx] = $merged->[$row];
        for my $idx ( sort { $b <=> $a } @$chosen_idxs ) {
            splice @{$aoa->[$row]}, $idx, 1 if $idx < @{$aoa->[$row]};
        }
    }
    $sql->{insert_into_args} = $aoa;
    return;
}


sub __transpose_rows_to_cols {
    my ( $sf, $sql, $filter_str ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $aoa = $sql->{insert_into_args};
    my $menu = [ undef, '- YES' ];
    my $count_static_rows = 3; # filter_str, prompt, trailing empty line
    my $info = $sf->__get_filter_info( $sql, $count_static_rows, undef, [ ( ' ' ) x @$menu ], 1 ) . "\n" . $filter_str;
    my $prompt = 'Transpose columns to rows?';
    my $ok = $tc->choose(
        $menu,
        { info => $info, prompt => $prompt, index => 1, undef => '- NO', layout => 3, busy_string => $sf->{i}{working},
          keep => $sf->{i}{keep} }
    );
    $sf->__print_filter_info( $sql, $count_static_rows, undef, [ ( ' ' ) x @$menu ], 1 ); #
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
    my ( $sf, $sql ) = @_;
    my $tu = Term::Choose::Util->new( $sf->{i}{tcu_default} );
    my $menu_elements = [
        [ 'empty_to_null', "  Empty fields to NULL", [ 'NO', 'YES' ] ]
    ];
    my $count_static_rows = 2; # prompt, trailing empty line
    my $pre_count = 2; # back, confirm
    my $info = $sf->__get_filter_info( $sql, $count_static_rows, [ ( ' ' ) x $pre_count ], [ ( ' ' ) x @$menu_elements ], 1 );
    my $tmp = { empty_to_null => $sf->{empty_to_null} };
    $tu->settings_menu(
        $menu_elements,
        $tmp,
        { info => $info, back => $sf->{i}{_back}, confirm => $sf->{i}{_confirm}, keep => $sf->{i}{keep} }
    );
    $sf->{empty_to_null} = $tmp->{empty_to_null};
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

sub __choose_a_column_idx {
    my ( $sf, $columns, $info, $prompt ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my @pre = ( undef );
    # Choose
    my $col_idx = $tc->choose(
        [ @pre, map( defined $_ ? $_ : '', @$columns ) ],
        { layout => 0, order => 0, index => 1, undef => '<<', info => $info, prompt => $prompt, empty => '--',
          keep => $sf->{i}{keep}, busy_string => $sf->{i}{working} } #
    );
    if ( ! $col_idx ) {
        return;
    }
    return $col_idx - @pre;
}

sub __choose_a_row_idx {
    my ( $sf, $aoa, $info, $prompt ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my @stringified_rows;
    {
        no warnings 'uninitialized';
        @stringified_rows = map { join ',', @$_ } @$aoa;
    }
    my @pre = ( undef );
    # Choose
    my $row_idx = $tc->choose(
        [ @pre, @stringified_rows ],
        { layout => 3, index => 1, undef => '<<', info => $info, prompt => $prompt, ## keep => $sf->{i}{keep},
          busy_string => $sf->{i}{working} }
    );
    if ( ! $row_idx ) {
        return;
    }
    return $row_idx - @pre;
}



1;


__END__
