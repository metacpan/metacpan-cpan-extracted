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
    my ( $sf, $sql, $cols ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $tr = Term::Form::ReadLine->new( $sf->{i}{tr_default} );
    my $no_selected_cols = 0;
    if ( ! @{$sql->{selected_cols}} ) {
        $sql->{selected_cols} = [ @$cols ];
        $no_selected_cols = 1;
    }
    my $bu_table = $sql->{table};
    my $table_no_alias = $ax->qq_table( $sf->{d}{tables_info}{$sf->{d}{table_key}} );
    my $bu_table_aliases = [ @{$sf->{d}{table_aliases}{$table_no_alias}//[]} ];
    my @bu;
    my $old_idx = 0;

    COLUMN: while ( 1 ) {
        my @menu_cols;
        for my $col ( @{$sql->{selected_cols}} ) {
            my $normalized_col = $ax->normalize_space_in_stmt( $col );
            push @menu_cols, $normalized_col . ( length $sql->{alias}{$col} ? " as ". $sql->{alias}{$col} : "" );
        }
        my $table_alias = '<Table>';
        my @pre = ( undef, $sf->{i}{ok}, $table_alias );
        my $menu = [ @pre, @menu_cols ];
        my $info = $ax->get_sql_info( $sql );
        # Choose
        my $idx = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_v}}, prompt => '', info => $info, index => 1, default => $old_idx, undef => '<<' }
        );
        $ax->print_sql_info( $info );
        if ( ! $idx ) {
            if ( @bu ) {
                $sql->{alias} = pop @bu;
                next COLUMN;
            }
            if ( $no_selected_cols ) {
                $sql->{selected_cols} = [];
            }
            $sql->{table} = $bu_table;
            $sf->{d}{table_aliases}{$table_no_alias} = $bu_table_aliases;
            return;
        }
        if ( $sf->{o}{G}{menu_memory} ) {
            if ( $old_idx == $idx && ! $ENV{TC_RESET_AUTO_UP} ) {
                $old_idx = 0;
                next COLUMN;
            }
            $old_idx = $idx;
        }
        if ( $menu->[$idx] eq $sf->{i}{ok} ) {
            if ( $no_selected_cols && ! keys %{$sql->{alias}} ) {
                $sql->{selected_cols} = [];
            }
            return { %{$sql->{alias}} };
        }
        elsif ( $menu->[$idx] eq $table_alias ) {
            $sf->__table_alias( $sql, $table_no_alias );
            next COLUMN;
        }
        my $chosen_col = $sql->{selected_cols}[$idx - @pre];
        my $prompt = $ax->normalize_space_in_stmt( $chosen_col );
        $info = $ax->get_sql_info( $sql );
        # Readline
        my $alias = $tr->readline(
            $prompt . " as ",
            { info => $info, default => $sql->{alias}{$chosen_col}, history => [ 'a' .. 'z' ] }
        );
        $ax->print_sql_info( $info );
        if ( ! length $alias ) {
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
    }
    return;
}



1

__END__
