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
    $saved = { map { $_->[1] => [ $_->[0] ] } @$saved } if ref $saved eq 'ARRAY'; # remove this after some time
    my $all_sr_groups = [];
    my $used_names = [];
    my $header_changed = 0;
    my @bu;

    MENU: while ( 1 ) {
        my @info = ( $filter_str );
        for my $sr_group ( @$all_sr_groups ) {
            for my $sr_single ( @$sr_group ) {
                push @info, '  s/' . join( '/', @$sr_single ) . ';';
            }
        }
        push @info, '';
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
        my $count_static_rows = @info + @$menu; # @info and @$menu
        $cf->__print_filter_info( $sql, $count_static_rows, undef );
        # Choose
        my $idx = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_v}}, info => join( "\n", @info ), prompt => '', default => 1, index => 1, undef => '  <=' }
        );
        if ( ! defined $idx || ! defined $menu->[$idx] ) {
            if ( @bu ) {
                ( $used_names, $available, $all_sr_groups ) = @{pop @bu};
                next;
            }
            return;
        }
        my $choice = $menu->[$idx];
        if ( $choice eq $hidden ) {
            $sf->__history( $sql );
            $saved = $ax->read_json( $sf->{i}{f_search_and_replace} ) // {};
            $saved = { map { $_->[1] => [ $_->[0] ] } @$saved } if ref $saved eq 'ARRAY'; # remove this after some time
            next MENU;
        }
        elsif ( $choice eq $select_cols ) {
            if ( ! @$all_sr_groups ) {
                return;
            }
            my $ok = $sf->__apply_to_cols( $sql, \@info, $header, $all_sr_groups );
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
            my $fields = [
                [ '  Pattern', ],
                [ '  Replacement', ],
                [ '  Modifiers', ]
            ];
            my $count_static_rows = @info + 3 + @$fields; # info, prompt, back, confirm and fields
            $cf->__print_filter_info( $sql, $count_static_rows, undef );
            # Fill_form
            my $form = $tf->fill_form(
                $fields,
                { info => join( "\n", @info ), prompt => $prompt, auto_up => 2, confirm => '  ' . $sf->{i}{confirm},
                back => '  ' . $sf->{i}{back} . '   ' }
            );
            if ( ! defined $form ) {
                next MENU;
            }
            my ( $pattern, $replacement, $modifiers ) = map { $_->[1] // '' } @$form;
            $modifiers = $sf->__filter_modifiers( $modifiers );
            $sr_group = [ [ $pattern, $replacement, $modifiers ] ];
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
    my ( $sf, $sql, $info, $header, $all_sr_groups ) = @_;
    my $tu = Term::Choose::Util->new( $sf->{i}{tcu_default} );
    my $cf = App::DBBrowser::GetContent::Filter->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $aoa = $sql->{insert_into_args};
    my $count_static_rows = @$info + 1; # info_count and cs_label
    $cf->__print_filter_info( $sql, $count_static_rows, [ '<<', $sf->{i}{ok}, @$header ] );
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
    # Choose
    my $col_idx = $tu->choose_a_subset(
        $header,
        { cs_label => 'Columns: ', info => join( "\n", @$info ), layout => 0, all_by_default => 1, index => 1,
        confirm => $sf->{i}{ok}, back => '<<', busy_string => $sf->{i}{working}, mark => $mark }
    );
    if ( ! defined $col_idx ) {
        return;
    }
    $sf->{i}{prev_chosen_cols}{$key_1}{$key_2} = [ @{$header}[@$col_idx] ];
    $cf->__print_filter_info( $sql, $count_static_rows, [ '<<', $sf->{i}{ok}, @$header ] ); #

    my $c;
    for my $row ( @$aoa ) { # modifies $aoa
        for my $i ( @$col_idx ) {
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
    $sql->{insert_into_args} = $aoa;
    return 1;
}


sub __init_data {
    my ( $sf ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $saved = $ax->read_json( $sf->{i}{f_search_and_replace} ) // {};
    $saved = { map { $_->[1] => [ $_->[0] ] } @$saved } if ref $saved eq 'ARRAY'; # remove this after some time
    my @info_rows = ( 'Saved Entries:' );
    push @info_rows, map { ' ' . $_ } sort { $a cmp $b } keys %$saved;
    push @info_rows, ' ';
    my $info = join "\n", @info_rows;
    return $saved, $info;
}

sub __stringified_code {
    my ( $sf, $sr_group ) = @_;
    my $code_tab = 8;
    return join( ';' . "\n" . ( ' ' x 8 ), map { 's/' . join '/', @$_ } @$sr_group ) . ';';
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
        my ( $saved, $info ) = $sf->__init_data();
        my ( $add, $edit, $remove ) = ( '- Add ', '- Edit', '- Remove' );
        my $menu = [ undef, $add, $edit, $remove ];
        # Choose
        my $idx = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_v}}, clear_screen => 1, info => $info, undef => '  <=', index => 1,
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
            my $sr_group = [];
            my @bu;
            my $old_idx_add = 0;
            my $add_s_and_r = 'Add s///;';

            ADD_MENU: while ( 1 ) {
                my $info_add = "\n" . 'New entry:' . "\n";
                my $confirm = $sf->{i}{_confirm};
                my $menu = [ undef, '  ' . $add_s_and_r ];
                if ( @$sr_group ) {
                    $info_add .= '  code: ' . $sf->__stringified_code( $sr_group ) . "\n";
                    splice @$menu, 1, 0, $confirm;
                    $old_idx_add = 0 if $old_idx_add == 1;
                }
                # Choose
                my $idx = $tc->choose(
                    $menu,
                    { %{$sf->{i}{lyt_v}}, info => $info . $info_add, prompt => 'Choose:', default => $old_idx_add,
                      index => 1, undef => $sf->{i}{_back} }
                );
                if ( ! defined $idx || ! defined $menu->[$idx] ) {
                    if ( @bu ) {
                        $sr_group = pop @bu;
                        next ADD_MENU;
                    }
                    next HISTORY;
                }
                if ( $sf->{o}{G}{menu_memory} ) {
                    if ( $old_idx_add == $idx && ! $ENV{TC_RESET_AUTO_UP} ) {
                        $old_idx_add = 0;
                        next ADD_MENU;
                    }
                    $old_idx_add = $idx;
                }
                my $choice = $menu->[$idx];
                if ( $choice eq $confirm ) {
                    my $name = $sf->__get_entry_name( $info . $info_add, $saved, $sr_group );
                    if ( ! length $name ) {
                        next ADD_MENU;
                    }
                    $saved->{$name} = [ @$sr_group ]; #
                    $ax->write_json( $sf->{i}{f_search_and_replace}, $saved );
                    next HISTORY;
                }
                else {
                    my $fields = [
                        [ '  Pattern',     ],
                        [ '  Replacement', ],
                        [ '  Modifiers',   ],
                    ];
                    # Fill_form
                    my $form = $tf->fill_form(
                        $fields,
                        { info => $info . $info_add, prompt => $add_s_and_r, auto_up => 2, clear_screen => 1,
                            confirm => '  ' . $sf->{i}{confirm}, back => '  ' . $sf->{i}{back} . '   ' }
                    );
                    if ( ! defined $form ) {
                        next ADD_MENU;
                    }
                    push @bu, [ @$sr_group ];
                    push @$sr_group, $sf->__from_form_to_sr_group_data( $form );
                }
            }
        }
        elsif ( $choice eq $edit ) {
            my $old_idx_choose_entry = 0;

            CHOOSE_ENTRY: while ( 1 ) {
                my ( $saved, $info ) = $sf->__init_data();
                my @pre = ( undef );
                my $menu = [ @pre, map( '- ' . $_, sort { $a cmp $b } keys %$saved ) ];
                # Choose
                my $idx = $tc->choose(
                    $menu,
                    { %{$sf->{i}{lyt_v}}, clear_screen => 1, prompt => 'Choose entry:', index => 1,
                        undef => '  <=', default => $old_idx_choose_entry, info => $info }
                );
                if ( ! defined $idx || ! defined $menu->[$idx] ) {
                    next HISTORY;
                }
                ( my $name = $menu->[$idx] ) =~ s/^- //;
                my $sr_group = delete $saved->{$name};
                my $old_idx_edit = 0;

                EDIT_ENTRY: while ( 1 ) {
                    my $fields = [];
                    my $c = 1;
                    for my $sr_single ( @$sr_group ) {
                        my ( $pattern, $replacement, $modifiers ) = @$sr_single;
                        push @$fields,
                            [ $c++ . ' Pattern', $pattern     ],
                            [ '  Replacement',   $replacement ],
                            [ '  Modifiers',     $modifiers   ];
                    }
                    my $code_tab = 8;
                    my $old_code = $sf->__stringified_code( $sr_group );
                    my $info_add_fmt = "\nChosen entry:\n  Name: \"%s\"\n  Code: %s\n\n"; #
                    my $info_add = sprintf $info_add_fmt, $name, $old_code;
                    # Fill_form
                    my $form = $tf->fill_form(
                        $fields,
                        { prompt => 'Edit code:', auto_up => 2, clear_screen => 1, info => $info . $info_add,
                          confirm => '  ' . $sf->{i}{confirm}, back => '  ' . $sf->{i}{back} . '   ' }
                    );
                    if ( ! defined $form ) {
                        $saved->{$name} = [ @$sr_group ];
                        next CHOOSE_ENTRY;
                    }

                    $sr_group = [ $sf->__from_form_to_sr_group_data( $form ) ];
                    my $code = $sf->__stringified_code( $sr_group );
                    if ( $name eq $old_code && $old_code ne $code) {
                        $name = $code;
                    }
                    $info_add = sprintf $info_add_fmt, $name, $code;
                    my $name = $sf->__get_entry_name( $info . $info_add, $saved, $sr_group, $name );
                    if ( ! length $name ) {
                        next EDIT_ENTRY;
                    }
                    else {
                        $saved->{$name} = [ @$sr_group ];
                        $ax->write_json( $sf->{i}{f_search_and_replace}, $saved );
                        last EDIT_ENTRY;
                    }
                }
            }
        }
        elsif ( $choice eq $remove ) {
            my $list = [ sort { $a cmp $b } keys %$saved ];
            # Choose
            my $idxs = $tu->choose_a_subset(
                $list,
                { prefix => '- ', cs_label => 'To remove:' . "\n  ", cs_separator => "\n  ", cs_end => "\n",
                  layout => 3, all_by_default => 0, index => 1, confirm => $sf->{i}{_confirm}, back => $sf->{i}{_back},
                  busy_string => $sf->{i}{working}, clear_screen => 1, prompt => 'Choose:', info => $info }
            );
            if ( ! defined $idxs ) {
                next;
            }
            # Ask yes/no with code
            my @names = @{$list}[@$idxs];
            delete @{$saved}{@names};
            $ax->write_json( $sf->{i}{f_search_and_replace}, $saved );
        }
    }
}


