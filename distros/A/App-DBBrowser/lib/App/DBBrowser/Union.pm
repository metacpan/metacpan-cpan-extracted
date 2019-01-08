package # hide from PAUSE
App::DBBrowser::Union;

use warnings;
use strict;
use 5.008003;

use Term::Choose           qw( choose );
use Term::Choose::LineFold qw( line_fold );
use Term::Choose::Util     qw( term_width );

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
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $u = $sf->{d}; # ###
    my $tables = [ @{$u->{user_tables}}, @{$u->{sys_tables}} ];
    ( $u->{col_names}, $u->{col_types} ) = $ax->column_names_and_types( $tables );
    my $union = {
        unused_tables => [ @$tables ],
        used_tables   => [],
        used_cols     => {},
        saved_cols    => [],
    };

    UNION_TABLE: while ( 1 ) {
        my $enough_tables = '  Enough TABLES';
        my $all_tables    = '  All Tables';
        my @pre_tbl  = ( undef, $enough_tables );
        my @post_tbl = ( $all_tables );
        my $prompt = 'Choose UNION table:';
        my $choices  = [
            @pre_tbl,
            map( "+ $_", @{$union->{used_tables}} ),
            map( "- $_", @{$union->{unused_tables}} ),
            @post_tbl
        ];
        $sf->__print_union_statement( $u, $union );
        # Choose
        my $idx_tbl = choose(
            $choices,
            { %{$sf->{i}{lyt_stmt_v}}, prompt => $prompt, index => 1 }
        );
        if ( ! defined $idx_tbl || ! defined $choices->[$idx_tbl] ) {
            return;
        }
        my $union_table = $choices->[$idx_tbl];
        if ( $union_table eq $enough_tables ) {
            if ( ! @{$union->{used_tables}} ) {
                return;
            }
            last UNION_TABLE;
        }
        elsif ( $union_table eq $all_tables ) {
            my $ok = $sf->__union_all_tables( $u, $union );
            if ( ! $ok ) {
                next UNION_TABLE;
            }
            last UNION_TABLE;
        }
        else {
            $union_table =~ s/^[-+]\s//;
            $idx_tbl -= @pre_tbl;
            if ( $idx_tbl <= $#{$union->{used_tables}} ) {
                delete $union->{used_cols}{$union_table};
                splice( @{$union->{used_tables}}, $idx_tbl, 1 );
                push @{$union->{unused_tables}}, $union_table;
                next UNION_TABLE;
            }
            else {
                splice( @{$union->{unused_tables}}, $idx_tbl - @{$union->{used_tables}}, 1 );
                push @{$union->{used_tables}}, $union_table;
                my $ok = $sf->__union_table_columns( $u, $union, $union_table );
                if ( ! $ok ) {
                    push @{$union->{unused_tables}}, pop @{$union->{used_tables}};
                    next UNION_TABLE;
                }

            }
        }
    }
    $sf->__print_union_statement( $u, $union );
    # column names in the result-set of a UNION are taken from the first query.
    my $first_table = $union->{used_tables}[0];
    my $qt_columns = $ax->quote_simple_many( $union->{used_cols}{$first_table} );
    my $qt_table = $sf->__get_union_statement( $u, $union );
    # alias: required if mysql, Pg, ...
    my $alias = $ax->alias( 'union', 'AS: ', "TABLES_UNION" );
    $qt_table .= " AS " . $ax->quote_col_qualified( [ $alias ] );
    return $qt_table, $qt_columns;
}


