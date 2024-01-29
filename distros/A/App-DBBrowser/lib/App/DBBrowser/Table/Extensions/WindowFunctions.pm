package # hide from PAUSE
App::DBBrowser::Table::Extensions::WindowFunctions;

use warnings;
use strict;
use 5.014;

use Term::Choose         qw();
use Term::Form::ReadLine qw();

use App::DBBrowser::Auxil;
use App::DBBrowser::Table::Extensions;


sub new {
    my ( $class, $info, $options, $d ) = @_;
    bless {
        i => $info,
        o => $options,
        d => $d
    }, $class;
}


sub __choose_a_column {
    my ( $sf, $sql, $clause, $qt_cols, $info, $func ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my @pre = ( undef );
    if ( $sf->{i}{menu_addition} ) {
        push @pre, $sf->{i}{menu_addition};
    }
    $info .= "\n" . $func . '(?)';
    while ( 1 ) {
        # Choose
        my $choice = $tc->choose(
            [ @pre, @$qt_cols ],
            { %{$sf->{i}{lyt_h}}, info => $info, prompt => 'Column:' }
        );
        if ( ! defined $choice ) {
            return;
        }
        elsif ( $choice eq $sf->{i}{menu_addition} ) {
            my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
            # clause 'window_function': to avoid window function in window function
            my $complex_col = $ext->column(
                $sql, $clause, {},
                { from =>'window_function', info => $info }
            );
            if ( ! defined $complex_col ) {
                next;
            }
            return $complex_col;
        }
        return $choice;
    }
}


sub __get_win_func_stmt {
    my ( $sf, $win_func_data ) = @_;
    my $win_func_stmt = $win_func_data->{func};
    $win_func_stmt .= sprintf '(%s)', $win_func_data->{col} // '';
    my @win_definition;
    for my $stmt ( qw(partition_by_stmt order_by_stmt frame_clause) ) {
        if ( length $win_func_data->{$stmt} ) {
            push @win_definition, $win_func_data->{$stmt};
        }
    }
    $win_func_stmt .= sprintf ' OVER (%s)', join( ' ',  @win_definition ) // '';
    return $win_func_stmt;
}


sub window_function {
    my ( $sf, $sql, $clause, $qt_cols, $opt ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $tr = Term::Form::ReadLine->new( $sf->{i}{tr_default} );
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $driver = $sf->{i}{driver};
    my $count_all = 'COUNT*';
    my $count_all_regex = quotemeta $count_all;
    my @win_func_aggr = ( 'AVG', 'COUNT', $count_all, 'MAX', 'MIN', 'SUM' );
    my @win_func_rank = ( 'CUME_DIST', 'DENSE_RANK', 'NTILE', 'PERCENT_RANK', 'RANK', 'ROW_NUMBER' );
    my @win_func_value = ( 'FIRST_VALUE', 'LAG', 'LAST_VALUE', 'LEAD', 'NTH_VALUE' );

    my @functions = sort( @win_func_aggr, @win_func_rank, @win_func_value );

    my @no_col_func = ( 'CUME_DIST', 'DENSE_RANK', 'PERCENT_RANK', 'RANK', 'ROW_NUMBER' );
    my $no_col_func_regex = join( '|', map { quotemeta } @no_col_func );

    my @col_is_number_func = ( 'NTILE' );
    my $col_is_number_func_regex = join( '|', map { quotemeta } @col_is_number_func );

    my @offset_func = ( 'LAG', 'LEAD', 'NTH_VALUE' );
    my $offset_func_regex = join( '|', map { quotemeta } @offset_func );

    my @default_value_func = ( 'LAG', 'LEAD' );
    my $default_value_func_regex = join( '|', map { quotemeta } @default_value_func );

    my $info = $opt->{info} // $ax->get_sql_info( $sql );
    my $win_func_data = {};
    my $hidden = 'Window function:';
    my $old_idx_wf = 1;

    WINDOW_FUNCTION: while( 1 ) {
        my @pre = ( $hidden, undef );
        my $menu = [ @pre, map { '- ' . $_ } @functions ];
        # Choose
        my $idx_wf = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_v}}, info => $info, prompt => '', index => 1,
              default => $old_idx_wf, undef => '<=' }
        );
        if ( ! defined $idx_wf || ! defined $menu->[$idx_wf] ) {
            return;
        }
        if ( $sf->{o}{G}{menu_memory} ) {
            if ( $old_idx_wf == $idx_wf && ! $ENV{TC_RESET_AUTO_UP} ) {
                $old_idx_wf = 1;
                next WINDOW_FUNCTION;
            }
            $old_idx_wf = $idx_wf;
        }
        if ( $menu->[$idx_wf] eq $hidden ) {
            $ext->enable_extended_arguments( $info );
            if ( $sf->{o}{enable}{extended_args} ) {
                $hidden = 'Window functions:*';
            }
            else {
                $hidden = 'Window functions:';
            }
            next WINDOW_FUNCTION;
        }
        my $func = $functions[$idx_wf-@pre];
        $win_func_data->{func} = $func;

        COLUMN: while ( 1 ) {
            if ( exists $win_func_data->{col} ) {
                delete $win_func_data->{col};
            }
            my $tmp_info = $info . "\n" . $sf->__get_win_func_stmt( $win_func_data );
            my $col;
            if ( $func =~ /^$count_all_regex\z/i ) {
                $col = '*';
                $win_func_data->{func} = $func =~ s/\*\z//r;
            }
            elsif ( $func =~ /^(?:$no_col_func_regex)\z/i ) {
                $col = '';
            }
            elsif ( $func =~ /^(?:$col_is_number_func_regex)\z/i ) {
                # Readline
                $col = $ext->argument( $sql, $clause, { info => $info . "\n" . $func . '(n)', history => undef, prompt => 'n = ' } );
                if ( ! length $col ) {
                    next WINDOW_FUNCTION;
                }
            }
            else {
                $col = $sf->__choose_a_column( $sql, $clause, $qt_cols, $info, $func );
                if ( ! defined $col ) {
                    delete $win_func_data->{func};
                    next WINDOW_FUNCTION;
                }
            }
            $win_func_data->{col} = $col;
            if ( $func =~ /^(?:$offset_func_regex)\z/i ) {
                $tmp_info = $info . "\n" . $sf->__get_win_func_stmt( $win_func_data );
                # Readline
                my $offset = $ext->argument( $sql, $clause, { info => $tmp_info, history => undef, prompt => 'offset: ' } );
                if ( ! defined $offset ) {
                    next WINDOW_FUNCTION;
                }
                if ( length $offset ) {
                    $col .= ',' . $offset;
                    $win_func_data->{col} = $col;
                    $tmp_info = $info . "\n" . $sf->__get_win_func_stmt( $win_func_data );
                    if ( $func =~ /^(?:$default_value_func_regex)\z/i ) {
                        # Readline
                        my $default_value = $ext->argument( $sql, $clause, { info => $tmp_info, history => undef, prompt => 'default: ' } );
                        if ( ! defined $default_value) {
                            next WINDOW_FUNCTION;
                        }
                        if ( length $default_value ) {
                            $col .= ',' . $default_value;
                            $win_func_data->{col} = $col;
                        }
                    }
                }
            }
            my @bu;
            my $old_idx = 0;

            WINDOW_DEFINITION: while( 1 ) {
                my ( $partition_by, $order_by, $frame_clause ) = ( '- Partition by', '- Order by', '- Frame clause' );
                my @pre = ( undef, $sf->{i}{confirm} );
                my $menu = [ @pre, $partition_by, $order_by, $frame_clause ];
                my $tmp_info = $info . "\n" . $sf->__get_win_func_stmt( $win_func_data );
                # Choose
                my $idx_wd = $tc->choose(
                    $menu,
                    { %{$sf->{i}{lyt_v}}, info => $tmp_info, prompt => '', index => 1, default => $old_idx,
                      undef => $sf->{i}{back} }
                );
                if ( ! defined $idx_wd || ! defined $menu->[$idx_wd] ) {
                    if ( @bu ) {
                        $win_func_data = pop @bu;
                        next WINDOW_DEFINITION;
                    }
                    if ( $func =~ /^(?:$count_all_regex|$no_col_func_regex)\z/ ) {
                        next WINDOW_FUNCTION;
                    }
                    next COLUMN;
                }
                if ( $sf->{o}{G}{menu_memory} ) {
                    if ( $old_idx == $idx_wd && ! $ENV{TC_RESET_AUTO_UP} ) {
                        $old_idx = 0;
                        next WINDOW_DEFINITION;
                    }
                    $old_idx = $idx_wd;
                }
                push @bu, { %$win_func_data };
                my $wd = $menu->[$idx_wd];
                if ( $wd eq $sf->{i}{confirm} ) {
                    my $win_func_stmt = $sf->__get_win_func_stmt( $win_func_data );
                    return $win_func_stmt;
                }
                elsif ( $wd eq $partition_by ) {
                    my $ret = $sf->__add_partition_by( $sql, $clause, $qt_cols, $win_func_data );
                    if ( ! $ret ) {
                        pop @bu;
                    }
                }
                elsif ( $wd eq $order_by ) {
                    my $ret = $sf->__add_order_by( $sql, $clause, $qt_cols, $win_func_data );
                    if ( ! $ret ) {
                        pop @bu;
                    }
                }
                elsif ( $wd eq $frame_clause ) {
                    my $ret = $sf->__add_frame_clause( $sql, $clause, $win_func_data );
                    if ( ! $ret ) {
                        pop @bu;
                    }
                }
            }
        }
    }
}


