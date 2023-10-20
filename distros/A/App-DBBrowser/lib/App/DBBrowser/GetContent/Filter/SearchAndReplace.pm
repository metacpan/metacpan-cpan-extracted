package # hide from PAUSE
App::DBBrowser::GetContent::Filter::SearchAndReplace;

use warnings;
use strict;
use 5.014;

use List::MoreUtils qw( any );

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
}


sub search_and_replace {
    my ( $sf, $sql, $bu_insert_args, $filter_str, $back  ) = @_;
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
    $sf->{s_back} = $back;
    my @bu;
    my ( $hidden, $add ) = ( 'Your choice:', '  NEW' );
    my $available = [ sort { $a cmp $b } keys %$saved  ];

    ADD_SEARCH_AND_REPLACE: while ( 1 ) {
        my @tmp_info = ( '', $filter_str );
        for my $sr_group ( @$all_sr_groups ) {
            for my $sr_single ( @$sr_group ) {
                push @tmp_info, '  s/' . join( '/', @$sr_single ) . ';';
            }
        }
        push @tmp_info, '';
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
            { %{$sf->{i}{lyt_v}}, info => $info, prompt => '', default => 1, index => 1, undef => $sf->{i}{_back} }
        );
        if ( ! defined $idx || ! defined $menu->[$idx] ) {
            if ( @bu ) {
                ( $used_names, $all_sr_groups ) = @{pop @bu};
                next ADD_SEARCH_AND_REPLACE;
            }
            return;
        }
        my $choice = $menu->[$idx];
        if ( $choice eq $hidden ) {
            $sf->__history( $sql );
            $saved = $ax->read_json( $sf->{i}{f_search_and_replace} ) // {};
            $available = [ sort { $a cmp $b } keys %$saved  ];
            next ADD_SEARCH_AND_REPLACE;
        }
        elsif ( $choice eq $sf->{i}{_confirm} ) {
            if ( ! @$all_sr_groups ) {
                return;
            }
            my $col_idxs = $sf->__get_col_idxs( $sql, \@tmp_info, $header, $all_sr_groups );
            if ( ! defined $col_idxs ) {
                next ADD_SEARCH_AND_REPLACE;
            }
            $sf->__execute_substitutions( $aoa, $col_idxs, $all_sr_groups ); # modifies $aoa
            $sql->{insert_args} = $aoa;
            my $header_changed = 0;
            if ( $sf->{d}{stmt_types}[0] =~ /^Create_table\z/i ) {
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
                my ( $yes, $no ) = ( 'Yes', 'No' );
                my $menu = [ undef, $yes, $no ];
                my @tmp_info_addition = ( 'Header: ' . join( ', ', map { $_ // '' } @{$sql->{insert_args}[0]} ), ' ' );
                my $info = $cf->__get_filter_info( $sql, join( "\n", @tmp_info, @tmp_info_addition ) );
                # Choose
                my $idx = $tc->choose(
                    $menu,
                    { %{$sf->{i}{lyt_v}}, info => $info, prompt => 'Restore header?', index => 1, undef => $sf->{s_back} }
                );
                if ( ! defined $idx || ! defined $menu->[$idx] ) {
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
            my $separator_key = ' ';
            my $skip_regex = qr/^\Q${separator_key}\E\z/;
            my $fields = [];
            for my $nr ( 1 .. 7 ) {
                push @$fields,
                    [ $separator_key,       ],
                    [ $nr . ' Pattern',     ],
                    [ $nr . ' Replacement', ],
                    [ $nr . ' Modifiers',   ];
            }
            my $back = $sf->{i}{back} . '   ';

            SUBSTITUTION: while ( 1 ) {
                my $info = $cf->__get_filter_info( $sql, join( "\n", @tmp_info ) );
                # Fill_form
                my $form = $tf->fill_form(
                    $fields,
                    { info => $info, prompt => $prompt, confirm => $sf->{i}{confirm},
                      back => $back, skip_items => $skip_regex }
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


sub __filter_modifiers {
    my ( $sf, $modifiers ) = @_;
    $modifiers =~ s/[^geis]+//g;
    $modifiers =~ tr/gis/gis/s; #;;
    return $modifiers;
}


sub __get_col_idxs {
    my ( $sf, $sql, $tmp_info, $header, $all_sr_groups ) = @_;
    my $tu = Term::Choose::Util->new( $sf->{i}{tcu_default} );
    my $cf = App::DBBrowser::GetContent::Filter->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $info = $cf->__get_filter_info( $sql, join( "\n", @$tmp_info ) );
    # Choose
    my $col_idxs = $tu->choose_a_subset(
        $header,
        { cs_label => 'Apply to: ', info => $info, layout => 0, all_by_default => 1, index => 1,
        confirm => $sf->{i}{ok}, back => $sf->{s_back} }
    );
    $cf->__print_busy_string();
    if ( ! defined $col_idxs ) {
        return;
    }
    return $col_idxs;
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
    my $separator_key = ' ';
    my $skip_regex = qr/^\Q${separator_key}\E\z/;
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
            my $separator_key = ' ';
            my $skip_regex = qr/^\Q${separator_key}\E\z/;
            my $fields = [];
            for my $nr ( 1 .. 9 ) {
                push @$fields,
                    [ $separator_key,       ],
                    [ $nr . ' Pattern',     ],
                    [ $nr . ' Replacement', ],
                    [ $nr . ' Modifiers',   ];
            }

            ADD_CODE: while ( 1 ) {
                # Fill_form
                my $form = $tf->fill_form(
                    $fields,
                    { prompt => 'Add s_&_r:', clear_screen => 1, info => $top,
                      skip_items => $skip_regex,
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
                my $name = $menu->[$idx] =~ s/^- //r;
                $top = join "\n", 'Saved s_&_r', map( '  ' . $_, sort { $a cmp $b } keys %$saved ), ' ';
                my $sr_group = delete $saved->{$name};
                my $old_idx_edit = 0;

                EDIT_ENTRY: while ( 1 ) {
                    my $fields = [
                        [ $separator_key   ],
                        [ '  Pattern',     ],
                        [ '  Replacement', ],
                        [ '  Modifiers',   ]
                    ];
                    my $c = 0;
                    for my $sr_single ( @$sr_group ) {
                        my ( $pattern, $replacement, $modifiers ) = @$sr_single;
                        $c++;
                        push @$fields,
                            [ $separator_key ],
                            [ $c . ' Pattern',     $pattern     ],
                            [ $c . ' Replacement', $replacement ],
                            [ $c . ' Modifiers',   $modifiers   ],
                            [ $separator_key ],
                            [ '  Pattern',     ],
                            [ '  Replacement', ],
                            [ '  Modifiers',   ];
                    }
                    my $old_code_str = join "\n" . ( ' ' x 6 ),  _stringified_code( $sr_group );
                    my $info_add_fmt = "\n\nName: \"%s\"\nCode: %s\n";
                    my $info_add = sprintf $info_add_fmt, $name, $old_code_str;
                    my $info = $top . $info_add;
                    # Fill_form
                    my $form = $tf->fill_form(
                        $fields,
                        { prompt => "Edit \"$name\":", clear_screen => 1, info => $info, skip_items => $skip_regex,
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
                    $info = sprintf $info_add_fmt, $name, $code_str;
                    my $new_name = $sf->__get_entry_name( $top . $info, 'Edit name: ', $saved, $new_sr_group, $name );
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
            my $info = 'Saved s_&_r';
            # Choose
            my $idxs = $tu->choose_a_subset(
                $list,
                { prefix => '- ', info => $info, cs_label => 'Chosen items:' . "\n  ", cs_separator => "\n  ", cs_end => "\n",
                  layout => 2, all_by_default => 0, index => 1, confirm => $sf->{i}{_confirm}, back => $sf->{i}{_back},
                  clear_screen => 1, prompt => 'Choose items to remove:' }
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
                my $info = $top . $info_add;
                # Choose
                my $idx = $tc->choose(
                    $menu,
                    { %{$sf->{i}{lyt_v}}, clear_screen => 1, prompt => "Remove \"$name\"?", index => 1,
                        undef => '  <=', info => $info }
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
    my $tr = Term::Form::ReadLine->new( $sf->{i}{tr_default} );
    my $name_default = $name;
    if ( ! length $name && @$sr_group < 3 ) {
        $name_default = join ' ', _stringified_code( $sr_group );
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


1;


__END__
