package # hide from PAUSE
App::DBBrowser::Join;

use warnings;
use strict;
use 5.014;

use List::MoreUtils qw( any );

use Term::Choose         qw();
use Term::Form::ReadLine qw();
use Term::TablePrint     qw();

use App::DBBrowser::Auxil;
#use App::DBBrowser::Subqueries; # required

sub new {
    my ( $class, $info, $options, $d ) = @_;
    my $sf = {
        i => $info,
        o => $options,
        d => $d
    };
    if ( $info->{driver} eq 'SQLite' ) {
        $sf->{join_types} = [ 'INNER JOIN', 'LEFT JOIN', 'CROSS JOIN' ];
    }
    elsif ( $info->{driver} =~ /^(?:mysql|MariaDB)\z/ ) {
        $sf->{join_types} = [ 'INNER JOIN', 'LEFT JOIN', 'RIGHT JOIN', 'CROSS JOIN' ];
    }
    else {
        $sf->{join_types} = [ 'INNER JOIN', 'LEFT JOIN', 'RIGHT JOIN', 'FULL JOIN', 'CROSS JOIN' ];
    }
    $sf->{d}{stmt_types} = [ 'Join' ];
    $sf->{join_info} = '  INFO';
    $sf->{derived_table} = '  Derived';
    $sf->{cte_table} = '  Cte';
    bless $sf, $class;
}


