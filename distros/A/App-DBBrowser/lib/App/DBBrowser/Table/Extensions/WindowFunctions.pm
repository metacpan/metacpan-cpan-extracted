package # hide from PAUSE
App::DBBrowser::Table::Extensions::WindowFunctions;

use warnings;
use strict;
use 5.016;

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
                { from => 'window_function' }
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
    my ( $sf, $win_data, $placeholder ) = @_;
    $placeholder //= '';
    my @parts;
    my $win_stmt = $win_data->{'func'};
    $win_stmt .= '(' . $win_data->{'args_str'} // '';
    if ( $placeholder eq 'args_str' ) {
        push @parts, $win_stmt;
        $win_stmt = '';
    }
    $win_stmt .= ') OVER (';
    if ( length $win_data->{'partition_by_stmt'} ) {
        $win_stmt .= $win_data->{'partition_by_stmt'} . " ";
    }
    if ( $placeholder eq 'partition_by_stmt' ) {
        push @parts, $win_stmt;
        $win_stmt = '';
    }
    if ( length $win_data->{'order_by_stmt'} ) {
        $win_stmt .= $win_data->{'order_by_stmt'} . " ";
    }
    if ( $placeholder eq 'order_by_stmt' ) {
        push @parts, $win_stmt;
        $win_stmt = '';
    }
    if ( length $win_data->{'frame_mode'} ) {
        $win_stmt .= $win_data->{'frame_mode'} . " ";
        if ( length $win_data->{'frame_start'} || $placeholder eq 'frame_start' ) {
            if ( length $win_data->{'frame_end'} || $placeholder eq 'frame_end' ) {
                $win_stmt .= "BETWEEN ";
            }
            if ( length $win_data->{'frame_start'} ) {
                $win_stmt .= $win_data->{'frame_start'} . " ";
            }
            if ( $placeholder eq 'frame_start' ) {
                push @parts, $win_stmt;
                $win_stmt = '';
            }
        }
        if ( length $win_data->{'frame_end'} || $placeholder eq 'frame_end' ) {
            if ( length $win_data->{'frame_start'} || $placeholder eq 'frame_start' ) {
                $win_stmt .= "AND ";
            }
            if ( length $win_data->{'frame_end'} ) {
                $win_stmt .= $win_data->{'frame_end'} . " ";
            }
            if ( $placeholder eq 'frame_end' ) {
                push @parts, $win_stmt;
                $win_stmt = '';
            }
        }
        if ( length $win_data->{'frame_exclusion'} ) {
            $win_stmt .= $win_data->{'frame_exclusion'};
        }
        if ( $placeholder eq 'frame_exclusion' ) {
            push @parts, $win_stmt;
            $win_stmt = '';
        }
    }
    if ( $placeholder eq 'frame_mode' ) {
        push @parts, $win_stmt;
        $win_stmt = '';
    }
    if ( ! $placeholder ) {
        push @parts, $win_stmt;
        $win_stmt = '';
    }
    $parts[0] =~ s/\s+\z//;
    $win_stmt =~ s/\s+\z//;
    $win_stmt .= ')';
    push @parts, $win_stmt;
    return @parts;
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

    my @func_with_offset_and_default = ( 'LAG', 'LEAD' ); # not if MariaDB ##
    my $rx_func_with_offset_and_default = join( '|', map { quotemeta } @func_with_offset_and_default );
    my $info_sql = $ax->get_sql_info( $sql );
    push @$r_data, [ 'win' ];
    my $hidden = 'Window function:';
    my $old_idx_wf = 1;

    WINDOW_FUNCTION: while( 1 ) {
        my $win_data = {};
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
        $win_data->{'func'} = $func;

        COLUMN: while ( 1 ) {
            $win_data->{'args_str'} = '';
            $r_data->[-1] = [ 'win', $sf->__get_win_func_stmt( $win_data, 'args_str' ) ];
            my $col;
            if ( $func =~ /^$rx_func_count_all\z/i ) {
                $col = '*';
                $win_data->{'func'} = $func =~ s/\*\z//r;
            }
            elsif ( $func =~ /^(?:$rx_func_no_col)\z/i ) {
                $col = '';
            }
            elsif ( $func =~ /^(?:$rx_func_col_is_number)\z/i ) {
                # Readline
                $col = $ext->argument(
                    $sql, $clause, $r_data,
                    { history => undef, prompt => 'n = ', is_numeric => 1, from => 'window_function' }
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
            $win_data->{'args_str'} = $col;
            if ( $func =~ /^(?:$rx_func_with_offset)\z/i ) {
                $r_data->[-1] = [ 'win', $sf->__get_win_func_stmt( $win_data, 'args_str' ) ];
                # Readline
                my $offset = $ext->argument(
                    $sql, $clause, $r_data,
                    { prompt => 'offset: ', is_numeric => 1 }
                );
                if ( length $offset && $offset ne "''" ) {
                    $win_data->{'args_str'} .= ',' . $offset;
                    if ( $func =~ /^(?:$rx_func_with_offset_and_default)\z/i ) {
                        $r_data->[-1] = [ 'win', $sf->__get_win_func_stmt( $win_data, 'args_str' ) ];
                        my $is_numeric = $ax->is_numeric( $sql, $col );
                        # Readline
                        my $default_value = $ext->argument(
                            $sql, $clause, $r_data,
                            { prompt => 'default: ', is_numeric => $is_numeric, from => 'window_function' }
                        );
                        if ( length $default_value && $default_value ne "''" ) {
                            $win_data->{'args_str'} .= ',' . $default_value;
                            #$r_data->[-1] = [ 'win', $sf->__get_win_func_stmt( $win_data ) ];
                        }
                    }
                }
            }
            my $old_idx = 0;

            WINDOW_DEFINITION: while( 1 ) {
                my ( $partition_by, $order_by, $frame_clause ) = ( '- Partition by', '- Order by', '- Frame clause' );
                my @pre = ( undef, $sf->{i}{confirm} );
                my $menu = [ @pre, $partition_by, $order_by, $frame_clause ];
                $r_data->[-1] = [ 'win', $sf->__get_win_func_stmt( $win_data ) ];
                my $info = $info_sql . $ext->nested_func_info( $r_data );
                # Choose
                my $idx_wd = $tc->choose(
                    $menu,
                    { %{$sf->{i}{lyt_v}}, info => $info, prompt => '', index => 1, default => $old_idx,
                      undef => $sf->{i}{back} }
                );
                if ( ! defined $idx_wd || ! defined $menu->[$idx_wd] ) {
                    if ( $win_data->{'partition_by_stmt'} || $win_data->{'order_by_stmt'} || $win_data->{'frame_mode'} ) {
                        $win_data = { func => $win_data->{'func'}, args_str => $win_data->{'args_str'} };
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
                    my @parts = $sf->__get_win_func_stmt( $win_data );
                    return join '', @parts;
                }
                elsif ( $wd eq $partition_by ) {
                    $sf->__add_partition_by( $sql, $clause, $cols, $r_data, $win_data );
                }
                elsif ( $wd eq $order_by ) {
                    $sf->__add_order_by( $sql, $clause, $cols, $r_data, $win_data );
                }
                elsif ( $wd eq $frame_clause ) {
                    $sf->__add_frame_clause( $sql, $clause, $r_data, $win_data );
                }
            }
        }
    }
}


sub __add_partition_by {
    my ( $sf, $sql, $clause, $cols, $r_data, $win_data ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    $win_data->{'partition_by_cols'} //= [];
    my @pre = ( undef, $sf->{i}{ok} );
    if ( $sf->{o}{enable}{extended_cols} ) {
        push @pre, $sf->{i}{menu_addition};
    }
    my $menu = [ @pre, @$cols ];
    my $info_sql = $ax->get_sql_info( $sql );

    PARTITION_BY: while ( 1 ) {
        if ( @{$win_data->{'partition_by_cols'}} ) {
            $win_data->{'partition_by_stmt'} = "PARTITION BY " . join ',', @{$win_data->{'partition_by_cols'}};
        }
        else {
            $win_data->{'partition_by_stmt'} = "PARTITION BY";
        }
        $r_data->[-1] = [ 'win', $sf->__get_win_func_stmt( $win_data, 'partition_by_stmt' ) ];
        my $info = $info_sql . $ext->nested_func_info( $r_data );
        my $prompt = 'Partition by:';
        # Choose
        my @idx = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_h}}, info => $info, meta_items => [ 0 .. $#pre - 1 ], no_spacebar => [ $#pre ],
              include_highlighted => 2, index => 1, prompt => $prompt }
        );
        $ax->print_sql_info( $info );
        if ( ! $idx[0] ) {
            if ( @{$win_data->{'partition_by_cols'}} ) {
                pop @{$win_data->{'partition_by_cols'}};
                next PARTITION_BY;
            }
            delete $win_data->{'partition_by_stmt'};
            return;
        }
        elsif ( $menu->[$idx[0]] eq $sf->{i}{ok} ) {
            shift @idx;
            push @{$win_data->{'partition_by_cols'}}, @{$menu}[@idx];
            if ( ! @{$win_data->{'partition_by_cols'}} ) {
                delete $win_data->{'partition_by_stmt'};
            }
            else {
                $win_data->{'partition_by_stmt'} = "PARTITION BY " . join ',', @{$win_data->{'partition_by_cols'}};
            }
            return 1;
        }
        elsif ( $menu->[$idx[0]] eq $sf->{i}{menu_addition} ) {
            my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
            my $complex_column = $ext->column(
                $sql, $clause, $r_data,
                { from => 'window_function' }
            );
            if ( defined $complex_column ) {
                push @{$win_data->{'partition_by_cols'}}, $complex_column;
            }
            next PARTITION_BY;
        }
        push @{$win_data->{'partition_by_cols'}}, @{$menu}[@idx];
    }
}


