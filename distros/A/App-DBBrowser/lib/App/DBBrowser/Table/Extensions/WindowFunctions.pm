package # hide from PAUSE
App::DBBrowser::Table::Extensions::WindowFunctions;

use warnings;
use strict;
use 5.014;

use Term::Choose qw();

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
    my ( $sf, $sql, $clause, $cols, $r_data ) = @_;
    my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my @pre = ( undef );
    if ( $sf->{i}{menu_addition} ) {
        push @pre, $sf->{i}{menu_addition};
    }
    my $info = $ax->get_sql_info( $sql ) . $ext->nested_func_info( $r_data );

    while ( 1 ) {
        # Choose
        my $choice = $tc->choose(
            [ @pre, @$cols ],
            { %{$sf->{i}{lyt_h}}, info => $info, prompt => 'Column:' }
        );
        if ( ! defined $choice ) {
            return;
        }
        elsif ( $choice eq $sf->{i}{menu_addition} ) {
            # from 'window_function': to avoid window function in window function
            my $complex_col = $ext->column(
                $sql, $clause, $r_data,
                { from =>'window_function' }
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
    $win_func_stmt .= sprintf '(%s)', $win_func_data->{args_str} // '';
    my @win_definition;
    for my $stmt ( qw(partition_by_stmt order_by_stmt) ) {
        if ( length $win_func_data->{$stmt} ) {
            push @win_definition, $win_func_data->{$stmt};
        }
    }
    if ( length $win_func_data->{frame_mode} ) {
        push @win_definition, $win_func_data->{frame_mode};
        if ( length $win_func_data->{frame_start} && length $win_func_data->{frame_end} ) {
            push @win_definition,  "BETWEEN " . $win_func_data->{frame_start} . " AND " . $win_func_data->{frame_end};
        }
        elsif ( length $win_func_data->{frame_start} ) {
            push @win_definition, $win_func_data->{frame_start};
        }
        elsif ( length $win_func_data->{frame_end} ) {
            push @win_definition, $win_func_data->{frame_end};
        }
        if ( length $win_func_data->{frame_exclusion} ) {
            push @win_definition, $win_func_data->{frame_exclusion};
        }
    }
    $win_func_stmt .= sprintf ' OVER (%s)', join( ' ',  @win_definition ) // '';
    return $win_func_stmt;
}


sub window_function {
    my ( $sf, $sql, $clause, $cols, $r_data ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $func_count_all = 'COUNT*';
    my $rx_func_count_all = quotemeta $func_count_all;
    my @win_func_aggr = ( 'AVG', 'COUNT', $func_count_all, 'MAX', 'MIN', 'SUM' );
    my @win_func_rank = ( 'CUME_DIST', 'DENSE_RANK', 'NTILE', 'PERCENT_RANK', 'RANK', 'ROW_NUMBER' );
    my @win_func_value = ( 'FIRST_VALUE', 'LAG', 'LAST_VALUE', 'LEAD', 'NTH_VALUE' );

    my @functions = sort( @win_func_aggr, @win_func_rank, @win_func_value );

    my @func_no_col = ( 'CUME_DIST', 'DENSE_RANK', 'PERCENT_RANK', 'RANK', 'ROW_NUMBER' );
    my $rx_func_no_col = join( '|', map { quotemeta } @func_no_col );

    my @func_col_is_number = ( 'NTILE' );
    my $rx_func_col_is_number = join( '|', map { quotemeta } @func_col_is_number );

    my @func_with_offset = ( 'LAG', 'LEAD', 'NTH_VALUE' );
    my $rx_func_with_offset = join( '|', map { quotemeta } @func_with_offset );

    my @func_with_offset_and_default = ( 'LAG', 'LEAD' );
    my $rx_func_with_offset_and_default = join( '|', map { quotemeta } @func_with_offset_and_default );

    my $info_sql = $ax->get_sql_info( $sql );
    push @$r_data, [ 'win' ];
    my $hidden = 'Window function:';
    my $old_idx_wf = 1;

    WINDOW_FUNCTION: while( 1 ) {
        my $win_func_data = {};
        $r_data->[-1] = [ 'win' ];
        my $info = $info_sql . $ext->nested_func_info( $r_data );
        my @pre = ( $hidden, undef );
        my $menu = [ @pre, map { '- ' . $_ } @functions ];
        # Choose
        my $idx_wf = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_v}}, info => $info, prompt => '', index => 1,
              default => $old_idx_wf, undef => '<=' }
        );
        if ( ! defined $idx_wf || ! defined $menu->[$idx_wf] ) {
            pop @$r_data;
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
            next WINDOW_FUNCTION;
        }
        my $func = $functions[$idx_wf-@pre];
        $win_func_data->{func} = $func;
        $r_data->[-1] = [ 'win', $sf->__get_win_func_stmt( $win_func_data ) ];

        COLUMN: while ( 1 ) {
            $win_func_data->{args_str} = '';
            my $col;
            if ( $func =~ /^$rx_func_count_all\z/i ) {
                $col = '*';
                $win_func_data->{func} = $func =~ s/\*\z//r;
            }
            elsif ( $func =~ /^(?:$rx_func_no_col)\z/i ) {
                $col = '';
            }
            elsif ( $func =~ /^(?:$rx_func_col_is_number)\z/i ) {
                # Readline
                $col = $ext->argument(
                    $sql, $clause, $r_data,
                    { history => undef, prompt => 'n = ', is_numeric => 1 }
                );
                if ( ! length $col || $col eq "''" ) {
                    next WINDOW_FUNCTION;
                }
            }
            else {
                $col = $sf->__choose_a_column( $sql, $clause, $cols, $r_data );
                if ( ! defined $col ) {
                    next WINDOW_FUNCTION;
                }
            }
            $win_func_data->{args_str} = $col;
            $r_data->[-1] = [ 'win', $sf->__get_win_func_stmt( $win_func_data ) ];
            if ( $func =~ /^(?:$rx_func_with_offset)\z/i ) {
                # Readline
                my $offset = $ext->argument(
                    $sql, $clause, $r_data,
                    { history => undef, prompt => 'offset: ', is_numeric => 1 }
                );
                if ( length $offset && $offset ne "''" ) {
                    $win_func_data->{args_str} .= ',' . $offset;
                    $r_data->[-1] = [ 'win', $sf->__get_win_func_stmt( $win_func_data ) ];
                    if ( $func =~ /^(?:$rx_func_with_offset_and_default)\z/i ) {
                        my $is_numeric = $ax->is_numeric_datatype( $sql, $col );
                        # Readline
                        my $default_value = $ext->argument(
                            $sql, $clause, $r_data,
                            { history => undef, prompt => 'default: ', is_numeric => $is_numeric }
                        );
                        if ( length $default_value && $default_value ne "''" ) {
                            $win_func_data->{args_str} .= ',' . $default_value;
                            $r_data->[-1] = [ 'win', $sf->__get_win_func_stmt( $win_func_data ) ];
                        }
                    }
                }
            }
            my $old_idx = 0;

            WINDOW_DEFINITION: while( 1 ) {
                my ( $partition_by, $order_by, $frame_clause ) = ( '- Partition by', '- Order by', '- Frame clause' );
                my @pre = ( undef, $sf->{i}{confirm} );
                my $menu = [ @pre, $partition_by, $order_by, $frame_clause ];
                my $info = $info_sql . $ext->nested_func_info( $r_data );
                # Choose
                my $idx_wd = $tc->choose(
                    $menu,
                    { %{$sf->{i}{lyt_v}}, info => $info, prompt => '', index => 1, default => $old_idx,
                      undef => $sf->{i}{back} }
                );
                if ( ! defined $idx_wd || ! defined $menu->[$idx_wd] ) {
                    if ( $win_func_data->{partition_by_stmt} || $win_func_data->{order_by_stmt} || $win_func_data->{frame_mode} ) {
                        $win_func_data = { func => $win_func_data->{func}, args_str => $win_func_data->{args_str} };
                        $r_data->[-1] = [ 'win', $sf->__get_win_func_stmt( $win_func_data ) ];
                        next WINDOW_DEFINITION;
                    }
                    if ( $func =~ /^(?:$rx_func_count_all|$rx_func_no_col)\z/ ) {
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
                my $wd = $menu->[$idx_wd];
                if ( $wd eq $sf->{i}{confirm} ) {
                    pop @$r_data;
                    my $win_func_stmt = $sf->__get_win_func_stmt( $win_func_data );
                    return $win_func_stmt;
                }
                elsif ( $wd eq $partition_by ) {
                    $sf->__add_partition_by( $sql, $clause, $cols, $r_data, $win_func_data );
                }
                elsif ( $wd eq $order_by ) {
                    $sf->__add_order_by( $sql, $clause, $cols, $r_data, $win_func_data );
                }
                elsif ( $wd eq $frame_clause ) {
                    $sf->__add_frame_clause( $sql, $clause, $r_data, $win_func_data );
                }
            }
        }
    }
}


sub __add_partition_by {
    my ( $sf, $sql, $clause, $cols, $r_data, $win_func_data ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    $win_func_data->{partition_by_cols} //= [];
    my @pre = ( undef, $sf->{i}{ok} );
    if ( $sf->{o}{enable}{extended_cols} ) {
        push @pre, $sf->{i}{menu_addition};
    }
    my $menu = [ @pre, @$cols ];
    my $info_sql = $ax->get_sql_info( $sql );

    PARTITION_BY: while ( 1 ) {
        if ( @{$win_func_data->{partition_by_cols}} ) {
            $win_func_data->{partition_by_stmt} = "PARTITION BY " . join ',', @{$win_func_data->{partition_by_cols}};
        }
        else {
            $win_func_data->{partition_by_stmt} = "PARTITION BY";
        }
        $r_data->[-1] = [ 'win', $sf->__get_win_func_stmt( $win_func_data ) ];
        my $info = $info_sql . $ext->nested_func_info( $r_data );
        # Choose
        my @idx = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_h}}, info => $info, meta_items => [ 0 .. $#pre - 1 ], no_spacebar => [ $#pre ],
              include_highlighted => 2, index => 1, prompt => 'Columns:' }
        );
        $ax->print_sql_info( $info );
        if ( ! $idx[0] ) {
            if ( @{$win_func_data->{partition_by_cols}} ) {
                pop @{$win_func_data->{partition_by_cols}};
                next PARTITION_BY;
            }
            delete $win_func_data->{partition_by_stmt};
            $r_data->[-1] = [ 'win', $sf->__get_win_func_stmt( $win_func_data ) ];
            return;
        }
        elsif ( $menu->[$idx[0]] eq $sf->{i}{ok} ) {
            shift @idx;
            push @{$win_func_data->{partition_by_cols}}, @{$menu}[@idx];
            if ( ! @{$win_func_data->{partition_by_cols}} ) {
                delete $win_func_data->{partition_by_stmt};
            }
            else {
                $win_func_data->{partition_by_stmt} = "PARTITION BY " . join ',', @{$win_func_data->{partition_by_cols}};
            }
            $r_data->[-1] = [ 'win', $sf->__get_win_func_stmt( $win_func_data ) ];
            return 1;
        }
        elsif ( $menu->[$idx[0]] eq $sf->{i}{menu_addition} ) {
            my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
            my $complex_column = $ext->column(
                $sql, $clause, $r_data,
                { from => 'window_function' }
            );
            if ( defined $complex_column ) {
                push @{$win_func_data->{partition_by_cols}}, $complex_column;
            }
            next PARTITION_BY;
        }
        push @{$win_func_data->{partition_by_cols}}, @{$menu}[@idx];
    }
}