sub join_tables {
    my ( $sf ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tables;
    if ( $sf->{o}{G}{metadata} ) {
        $tables = [ @{$sf->{d}{user_table_keys}}, @{$sf->{d}{sys_table_keys}} ];
    }
    else {
        $tables = [ @{$sf->{d}{user_table_keys}} ];
    }
    my ( $sql, $data );

    MASTER: while ( 1 ) {
        $sql = {};
        $ax->reset_sql( $sql );
        $data = {
            used_tables => [],
            aliases => [],
            default_alias => 'a',
        };
        my $join_info = $sf->{join_info};
        my $derived_table = $sf->{derived_table};
        my $cte_table = $sf->{cte_table};
        my @choices = map { "- $_" } @$tables;
        push @choices, $derived_table if $sf->{o}{enable}{j_derived};
        push @choices, $cte_table     if $sf->{o}{enable}{j_cte};
        push @choices, $join_info;
        my @pre = ( undef );
        my $info = $ax->get_sql_info( $sql );
        # Choose
        my $master = $tc->choose(
            [ @pre, @choices ],
            { %{$sf->{i}{lyt_v}}, info => $info, prompt => 'Choose MAIN table:' }
        );
        $ax->print_sql_info( $info );
        if ( ! defined $master ) {
            return;
        }
        elsif ( $master eq $join_info ) {
            $sf->__get_join_info();
            $sf->__print_join_info();
            next MASTER;
        }
        my $qt_master;
        if ( $master eq $derived_table ) {
            require App::DBBrowser::Subqueries;
            my $sq = App::DBBrowser::Subqueries->new( $sf->{i}, $sf->{o}, $sf->{d} );
            $master = $sq->subquery( $sql );
            if ( ! defined $master ) {
                next MASTER;
            }
            $qt_master = $master;
        }
        elsif ( $master eq $cte_table ) {
            require App::DBBrowser::Subqueries;
            my $sq = App::DBBrowser::Subqueries->new( $sf->{i}, $sf->{o}, $sf->{d} );
            $master = $sq->prepare_cte( $sql );
            if ( ! defined $master ) {
                next MASTER;
            }
            $qt_master = $master;
        }
        else {
            $master =~ s/^-\s//;
            $qt_master = $ax->quote_table( $sf->{d}{tables_info}{$master} );
        }
        push @{$data->{used_tables}}, $master;
        $data->{default_alias} = 'a';
        # Alias
        my $master_alias = $ax->alias( $sql, 'join_table', $qt_master, $data->{default_alias} );
        push @{$data->{aliases}}, [ $master, $master_alias ];
        push @{$sql->{join_data}}, { table => $qt_master . " " . $ax->quote_alias( $master_alias ) };
        $sf->{d}{col_names}{$master} //= $ax->column_names( $qt_master . " " . $ax->quote_alias( $master_alias ) ); ##
        my @bu;

        JOIN_TYPE: while ( 1 ) {
            my $enough_tables = '  Enough TABLES';
            my @pre = ( undef, $enough_tables );
            my $info = $ax->get_sql_info( $sql );
            # Choose
            my $join_type = $tc->choose(
                [ @pre, map( "- $_", @{$sf->{join_types}} ) ],
                { %{$sf->{i}{lyt_v}}, info => $info, prompt => 'Choose Join Type:' }
            );
            $ax->print_sql_info( $info );
            if ( ! defined $join_type ) {
                if ( @bu ) {
                    if ( @{$sf->{d}{ctes}//[]} && $data->{used_tables}[-1] eq $sf->{d}{ctes}[-1]{table} ) {
                        pop @{$sf->{d}{ctes}};
                    }
                    ( $data->{default_alias}, $data->{aliases}, $data->{used_tables} ) = @{pop @bu};
                    pop @{$sql->{join_data}};
                    next JOIN_TYPE;
                }
                next MASTER;
            }
            elsif ( $join_type eq $enough_tables ) {
                if ( @{$data->{used_tables}} == 1 ) {
                    return;
                }
                last JOIN_TYPE;
            }
            $join_type =~ s/^-\s//;
            push @bu, [ $data->{default_alias}, [ @{$data->{aliases}} ], [ @{$data->{used_tables}} ] ];
            push @{$sql->{join_data}}, { join_type => $join_type };
            my $ok = $sf->__add_slave_with_join_condition( $sql, $data, $tables );
            if ( ! $ok ) {
                ( $data->{default_alias}, $data->{aliases}, $data->{used_tables} ) = @{pop @bu};
                pop @{$sql->{join_data}}
            }
        }
        last MASTER;
    }

    my $aliases_hash = {};
    for my $ref ( @{$data->{aliases}} ) {
        push @{$aliases_hash->{$ref->[0]}}, $ref->[1];
    }
    my %col_names;
    #my $qualified_column_names;              ##
    for my $table ( @{$data->{used_tables}} ) {
        for my $col ( @{$sf->{d}{col_names}{$table}} ) {
            ++$col_names{lc $col};
            #if ( $col_names{lc $col} > 1 ) { ##
            #    $qualified_column_names = 1; ##
            #}                                ##
        }
    }
    my $qt_columns = [];
    my $qt_aliases = {};
    for my $table ( @{$data->{used_tables}} ) {
        for my $table_alias ( @{$aliases_hash->{$table}} ) {
            for my $col ( @{$sf->{d}{col_names}{$table}} ) {
                my $col_qt = $ax->quote_column( $table_alias, $col );
                #my $col_qt = $ax->quote_column( $qualified_column_names ? ( $table_alias, $col ) : ( $col ) ); ##
                if ( any { $_ eq $col_qt } @$qt_columns ) {
                    next;
                }
                if ( $sf->{o}{alias}{join_columns} && $col_names{lc $col} > 1 ) {
                    $qt_aliases->{$col_qt} = $ax->quote_alias( $table_alias . '_' . $col );
                }
                push @$qt_columns, $col_qt;
            }
        }
    }
    my $qt_table = $ax->get_stmt( $sql, 'Join', 'prepare' );
    return $qt_table, $qt_columns, $qt_aliases;
}


sub __add_slave_with_join_condition {
    my ( $sf, $sql, $data, $tables ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $used = ' (used)';
    my $join_info = $sf->{join_info};
    my $derived_table = $sf->{derived_table};
    my $cte_table = $sf->{cte_table};
    my @choices;
    for my $table ( @$tables ) {
        if ( any { $_ eq $table } @{$data->{used_tables}} ) {
            push @choices, '- ' . $table . $used;
        }
        else {
            push @choices, '- ' . $table;
        }
    }
    push @choices, $derived_table if $sf->{o}{enable}{j_derived};
    push @choices, $cte_table     if $sf->{o}{enable}{j_cte};
    push @choices, $join_info;
    my @bu;
    my $old_idx = 0;

    SLAVE: while ( 1 ) {
        my @pre = ( undef );
        my $menu = [ @pre, @choices ];
        my $info = $ax->get_sql_info( $sql );
        # Choose
        my $idx = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_v}}, info => $info, prompt => 'Add table:', index => 1,
              default => $old_idx, undef => $sf->{i}{_reset} }
        );
        $ax->print_sql_info( $info );

        if ( ! defined $idx || ! defined $menu->[$idx] ) {
            if ( @bu ) {
                ( $data->{default_alias}, $data->{aliases}, $data->{used_tables} ) = @{pop @bu};
                delete $sql->{join_data}[-1]{table};
                next SLAVE;
            }
            return;
        }
        if ( $sf->{o}{G}{menu_memory} ) {
            if ( $old_idx == $idx && ! $ENV{TC_RESET_AUTO_UP} ) {
                $old_idx = 0;
                next SLAVE;
            }
            $old_idx = $idx;
        }
        if ( $menu->[$idx] eq $join_info ) {
            $sf->__get_join_info();
            $sf->__print_join_info();
            next SLAVE;
        }
        my $slave = $menu->[$idx];
        my $qt_slave;
        if ( $slave eq $derived_table ) {
            require App::DBBrowser::Subqueries;
            my $sq = App::DBBrowser::Subqueries->new( $sf->{i}, $sf->{o}, $sf->{d} );
            $slave = $sq->subquery( $sql );
            if ( ! defined $slave ) {
                next MASTER;
            }
            $qt_slave = $slave;
        }
        elsif ( $slave eq $cte_table ) {
            require App::DBBrowser::Subqueries;
            my $sq = App::DBBrowser::Subqueries->new( $sf->{i}, $sf->{o}, $sf->{d} );
            $slave = $sq->prepare_cte( $sql );
            if ( ! defined $slave ) {
                next MASTER;
            }
            $qt_slave = $slave;
        }
        else {
            $slave =~ s/^-\s//;
            $slave =~ s/\Q$used\E\z//;
            $qt_slave = $ax->quote_table( $sf->{d}{tables_info}{$slave} );
        }
        push @bu, [ $data->{default_alias}, [ @{$data->{aliases}} ], [ @{$data->{used_tables}} ] ];
        push @{$data->{used_tables}}, $slave;
        # Alias
        my $slave_alias = $ax->alias( $sql, 'join_table', $qt_slave, ++$data->{default_alias} );
        $sql->{join_data}[-1]{table} = $qt_slave . " " . $ax->quote_alias( $slave_alias );
        push @{$data->{aliases}}, [ $slave, $slave_alias ];
        $sf->{d}{col_names}{$slave} //= $ax->column_names( $qt_slave . " " . $ax->quote_alias( $slave_alias ) ); ##
        if ( $sql->{join_data}[-1]{join_type} ne 'CROSS JOIN' ) {
            my $ok = $sf->__add_join_condition( $sql, $data, $slave, $slave_alias );
            if ( ! $ok ) {
                if ( @{$sf->{d}{ctes}//[]} && $slave eq $sf->{d}{ctes}[-1]{table} ) {
                    pop @{$sf->{d}{ctes}};
                }
                ( $data->{default_alias}, $data->{aliases}, $data->{used_tables} ) = @{pop @bu};
                delete $sql->{join_data}[-1]{table};
                delete $sql->{join_data}[-1]{condition};
                next SLAVE;
            }
        }
        $ax->print_sql_info( $ax->get_sql_info( $sql ) );
        return 1;
    }
}