sub __add_partition_by {
    my ( $sf, $sql, $clause, $qt_cols, $win_func_data ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my @partition_by_cols;
    my @pre = ( undef, $sf->{i}{ok} );
    if ( $sf->{o}{enable}{extended_cols} ) {
        push @pre, $sf->{i}{menu_addition};
    }
    my $menu = [ @pre, @$qt_cols ];
    my $info = $ax->get_sql_info( $sql );

    PARTITION_BY: while ( 1 ) {
        my $partition_by_stmt = "PARTITION BY " . join ',', @partition_by_cols;
        my $tmp_info = $info . "\n" . $sf->__get_win_func_stmt( $win_func_data ) . "\n" . $partition_by_stmt;
        # Choose
        my @idx = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_h}}, info => $tmp_info, meta_items => [ 0 .. $#pre - 1 ], no_spacebar => [ $#pre ],
              include_highlighted => 2, index => 1, prompt => 'Columns:' }
        );
        $ax->print_sql_info( $tmp_info );
        if ( ! $idx[0] ) {
            if ( @partition_by_cols ) {
                pop @partition_by_cols;
                next PARTITION_BY;
            }
            return;
        }
        elsif ( $menu->[$idx[0]] eq $sf->{i}{ok} ) {
            shift @idx;
            push @partition_by_cols, @{$menu}[@idx];
            if ( ! @partition_by_cols ) {
                delete $win_func_data->{partition_by_stmt};
            }
            else {
                $win_func_data->{partition_by_stmt} = "PARTITION BY " . join ',', @partition_by_cols;
            }
            return 1;
        }
        elsif ( $menu->[$idx[0]] eq $sf->{i}{menu_addition} ) {
            my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
            my $complex_column = $ext->column(
                $sql, $clause, {},
                { info => $tmp_info, from => 'window_function' }
            );
            if ( defined $complex_column ) {
                push @partition_by_cols, $complex_column;
            }
            next PARTITION_BY;
        }
        push @partition_by_cols, @{$menu}[@idx];
    }
}


