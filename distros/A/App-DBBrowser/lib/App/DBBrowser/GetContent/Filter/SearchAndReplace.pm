package # hide from PAUSE
App::DBBrowser::GetContent::Filter::SearchAndReplace;

use warnings;
use strict;
use 5.016;

use List::MoreUtils      qw( any );
use String::Substitution qw( sub_modify gsub_modify );

use Term::Choose       qw();
use Term::Choose::Util qw();
use Term::Form         qw();

use App::DBBrowser::Auxil;
use App::DBBrowser::GetContent::Filter;


sub new {
    my ( $class, $info, $options, $d ) = @_;
    my $sf = {
        i => $info,
        o => $options,
        d => $d
    };
    bless $sf, $class;
    return $sf;
}


sub search_and_replace {
    my ( $sf, $sql, $bu_insert_args, $filter_str ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $tf = Term::Form->new( $sf->{i}{tf_default} );
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $cf = App::DBBrowser::GetContent::Filter->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $aoa = $sql->{insert_args};
    my $is_empty = $cf->__search_empty_cols( $aoa );
    my $header = $cf->__prepare_header( $aoa, $is_empty );
    my $saved = $ax->read_json( $sf->{i}{f_search_and_replace} ) // {};
    my $all_sr_groups = [];
    my $used_names = [];
    my @bu;
    my ( $hidden, $add ) = ( 'Your choice:', '  * New *' );
    my $available = [ sort { $a cmp $b } keys %$saved  ];
    my $old_idx = 1;

    ADD_SEARCH_AND_REPLACE: while ( 1 ) {
        my @tmp_info = ( $filter_str );
        for my $sr_group ( @$all_sr_groups ) {
            push @tmp_info, map { '  ' . $_ } _stringified_sr_group( $sr_group );
        }
        push @tmp_info, '' if @$all_sr_groups;
        my @pre = ( $hidden, undef, $sf->{i}{_confirm}, $add );
        my $prefixed_available = [];
        for my $name ( @$available ) {
            if ( any { $_ eq $name } @$used_names ) {
                push @$prefixed_available, '- ' . $name . ' (used)';
            }
            else {
                push @$prefixed_available, '- ' . $name;
            }
        }
        my $menu = [ @pre, @$prefixed_available ];
        my $info = $cf->__get_filter_info( $sql, join( "\n", @tmp_info ) );
        # Choose
        my $idx = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_v}}, info => $info, prompt => '', default => $old_idx, index => 1, undef => $sf->{i}{_back} }
        );
        if ( ! defined $idx || ! defined $menu->[$idx] ) {
            if ( @bu ) {
                ( $used_names, $all_sr_groups ) = @{pop @bu};
                next ADD_SEARCH_AND_REPLACE;
            }
            return;
        }
        if ( $sf->{o}{G}{menu_memory} ) {
            if ( $old_idx == $idx && ! $ENV{TC_RESET_AUTO_UP} ) {
                $old_idx = 1;
                next ADD_SEARCH_AND_REPLACE;
            }
            $old_idx = $idx;
        }
        my $choice = $menu->[$idx];
        if ( $choice eq $hidden ) {
            $sf->__saved_search_and_replace();
            $saved = $ax->read_json( $sf->{i}{f_search_and_replace} ) // {};
            $available = [ sort { $a cmp $b } keys %$saved  ];
            next ADD_SEARCH_AND_REPLACE;
        }
        elsif ( $choice eq $sf->{i}{_confirm} ) {
            if ( ! @$all_sr_groups ) {
                return;
            }
            $info = $cf->__get_filter_info( $sql, join( "\n", @tmp_info ) );
            my $col_idxs = $sf->__choose_column_indexes( $header, $info, 'Apply to: ' );
            if ( ! defined $col_idxs ) {
                next ADD_SEARCH_AND_REPLACE;
            }
            if ( ! eval {
                $sf->__execute_substitutions( $aoa, $col_idxs, $all_sr_groups ); # modifies $aoa
                1 }
            ) {
                $ax->print_error_message( $@ );
                next ADD_SEARCH_AND_REPLACE;
            }
            $sql->{insert_args} = $aoa;
            my $header_changed = 0;
            if ( $sf->{d}{stmt_types}[0] eq 'Create_Table' ) {
                for my $i ( @$col_idxs ) {
                    if ( ! defined $sql->{insert_args}[0][$i] ) {
                        next;
                    }
                    if ( $header->[$i] ne $sql->{insert_args}[0][$i] ) {
                        $header_changed = 1;
                        last;
                    }
                }
            }
            if ( $header_changed ) {
                my ( $yes, $no ) = ( '- YES', '- NO' );
                my $menu = [ undef, $yes, $no ];
                my @tmp_info_addition = ( 'Header: ' . join( ', ', map { $_ // '' } @{$sql->{insert_args}[0]} ), ' ' );
                $info = $cf->__get_filter_info( $sql, join( "\n", @tmp_info, @tmp_info_addition ) );
                # Choose
                my $idx = $tc->choose(
                    $menu,
                    { %{$sf->{i}{lyt_v}}, info => $info, prompt => 'Restore header?', index => 1, undef => $sf->{i}{s_back} }
                );
                if ( ! defined $idx || ! defined $menu->[$idx] ) {
                    if ( @$aoa * @$col_idxs > 500_000 ) {
                        $cf->__print_busy_string( 'Working ...' );
                    }
                    $sql->{insert_args} = [ map { [ @$_ ] } @{$bu_insert_args} ];
                    return;
                }
                my $choice = $menu->[$idx];
                if ( $choice eq $yes ) {
                    $sql->{insert_args}[0] = $header;
                }
            }
            return 1;
        }
        elsif ( $choice eq $add ) {
            my $prompt = 'Build s///;';
            my $skip = ' ';
            my $fields = [];
            for my $nr ( 1 .. 5 ) {
                push @$fields,
                    [ $skip ],
                    [ $nr . ' Pattern',     ],
                    [ $nr . ' Replacement', ],
                    [ $nr . ' Modifiers',   ];
            }
            my $back = $sf->{i}{back} . '   ';

            SUBSTITUTION: while ( 1 ) {
                $info = $cf->__get_filter_info( $sql, join( "\n", @tmp_info ) );
                # Fill_form
                my $form = $tf->fill_form(
                    $fields,
                    { info => $info, prompt => $prompt, confirm => $sf->{i}{confirm}, back => $back }
                );
                if ( ! defined $form ) {
                    next ADD_SEARCH_AND_REPLACE;
                }
                my $sr_group = [ $sf->__from_form_to_sr_group_data( $form ) ];
                if ( ! @$sr_group ) {
                    next ADD_SEARCH_AND_REPLACE;
                }
                if ( ! eval {
                    $sf->__execute_substitutions( [ [ 'test_string' ] ], [ 0 ], [ $sr_group ] );
                    1 }
                ) {
                    $ax->print_error_message( $@ );
                    $fields = $form;
                    next SUBSTITUTION;
                }
                push @bu, [ [ @$used_names ], [ @$all_sr_groups ] ];
                push @$all_sr_groups, $sr_group;
                last SUBSTITUTION;
            }
        }
        else {
            my $name = $available->[$idx-@pre];
            my $sr_group = $saved->{$name};
            push @bu, [ [ @$used_names ], [ @$all_sr_groups ] ];
            push @$used_names, $name;
            push @$all_sr_groups, $sr_group;
        }
    }
}


sub __from_form_to_sr_group_data {
    my ( $sf, $form ) = @_;
    my @sr_group_data;
    my @copy = @$form;
    while ( @copy ) {
        my ( $section_separator, $pattern, $replacement, $modifiers ) = map { $_->[1] // '' } splice @copy, 0, 4;
        if ( length $pattern ) {
            push @sr_group_data, { pattern => $pattern, replacement => $replacement, modifiers => $modifiers };
        }
    }
    return @sr_group_data;
}


sub __choose_column_indexes {
    my ( $sf, $columns, $info, $prompt ) = @_;
    my $tu = Term::Choose::Util->new( $sf->{i}{tcu_default} );
    # Choose
    my $col_idxs = $tu->choose_a_subset(
        $columns,
        { cs_label => $prompt, info => $info, layout => 0, all_by_default => 1, index => 1, keep_chosen => 0 }
    );
    if ( ! defined $col_idxs ) {
        return;
    }
    return $col_idxs;
}


sub __execute_substitutions {
    my ( $sf, $aoa, $col_idxs, $all_sr_groups ) = @_;
    my $cf = App::DBBrowser::GetContent::Filter->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $busy_string = 'Search and replace: ';
    my $col_count = @$col_idxs;
    my $cell_count = @$aoa * $col_count;
    my $threshold_busy = 25_000;
    if ( $cell_count > $threshold_busy ) {
        $cf->__print_busy_string( $busy_string . '...' );
    }
    my $threshold_progress = 500_000;
    my ( $show_progress, $step, $total, $fmt );
    if ( $cell_count > $threshold_progress ) {
        $show_progress = $cell_count > ( $threshold_progress * 3 ) ? 2 : 1;
        $step = 1_000;
        $total = int $cell_count / $step;
        $fmt = $busy_string . $total . '/%' . length( $total ) . 'd';
    }
    else {
        $show_progress = 0;
    }
    my $c;

    for my $sr_group ( @$all_sr_groups ) {
        for my $sr_single ( @$sr_group ) {
            my ( $pattern, $replacement_str, $modifiers ) = @$sr_single{qw(pattern replacement modifiers)};
            my $global = $modifiers =~ tr/g//;
            my $count_e = $modifiers =~ tr/e//;
            my $replacement;
            if ( $count_e ) {
                my $replacement_code = sub { $replacement_str };
                for ( 1 .. $count_e ) {
                    my $recurse = $replacement_code;
                    $replacement_code = sub { eval $recurse->() }; # execute (e) substitution
                }
                $replacement = $replacement_code;
            }
            else {
                # with no `e`: the replacement has to be passed as a string
                $replacement = $replacement_str;
            }
            $modifiers =~ tr/imnsxa//dc             if length $modifiers; # tr/imnsxadlup//dc
            $pattern = "(?${modifiers}:${pattern})" if length $modifiers;
            if ( $count_e || $replacement_str =~ tr/$// ) {
                for my $row ( 0 .. $#$aoa ) {
                    for my $col ( @$col_idxs ) {
                        $c = 0;
                        if ( ! defined $aoa->[$row][$col] ) {
                            next;
                        }
                        elsif ( $global ) {
                            gsub_modify( $aoa->[$row][$col], $pattern, $replacement );   # modifies $aoa
                        }
                        else {
                            sub_modify( $aoa->[$row][$col], $pattern, $replacement );    # modifies $aoa
                        }
                    }
                    if ( $show_progress && ! ( $row * $col_count % $step ) ) {
                        $cf->__print_busy_string( sprintf $fmt, $row * $col_count / $step );
                    }
                }
            }
            else {
                if ( $show_progress == 1 ) {
                    $cf->__print_busy_string( $busy_string . '...' );
                }
                for my $row ( 0 .. $#$aoa ) {
                    for my $col ( @$col_idxs ) {
                        $c = 0;
                        if ( ! defined $aoa->[$row][$col] ) {
                            next;
                        }
                        elsif ( $global ) {
                            $aoa->[$row][$col] =~ s/$pattern/$replacement/g;   # modifies $aoa
                        }
                        else {
                            $aoa->[$row][$col] =~ s/$pattern/$replacement/;    # modifies $aoa
                        }
                    }
                    if ( $show_progress == 2 && ! ( $row * $col_count % $step ) ) {
                        $cf->__print_busy_string( sprintf $fmt, $row * $col_count / $step );
                    }
                }
            }
        }
    }
}


sub _stringified_sr_group {
    my ( $sr_group ) = @_;
    return map { sprintf 's/%s/%s/%s;', @$_{qw(pattern replacement modifiers)} } @$sr_group;
}


sub __saved_search_and_replace {
    my ( $sf ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $saved = $ax->read_json( $sf->{i}{f_search_and_replace} ) // {};
    my $save_data = 0;
    my $old_idx_history = 0;

    HISTORY: while ( 1 ) {
        my $info = 'Saved "search & replace":';
        $info = join "\n", $info, map( '  ' . $_, sort { $a cmp $b } keys %$saved ), ' ';
        my ( $add, $edit, $remove ) = ( '- Add ', '- Edit', '- Remove' );
        my $menu = [ undef, $add, $edit, $remove ];
        # Choose
        my $idx = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_v}}, info => $info, undef => '  <=', index => 1, default => $old_idx_history }
        );
        if ( ! defined $idx || ! defined $menu->[$idx] ) {
            if ( $save_data ) {
                $ax->write_json( $sf->{i}{f_search_and_replace}, $saved );
            }
            return;
        }
        if ( $sf->{o}{G}{menu_memory} ) {
            if ( $old_idx_history == $idx && ! $ENV{TC_RESET_AUTO_UP} ) {
                $old_idx_history = 0;
                next HISTORY;
            }
            $old_idx_history = $idx;
        }
        my $choice = $menu->[$idx];
        my $changed;
        if ( $choice eq $add ) {
            $changed = $sf->__add_saved( $saved );
        }
        elsif ( $choice eq $edit ) {
            $changed = $sf->__edit_saved( $saved );
        }
        elsif ( $choice eq $remove ) {
            $changed = $sf->__remove_saved( $saved );
        }
        if ( $changed && ! $save_data ) {
            $save_data = 1;
        }
    }
}