sub __add_order_by {
    my ( $sf, $sql, $clause, $cols, $r_data, $win_func_data ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    $win_func_data->{order_by_cols} //= [];
    my @pre = ( undef, $sf->{i}{ok} );
    if ( $sf->{o}{enable}{extended_cols} ) {
        push @pre, $sf->{i}{menu_addition};
    }
    my $info_sql = $ax->get_sql_info( $sql );

    ORDER_BY: while ( 1 ) {
        if ( @{$win_func_data->{order_by_cols}} ) {
            $win_func_data->{order_by_stmt} = "ORDER BY " . join ',', @{$win_func_data->{order_by_cols}};
        }
        else {
            $win_func_data->{order_by_stmt} = "ORDER BY";
        }
        $r_data->[-1] = [ 'win', $sf->__get_win_func_stmt( $win_func_data ) ];
        my $info = $info_sql . $ext->nested_func_info( $r_data );
        # Choose
        my $col = $tc->choose(
            [ @pre, @$cols ],
            { %{$sf->{i}{lyt_h}}, info => $info, prompt => 'Column:' }
        );
        $ax->print_sql_info( $info );
        if ( ! defined $col ) {
            if ( @{$win_func_data->{order_by_cols}} ) {
                pop @{$win_func_data->{order_by_cols}};
                next ORDER_BY;
            }
            delete $win_func_data->{order_by_stmt};
            $r_data->[-1] = [ 'win', $sf->__get_win_func_stmt( $win_func_data ) ];
            return
        }
        if ( $col eq $sf->{i}{ok} ) {
            if ( ! @{$win_func_data->{order_by_cols}} ) {
                delete $win_func_data->{order_by_stmt};
            }
            else {
                $win_func_data->{order_by_stmt} = "ORDER BY " . join ',', @{$win_func_data->{order_by_cols}};
            }
            $r_data->[-1] = [ 'win', $sf->__get_win_func_stmt( $win_func_data ) ];
            return 1;
        }
        elsif ( $col eq $sf->{i}{menu_addition} ) {
            my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
            my $complex_column = $ext->column(
                $sql, $clause, $r_data,
                { from => 'window_function' }
            );
            if ( ! defined $complex_column ) {
                next ORDER_BY;
            }
            $col = $complex_column;
        }
        push @{$win_func_data->{order_by_cols}}, $col;
        $win_func_data->{order_by_stmt} = "ORDER BY " . join ',', @{$win_func_data->{order_by_cols}};
        $r_data->[-1] = [ 'win', $sf->__get_win_func_stmt( $win_func_data ) ];
        $info = $info_sql . $ext->nested_func_info( $r_data );
        # Choose
        my $direction = $tc->choose(
            [ undef, "ASC", "DESC" ],
            { %{$sf->{i}{lyt_h}}, info => $info }
        );
        $ax->print_sql_info( $info );
        if ( ! defined $direction ){
            pop @{$win_func_data->{order_by_cols}};
            next ORDER_BY;
        }
        else {
            $win_func_data->{order_by_cols}[-1] .= ' ' . $direction;
        }
    }
}


sub __add_frame_clause {
    my ( $sf, $sql, $clause, $r_data, $win_func_data ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my @frame_clause_modes = ( 'ROWS', 'RANGE' );
    if ( $sf->{i}{driver} =~ /^(?:SQLite|Pg|Oracle)\z/ ) {
        push @frame_clause_modes, 'GROUPS';
    }
    my $info_sql = $ax->get_sql_info( $sql );
    my $old_idx_fc = 0;

     FRAME_CLAUSE: while ( 1 ) {
        my $info = $info_sql . $ext->nested_func_info( $r_data );
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
        $win_func_data->{frame_mode} = $frame_mode;
        $r_data->[-1] = [ 'win', $sf->__get_win_func_stmt( $win_func_data ) ];
        my $old_idx_fe = 0;

        FRAME_END_AND_EXCLUSION: while ( 1 ) {
            my $confirm = 'Confirm';
            my @pre = ( undef, $confirm );
            my ( $frame_start, $frame_end, $frame_exclusion ) = ( '- Add Frame start', '- Add Frame end', '- Add Frame exclusion' );
            my $menu = [ @pre, $frame_start, $frame_end ];
            if ( $sf->{i}{driver} =~ /^(?:SQLite|Pg|Oracle)\z/ ) {
                push @$menu, $frame_exclusion;
            }
            my $info = $info_sql . "\n" . $sf->__get_win_func_stmt( $win_func_data );
            # Choose
            my $idx_fe = $tc->choose(
                $menu,
                { %{$sf->{i}{lyt_v}}, info => $info, index => 1, default => $old_idx_fe, prompt => 'Frame clause:', undef => 'Back' }
            );
            $ax->print_sql_info( $info );
            if ( ! defined $idx_fe || ! defined $menu->[$idx_fe] ) {
                if ( $win_func_data->{frame_start} || $win_func_data->{frame_end} || $win_func_data->{frame_exclusion} ) {
                    delete @{$win_func_data}{qw(frame_start frame_end frame_exclusion)};
                    $r_data->[-1] = [ 'win', $sf->__get_win_func_stmt( $win_func_data ) ];
                    next FRAME_END_AND_EXCLUSION;
                }
                delete $win_func_data->{frame_mode};
                $r_data->[-1] = [ 'win', $sf->__get_win_func_stmt( $win_func_data ) ];
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
                return 1;
            }
            if ( $choice eq $frame_start ) {
                $sf->__add_frame_start_or_end( $sql, $clause, $r_data, $win_func_data, 'frame_start' );
            }
            elsif ( $choice eq $frame_end ) {
                $sf->__add_frame_start_or_end( $sql, $clause, $r_data, $win_func_data, 'frame_end' );
            }
            else {
                $sf->__add_frame_exclusion( $sql, $r_data, $win_func_data );
            }
        }
    }
}


sub __add_frame_start_or_end {
    my ( $sf, $sql, $clause, $r_data, $win_func_data, $pos ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my ( @frame_point_types, $prompt );
    if ( $pos eq 'frame_start' ) {
        @frame_point_types = ( 'UNBOUNDED PRECEDING', 'n PRECEDING', 'CURRENT ROW', 'n FOLLOWING' );
        $prompt = 'Frame start:';
    }
    elsif ( $pos eq 'frame_end' ) {
        @frame_point_types = ( 'n PRECEDING', 'CURRENT ROW', 'n FOLLOWING', 'UNBOUNDED FOLLOWING' );
        $prompt = 'Frame end:';
    }
    my $confirm = '-OK-';
    my @pre = ( undef, $confirm );
    my $info_sql = $ax->get_sql_info( $sql );

    FRAME_START: while ( 1 ) {
        my $info = $info_sql . $ext->nested_func_info( $r_data );
        my $menu = [ @pre, map( '- ' . $_, @frame_point_types ) ];
        # Choose
        my $point = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_v}}, info => $info, prompt => $prompt, undef => '<=' }
        );
        $ax->print_sql_info( $info );
        if ( ! defined $point ) {
            delete $win_func_data->{$pos};
            $r_data->[-1] = [ 'win', $sf->__get_win_func_stmt( $win_func_data ) ];
            return;
        }
        elsif ( $point eq $confirm ) {
            return 1;
        }
        else {
            my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
            $point =~ s/-\s//;
            $win_func_data->{$pos} = $point;
            $r_data->[-1] = [ 'win', $sf->__get_win_func_stmt( $win_func_data ) ];
            if ( $point =~ /^n / ) {
                my $offset = $ext->argument(
                    $sql, $clause, $r_data,
                    { history => undef, prompt => 'n = ', is_numeric => 1 }
                );
                if ( ! length $offset || $offset eq "''" ) {
                    delete $win_func_data->{$pos};
                    $r_data->[-1] = [ 'win', $sf->__get_win_func_stmt( $win_func_data ) ];
                    next FRAME_START;
                }
                $point =~ s/^n/$offset/;
                $win_func_data->{$pos} = $point;
                $r_data->[-1] = [ 'win', $sf->__get_win_func_stmt( $win_func_data ) ];
            }
        }
    }
}