sub __add_order_by {
    my ( $sf, $sql, $clause, $cols, $r_data, $win_data ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    $win_data->{'order_by_cols'} //= [];
    my @pre = ( undef, $sf->{i}{ok} );
    if ( $sf->{o}{enable}{extended_cols} ) {
        push @pre, $sf->{i}{menu_addition};
    }
    my $info_sql = $ax->get_sql_info( $sql );

    ORDER_BY: while ( 1 ) {
        if ( @{$win_data->{'order_by_cols'}} ) {
            $win_data->{'order_by_stmt'} = "ORDER BY " . join ',', @{$win_data->{'order_by_cols'}};
        }
        else {
            $win_data->{'order_by_stmt'} = "ORDER BY";
        }
        $r_data->[-1] = [ 'win', $sf->__get_win_func_stmt( $win_data, 'order_by_stmt' ) ];
        my $info = $info_sql . $ext->nested_func_info( $r_data );
        my $prompt = 'Order by:';
        # Choose
        my $col = $tc->choose(
            [ @pre, @$cols ],
            { %{$sf->{i}{lyt_h}}, info => $info, prompt => $prompt }
        );
        $ax->print_sql_info( $info );
        if ( ! defined $col ) {
            if ( @{$win_data->{'order_by_cols'}} ) {
                pop @{$win_data->{'order_by_cols'}};
                next ORDER_BY;
            }
            delete $win_data->{'order_by_stmt'};
            return
        }
        if ( $col eq $sf->{i}{ok} ) {
            if ( ! @{$win_data->{'order_by_cols'}} ) {
                delete $win_data->{'order_by_stmt'};
            }
            else {
                $win_data->{'order_by_stmt'} = "ORDER BY " . join ',', @{$win_data->{'order_by_cols'}};
            }
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
        push @{$win_data->{'order_by_cols'}}, $col;
        $win_data->{'order_by_stmt'} = "ORDER BY " . join ',', @{$win_data->{'order_by_cols'}};
        $r_data->[-1] = [ 'win', $sf->__get_win_func_stmt( $win_data, 'order_by_stmt' ) ];
        $info = $info_sql . $ext->nested_func_info( $r_data );
        # Choose
        my $direction = $tc->choose(
            [ undef, "ASC", "DESC" ],
            { %{$sf->{i}{lyt_h}}, info => $info }
        );
        $ax->print_sql_info( $info );
        if ( ! defined $direction ){
            pop @{$win_data->{'order_by_cols'}};
            next ORDER_BY;
        }
        else {
            $win_data->{'order_by_cols'}[-1] .= ' ' . $direction;
        }
    }
}


sub __add_frame_clause {
    my ( $sf, $sql, $clause, $r_data, $win_data ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $dbms = $sf->{i}{dbms};
    my @frame_clause_modes = ( 'ROWS', 'RANGE' );
    if ( $dbms =~ /^(?:SQLite|Pg|DuckDB|Oracle)\z/ ) {
        push @frame_clause_modes, 'GROUPS';
    }
    if ( ! length $win_data->{'frame_mode'} ) {
        $r_data->[-1] = [ 'win', $sf->__get_win_func_stmt( $win_data, 'frame_mode' ) ];
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
        $win_data->{'frame_mode'} = $frame_mode;
        my $old_idx_fe = 0;

        FRAME_END_AND_EXCLUSION: while ( 1 ) {
            my $confirm = $sf->{i}{confirm};
            my $back = $sf->{i}{back};
            my @pre = ( undef, $confirm );
            my ( $frame_start, $frame_end, $frame_exclusion ) = ( '- Add Frame start', '- Add Frame end', '- Add Frame exclusion' );
            my $menu = [ @pre, $frame_start, $frame_end ];
            if ( $dbms =~ /^(?:SQLite|Pg|DuckDB|Oracle)\z/ ) {
                push @$menu, $frame_exclusion;
            }
            $r_data->[-1] = [ 'win', $sf->__get_win_func_stmt( $win_data, 'frame_mode' ) ];
            my $info = $info_sql . $ext->nested_func_info( $r_data );
            # Choose
            my $idx_fe = $tc->choose(
                $menu,
                { %{$sf->{i}{lyt_v}}, info => $info, index => 1, default => $old_idx_fe, prompt => 'Frame clause:', undef => $back }
            );
            $ax->print_sql_info( $info );
            if ( ! defined $idx_fe || ! defined $menu->[$idx_fe] ) {
                if ( $win_data->{'frame_start'} || $win_data->{'frame_end'} || $win_data->{'frame_exclusion'} ) {
                    delete @{$win_data}{qw(frame_start frame_end frame_exclusion)};
                    next FRAME_END_AND_EXCLUSION;
                }
                delete $win_data->{'frame_mode'};
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
                $sf->__add_frame_start_or_end( $sql, $clause, $r_data, $win_data, 'frame_start' );
            }
            elsif ( $choice eq $frame_end ) {
                $sf->__add_frame_start_or_end( $sql, $clause, $r_data, $win_data, 'frame_end' );
            }
            else {
                $sf->__add_frame_exclusion( $sql, $r_data, $win_data );
            }
        }
    }
}


sub __add_frame_start_or_end {
    my ( $sf, $sql, $clause, $r_data, $win_data, $pos ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $dbms = $sf->{i}{dbms};
    my ( @frame_point_types, $prompt );
    if ( $pos eq 'frame_start' ) {
        if ( $win_data->{'frame_mode'} eq 'RANGE' && $dbms eq 'MSSQL' ) {
            @frame_point_types = ( 'UNBOUNDED PRECEDING', 'CURRENT ROW' );
        }
        else {
            @frame_point_types = ( 'UNBOUNDED PRECEDING', 'n PRECEDING', 'CURRENT ROW', 'n FOLLOWING' );
        }
        $prompt = 'Frame start:';
    }
    elsif ( $pos eq 'frame_end' ) {
        if ( $win_data->{'frame_mode'} eq 'RANGE' && $dbms eq 'MSSQL' ) {
            @frame_point_types = ( 'CURRENT ROW', 'UNBOUNDED FOLLOWING' );
        }
        else {
            @frame_point_types = ( 'n PRECEDING', 'CURRENT ROW', 'n FOLLOWING', 'UNBOUNDED FOLLOWING' );
        }
        $prompt = 'Frame end:';
    }
    my $info_sql = $ax->get_sql_info( $sql );

    FRAME_START: while ( 1 ) {
        if ( ! length $win_data->{$pos} ) {
            $r_data->[-1] = [ 'win', $sf->__get_win_func_stmt( $win_data, $pos ) ];
        }
        else {
            $r_data->[-1] = [ 'win', $sf->__get_win_func_stmt( $win_data ) ];
        }
        my $info = $info_sql . $ext->nested_func_info( $r_data );
        my $confirm = $sf->{i}{ok};
        my @pre = ( undef, $confirm );
        my $menu = [ @pre, map( '- ' . $_, @frame_point_types ) ];
        # Choose
        my $point = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_v}}, info => $info, prompt => $prompt, undef => '<=' }
        );
        $ax->print_sql_info( $info );
        if ( ! defined $point ) {
            delete $win_data->{$pos};
            return;
        }
        elsif ( $point eq $confirm ) {
            return 1;
        }
        else {
            my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
            $point =~ s/-\s//;
            $win_data->{$pos} = $point;
            $r_data->[-1] = [ 'win', $sf->__get_win_func_stmt( $win_data ) ];
            if ( $point =~ /^n / ) {
                my $offset = $ext->argument(
                    $sql, $clause, $r_data,
                    { history => undef, prompt => 'n = ', is_numeric => 1 }
                );
                if ( ! length $offset || $offset eq "''" ) {
                    delete $win_data->{$pos};
                    next FRAME_START;
                }
                $point =~ s/^n/$offset/;
                $win_data->{$pos} = $point;
            }
        }
    }
}