sub __add_saved {
    my ( $sf, $saved ) = @_;
    my $tf = Term::Form->new( $sf->{i}{tf_default} );
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $skip = ' ';
    my $fields = [];
    for my $nr ( 1 .. 9 ) {
        push @$fields,
            [ $skip ],
            [ $nr . ' Pattern',     ],
            [ $nr . ' Replacement', ],
            [ $nr . ' Modifiers',   ];
    }
    my $prompt = 'Add "search & replace":';

    ADD_CODE: while ( 1 ) {
        # Fill_form
        my $form = $tf->fill_form(
            $fields,
            { prompt => $prompt, confirm => $sf->{i}{_confirm}, back => $sf->{i}{_back} . '   ' }
        );
        if ( ! defined $form ) {
            return;
        }
        my $sr_group = [ $sf->__from_form_to_sr_group_data( $form ) ];
        if ( ! @$sr_group ) {
            return;
        }
        if ( ! eval {
            $sf->__execute_substitutions( [ [ 'test_string' ] ], [ 0 ], [ $sr_group ] );
            1 }
        ) {
            $ax->print_error_message( $@ );
            $fields = $form;
            next ADD_CODE;
        }
        my @code = _stringified_sr_group( $sr_group );
        my $info = join "\n", map { ( ' ' x 6 ) . $_ } @code;
        $info =~ s/^\s{5}/Code:/;
        $info = $prompt . "\n\n" . $info;
        my $name = $sf->__get_new_name( $info, 'Name: ', $saved, $sr_group );
        if ( ! length $name ) {
            $fields = $form;
            next ADD_CODE;
        }
        $saved->{$name} = [ @$sr_group ];
        return 1;
    }
}


