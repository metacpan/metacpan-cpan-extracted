package # hide from PAUSE
App::DBBrowser::Union;

use warnings;
use strict;
use 5.010001;

use List::MoreUtils qw( any );

use Term::Choose qw();

use App::DBBrowser::Auxil;


sub new {
    my ( $class, $info, $options, $data ) = @_;
    bless {
        i => $info,
        o => $options,
        d => $data
    }, $class;
}


sub union_tables {
    my ( $sf ) = @_;
    $sf->{i}{stmt_types} = [ 'Union' ];
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $tables = [ @{$sf->{d}{user_tables}}, @{$sf->{d}{sys_tables}} ];
    ( $sf->{d}{col_names}, $sf->{d}{col_types} ) = $ax->column_names_and_types( $tables );
    my $union = {
        used_tables    => [],
        subselect_data => [],
        saved_cols     => [],
    };
    my $unique_char = 'A';
    my @bu;

    UNION_TABLE: while ( 1 ) {
        my $enough_tables = '  Enough TABLES';
        my $from_subquery = '  Derived';
        my $all_tables    = '  All Tables';
        my @pre  = ( undef, $enough_tables );
        my @post;
        push @post, $from_subquery if $sf->{o}{enable}{u_derived};
        push @post, $all_tables    if $sf->{o}{enable}{union_all};
        my $used = ' (used)';
        my @tmp_tables;
        for my $table ( @$tables ) {
            if ( any { $_ eq $table } @{$union->{used_tables}} ) {
                push @tmp_tables, '- ' . $table . $used;
            }
            else {
                push @tmp_tables, '- ' . $table;
            }
        }
        my $prompt = 'Choose UNION table:';
        my $menu  = [ @pre, @tmp_tables, @post ];
        $ax->print_sql( $union );
        # Choose
        my $idx_tbl = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_v}}, prompt => $prompt, index => 1 }
        );
        if ( ! defined $idx_tbl || ! defined $menu->[$idx_tbl] ) {
            if ( @bu ) {
                ( $union->{used_tables}, $union->{subselect_data}, $union->{saved_cols} ) = @{pop @bu};
                next UNION_TABLE;
            }
            return;
        }
        my $union_table = $menu->[$idx_tbl];
        my $qt_union_table;
        if ( $union_table eq $enough_tables ) {
            if ( ! @{$union->{subselect_data}} ) {
                return;
            }
            last UNION_TABLE;
        }
        elsif ( $union_table eq $all_tables ) {
            my $ok = $sf->__union_all_tables( $union );
            if ( ! $ok ) {
                next UNION_TABLE;
            }
            last UNION_TABLE;
        }
        elsif ( $union_table eq $from_subquery ) {
            require App::DBBrowser::Subqueries;
            my $sq = App::DBBrowser::Subqueries->new( $sf->{i}, $sf->{o}, $sf->{d} );
            $union_table = $sq->choose_subquery( $union );
            if ( ! defined $union_table ) {
                next UNION_TABLE;
            }
            my $default_alias = 'U_TBL_' . $unique_char++;
            my $alias = $ax->alias( 'union', $union_table, $default_alias );
            $qt_union_table = $union_table . " AS " . $ax->quote_col_qualified( [ $alias ] );
            my $sth = $sf->{d}{dbh}->prepare( "SELECT * FROM " . $qt_union_table . " LIMIT 0" );
            $sth->execute() if $sf->{i}{driver} ne 'SQLite';
            $sf->{d}{col_names}{$union_table} = $sth->{NAME};
        }
        else {
            $union_table =~ s/^-\s//;
            $union_table =~ s/\Q$used\E\z//;
            $qt_union_table = $ax->quote_table( $sf->{d}{tables_info}{$union_table} );
        }
        push @bu, [ [ @{$union->{used_tables}} ], [ @{$union->{subselect_data}} ], [ @{$union->{saved_cols}} ] ];
        push @{$union->{used_tables}}, $union_table;
        $ax->print_sql( $union );
        my $ok = $sf->__union_table_columns( $union, $union_table, $qt_union_table );
        if ( ! $ok ) {
            ( $union->{used_tables}, $union->{subselect_data}, $union->{saved_cols} ) = @{pop @bu};
            next UNION_TABLE;
        }
    }
    $ax->print_sql( $union );
    my $qt_table = $ax->get_stmt( $union, 'Union', 'prepare' );
    # alias: required if mysql, Pg, ...
    my $alias = $ax->alias( 'union', '', "TABLES_UNION" );
    $qt_table .= " AS " . $ax->quote_col_qualified( [ $alias ] );
    # column names in the result-set of a UNION are taken from the first query.
    my $qt_columns = $union->{subselect_data}[0][1];
    return $qt_table, $qt_columns;
}