sub __union_all_tables {
    my ( $sf, $u, $union ) = @_;
    $union->{unused_tables} = [];
    $union->{used_tables}   = [ @{$u->{user_tables}} ];
    $union->{used_cols}{$_} = [ '?' ] for @{$u->{user_tables}};
    $union->{saved_cols}    = [];
    my $union_table;
    my $choices  = [ undef, map( "- $_", @{$u->{user_tables}} ) ];

    while ( 1 ) {
        $sf->__print_union_statement( $u, $union );
        # Choose
        my $idx_tbl = choose(
            $choices,
            { %{$sf->{i}{lyt_stmt_v}}, prompt => 'One UNION table for cols:', index => 1 }
        );
        if ( ! defined $idx_tbl || ! defined $choices->[$idx_tbl] ) {
            $union->{unused_tables} = [ @{$u->{user_tables}}, @{$u->{sys_tables}} ];
            $union->{used_tables}   = [];
            $union->{used_cols}     = {};
            return;
        }
        ( $union_table = $choices->[$idx_tbl] ) =~ s/^-\s//;
        my $ok = $sf->__union_table_columns( $u, $union, $union_table );
        if ( $ok ) {
            last;
        }
    }

    my @selected_cols = @{$union->{used_cols}{$union_table}};
    for my $union_table ( @{$union->{used_tables}} ) {
        @{$union->{used_cols}{$union_table}} = @selected_cols;
    }
    return 1;
}


sub __union_table_columns {
    my ( $sf, $u, $union, $union_table ) = @_;
    my ( $privious_cols, $void ) = ( q['^'], q[' '] );
    delete $union->{used_cols}{$union_table}; #

    while ( 1 ) {
        my @pre_col = ( undef, $sf->{i}{ok}, @{$union->{saved_cols}} ? $privious_cols : $void );
        $sf->__print_union_statement( $u, $union );
        # Choose
        my @col = choose(
            [ @pre_col, @{$u->{col_names}{$union_table}} ],
            { %{$sf->{i}{lyt_stmt_h}}, prompt => 'Choose Column:',
            meta_items => [ 0 .. $#pre_col ], include_highlighted => 2 }
        );
        if ( ! defined $col[0] ) {
            if ( defined $union->{used_cols}{$union_table} ) {
                delete $union->{used_cols}{$union_table};
                next;
            }
            return;
        }
        elsif ( $col[0] eq $void ) {
            next;
        }
        elsif ( $col[0] eq $privious_cols ) {
            $union->{used_cols}{$union_table} = $union->{saved_cols};
            return 1;
        }
        elsif ( $col[0] eq $sf->{i}{ok} ) {
            shift @col;
            push @{$union->{used_cols}{$union_table}}, @col;
            if ( ! @{$union->{used_cols}{$union_table}} ) {
                @{$union->{used_cols}{$union_table}} = @{$u->{col_names}{$union_table}};
            }
            $union->{saved_cols} = $union->{used_cols}{$union_table};
            return 1;
        }
        else {
            push @{$union->{used_cols}{$union_table}}, @col;
        }
    }
}


sub __get_union_statement {
    my ( $sf, $u, $union ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $str = "(";
    my $count = 0;
    for my $table ( @{$union->{used_tables}} ) {
        ++$count;
        $str .= " SELECT ";
        if ( defined $union->{used_cols}{$table} && @{$union->{used_cols}{$table}} ) { #
            my $qt_cols = $ax->quote_simple_many( $union->{used_cols}{$table} );
            $str .= join( ', ', @$qt_cols );
        }
        else {
            $str .= '*';
        }
        $str.= " FROM " . $ax->quote_table( $u->{tables_info}{$table} );
        $str .= $count < @{$union->{used_tables}} ? " UNION ALL " : " )";
    }
    return $str;
}


sub __print_union_statement {
    my ( $sf, $u, $union ) = @_;
    my $str = $sf->__get_union_statement( $u, $union );
    $str =~ s/ SELECT /  SELECT /g;
    $str =~ s/UNION ALL /UNION ALL\n/g;
    $str =~ s/^\(/SELECT * FROM (\n/;
    $str =~ s/ \)/\n)\n\n/;
    print $sf->{i}{clear_screen};
    print line_fold( $str, term_width() - 2, '', ' ' x $sf->{i}{stmt_init_tab} ); #
}






1;

__END__
