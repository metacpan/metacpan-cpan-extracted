package # hide from PAUSE
App::DBBrowser::Table::Extensions::ColAliases;

use warnings;
use strict;
use 5.014;

use List::MoreUtils qw( first_index );

use Term::Choose         qw();
use Term::Form::ReadLine qw();

use App::DBBrowser::Auxil;


sub new {
    my ( $class, $info, $options, $d ) = @_;
    bless {
        i => $info,
        o => $options,
        d => $d
    }, $class;
}


sub column_aliases {
    my ( $sf, $sql ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $tr = Term::Form::ReadLine->new( $sf->{i}{tr_default} );
    my $bu_selected_cols = [ @{$sql->{selected_cols}} ];
    if ( ! @{$sql->{selected_cols}} ) {
        if ( $sql->{aggregate_mode} ) {
            $sql->{selected_cols} = [ @{$sql->{group_by_cols}} ];
        }
        else {
            $sql->{selected_cols} = [ @{$sql->{columns}} ];
        }
    }
    my $bu_table = $sql->{table};
    my $bu_table_alias = $sql->{table_alias};
    my $table_no_alias = $sql->{table};
    if ( length $sql->{table_alias} ) {
        $table_no_alias =~ s/\s\Q$sql->{table_alias}\E\z//;
    }
    my $bu_d_table_aliases = [ @{$sf->{d}{table_aliases}{$table_no_alias}//[]} ];
    my $rearranged = 0;
    my @bu;
    my $old_idx = 0;

    COLUMN: while ( 1 ) {
        my @menu_cols;
        for my $col ( @{$sql->{selected_cols}} ) {
            my $normalized_col = $ax->normalize_space_in_stmt( $col );
            push @menu_cols, '- ' . $normalized_col . ( length $sql->{alias}{$col} ? " as ". $sql->{alias}{$col} : "" );
        }
        my $confirm = $sf->{i}{_confirm};
        my $rearrange = '  Rearrange Cols';
        my $change_table_alias = '  Table Alias';
        my @pre = ( undef, $confirm );
        push @pre, $rearrange;
        if ( $sf->{d}{table_origin} ne 'join' ) {
            push @pre, $change_table_alias;
        }
        my $menu = [ @pre, @menu_cols ];
        my $info = $ax->get_sql_info( $sql );
        # Choose
        my $idx = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_v}}, info => $info, index => 1, default => $old_idx, undef => $sf->{i}{_back} }
        );
        $ax->print_sql_info( $info );
        if ( ! $idx ) {
            if ( @bu ) {
                $sql->{alias} = pop @bu;
                next COLUMN;
            }
            $sql->{table} = $bu_table;
            $sql->{table_alias} = $bu_table_alias;
            $sf->{d}{table_aliases}{$table_no_alias} = $bu_d_table_aliases;
            $sql->{selected_cols} = $bu_selected_cols;
            return;
        }
        if ( $sf->{o}{G}{menu_memory} ) {
            if ( $old_idx == $idx && ! $ENV{TC_RESET_AUTO_UP} ) {
                $old_idx = 0;
                next COLUMN;
            }
            $old_idx = $idx;
        }
        if ( $menu->[$idx] eq $confirm ) {
            if ( ! @$bu_selected_cols && ! keys %{$sql->{alias}} && ! $rearranged ) {
                $sql->{selected_cols} = [];
            }
            return { %{$sql->{alias}} };
        }
        elsif ( $menu->[$idx] eq $rearrange ) {
            $rearranged = $sf->__rearrange_columns( $sql );
            next COLUMN;
        }
        elsif ( $menu->[$idx] eq $change_table_alias ) {
            $sf->__table_alias( $sql, $table_no_alias );
            next COLUMN;
        }
        my $chosen_col = $sql->{selected_cols}[$idx - @pre];
        my $prompt = $ax->normalize_space_in_stmt( $chosen_col );
        my $default = $sql->{alias}{$chosen_col} // '';
        $info = $ax->get_sql_info( $sql );
        # Readline
        my $alias = $tr->readline(
            $prompt . " as ",
            { info => $info, default => $default, history => [ 'a' .. 'z' ] }
        );
        $ax->print_sql_info( $info );
        if ( ( $alias // '' ) eq $default ) {
            next COLUMN;
        }
        if ( ! length $alias ) {
            push @bu, { %{$sql->{alias}} };
            delete $sql->{alias}{$chosen_col};
            next COLUMN;
        }
        push @bu, { %{$sql->{alias}} };
        $sql->{alias}{$chosen_col} = $alias;
    }
}


sub __table_alias {
    my ( $sf, $sql, $table_no_alias ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $type = 'ordinary_table';
    my $bu = $sf->{o}{alias}{$type};
    $sf->{o}{alias}{$type} = 2;
    my $table_alias = $ax->table_alias( $sql, $type, $table_no_alias );
    $sf->{o}{alias}{$type} = $bu;
    if ( length $table_alias ) {
        my $prev_alias = $sql->{table} =~ s/^\Q$table_no_alias\E\s+//r;
        if ( length $prev_alias ) {
            my $first_index = first_index { $_ eq $prev_alias } @{$sf->{d}{table_aliases}{$table_no_alias}};
            if ( $first_index > -1 ) {
                splice( @{$sf->{d}{table_aliases}{$table_no_alias}}, $first_index, 1 );
            }
        }
        $sql->{table} = $table_no_alias . ' ' . $table_alias;
        $sql->{table_alias} = $table_alias;
    }
    return;
}


sub __rearrange_columns {
    my ( $sf, $sql ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my @bu_selected_cols = @{$sql->{selected_cols}};
    $sql->{selected_cols} = [];
    my @pre = ( undef, $sf->{i}{ok} );
    my $menu = [ @pre, @bu_selected_cols ];

    COLUMNS: while ( 1 ) {
        my $info = $ax->get_sql_info( $sql );
        # Choose
        my @idx = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_h}}, info => $info, prompt => 'Rearragne columns:', meta_items => [ 0 .. $#pre - 1 ], no_spacebar => [ $#pre ],
            include_highlighted => 2, index => 1 }
        );
        $ax->print_sql_info( $info );
        if ( ! $idx[0] ) {
            if ( @{$sql->{selected_cols}} ) {
                pop @{$sql->{selected_cols}};
                next COLUMNS;
            }
            $sql->{selected_cols} = [ @bu_selected_cols ];
            return;
        }
        if ( $menu->[$idx[0]] eq $sf->{i}{ok} ) {
            shift @idx;
            if ( @idx ) {
                push @{$sql->{selected_cols}}, @{$menu}[@idx];
            }
            if ( ! @{$sql->{selected_cols}} ) {
                $sql->{selected_cols} = [ @bu_selected_cols ];
                return;
            }
            return 1;
        }
        push @{$sql->{selected_cols}}, @{$menu}[@idx];
    }
}



1

__END__
