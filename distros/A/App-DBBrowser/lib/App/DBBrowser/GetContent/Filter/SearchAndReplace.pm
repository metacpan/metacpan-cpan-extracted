package # hide from PAUSE
App::DBBrowser::GetContent::Filter::SearchAndReplace;

use warnings;
use strict;
use 5.010001;

use List::MoreUtils qw( any none );

use Term::Choose       qw();
use Term::Choose::Util qw();
use Term::Form         qw();

use App::DBBrowser::Auxil;
use App::DBBrowser::GetContent::Filter;


sub new {
    my ( $class, $info, $options, $data ) = @_;
    my $sf = {
        i => $info,
        o => $options,
        d => $data,
    };
    bless $sf, $class;
}


sub __search_and_replace {
    my ( $sf, $sql, $filter_str ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $tf = Term::Form->new( $sf->{i}{tf_default} );
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $cf = App::DBBrowser::GetContent::Filter->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $aoa = $sql->{insert_into_args};
    my $empty_cells_of_col_count =  $cf->__count_empty_cells_of_cols( $aoa ); ##
    my $header = $cf->__prepare_header( $aoa, $empty_cells_of_col_count );
    my $saved = $ax->read_json( $sf->{i}{f_search_and_replace} ) // {};
    my $all_sr_groups = [];
    my $used_names = [];
    my $header_changed = 0;
    my @bu;

    MENU: while ( 1 ) {
        my @tmp_info = ( '', $filter_str );
        for my $sr_group ( @$all_sr_groups ) {
            for my $sr_single ( @$sr_group ) {
                push @tmp_info, '  s/' . join( '/', @$sr_single ) . ';';
            }
        }
        push @tmp_info, '';
        my ( $hidden, $select_cols, $add, $restore_header ) = ( 'Choose:', '  SELECT COLUMNS', '  ADD s///;', '  RESTORE header row' );
        my @pre = ( $hidden, undef, $add );
        if ( @$all_sr_groups ) {
            splice @pre, 2, 0, $select_cols;
        }
        elsif ( $header_changed ) {
            splice @pre, 2, 0, $restore_header;
        }
        my $available = [];
        for my $name ( sort { $a cmp $b } keys %$saved ) {
            if ( none { $name eq $_ } @$used_names ) {
                push @$available, $name;
            }
        }
        my $menu = [ @pre, map( '- ' . $_, @$available ) ];
        my $count_static_rows = @tmp_info;
        my $info = $cf->__get_filter_info( $sql, $count_static_rows, undef, $menu, 1 ) . join( "\n", @tmp_info );
        # Choose
        my $idx = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_v}}, info => $info, prompt => '', default => 1, index => 1, undef => '  <=',
              keep => $sf->{i}{keep} }
        );
        if ( ! defined $idx || ! defined $menu->[$idx] ) {
            if ( @bu ) {
                ( $used_names, $available, $all_sr_groups ) = @{pop @bu};
                next;
            }
            return; ## no s/// => 2 x
        }
        my $choice = $menu->[$idx];
        if ( $choice eq $hidden ) {
            $sf->__history( $sql );
            $saved = $ax->read_json( $sf->{i}{f_search_and_replace} ) // {};
            next MENU;
        }
        elsif ( $choice eq $select_cols ) {
            if ( ! @$all_sr_groups ) {
                return;
            }
            my $ok = $sf->__apply_to_cols( $sql, \@tmp_info, $header, $all_sr_groups );
            for my $i ( 0 .. $#$header ) {
                if ( $header->[$i] ne $sql->{insert_into_args}[0][$i] ) {
                    $header_changed = 1;
                    last;
                }
            }
            if ( $ok ) {
                $all_sr_groups = [];
                $used_names = [];
                @bu = ();
            }
            next MENU;
        }
        elsif ( $choice eq $restore_header ) {
            $sql->{insert_into_args}[0] = $header;
            $header_changed = 0;
            next MENU;
        }
        push @bu, [ [ @$used_names ], [ @$available ], [ @$all_sr_groups ] ];
        my $sr_group;
        if ( $choice eq $add ) {
            my $prompt = 'Build s///;';
            my $fields = [];
            for my $nr ( 1 .. 9 ) {
                push @$fields,
                    [ ' ',                  ],
                    [ $nr . ' Pattern',     ],
                    [ $nr . ' Replacement', ],
                    [ $nr . ' Modifiers',   ];
            }
            my $count_static_rows = @tmp_info + 1; # tmp_info, prompt
            my $pre_count = 2; # back, confirm

            SUBSTITUTION: while ( 1 ) {
                my $info = $cf->__get_filter_info( $sql, $count_static_rows, [ ( ' ' ) x $pre_count ], $fields, 1 ) . join( "\n", @tmp_info );
                # Fill_form
                my $form = $tf->fill_form(
                    $fields,
                    { info => $info, prompt => $prompt, auto_up => 2, confirm => '  ' . $sf->{i}{confirm}, keep => $sf->{i}{keep},
                    back => '  ' . $sf->{i}{back} . '   ', section_separators => [ grep { ! ( $_ % 4 ) } 0 .. $#$fields ] }
                );
                if ( ! defined $form ) {
                    next MENU;
                }
                $sr_group = [ $sf->__from_form_to_sr_group_data( $form ) ];
                if ( ! @$sr_group ) {
                    next MENU;
                }
                if ( ! eval {
                    $sf->__execute_substitutions( [ [ 'test_string' ] ], [ 0 ], [ $sr_group ] );
                    1 }
                ) {
                    $ax->print_error_message( $@ );
                    $fields = $form;
                    next SUBSTITUTION;
                }
                last SUBSTITUTION;
            }
        }
        else {
            my $name = $available->[$idx-@pre];
            $sr_group = $saved->{$name};
            push @$used_names, $name;
        }
        push @$all_sr_groups, $sr_group;
    }
}


