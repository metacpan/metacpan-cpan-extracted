package # hide from PAUSE
App::DBBrowser::Table::Extensions::ColumnAliases;

use warnings;
use strict;
use 5.014;

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
    my ( $sf, $sql, $qt_cols ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $tr = Term::Form::ReadLine->new( $sf->{i}{tr_default} );
    my $no_selected_cols = 0;
    if ( ! @{$sql->{selected_cols}} ) {
        $sql->{selected_cols} = [ @$qt_cols ];
        $no_selected_cols = 1;
    }
    my @bu;
    my $old_idx = 0;

    COLUMN: while ( 1 ) {
        my @menu_cols;
        for my $col ( @{$sql->{selected_cols}} ) {
            my $normalized_col = $ax->normalize_space_in_stmt( $col );
            push @menu_cols, $normalized_col . ( length $sql->{alias}{$col} ? " as ". $sql->{alias}{$col} : "" );
        }
        my @pre = ( undef, $sf->{i}{ok} );
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




1
__END__
