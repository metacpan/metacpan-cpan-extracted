package # hide from PAUSE
App::DBBrowser::Join_Union;

use warnings;
use strict;
use 5.008003;

use List::MoreUtils qw( any );

use Term::Choose           qw( choose );
use Term::Choose::LineFold qw( line_fold );
use Term::Choose::Util     qw( term_width );
use Term::TablePrint       qw( print_table );

use App::DBBrowser::DB;
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
    my $tbls = [ @{$u->{user_tables}}, @{$u->{sys_tables}} ];
    ( $u->{col_names}, $u->{col_types} ) = $sf->__column_names_and_types( $tbls );
    my $union = {
        unused_tables => [ @$tbls ],
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


sub __column_names_and_types {
    my ( $sf, $tables ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my ( $col_names, $col_types );
    for my $table ( @$tables ) {
        my $sth = $sf->{d}{dbh}->prepare( "SELECT * FROM " . $ax->quote_table( $sf->{d}{tables_info}{$table} ) . " LIMIT 0" );
        $sth->execute() if $sf->{d}{driver} ne 'SQLite';
        $col_names->{$table} ||= $sth->{NAME};
        $col_types->{$table} ||= $sth->{TYPE};
    }
    return $col_names, $col_types;
}


sub join_tables {
    my ( $sf ) = @_;
    my $stmt_v = Term::Choose->new( $sf->{i}{lyt_stmt_v} );
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $j = $sf->{d}; # ###
    my $tbls = [ sort keys %{$j->{tables_info}} ]; # name
    ( $j->{col_names}, $j->{col_types} ) = $sf->__column_names_and_types( $tbls );
    my $join = {};

    MASTER: while ( 1 ) {
        $join = {};
        $join->{stmt} = "SELECT * FROM";
        $join->{primary_keys} = [];
        $join->{foreign_keys} = [];
        my @tables = map { "- $_" } @$tbls;
        my $info   = '  INFO';
        my @pre = ( undef );
        my $choices = [ @pre, @tables, $info ];
        $sf->__print_join_statement( $join->{stmt} );
        # Choose
        my $idx = $stmt_v->choose(
            $choices,
            { prompt => 'Choose MASTER table:', index => 1 }
        );
        if ( ! defined $idx || ! defined $choices->[$idx] ) {
            return;
        }
        if ( $choices->[$idx] eq $info ) {
            $sf->__get_join_info();
            $sf->__print_join_info();
            next MASTER;
        }
        $idx -= @pre;
        ( my $master = splice( @tables, $idx, 1 ) ) =~ s/^-\s//;
        $join->{used_tables}  = [ $master ];
        $join->{avail_tables} = [ @tables ];
        my $default_alias = $sf->{d}{driver} eq 'Pg' ? 'a' : 'A';
        my $qt_master = $ax->quote_table( $j->{tables_info}{$master} );
        $join->{stmt} = "SELECT * FROM " . $qt_master;
        $sf->__print_join_statement( $join->{stmt} );
        $join->{alias}{$master} = $ax->alias( 'join', 'AS: ', $default_alias, $qt_master );
        $join->{stmt} .= " AS " . $ax->quote_col_qualified( [ $join->{alias}{$master} ] );
        my $backup_master = $ax->backup_href( $join );

        JOIN: while ( 1 ) {
            my $idx;
            my $enough_slaves = '  Enough TABLES';
            my @pre = ( undef, $enough_slaves );
            my $backup_join = $ax->backup_href( $join );

            SLAVE: while ( 1 ) {
                my $choices = [ @pre, @{$join->{avail_tables}}, $info ];
                $sf->__print_join_statement( $join->{stmt} );
                # Choose
                $idx = $stmt_v->choose(
                    $choices,
                    { prompt => 'Add a SLAVE table:', index => 1, undef => $sf->{i}{_reset} }
                );
                if ( ! defined $idx || ! defined $choices->[$idx] ) {
                    if ( @{$join->{used_tables}} == 1 ) {
                        next MASTER;
                    }
                    else {
                        $join = $backup_master;
                        next JOIN;
                    }
                }
                elsif ( $choices->[$idx] eq $enough_slaves ) {
                    last JOIN;
                }
                elsif ( $choices->[$idx] eq $info ) {
                    $sf->__get_join_info();
                    $sf->__print_join_info();
                    next SLAVE;
                }
                else {
                    last SLAVE;
                }
            }
            $idx -= @pre;
            ( my $slave = splice( @{$join->{avail_tables}}, $idx, 1 ) ) =~ s/^-\s//;
            my $qt_slave = $ax->quote_table( $j->{tables_info}{$slave} );
            $join->{stmt} .= " LEFT OUTER JOIN " . $qt_slave;
            $sf->__print_join_statement( $join->{stmt} );
            $join->{alias}{$slave} = $ax->alias( 'join', 'AS: ', ++$default_alias, $qt_slave );
            $join->{stmt} .= " AS " . $ax->quote_col_qualified( [ $join->{alias}{$slave} ] ). " ON";
            my %avail_pk_cols;
            for my $used_table ( @{$join->{used_tables}} ) {
                for my $col ( @{$j->{col_names}{$used_table}} ) {
                    $avail_pk_cols{ $join->{alias}{$used_table} . '.' . $col } = $ax->quote_col_qualified( [undef, $join->{alias}{$used_table}, $col ] ); #
                }
            }
            my %avail_fk_cols;
            for my $col ( @{$j->{col_names}{$slave}} ) {
                $avail_fk_cols{ $join->{alias}{$slave} . '.' . $col } = $ax->quote_col_qualified( [ $join->{alias}{$slave}, $col ] );
            }

            my $AND = '';

            ON: while ( 1 ) {
                my @pre = ( undef );
                $sf->__print_join_statement( $join->{stmt} );
                push @pre, $sf->{i}{_continue} if $AND;
                # Choose
                my $pk_col = $stmt_v->choose(
                    [ @pre, map( "- $_", sort keys %avail_pk_cols ) ],
                    { prompt => 'Choose PRIMARY KEY column:', index => 0, undef => $sf->{i}{_reset} }
                );
                if ( ! defined $pk_col ) {
                    $join = $backup_join;
                    next JOIN;
                }
                if ( $pk_col eq $sf->{i}{_continue} ) {
                    if ( @{$join->{primary_keys}} == @{$backup_join->{primary_keys}} ) {
                        $join = $backup_join;
                        next JOIN;
                    }
                    last ON;
                }
                $pk_col =~ s/^-\s//;
                push @{$join->{primary_keys}}, $avail_pk_cols{$pk_col};
                $join->{stmt} .= $AND;
                $join->{stmt} .= ' ' . $avail_pk_cols{$pk_col} . " =";
                $sf->__print_join_statement( $join->{stmt} );
                # Choose
                my $fk_col = $stmt_v->choose(
                    [ undef, map( "- $_", sort keys %avail_fk_cols ) ],
                    { prompt => 'Choose FOREIGN KEY column:', index => 0, undef => $sf->{i}{_reset} }
                );
                if ( ! defined $fk_col ) {
                    $join = $backup_join;
                    next JOIN;
                }
                $fk_col =~ s/^-\s//;
                push @{$join->{foreign_keys}}, $avail_fk_cols{$fk_col};
                $join->{stmt} .= ' ' . $avail_fk_cols{$fk_col};
                $AND = " AND";
            }
            push @{$join->{used_tables}}, $slave;
        }
        last MASTER;
    }

    my $qt_columns = [];
    for my $table ( @{$join->{used_tables}} ) {
        for my $col ( @{$j->{col_names}{$table}} ) {
            my $col_qt = $ax->quote_col_qualified( [ undef, $join->{alias}{$table}, $col ] );
            if ( any { $_ eq $col_qt } @{$join->{foreign_keys}} ) { ##
                next;
            }
            push @$qt_columns, $col_qt;
        }
    }
    my ( $qt_table ) = $join->{stmt} =~ /^SELECT\s\*\sFROM\s(.*)\z/;
    return $qt_table, $qt_columns;
}


sub __print_join_statement {
    my ( $sf, $join_stmt_pr ) = @_;
    $join_stmt_pr =~ s/(?=\sLEFT\sOUTER\sJOIN)/\n\ /g; ##
    $join_stmt_pr .= "\n\n";
    print $sf->{i}{clear_screen};
    print line_fold( $join_stmt_pr, term_width() - 2, '', ' ' x $sf->{i}{stmt_init_tab} );
}


sub __print_join_info {
    my ( $sf ) = @_;
    my $pk = $sf->{d}{pk_info};
    my $fk = $sf->{d}{fk_info};
    my $aref = [ [ qw(PK_TABLE PK_COLUMN), ' ', qw(FK_TABLE FK_COLUMN) ] ];
    my $r = 1;
    for my $t ( sort keys %$pk ) {
        $aref->[$r][0] = $pk->{$t}{TABLE_NAME};
        $aref->[$r][1] = join( ', ', @{$pk->{$t}{COLUMN_NAME}} );
        if ( defined $fk->{$t}->{FKCOLUMN_NAME} && @{$fk->{$t}{FKCOLUMN_NAME}} ) {
            $aref->[$r][2] = 'ON';
            $aref->[$r][3] = $fk->{$t}{FKTABLE_NAME};
            $aref->[$r][4] = join( ', ', @{$fk->{$t}{FKCOLUMN_NAME}} );
        }
        else {
            $aref->[$r][2] = '';
            $aref->[$r][3] = '';
            $aref->[$r][4] = '';
        }
        $r++;
    }
    print_table( $aref, { keep_header => 0, tab_width => 3 } );
}


sub __get_join_info {
    my ( $sf ) = @_;
    return if $sf->{d}{pk_info};
    my $td = $sf->{d}{tables_info};
    my $tables = $sf->{d}{user_tables}; ###
    my $pk = {};
    for my $table ( @$tables ) {
        my $sth = $sf->{d}{dbh}->primary_key_info( @{$td->{$table}} );
        next if ! defined $sth;
        while ( my $ref = $sth->fetchrow_hashref() ) {
            next if ! defined $ref;
            #$pk->{$table}{TABLE_SCHEM} =        $ref->{TABLE_SCHEM};
            $pk->{$table}{TABLE_NAME}  =        $ref->{TABLE_NAME};
            push @{$pk->{$table}{COLUMN_NAME}}, $ref->{COLUMN_NAME};
            #push @{$pk->{$table}{KEY_SEQ}},     defined $ref->{KEY_SEQ} ? $ref->{KEY_SEQ} : $ref->{ORDINAL_POSITION};
        }
    }
    my $fk = {};
    for my $table ( @$tables ) {
        my $sth = $sf->{d}{dbh}->foreign_key_info( @{$td->{$table}}, undef, undef, undef );
        next if ! defined $sth;
        while ( my $ref = $sth->fetchrow_hashref() ) {
            next if ! defined $ref;
            #$fk->{$table}{FKTABLE_SCHEM} =        defined $ref->{FKTABLE_SCHEM} ? $ref->{FKTABLE_SCHEM} : $ref->{FK_TABLE_SCHEM};
            $fk->{$table}{FKTABLE_NAME}  =        defined $ref->{FKTABLE_NAME}  ? $ref->{FKTABLE_NAME}  : $ref->{FK_TABLE_NAME};
            push @{$fk->{$table}{FKCOLUMN_NAME}}, defined $ref->{FKCOLUMN_NAME} ? $ref->{FKCOLUMN_NAME} : $ref->{FK_COLUMN_NAME};
            #push @{$fk->{$table}{KEY_SEQ}},       defined $ref->{KEY_SEQ}       ? $ref->{KEY_SEQ}       : $ref->{ORDINAL_POSITION};
        }
    }
    $sf->{d}{pk_info} = $pk;
    $sf->{d}{fk_info} = $fk;
}




1;

__END__