sub __from_form_to_sr_group_data {
    my ( $sf, $form ) = @_;
    my @sr_group_data;
    while ( @$form ) {
        my ( $pattern, $replacement, $modifiers ) = map { $_->[1] // '' } splice @$form, 0, 3;
        if ( length $pattern ) {
            $modifiers = $sf->__filter_modifiers( $modifiers );
            push @sr_group_data, [ $pattern, $replacement, $modifiers ];
        }
    }
    return @sr_group_data;
}


sub __get_entry_name {
    my ( $sf, $info, $saved, $sr_group, $name ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $tf = Term::Form->new( $sf->{i}{tf_default} );
    my $code = join( '; ', map { 's/' . join '/', @$_ } @$sr_group ) . ';';
    my $name_default = $name // $code;
    my $count = 1;

    NAME: while ( 1 ) {
        my $fields = [
            [ '  Code', $code         ],
            [ '  Name', $name_default ]
        ];
        $name = $tf->readline( 'Name: ', { info => $info, default => $name_default } );
        if ( ! defined $name || ! length $name ) {
            return;
        }
        if ( any { $name eq $_ } keys %$saved ) {
            my $prompt = "\"$name\" already exists.";
            my $choice = $tc->choose(
                [ undef, '  New name' ],
                { %{$sf->{i}{lyt_v}}, prompt => $prompt, info => $info }
            );
            if ( ! defined $choice ) {
                return;
            }
            if ( $count > 1 ) {
                $name = undef;
            }
            $count++;
            next NAME;
        }
        return $name;
    }
}


1;


__END__