sub __add_frame_exclusion {
    my ( $sf, $sql, $r_data, $win_data ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my @exclusion_types = ( 'EXCLUDE CURRENT ROW', 'EXCLUDE GROUP', 'EXCLUDE TIES', 'EXCLUDE NO OTHERS' );
    my $info_sql = $ax->get_sql_info( $sql );

    FRAME_EXCLUSION: while ( 1 ) {
        if ( ! length $win_data->{'frame_exclusion'} ) {
            $r_data->[-1] = [ 'win', $sf->__get_win_func_stmt( $win_data, 'frame_exclusion' ) ];
        }
        else {
            $r_data->[-1] = [ 'win', $sf->__get_win_func_stmt( $win_data ) ];
        }
        my $info = $info_sql . $ext->nested_func_info( $r_data );
        my $confirm = $sf->{i}{ok};
        my @pre = ( undef, $confirm );
        my $menu = [ @pre, map( '- ' . $_, @exclusion_types ) ];
        # Choose
        my $frame_exclusion = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_v}}, info => $info, prompt => 'Frame exclusion:', undef => '<=' }
        );
        $ax->print_sql_info( $info );
        if ( ! defined $frame_exclusion ) {
            delete $win_data->{'frame_exclusion'};
            return;
        }
        elsif ( $frame_exclusion eq $confirm ) {
            return 1;
        }
        else {
            $frame_exclusion =~ s/^-\s//;
            $win_data->{'frame_exclusion'} = $frame_exclusion;
        }
    }
}



1;

__END__