sub __get_new_name {
    my ( $sf, $info, $prompt, $saved, $sr_group ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $tr = Term::Form::ReadLine->new( $sf->{i}{tr_default} );
    my $name_default = '';
    if ( @$sr_group == 1 ) {
        $name_default = ( _stringified_sr_group( $sr_group ) )[0];
    }
    my $count = 1;

    NAME: while ( 1 ) {
        # Readline
        my $new_name = $tr->readline(
            $prompt,
            { info => $info, default => $name_default, history => [] }
        );
        if ( ! length $new_name ) {
            return;
        }
        if ( any { $new_name eq $_ } keys %$saved ) {
            my $prompt = "\"$new_name\" already exists.";
            my $choice = $tc->choose(
                [ undef, '  New name' ],
                { %{$sf->{i}{lyt_v}}, prompt => $prompt, info => $info }
            );
            if ( ! defined $choice ) {
                return;
            }
            if ( $count > 1 ) {
                $new_name = undef;
            }
            $name_default = $new_name;
            $count++;
            next NAME;
        }
        return $new_name;
    }
}


sub __edit_saved {
    my ( $sf, $saved ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $tf = Term::Form->new( $sf->{i}{tf_default} );
    my $tr = Term::Form::ReadLine->new( $sf->{i}{tr_default} );
    my @pre = ( undef );
    my $menu = [ @pre, map( '- ' . $_, sort { $a cmp $b } keys %$saved ) ];
    my $prompt = 'Edit "search & replace":';
    # Choose
    my $idx = $tc->choose(
        $menu,
        { %{$sf->{i}{lyt_v}}, prompt => $prompt, index => 1, undef => '  <=' }
    );
    if ( ! defined $idx || ! defined $menu->[$idx] ) {
        return;
    }
    my $name = $menu->[$idx] =~ s/^- //r;
    my $skip = ' ';
    my $sr_group = $saved->{$name};
    my $fields = [
        [ $skip ],
        [ '  Pattern',     ],
        [ '  Replacement', ],
        [ '  Modifiers',   ]
    ];
    my $c = 0;
    for my $sr_single ( @$sr_group ) {
        $c++;
        push @$fields,
            [ $skip ],
            [ $c . ' Pattern',     $sr_single->{pattern}     ],
            [ $c . ' Replacement', $sr_single->{replacement} ],
            [ $c . ' Modifiers',   $sr_single->{modifiers}   ],
            [ $skip ],
            [ '  Pattern',     ],
            [ '  Replacement', ],
            [ '  Modifiers',   ];
    }
    my $info_fmt = "$prompt\n\nName: \"%s\"\nCode: %s\n";
    my $code_str = join "\n" . ( ' ' x 6 ),  _stringified_sr_group( $sr_group );
    my $info = sprintf $info_fmt, $name, $code_str;
    # Readline
    my $new_name = $tr->readline(
        'Confirm name: ',
        { info => $info, default => $name, history => [] }
    );
    if ( ! length $new_name ) {
        return;
    }
    my $old_code_str = join "\n" . ( ' ' x 6 ),  _stringified_sr_group( $sr_group );
    $info = sprintf $info_fmt, $new_name, $old_code_str;
    # Fill_form
    my $form = $tf->fill_form(
        $fields,
        { prompt => "Edit \"$new_name\":", info => $info, confirm => $sf->{i}{_confirm},
          back => $sf->{i}{_back} . '   ' }
    );
    if ( ! defined $form ) {
        return;
    }
    my $new_sr_group = [ $sf->__from_form_to_sr_group_data( $form ) ];
    if ( ! @$new_sr_group ) {
        return;
    }
    if ( $new_name ne $name ) {
        delete $saved->{$name};
    }
    $saved->{$new_name} = [ @$new_sr_group ];
    return 1;
}


sub __remove_saved {
    my ( $sf, $saved ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my @pre = ( undef );
    my $prompt = 'Remove "search & replace":';
    my $menu = [ @pre, map { '- ' . $_ } sort { $a cmp $b } keys %$saved ];
    # Choose
    my $idx = $tc->choose(
        $menu,
        { %{$sf->{i}{lyt_v}}, index => 1, undef => '  <=', prompt => $prompt }
    );
    if ( ! defined $idx || ! defined $menu->[$idx] ) {
        return;
    }
    my $name = $menu->[$idx] =~ s/^- //r;
    my $sr_group = $saved->{$name};
    my $code_str = join "\n" . ( ' ' x 6 ), _stringified_sr_group( $sr_group );
    my $info_fmt = "$prompt\n\nName: \"%s\"\nCode: %s\n";
    my $info = sprintf $info_fmt, $name, $code_str;
    my ( $no, $yes ) = ( '- NO', '- YES' );
    $menu = [ undef, $no, $yes ];
    # Choose
    $idx = $tc->choose(
        $menu,
        { %{$sf->{i}{lyt_v}}, prompt => "Remove \"$name\"?", index => 1, undef => '  <=', info => $info }
    );
    if ( ! defined $idx || ! defined $menu->[$idx] ) {
        return;
    }
    elsif ( $menu->[$idx] eq $yes ) {
        delete $saved->{$name};
        return 1;
    }
    else {
        return;
    }
}





1;


__END__