sub __add_order_by {
    my ( $sf, $sql, $clause, $qt_cols, $win_func_data ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my @pre = ( undef, $sf->{i}{ok} );
    if ( $sf->{o}{enable}{extended_cols} ) {
        push @pre, $sf->{i}{menu_addition};
    }
    my $info = $ax->get_sql_info( $sql );
    my $col_sep = ' ';
    my $order_by_stmt =  "ORDER BY";
    my @bu;

    ORDER_BY: while ( 1 ) {
        my $tmp_info = $info . "\n" . $sf->__get_win_func_stmt( $win_func_data ) . "\n" . $order_by_stmt;
        # Choose
        my $col = $tc->choose(
            [ @pre, @$qt_cols ],
            { %{$sf->{i}{lyt_h}}, info => $tmp_info, prompt => 'Column:' }
        );
        $ax->print_sql_info( $tmp_info );
        if ( ! defined $col ) {
            if ( @bu ) {
                ( $order_by_stmt, $col_sep ) = @{pop @bu};
                next ORDER_BY;
            }
            delete $win_func_data->{order_by_stmt};
            return
        }
        if ( $col eq $sf->{i}{ok} ) {
            if ( $col_sep eq ' ' ) {
                delete $win_func_data->{order_by_stmt};
            }
            else {
                $win_func_data->{order_by_stmt} = $order_by_stmt;
            }
            return 1;
        }
        elsif ( $col eq $sf->{i}{menu_addition} ) {
            my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
            my $complex_column = $ext->column(
                $sql, $clause, {},
                { info => $tmp_info, from => 'window_function' }
            );
            if ( ! defined $complex_column ) {
                if ( @bu ) {
                    ( $order_by_stmt, $col_sep ) = @{pop @bu};
                }
                next ORDER_BY;
            }
            $col = $complex_column;
        }
        push @bu, [ $order_by_stmt, $col_sep ];
        $order_by_stmt .= $col_sep . $col;
        $tmp_info = $info . "\n" . $sf->__get_win_func_stmt( $win_func_data ) . "\n" . $order_by_stmt;
        # Choose
        my $direction = $tc->choose(
            [ undef, "ASC", "DESC" ],
            { %{$sf->{i}{lyt_h}}, info => $tmp_info, prompt => '' }
        );
        $ax->print_sql_info( $tmp_info );
        if ( ! defined $direction ){
            ( $order_by_stmt, $col_sep ) = @{pop @bu};
            next ORDER_BY;
        }
        $order_by_stmt .= ' ' . $direction;
        $col_sep = ', ';
    }
}


sub __add_frame_clause {
    my ( $sf, $sql, $clause, $win_func_data ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my @frame_clause_modes = ( 'ROWS', 'RANGE' );
    if ( $sf->{i}{driver} =~ /^(?:SQLite|Pg|Oracle)\z/ ) {
        push @frame_clause_modes, 'GROUPS';
    }
    my $info = $ax->get_sql_info( $sql );
    my $win_func_stmt = $sf->__get_win_func_stmt( $win_func_data );
    $info .= "\n" . $win_func_stmt;
    my $old_idx_fc = 0;

     FRAME_CLAUSE: while ( 1 ) {
        my @pre = ( undef );
        my $menu = [ @pre, map { '- ' . $_ } @frame_clause_modes ];
        # Choose
        my $idx_fc = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_v}}, info => $info, index => 1, default => $old_idx_fc, prompt => 'Frame clause:', undef => '  <=' }
        );
        $ax->print_sql_info( $info );
        if ( ! defined $idx_fc || ! defined $menu->[$idx_fc] ) {
            return;
        }
        if ( $sf->{o}{G}{menu_memory} ) {
            if ( $old_idx_fc == $idx_fc && ! $ENV{TC_RESET_AUTO_UP} ) {
                $old_idx_fc = 0;
                next FRAME_CLAUSE;
            }
            $old_idx_fc = $idx_fc;
        }
        my $frame_mode = $frame_clause_modes[$idx_fc-@pre];
        my $frame_clause_data = { frame_mode => $frame_mode };
        my @bu;
        my $old_idx_fe = 0;

        FRAME_END_AND_EXCLUSION: while ( 1 ) {
            my $confirm = 'Confirm';
            my @pre = ( undef, $confirm );
            my ( $frame_start, $frame_end, $frame_exclusion ) = ( '- Add Frame start', '- Add Frame end', '- Add Frame exclusion' );
            my $menu = [ @pre, $frame_start, $frame_end ];
            if ( $sf->{i}{driver} =~ /^(?:SQLite|Pg|Oracle)\z/ ) {
                push @$menu, $frame_exclusion;
            }
            my $tmp_info = $info . "\n" . $sf->__get_frame_clause_stmt( $frame_clause_data );
            # Choose
            my $idx_fe = $tc->choose(
                $menu,
                { %{$sf->{i}{lyt_v}}, info => $tmp_info, index => 1, default => $old_idx_fe, prompt => 'Frame clause:', undef => 'Back' }
            );
            $ax->print_sql_info( $tmp_info );
            if ( ! defined $idx_fe || ! defined $menu->[$idx_fe] ) {
                if ( @bu ) {
                    $frame_clause_data = pop @bu;
                    next FRAME_END_AND_EXCLUSION;
                }
                next FRAME_CLAUSE;
            }
            if ( $sf->{o}{G}{menu_memory} ) {
                if ( $old_idx_fe == $idx_fe && ! $ENV{TC_RESET_AUTO_UP} ) {
                    $old_idx_fe = 0;
                    next FRAME_END_AND_EXCLUSION;
                }
                $old_idx_fe = $idx_fe;
            }
            my $choice = $menu->[$idx_fe];
            if ( $choice eq $confirm ) {
                $win_func_data->{frame_clause} = $sf->__get_frame_clause_stmt( $frame_clause_data );
                return 1;
            }
            push @bu, { %$frame_clause_data };
            if ( $choice eq $frame_start ) {
                my $ret = $sf->__add_frame_start_or_end( $sql, $clause, $frame_clause_data, $info, 'frame_start' );
                if ( ! defined $ret ) {
                    pop @bu;
                    next FRAME_END_AND_EXCLUSION;
                }
            }
            elsif ( $choice eq $frame_end ) {
                my $ret = $sf->__add_frame_start_or_end( $sql, $clause, $frame_clause_data, $info, 'frame_end' );
                if ( ! defined $ret ) {
                    pop @bu;
                    next FRAME_END_AND_EXCLUSION;
                }
            }
            else {
                my $ret = $sf->__add_frame_exclusion( $frame_clause_data, $info );
                if ( ! defined $ret ) {
                    pop @bu;
                    next FRAME_END_AND_EXCLUSION;
                }
            }
        }
    }
}