sub __union_table_columns {
    my ( $sf, $union, $union_table, $qt_union_table ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my ( $privious_cols, $void ) = ( q['^'], q[' '] );
    my $next_idx = @{$union->{subselect_data}};
    my $table_cols = [];
    my @bu_cols;

    while ( 1 ) {
        my @pre = ( undef, $sf->{i}{ok}, @{$union->{saved_cols}} ? $privious_cols : $void );
        $ax->print_sql( $union );
        # Choose
        my @chosen = $tc->choose(
            [ @pre, @{$sf->{d}{col_names}{$union_table}} ],
            { %{$sf->{i}{lyt_h}}, prompt => 'Choose Column:', meta_items => [ 0 .. $#pre ], include_highlighted => 2 }
        );
        if ( ! defined $chosen[0] ) {
            if ( @bu_cols ) {
                $table_cols = pop @bu_cols;
                $union->{subselect_data}[$next_idx] = [ $qt_union_table, $ax->quote_simple_many( $table_cols ) ];
                next;
            }
            $#{$union->{subselect_data}} = $next_idx - 1;
            return;
        }
        if ( $chosen[0] eq $void ) {
            next;
        }
        elsif ( $chosen[0] eq $privious_cols ) {
            push @{$union->{subselect_data}}, [ $qt_union_table, $ax->quote_simple_many( $union->{saved_cols} ) ];
            return 1;
        }
        elsif ( $chosen[0] eq $sf->{i}{ok} ) {
            shift @chosen;
            push @$table_cols, @chosen;
            if ( ! @$table_cols ) {
                $table_cols = [ @{$sf->{d}{col_names}{$union_table}} ];
            }
            $union->{subselect_data}[$next_idx] = [ $qt_union_table, $ax->quote_simple_many( $table_cols ) ];
            $union->{saved_cols} = $table_cols;
            return 1;
        }
        else {
            push @bu_cols, $table_cols;
            push @$table_cols, @chosen;
            $union->{subselect_data}[$next_idx] = [ $qt_union_table, $ax->quote_simple_many( $table_cols ) ];
        }
    }
}


sub __union_all_tables {
    my ( $sf, $union ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my @tables_union_auto;
    for my $table ( @{$sf->{d}{user_tables}} ) {
        if ( $sf->{d}{tables_info}{$table}[3] ne 'TABLE' ) {
            next;
        }
        push @tables_union_auto, $table;
    }
    my $menu = [ undef, map( "- $_", @tables_union_auto ) ];

    while ( 1 ) {
        $union->{subselect_data} = [ map { [ $_, [ '?' ] ] } @tables_union_auto ];
        $ax->print_sql( $union );
        # Choose
        my $idx_tbl = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_v}}, prompt => 'One UNION table for cols:', index => 1 }
        );
        if ( ! defined $idx_tbl || ! defined $menu->[$idx_tbl] ) {
            $union->{subselect_data} = [];
            return;
        }
        ( my $union_table = $menu->[$idx_tbl] ) =~ s/^-\s//;
        my $qt_union_table = $ax->quote_table( $sf->{d}{tables_info}{$union_table} );
        my $ok = $sf->__union_table_columns( $union, $union_table, $qt_union_table );
        if ( $ok ) {
            last;
        }
    }
    my $qt_used_cols = $union->{subselect_data}[-1][1];
    $union->{subselect_data} = [];
    for my $union_table ( @tables_union_auto ) {
        push @{$union->{subselect_data}}, [ $ax->quote_table( $sf->{d}{tables_info}{$union_table} ), $qt_used_cols ];
    }
    $ax->print_sql( $union );
    return 1;
}






1;

__END__