sub __add_frame_exclusion {
    my ( $sf, $sql, $r_data, $win_func_data ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my @exclusion_types = ( 'EXCLUDE CURRENT ROW', 'EXCLUDE GROUP', 'EXCLUDE TIES', 'EXCLUDE NO OTHERS' );
    my $confirm = '-OK-';
    my @pre = ( undef, $confirm );
    my $menu = [ @pre, map( '- ' . $_, @exclusion_types ) ];

    FRAME_EXCLUSION: while ( 1 ) {
        my $info = $ax->get_sql_info( $sql ) . $ext->nested_func_info( $r_data );
        # Choose
        my $frame_exclusion = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_v}}, info => $info, prompt => 'Frame exclusion:', undef => '<=' }
        );
        $ax->print_sql_info( $info );
        if ( ! defined $frame_exclusion ) {
            delete $win_func_data->{frame_exclusion};
            $r_data->[-1] = [ 'win', $sf->__get_win_func_stmt( $win_func_data ) ];
            return;
        }
        elsif ( $frame_exclusion eq $confirm ) {
            return 1;
        }
        else {
            $frame_exclusion =~ s/^-\s//;
            $win_func_data->{frame_exclusion} = $frame_exclusion;
            $r_data->[-1] = [ 'win', $sf->__get_win_func_stmt( $win_func_data ) ];
        }
    }
}



1;

__END__