sub __filter_modifiers {
    my ( $sf, $modifiers ) = @_;
    $modifiers =~ s/[^geis]+//g;
    $modifiers =~ tr/gis/gis/s; #;;
    return $modifiers;
}


sub __apply_to_cols {
    my ( $sf, $sql, $tmp_info, $header, $all_sr_groups ) = @_;
    my $tu = Term::Choose::Util->new( $sf->{i}{tcu_default} );
    my $cf = App::DBBrowser::GetContent::Filter->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $aoa = $sql->{insert_into_args};
    my $count_static_rows = @$tmp_info + 1; # info_count and cs_label
    $cf->__print_filter_info( $sql, $count_static_rows, [ '<<', $sf->{i}{ok} ], $header, undef );
    my $key_1 = 'search&replace';
    my $key_2;
    for my $sr_group ( @$all_sr_groups ) {
        for my $sr ( @$sr_group ) {
            $key_2 .= join( '', @$sr );
        }
    }
    my $prev_chosen = $sf->{i}{prev_chosen_cols}{$key_1}{$key_2} // [];
    my $mark;
    if ( @$prev_chosen && @$prev_chosen < @$header ) {
        $mark = [];
        for my $i ( 0 .. $#{$header} ) {
            push @$mark, $i if any { $_ eq $header->[$i] } @$prev_chosen;
        }
        $mark = undef if @$mark != @$prev_chosen;
    }
    my $info = $cf->__get_filter_info( $sql, $count_static_rows, [ '<<', $sf->{i}{ok} ], $header, undef ) . join( "\n", @$tmp_info );
    # Choose
    my $col_idxs = $tu->choose_a_subset(
        $header,
        { cs_label => 'Columns: ', info => $info, layout => 0, all_by_default => 1, index => 1, keep => $sf->{i}{keep},
        confirm => $sf->{i}{ok}, back => '<<', busy_string => $sf->{i}{working}, mark => $mark }
    );
    if ( ! defined $col_idxs ) {
        return;
    }
    $sf->{i}{prev_chosen_cols}{$key_1}{$key_2} = [ @{$header}[@$col_idxs] ];
    $cf->__print_filter_info( $sql, $count_static_rows, [ '<<', $sf->{i}{ok} ], $header, undef ); #
    $sf->__execute_substitutions( $aoa, $col_idxs, $all_sr_groups );
    $sql->{insert_into_args} = $aoa;
    return 1;
}