sub __add_join_condition {
    my ( $sf, $sql, $data, $slave, $slave_alias ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $aliases_hash = {};
    for my $ref ( @{$data->{aliases}} ) {
        push @{$aliases_hash->{$ref->[0]}}, $ref->[1];
    }
    my %avail_pk_cols;
    for my $used_table ( @{$data->{used_tables}} ) {
        for my $table_alias ( @{$aliases_hash->{$used_table}} ) {
            if ( $used_table eq $slave && $table_alias eq $slave_alias ) {
                next;
            }
            for my $col ( @{$sf->{d}{col_names}{$used_table}} ) {
                $avail_pk_cols{ $table_alias . '.' . $col } = $ax->quote_column( $table_alias, $col );
            }
        }
    }
    my %avail_fk_cols;
    for my $col ( @{$sf->{d}{col_names}{$slave}} ) {
        $avail_fk_cols{ $slave_alias . '.' . $col } = $ax->quote_column( $slave_alias, $col );
    }
    $sql->{join_data}[-1]{condition} = "ON";
    my @bu;

    JOIN_PREDICATE: while ( 1 ) {
        my $AND = @bu ? " AND" : "";
        my @pre = ( undef, $AND ? $sf->{i}{_confirm} : () );
        my $fk_pre = '  '; #

        PRIMARY_KEY: while ( 1 ) {
            my $info = $ax->get_sql_info( $sql );
            # Choose
            my $pk_col = $tc->choose(
                [ @pre,
                  map(    '- ' . $_, sort keys %avail_pk_cols ),
                  map( $fk_pre . $_, sort keys %avail_fk_cols ),
                ],
                { %{$sf->{i}{lyt_v}}, info => $info, prompt => 'Choose PRIMARY KEY column:' }
            );
            $ax->print_sql_info( $info );
            if ( ! defined $pk_col ) {
                if ( @bu ) {
                    $sql->{join_data}[-1]{condition} = pop @bu;
                    last PRIMARY_KEY;
                }
                return;
            }
            elsif ( $pk_col eq $sf->{i}{_confirm} ) {
                if ( ! $AND ) {
                    return;
                }
                my $condition = $sql->{join_data}[-1]{condition} =~ s/^ON //r;
                $sql->{join_data}[-1]{condition} = "ON";
                my $info = $ax->get_sql_info( $sql );
                my $tr = Term::Form::ReadLine->new( $sf->{i}{tr_default} );
                # Readline
                $condition = $tr->readline( # conditions are boolean expressions
                    'Edit: ',
                    { info => $info, default => $condition, show_context => 1, history => [] }
                );
                $ax->print_sql_info( $info );
                if ( ! length $condition ) {
                    return;
                }
                $sql->{join_data}[-1]{condition} .= " " . $condition;
                return 1;
            }
            elsif ( any { $fk_pre . $_ eq $pk_col } keys %avail_fk_cols ) {
                next PRIMARY_KEY;
            }
            $pk_col =~ s/^-\s//;
            push @bu, $sql->{join_data}[-1]{condition};
            $sql->{join_data}[-1]{condition} .= $AND . " " . $avail_pk_cols{$pk_col} . " " . '=';
            last PRIMARY_KEY;
        }

        FOREIGN_KEY: while ( 1 ) {
            my $info = $ax->get_sql_info( $sql );
            # Choose
            my $fk_col = $tc->choose(
                [ undef, map( "- $_", sort keys %avail_fk_cols ) ],
                { %{$sf->{i}{lyt_v}}, info => $info, prompt => 'Choose FOREIGN KEY column:' }
            );
            $ax->print_sql_info( $info );
            if ( ! defined $fk_col ) {
                $sql->{join_data}[-1]{condition} = pop @bu;
                next JOIN_PREDICATE;
            }
            $fk_col =~ s/^-\s//;
            push @bu, $sql->{join_data}[-1]{condition};
            $sql->{join_data}[-1]{condition} .= " " . $avail_fk_cols{$fk_col};
            next JOIN_PREDICATE;
        }
    }
}


sub __print_join_info {
    my ( $sf ) = @_;
    my $pk = $sf->{d}{pk_info};
    my $fk = $sf->{d}{fk_info};
    my $aref = [ [ qw(PK_TABLE PK_COLUMN FK_TABLE FK_COLUMN) ] ];
    my $r = 1;
    for my $t ( sort keys %$pk ) {
        $aref->[$r][0] = $pk->{$t}{TABLE_NAME};
        $aref->[$r][1] = join( ', ', @{$pk->{$t}{COLUMN_NAME}} );
        if ( defined $fk->{$t}->{FKCOLUMN_NAME} && @{$fk->{$t}{FKCOLUMN_NAME}} ) {
            $aref->[$r][2] = $fk->{$t}{FKTABLE_NAME};
            $aref->[$r][3] = join( ', ', @{$fk->{$t}{FKCOLUMN_NAME}} );
        }
        else {
            $aref->[$r][2] = '';
            $aref->[$r][3] = '';
        }
        $r++;
    }
    my $tp = Term::TablePrint->new( $sf->{o}{table} );
    $tp->print_table( $aref, { tab_width => 3 } ); # info
}


sub __get_join_info {
    my ( $sf ) = @_;
    return if $sf->{d}{pk_info};
    my $td = $sf->{d}{tables_info};
    my $tables;
    if ( $sf->{o}{G}{metadata} ) {
        $tables = [ @{$sf->{d}{user_table_keys}}, @{$sf->{d}{sys_table_keys}} ];
    }
    else {
        $tables = [ @{$sf->{d}{user_table_keys}} ];
    }
    my $pk = {};
    for my $table ( @$tables ) {
        my $sth = $sf->{d}{dbh}->primary_key_info( @{$td->{$table}}[0..2] );
        next if ! defined $sth;
        while ( my $ref = $sth->fetchrow_hashref() ) {
            next if ! defined $ref;
            #$pk->{$table}{TABLE_SCHEM} =        $ref->{TABLE_SCHEM};
            $pk->{$table}{TABLE_NAME}  =        $ref->{TABLE_NAME};
            push @{$pk->{$table}{COLUMN_NAME}}, $ref->{COLUMN_NAME};
            #push @{$pk->{$table}{KEY_SEQ}},     $ref->{KEY_SEQ} // $ref->{ORDINAL_POSITION};
        }
    }
    my $fk = {};
    for my $table ( @$tables ) {
        my $sth = $sf->{d}{dbh}->foreign_key_info( @{$td->{$table}}[0..2], undef, undef, undef );
        next if ! defined $sth;
        while ( my $ref = $sth->fetchrow_hashref() ) {
            next if ! defined $ref;
            #$fk->{$table}{FKTABLE_SCHEM} =        $ref->{FKTABLE_SCHEM} // $ref->{FK_TABLE_SCHEM};
            $fk->{$table}{FKTABLE_NAME}  =        $ref->{FKTABLE_NAME} // $ref->{FK_TABLE_NAME};
            push @{$fk->{$table}{FKCOLUMN_NAME}}, $ref->{FKCOLUMN_NAME} // $ref->{FK_COLUMN_NAME};
            #push @{$fk->{$table}{KEY_SEQ}},       $ref->{KEY_SEQ} // $ref->{ORDINAL_POSITION};
        }
    }
    $sf->{d}{pk_info} = $pk;
    $sf->{d}{fk_info} = $fk;
}






1;

__END__
