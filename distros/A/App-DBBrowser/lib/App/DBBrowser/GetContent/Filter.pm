package # hide from PAUSE
App::DBBrowser::GetContent::Filter;

use warnings;
use strict;
use 5.014;

use List::MoreUtils qw( any );

use Term::Choose           qw();
use Term::Choose::LineFold qw( line_fold print_columns );
use Term::Choose::Util     qw( insert_sep get_term_width get_term_height unicode_sprintf );
use Term::Choose::Screen   qw( clear_screen );
use Term::Form             qw();
use Term::Form::ReadLine   qw();

use App::DBBrowser::Auxil;


sub new {
    my ( $class, $info, $options, $d ) = @_;
    my $sf = {
        i => $info,
        o => $options,
        d => $d
    };
    $sf->{s_back} = '<<';
    bless $sf, $class;
}


sub input_filter {
    my ( $sf, $sql, $source ) = @_;
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
    my $field_count = @{$sql->{insert_into_args}} * @{$sql->{insert_into_args}[0]};
    my $bu_insert_into_args = [ map { [ @$_ ] } @{$sql->{insert_into_args}} ]; # copy the entire data
    $sf->{empty_to_null} = $sf->{o}{insert}{empty_to_null_file};
    $sf->{working} = $field_count > 1_000_000 ? 'Working ... ' : undef;
    my $old_idx = 0;

    FILTER: while ( 1 ) {
        my $skip = ' ';
        my $regex = qr/^\Q$skip\E\z/;
        my $menu = [
            undef,          $choose_rows,   $range_rows,   $row_groups,
            $confirm,       $choose_cols,   $skip,         $skip,
            $reset,         $s_and_replace, $skip,         $skip,
            $reparse,       $remove_cell,   $insert_cell,  $skip,
            $empty_to_null, $join_columns,  $split_column, $append_col,
            $cols_to_rows,  $split_table,   $merge_rows,   $fill_up_rows,
        ];
        my $max_cols = 4;
        my $info = $sf->__get_filter_info( $sql );
        # Choose
        my $idx = $tc->choose(
            $menu,
            { info => $info, prompt => 'Filter:', layout => 0, order => 0, max_cols => $max_cols, index => 1,
              default => $old_idx, undef => $back, skip_items => $regex, busy_string => $sf->{working} }
        );
        $sf->__print_busy_string();
        if ( ! $idx ) {
            $sql->{insert_into_args} = [];
            delete $sf->{d}{fi};
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
            $sql->{insert_into_args} = [ map { [ @$_ ] } @{$bu_insert_into_args} ];
            $sf->{empty_to_null} = $sf->{o}{insert}{empty_to_null_file};
            next FILTER
        }
        elsif ( $filter eq $confirm ) {
            if ( $sf->{empty_to_null} ) {
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
            $sr->search_and_replace( $sql, $bu_insert_into_args, $filter_str, $sf->{s_back} );
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
    }
}


sub __print_busy_string {
    my ( $sf ) = @_;
    if ( $sf->{working} ) {
        print clear_screen();
        print $sf->{working} . "\r";
    }
}


sub __get_filter_info {
    my ( $sf, $sql, $filter_str ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $indent = '';
    my $bu_stmt_types = [ @{$sf->{d}{stmt_types}} ];
    $sf->{d}{stmt_types} = [];
    my $rows = $ax->info_format_insert_args( $sql, $indent );
    $sf->{d}{stmt_types} = $bu_stmt_types;
    my $info = join( "\n", 'DATA:', @$rows, '' ); # '' == empty line after insert_args
    if ( defined $filter_str ) {
        $info .= "\n" . $filter_str;
    }
    return $info;
}


sub __choose_columns {
    my ( $sf, $sql, $filter_str ) = @_;
    my $tu = Term::Choose::Util->new( $sf->{i}{tcu_default} );
    my $aoa = $sql->{insert_into_args};
    my $is_empty = $sf->__search_empty_cols( $aoa );
    my $header = $sf->__prepare_header( $aoa, $is_empty );
    my $row_count = @$aoa;
    my $col_count = @{$aoa->[0]};
    my $non_empty_cols = [];
    for my $col_idx ( 0 .. $col_count - 1 ) {
        if ( ! $is_empty->[$col_idx] ) {
            push @$non_empty_cols, $col_idx;
        }
    }
    if ( @$non_empty_cols == $col_count ) {
        $non_empty_cols = undef; # no preselect if all cols have entries
    }
    my $info = $sf->__get_filter_info( $sql, $filter_str );
    # Choose
    my $col_idx = $tu->choose_a_subset(
        $header,
        { cs_label => 'Cols: ', layout => 0, order => 0, mark => $non_empty_cols, all_by_default => 1, index => 1,
          confirm => $sf->{i}{ok}, back => $sf->{s_back}, info => $info, busy_string => $sf->{working} }
    );
    $sf->__print_busy_string();
    if ( ! defined $col_idx ) {
        return;
    }
    $sql->{insert_into_args} = [ map { [ @{$_}[@$col_idx] ] } @$aoa ];
    return 1;
}


sub __choose_rows {
    my ( $sf, $sql, $filter_str ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $aoa = $sql->{insert_into_args};
    my @pre = ( undef, $sf->{i}{ok} );
    my $stringified_rows = [];
    my $non_empty_rows = [];
    {
        no warnings 'uninitialized';
        for my $i ( 0 .. $#$aoa ) {
            push @$non_empty_rows, $i + @pre if length join '', @{$aoa->[$i]};
            push @$stringified_rows, join ',', @{$aoa->[$i]};
        }
    }
    if ( @$non_empty_rows == @$stringified_rows ) {
        $non_empty_rows = undef;
    }
    my $prompt = 'Choose rows:';
    $sql->{insert_into_args} = []; # $sql->{insert_into_args} refers to a new empty array - this doesn't delete $aoa

    while ( 1 ) {
        my $info = $sf->__get_filter_info( $sql, $filter_str );
        # Choose
        my @idx = $tc->choose(
            [ @pre, @$stringified_rows ],
            { %{$sf->{i}{lyt_v}}, prompt => $prompt, info => $info, meta_items => [ 0 .. $#pre ],
              include_highlighted => 2, index => 1, undef => $sf->{s_back}, busy_string => $sf->{working},
              mark => $non_empty_rows }
        );
        $sf->__print_busy_string();
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
    $sql->{insert_into_args} = []; # temporarily for the info output
    my $prompt = "Choose first row:";
    my $info = $sf->__get_filter_info( $sql, $filter_str );
    # Stop
    my $idx_first_row = $sf->__choose_a_row_idx( $aoa, $info, $prompt, $sf->{s_back} );
    if ( ! defined $idx_first_row ) {
        $sql->{insert_into_args} = $aoa;
        return;
    }
    $sql->{insert_into_args} = [ $aoa->[$idx_first_row] ]; # temporarily for the info output
    $prompt = "Choose last row:";
    $info = $sf->__get_filter_info( $sql, $filter_str );
    # Stop
    my $idx_last_row = $sf->__choose_a_row_idx( [ @{$aoa}[$idx_first_row .. $#$aoa] ], $info, $prompt, $sf->{s_back} );
    if ( ! defined $idx_last_row ) {
        $sql->{insert_into_args} = $aoa;
        return;
    }
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
    my $len = length insert_sep( scalar @{$group{$keys_sorted[0]}}, $sf->{i}{info_thsd_sep} );
    for my $col_count ( @keys_sorted ) {
        my $row_count = scalar @{$group{$col_count}};
        my $row_str = $row_count == 1 ? 'row  has ' : 'rows have';
        my $col_str = $col_count == 1 ? 'column ' : 'columns';
        push @choices_groups, sprintf '  %*s %s %2d %s',
            $len, insert_sep( $row_count, $sf->{i}{info_thsd_sep} ), $row_str,
            $col_count, $col_str;
    }
    my $prompt = 'Choose group:';
    my $info = $sf->__get_filter_info( $sql, $filter_str );
    # Choose
    my $idxs = $tu->choose_a_subset(
        \@choices_groups,
        { info => $info, prompt => $prompt, layout => 2, index => 1, confirm => $sf->{i}{ok}, back => $sf->{s_back},
          all_by_default => 1, cs_label => "Chosen groups:\n", cs_separator => "\n", cs_end => "\n",
          busy_string => $sf->{working} }
    );
    $sf->__print_busy_string();
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
        my $prompt = "Choose row:";
        my $info = $filter_str;
        # Stop
        my $row_idx = $sf->__choose_a_row_idx( $aoa, $info, $prompt, $sf->{s_back} );
        if ( ! defined $row_idx ) {
            return;
        }
        $prompt = "Choose cell:";
        $info = $sf->__get_filter_info( $sql, $filter_str );
        # Stop
        my $col_idx = $sf->__choose_a_column_idx( [ @{$aoa->[$row_idx]} ], $info, $prompt, $sf->{s_back} );
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
    my $tr = Term::Form::ReadLine->new( $sf->{i}{tr_default} );
    my $aoa = $sql->{insert_into_args};

    while ( 1 ) {
        my $prompt = "Choose row:";
        my $info = $filter_str;
        # Stop
        my $row_idx = $sf->__choose_a_row_idx( $aoa, $info, $prompt, $sf->{s_back} );
        if ( ! defined $row_idx ) {
            return;
        }
        my $cols = [ @{$aoa->[$row_idx]}, 'END_of_Row' ];
        $prompt = "Insert cell before:";
        $info = $sf->__get_filter_info( $sql, $filter_str );
        # Stop
        my $col_idx = $sf->__choose_a_column_idx( $cols, $info, $prompt, $sf->{s_back} );
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
        $prompt = "<*>: ";
        $info = $sf->__get_filter_info( $sql, join( "\n", @tmp_info ) );
        # Readline
        my $cell = $tr->readline(
            $prompt,
            { info => $info }
        );
        $sf->__print_busy_string();
        splice( @{$aoa->[$row_idx]}, $col_idx, 0, $cell );
        $sql->{insert_into_args} = $aoa;
        return;
    }
}


sub __fill_up_rows {
    my ( $sf, $sql, $filter_str ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $aoa = $sql->{insert_into_args};
    my $menu = [ undef, '- YES' ];
    my $prompt = 'Fill up shorter rows?';
    my $info = $sf->__get_filter_info( $sql, $filter_str );
    # Choose
    my $ok = $tc->choose(
        $menu,
        { info => $info, prompt => $prompt, index => 1, undef => '- NO', layout => 2 }
    );
    $sf->__print_busy_string();
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
    my $menu = [ undef, '- YES' ];
    my $prompt = 'Append an empty column?';
    my $info = $sf->__get_filter_info( $sql, $filter_str );
    # Choose
    my $ok = $tc->choose(
        $menu,
        { info => $info, prompt => $prompt, index => 1, undef => '- NO', layout => 2 }
    );
    $sf->__print_busy_string();
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
    my $is_empty =  $sf->__search_empty_cols( $aoa );
    my $header = $sf->__prepare_header( $aoa, $is_empty );
    my $prompt = 'Choose column:';
    my $info = $sf->__get_filter_info( $sql, $filter_str );
    # Stop
    my $idx = $sf->__choose_a_column_idx( $header, $info, $prompt, $sf->{s_back} );
    if ( ! defined $idx ) {
        return;
    }
    my $fields = [
        [ 'Pattern', ],
        [ 'Limit', ],
        [ 'Left trim', '\s+' ],
        [ 'Right trim', '\s+' ]
    ];
    my $back = $sf->{i}{back} . ' ' x 3;
    $prompt = "Split column \"$header->[$idx]\"";
    $info = $sf->__get_filter_info( $sql, $filter_str );
    my $c;
    # Fill_form
    my $form = $tf->fill_form(
        $fields,
        { info => $info, prompt => $prompt, auto_up => 2, confirm => $sf->{i}{confirm}, back => $back }
    );
    $sf->__print_busy_string();
    if ( ! $form ) {
        return;
    }
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
    my $col_count;

    CHOOSE_A_NUMBER: while( 1 ) {
        my $info = $sf->__get_filter_info( $sql, $filter_str );
        # Choose
        $col_count = $tu->choose_a_number(
            $digits,
            { info => $info, cs_label => 'Number columns new table: ', small_first => 1 }
        );
        $sf->__print_busy_string();
        if ( ! $col_count ) {
            return;
        }
        if ( @{$aoa->[0]} < $col_count ) {
            my $prompt = sprintf 'Chosen number(%d) bigger than the available columns(%d)!', $col_count, scalar( @{$aoa->[0]} );
            my $info = $sf->__get_filter_info( $sql, $filter_str );
            $tc->choose(
                [ 'Continue with ENTER' ],
                { info => $info, prompt => $prompt }
            );
            $sf->__print_busy_string();
            next CHOOSE_A_NUMBER;
        }
        if ( @{$aoa->[0]} % $col_count ) {
            my $prompt = sprintf 'The number of available columns(%d) cannot be divided by the selected number(%d) without remainder!', scalar( @{$aoa->[0]} ), $col_count;
            my $info = $sf->__get_filter_info( $sql, $filter_str );
            $tc->choose(
                [ 'Continue with ENTER' ],
                { info => $info, prompt => $prompt }
            );
            $sf->__print_busy_string();
            next CHOOSE_A_NUMBER;
        }
        last CHOOSE_A_NUMBER;
    }
    my $begin = 0;
    my $end = $col_count - 1;
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
    my $term_w = get_term_width();
    my $stringified_rows;
    {
        my $dots = $sf->{i}{dots};
        my $dots_w = print_columns( $dots );
        no warnings 'uninitialized';
        @$stringified_rows = map {
            my $str_row = join( ',', @$_ );
            if ( print_columns( $str_row ) > $term_w ) {
                unicode_sprintf( $str_row, $term_w, { mark_if_trundated => [ $dots, $dots_w ] } );
            }
            else {
                $str_row;
            }
        } @$aoa;
    }
    my $prompt = 'Choose rows:';
    my $info = $filter_str;
    # Choose
    my $chosen_idxs = $tu->choose_a_subset(
        $stringified_rows,
        { cs_separator => "\n", cs_end => "\n", layout => 2, order => 0, all_by_default => 0, prompt => $prompt,
          index => 1, confirm => $sf->{i}{ok}, back => $sf->{s_back}, info => $info, busy_string => $sf->{working} }
    );
    $sf->__print_busy_string();
    if ( ! defined $chosen_idxs || ! @$chosen_idxs ) {
        return;
    }
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
    $info = $sf->__get_filter_info( $sql, $filter_str );
    # Fill_form
    my $form = $tf->fill_form(
        $fields,
        { info => $info, prompt => 'Edit cells of merged rows:', auto_up => 2, confirm => $sf->{i}{_confirm},
          back => $sf->{i}{_back} . '   ' }
    );
    $sf->__print_busy_string();
    if ( ! $form ) {
        return;
    }
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
    my $tr = Term::Form::ReadLine->new( $sf->{i}{tr_default} );
    my $aoa = $sql->{insert_into_args};
    my $is_empty = $sf->__search_empty_cols( $aoa );
    my $header = $sf->__prepare_header( $aoa, $is_empty );
    my $info = $sf->__get_filter_info( $sql, $filter_str );
    # Choose
    my $chosen_idxs = $tu->choose_a_subset(
        $header,
        { cs_label => 'Cols: ', layout => 0, order => 0, index => 1, confirm => $sf->{i}{ok}, back => $sf->{s_back},
          info => $info, busy_string => $sf->{working} }
    );
    $sf->__print_busy_string();
    if ( ! defined $chosen_idxs || ! @$chosen_idxs ) {
        return;
    }
    my @tmp_info = ( $filter_str );
    my $label = 'Cols: ';
    push @tmp_info, line_fold(
        $label . '"' . join( '", "', @{$header}[@$chosen_idxs] ) . '"', get_term_width(),
        { subseq_tab => ' ' x length $label, join => 0 }
    );
    $info = $sf->__get_filter_info( $sql, join( "\n", @tmp_info ) );
    # Readline
    my $join_char = $tr->readline(
        'Join-string: ',
        { info => $info }
    );
    $sf->__print_busy_string();
    if ( ! defined $join_char ) {
        return;
    }
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
    $info = $filter_str;
    # Fill_form
    my $form = $tf->fill_form(
        $fields,
        { info => $info, prompt => 'Edit cells of joined cols:', auto_up => 2, confirm => $sf->{i}{_confirm},
          back => $sf->{i}{_back} . '   ' }
    );
    $sf->__print_busy_string();
    if ( ! $form ) {
        $sql->{insert_into_args} = $aoa;
        return;
    }
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
    my $prompt = 'Transpose columns to rows?';
    my $info = $sf->__get_filter_info( $sql, $filter_str );
    my $ok = $tc->choose(
        $menu,
        { info => $info, prompt => $prompt, index => 1, undef => '- NO', layout => 2, busy_string => $sf->{working} }
    );
    $sf->__print_busy_string();
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
    my $tmp = { empty_to_null => $sf->{empty_to_null} };
    my $info = $sf->__get_filter_info( $sql );
    $tu->settings_menu(
        $menu_elements,
        $tmp,
        { info => $info, back => $sf->{i}{_back}, confirm => $sf->{i}{_confirm} }
    );
    $sf->{empty_to_null} = $tmp->{empty_to_null};
}



sub __search_empty_cols {
    my ( $sf, $aoa ) = @_;
    my $row_count = @$aoa;
    my $col_count = @{$aoa->[0]};
    my $is_empty ;
    COL: for my $col_idx ( 0 .. $col_count - 1 ) {
        for my $row_idx ( 0 .. $row_count - 1 ) {
            if ( length $aoa->[$row_idx][$col_idx] ) {
                $is_empty->[$col_idx] = 0;
                next COL;
            }
        }
        $is_empty->[$col_idx] = 1;
    }
    return $is_empty;
}

sub __prepare_header {
    my ( $sf, $aoa, $is_empty ) = @_;
    my $row_count = @$aoa;
    my $col_count = @{$aoa->[0]};
    my $header = [];
    for my $col_idx ( 0 .. $col_count - 1 ) {
        if ( $is_empty->[$col_idx] ) {
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
    my ( $sf, $columns, $info, $prompt, $back ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my @pre = ( undef );
    # Choose
    my $col_idx = $tc->choose(
        [ @pre, map( defined $_ ? $_ : '', @$columns ) ],
        { layout => 0, order => 0, index => 1, undef => $back // '<<', info => $info, prompt => $prompt, empty => '--',
          busy_string => $sf->{working} } #
    );
    $sf->__print_busy_string();
    if ( ! $col_idx ) {
        return;
    }
    return $col_idx - @pre;
}

sub __choose_a_row_idx {
    my ( $sf, $aoa, $info, $prompt, $back ) = @_;
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
        { layout => 2, index => 1, undef => $back // '<<', info => $info, prompt => $prompt,
          busy_string => $sf->{working} }
    );
    $sf->__print_busy_string();
    if ( ! $row_idx ) {
        return;
    }
    return $row_idx - @pre;
}



1;


__END__