sub __add_frame_start_or_end {
    my ( $sf, $sql, $clause, $frame_clause_data, $info, $pos ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $tr = Term::Form::ReadLine->new( $sf->{i}{tr_default} );
    my ( @frame_point_types, $prompt );
    if ( $pos eq 'frame_start' ) {
        @frame_point_types = ( 'UNBOUNDED PRECEDING', 'n PRECEDING', 'CURRENT ROW', 'n FOLLOWING' );
        $prompt = 'Frame start:';
    }
    elsif ( $pos eq 'frame_end' ) {
        @frame_point_types = ( 'n PRECEDING', 'CURRENT ROW', 'n FOLLOWING', 'UNBOUNDED FOLLOWING' );
        $prompt = 'Frame end:';
    }
    my $reset = '  Reset';
    my @pre = ( undef );

    FRAME_START: while ( 1 ) {
        my $tmp_info = $info . "\n" . $sf->__get_frame_clause_stmt( $frame_clause_data );
        my $menu = [ @pre, map( '- ' . $_, @frame_point_types ), $reset ];
        # Choose
        my $point = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_v}}, info => $tmp_info, prompt => $prompt, undef => '<=' }
        );
        $ax->print_sql_info( $tmp_info );
        if ( ! defined $point ) {
            return;
        }
        elsif ( $point eq $reset ) {
            delete $frame_clause_data->{$pos};
        }
        else {
            my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
            $point =~ s/-\s//;
            $frame_clause_data->{$pos} = $point;
            if ( $point =~ /^n / ) {
                my $tmp_info = $info . "\n" . $sf->__get_frame_clause_stmt( $frame_clause_data );
                my $offset = $ext->argument( $sql, $clause, { info => $tmp_info, history => undef, prompt => 'n = ' } );
                if ( ! length $offset ) {
                    next FRAME_START;
                }
                $point =~ s/^n/$offset/;
                $frame_clause_data->{$pos} = $point;
            }
        }
        return 1;
    }
}