sub __execute_substitutions {
    my ( $sf, $aoa, $col_idxs, $all_sr_groups ) = @_;
    my $c;
    for my $row ( @$aoa ) { # modifies $aoa
        for my $i ( @$col_idxs ) {
            for my $sr_group ( @$all_sr_groups ) {
                for my $sr_single ( @$sr_group ) {
                    my ( $pattern, $replacement, $modifiers ) = @$sr_single;
                    my $regex = $modifiers =~ /i/ ? qr/(?i:${pattern})/ : qr/${pattern}/;
                    my $replacement_code = sub { return $replacement };
                    for ( grep { /^e\z/ } split( //, $modifiers ) ) {
                        my $recurse = $replacement_code;
                        $replacement_code = sub { return eval $recurse->() }; # execute (e) substitution
                    }
                    $c = 0;
                    if ( ! defined $row->[$i] ) {
                        next;
                    }
                    elsif ( $modifiers =~ /g/ ) {
                        if ( $modifiers =~ /s/ ) { # s not documented
                            $row->[$i] =~ s/$regex/$replacement_code->()/gse;
                        }
                        else {
                            $row->[$i] =~ s/$regex/$replacement_code->()/ge;
                        }
                    }
                    else {
                        if ( $modifiers =~ /s/ ) { # s not documented
                            $row->[$i] =~ s/$regex/$replacement_code->()/se;
                        }
                        else {
                            $row->[$i] =~ s/$regex/$replacement_code->()/e;
                        }
                    }
                }
            }
        }
    }
}


sub _stringified_code {
    my ( $sr_group ) = @_;
    return ( map { 's/' . join( '/', @$_ ) . ';' } @$sr_group );
}


sub __history {
    my ( $sf, $sql ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $tf = Term::Form->new( $sf->{i}{tf_default} );
    my $tu = Term::Choose::Util->new( $sf->{i}{tcu_default} );
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $cf = App::DBBrowser::GetContent::Filter->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $old_idx_history = 0;

    HISTORY: while ( 1 ) {
        my $saved = $ax->read_json( $sf->{i}{f_search_and_replace} ) // {};
        my $top = join "\n", 'Saved s_&_r', map( '  ' . $_, sort { $a cmp $b } keys %$saved ), ' ';
        my ( $add, $edit, $remove ) = ( '- Add ', '- Edit', '- Remove' );
        my $menu = [ undef, $add, $edit, $remove ];
        # Choose
        my $idx = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_v}}, clear_screen => 1, info => $top, undef => '  <=', index => 1,
              default => $old_idx_history }
        );
        if ( ! defined $idx || ! defined $menu->[$idx] ) {
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
        if ( $choice eq $add ) {
            my $fields = [];
            for my $nr ( 1 .. 9 ) {
                push @$fields,
                    [ ' ',                  ],
                    [ $nr . ' Pattern',     ],
                    [ $nr . ' Replacement', ],
                    [ $nr . ' Modifiers',   ];
            }

            ADD_CODE: while ( 1 ) {

                # Fill_form
                my $form = $tf->fill_form(
                    $fields,
                    { prompt => 'Add s_&_r:', auto_up => 2, clear_screen => 1, info => $top,
                      section_separators => [ grep { ! ( $_ % 4 ) } 0 .. $#$fields ],
                      confirm => '  ' . $sf->{i}{confirm}, back => '  ' . $sf->{i}{back} . '   ' }
                );
                if ( ! defined $form ) {
                    next HISTORY;
                }
                my $sr_group = [ $sf->__from_form_to_sr_group_data( $form ) ];
                if ( ! @$sr_group ) {
                    next HISTORY;
                }
                if ( ! eval {
                    $sf->__execute_substitutions( [ [ 'test_string' ] ], [ 0 ], [ $sr_group ] );
                    1 }
                ) {
                    $ax->print_error_message( $@ );
                    $fields = $form;
                    next ADD_CODE;
                }
                my @code = _stringified_code( $sr_group );
                my $info = join( "\n", map { "      $_" } @code );
                $info =~ s/\s{5}/\nCode:/;
                $info = $top . $info;
                my $name = $sf->__get_entry_name( $info, 'Name: ', $saved, $sr_group );
                if ( ! length $name ) {
                    $fields = $form;
                    next ADD_CODE;
                }
                else {
                    $saved->{$name} = [ @$sr_group ];
                    $ax->write_json( $sf->{i}{f_search_and_replace}, $saved );
                    last ADD_CODE;
                }
            }
        }
        elsif ( $choice eq $edit ) {
            my $old_idx_choose_entry = 0;

            CHOOSE_ENTRY: while ( 1 ) {
                my $saved = $ax->read_json( $sf->{i}{f_search_and_replace} ) // {};
                my @pre = ( undef );
                my $menu = [ @pre, map( '- ' . $_, sort { $a cmp $b } keys %$saved ) ];
                my $top = "Saved s_&_r";
                # Choose
                my $idx = $tc->choose(
                    $menu,
                    { %{$sf->{i}{lyt_v}}, clear_screen => 1, prompt => 'Edit item:', index => 1,
                        undef => '  <=', default => $old_idx_choose_entry, info => $top }
                );
                if ( ! defined $idx || ! defined $menu->[$idx] ) {
                    next HISTORY;
                }
                ( my $name = $menu->[$idx] ) =~ s/^- //;
                $top = join "\n", 'Saved s_&_r', map( '  ' . $_, sort { $a cmp $b } keys %$saved ), ' ';
                my $sr_group = delete $saved->{$name};
                my $old_idx_edit = 0;

                EDIT_ENTRY: while ( 1 ) {
                    my $fields = [
                        [ ' ' ],
                        [ '  Pattern',     ],
                        [ '  Replacement', ],
                        [ '  Modifiers',   ]
                    ];
                    my $c = 0;
                    for my $sr_single ( @$sr_group ) {
                        my ( $pattern, $replacement, $modifiers ) = @$sr_single;
                        $c++;
                        push @$fields,
                            [ ' ' ],
                            [ $c . ' Pattern',     $pattern     ],
                            [ $c . ' Replacement', $replacement ],
                            [ $c . ' Modifiers',   $modifiers   ],
                            [ ' ' ],
                            [ '  Pattern',     ],
                            [ '  Replacement', ],
                            [ '  Modifiers',   ];
                    }
                    my $old_code_str = join "\n" . ( ' ' x 6 ),  _stringified_code( $sr_group );
                    my $info_add_fmt = "\n\nName: \"%s\"\nCode: %s\n";
                    my $info_add = sprintf $info_add_fmt, $name, $old_code_str;
                    # Fill_form
                    my $form = $tf->fill_form(
                        $fields,
                        { prompt => "Edit \"$name\":", auto_up => 2, clear_screen => 1, info => $top . $info_add,
                          section_separators => [ grep { ! ( $_ % 4 ) } 0 .. $#$fields ],
                          confirm => '  ' . $sf->{i}{confirm}, back => '  ' . $sf->{i}{back} . '   ' }
                    );
                    if ( ! defined $form ) {
                        $saved->{$name} = [ @$sr_group ];
                        next CHOOSE_ENTRY;
                    }

                    my $new_sr_group = [ $sf->__from_form_to_sr_group_data( $form ) ];
                    if ( ! @$new_sr_group ) {
                        $saved->{$name} = [ @$sr_group ];
                        next CHOOSE_ENTRY;
                    }
                    my $code_str = join "\n" . ( ' ' x 6 ),  _stringified_code( $new_sr_group );
                    if ( $name eq $old_code_str && $old_code_str ne $code_str) {
                        $name = $code_str;
                    }
                    $info_add = sprintf $info_add_fmt, $name, $code_str;
                    my $new_name = $sf->__get_entry_name( $top . $info_add, 'Edit name: ', $saved, $new_sr_group, $name );
                    if ( ! length $new_name ) {
                        next EDIT_ENTRY;
                    }
                    else {
                        $name = $new_name;
                        $saved->{$name} = [ @$new_sr_group ];
                        $ax->write_json( $sf->{i}{f_search_and_replace}, $saved );
                        $top = join "\n", 'Saved s_&_r', map( '  ' . $_, sort { $a cmp $b } keys %$saved ), ' ';
                        next CHOOSE_ENTRY;
                    }
                }
            }
        }
        elsif ( $choice eq $remove ) {
            my $list = [ sort { $a cmp $b } keys %$saved ];
            # Choose
            my $idxs = $tu->choose_a_subset(
                $list,
                { prefix => '- ', info => 'Saved s_&_r', cs_label => 'Chosen items:' . "\n  ", cs_separator => "\n  ", cs_end => "\n",
                  layout => 3, all_by_default => 0, index => 1, confirm => $sf->{i}{_confirm}, back => $sf->{i}{_back},
                  busy_string => $sf->{i}{working}, clear_screen => 1, prompt => 'Choose items to remove:' }
            );
            if ( ! defined $idxs ) {
                next HISTORY;
            }
            my @names = @{$list}[@$idxs];
            REMOVE_ENTRY: for my $name ( @names ) {
                my $sr_group = $saved->{$name};
                my $code_str = join "\n" . ( ' ' x 6 ), _stringified_code( $sr_group );
                my $info_add_fmt = "\nName: \"%s\"\nCode: %s\n";
                my $info_add = sprintf $info_add_fmt, $name, $code_str;
                my ( $no, $yes ) = ( '- NO', '- YES' );
                my $menu = [ undef, $no, $yes ];
                # Choose
                my $idx = $tc->choose(
                    $menu,
                    { %{$sf->{i}{lyt_v}}, clear_screen => 1, prompt => "Remove \"$name\"?", index => 1,
                        undef => '  <=', info => $top . $info_add }
                );
                if ( ! defined $idx || ! defined $menu->[$idx] ) {
                    next HISTORY;
                }
                elsif ( $menu->[$idx] eq $no ) {
                    next REMOVE_ENTRY;
                }
                delete $saved->{$name};
                $top = join "\n", 'Saved s_&_r', map( '  ' . $_, sort { $a cmp $b } keys %$saved ), ' ';
            }
            $ax->write_json( $sf->{i}{f_search_and_replace}, $saved );
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
            $modifiers = $sf->__filter_modifiers( $modifiers );
            push @sr_group_data, [ $pattern, $replacement, $modifiers ];
        }
    }
    return @sr_group_data;
}


sub __get_entry_name {
    my ( $sf, $info, $prompt, $saved, $sr_group, $name ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $tf = Term::Form->new( $sf->{i}{tf_default} );
    my $name_default = $name;
    if ( ! length $name && @$sr_group < 3 ) {
        $name_default = join ' ', _stringified_code( $sr_group );
    }
    my $count = 1;

    NAME: while ( 1 ) {
        # Readline
        my $new_name = $tf->readline(
            $prompt,
            { info => $info, default => $name_default }
        );
        if ( ! defined $new_name || ! length $new_name ) {
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
            $count++;
            next NAME;
        }
        return $new_name;
    }
}


1;


__END__