sub __add_frame_exclusion {
    my ( $sf, $frame_clause_data, $info ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my @exclusion_types = ( 'EXCLUDE CURRENT ROW', 'EXCLUDE GROUP', 'EXCLUDE TIES', 'EXCLUDE NO OTHERS' );
    my $reset = '  Reset';
    my @pre = ( undef );
    my $menu = [ @pre, map( '- ' . $_, @exclusion_types ), $reset ];
    my $tmp_info = $info . "\n" . $sf->__get_frame_clause_stmt( $frame_clause_data );
    # Choose
    my $frame_exclusion = $tc->choose(
        $menu,
        { %{$sf->{i}{lyt_v}}, info => $tmp_info, prompt => 'Frame exclusion:', undef => '<=' }
    );
    $ax->print_sql_info( $tmp_info );
    if ( ! defined $frame_exclusion ) {
        return;
    }
    elsif ( $frame_exclusion eq $reset ) {
        delete $frame_clause_data->{frame_exclusion};
    }
    else {
        $frame_exclusion =~ s/^-\s//;
        $frame_clause_data->{frame_exclusion} = $frame_exclusion;
    }
    return 1;
}


sub __get_frame_clause_stmt {
    my ( $sf, $frame_clause_data ) = @_;
    my $frame_clause_stmt = $frame_clause_data->{frame_mode};
    if ( length $frame_clause_data->{frame_start} && length $frame_clause_data->{frame_end} ) {
        $frame_clause_stmt .= " BETWEEN " . $frame_clause_data->{frame_start} . " AND " . $frame_clause_data->{frame_end};
    }
    elsif ( length $frame_clause_data->{frame_start} ) {
        $frame_clause_stmt .= " " . $frame_clause_data->{frame_start};
    }
    elsif ( length $frame_clause_data->{frame_end} ) {
         $frame_clause_stmt .= " " . $frame_clause_data->{frame_end};
    }
    if ( length $frame_clause_data->{frame_exclusion} ) {
        $frame_clause_stmt .= " " . $frame_clause_data->{frame_exclusion};
    }
    return $frame_clause_stmt;
}




1;


__END__
