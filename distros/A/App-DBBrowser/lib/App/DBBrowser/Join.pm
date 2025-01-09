package # hide from PAUSE
App::DBBrowser::Join;

use warnings;
use strict;
use 5.014;

use List::MoreUtils qw( any uniq );

use Term::Choose         qw();
use Term::Form::ReadLine qw();
use Term::TablePrint     qw();

use App::DBBrowser::Auxil;
use App::DBBrowser::Subqueries;
use App::DBBrowser::Table::Substatements;

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
    $sf->{join_info} = '  Info';
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
    my $old_idx_master = 0;

    MASTER: while ( 1 ) {
        $sql = {};
        $ax->reset_sql( $sql );
        $sql->{ctes} = [ @{$sf->{d}{cte_history}} ];
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
        my $menu = [ @pre, @choices ];
        my $info = $ax->get_sql_info( $sql );
        my $idx_master = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_v}}, info => $info, prompt => 'Choose MAIN table:', index => 1, default => $old_idx_master }
        );
        $ax->print_sql_info( $info );
        if ( ! defined $idx_master || ! defined $menu->[$idx_master] ) {
            return;
        }
        if ( $sf->{o}{G}{menu_memory} ) {
            if ( $old_idx_master == $idx_master && ! $ENV{TC_RESET_AUTO_UP} ) {
                $old_idx_master = 0;
                next MASTER;
            }
            $old_idx_master = $idx_master;
        }
        my $master = $menu->[$idx_master];
        if ( $master eq $join_info ) {
            $sf->__get_join_info();
            $sf->__print_join_info();
            next MASTER;
        }
        my $qt_master;
        if ( $master eq $derived_table ) {
            my $sq = App::DBBrowser::Subqueries->new( $sf->{i}, $sf->{o}, $sf->{d} );
            $master = $sq->subquery( $sql );
            if ( ! defined $master ) {
                next MASTER;
            }
            $qt_master = $master;
        }
        elsif ( $master eq $cte_table ) {
            my $sq = App::DBBrowser::Subqueries->new( $sf->{i}, $sf->{o}, $sf->{d} );
            $master = $sq->choose_cte( $sql );
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
        my $master_alias = $ax->alias( $sql, 'tables_in_join', $qt_master, $data->{default_alias} );
        push @{$data->{aliases}}, [ $master, $master_alias ];
        push @{$sql->{join_data}}, { table => $qt_master . " " . $ax->quote_alias( $master_alias ) };
        ( $data->{col_names}{$master}, undef ) = $ax->column_names_and_types( $qt_master . " " . $ax->quote_alias( $master_alias ), $sql->{ctes} );
        if ( ! defined $data->{col_names}{$master} ) {
            next MASTER;
        }
        my @bu;
        my $old_idx_type = 0;

        JOIN_TYPE: while ( 1 ) {
            my $enough_tables = '  Enough TABLES';
            my @pre = ( undef, $enough_tables );
            my $menu = [ @pre, map( "- $_", @{$sf->{join_types}} ) ];
            my $info = $ax->get_sql_info( $sql );
            # Choose
            my $idx_type = $tc->choose(
                $menu,
                { %{$sf->{i}{lyt_v}}, info => $info, prompt => 'Choose Join Type:', index => 1, default => $old_idx_type }
            );
            $ax->print_sql_info( $info );
            if ( ! defined $idx_type || ! defined $menu->[$idx_type] ) {
                if ( @bu ) {
                    pop @{$sql->{join_data}};
                    $data = pop @bu;
                    next JOIN_TYPE;
                }
                next MASTER;
            }
            if ( $sf->{o}{G}{menu_memory} ) {
                if ( $old_idx_type == $idx_type && ! $ENV{TC_RESET_AUTO_UP} ) {
                    $old_idx_type = 0;
                    next JOIN_TYPE;
                }
                $old_idx_type = $idx_type;
            }
            if ( $menu->[$idx_type] eq $enough_tables ) {
                if ( @{$data->{used_tables}} == 1 ) {
                    return;
                }
                last JOIN_TYPE;
            }
            my $join_type = $menu->[$idx_type];
            $join_type =~ s/^-\s//;
            push @bu, $ax->clone_data( $data );
            push @{$sql->{join_data}}, { join_type => $join_type };
            my $ok = $sf->__add_slave_with_join_condition( $sql, $data, $tables );
            if ( ! $ok ) {
                $data = pop @bu;
                pop @{$sql->{join_data}}
            }
            else {
                $old_idx_type = 0;
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
        for my $col ( @{$data->{col_names}{$table}} ) {
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
            for my $col ( @{$data->{col_names}{$table}} ) {
                my $col_qt = $ax->quote_column( $table_alias, $col );
                #my $col_qt = $ax->quote_column( $qualified_column_names ? ( $table_alias, $col ) : ( $col ) ); ##
                if ( any { $_ eq $col_qt } @$qt_columns ) {
                    next;
                }
                if ( $sf->{o}{alias}{join_columns} && $col_names{lc $col} > 1 ) {
                    my $alias = $ax->alias( $sql, 'join_columns', $col_qt, $table_alias . '_' . $col );
                    if ( $alias ) {
                        $qt_aliases->{$col_qt} = $ax->quote_alias( $alias );
                    }
                }
                push @$qt_columns, $col_qt;
            }
        }
    }
    my $qt_table = $ax->get_stmt( $sql, 'Join', 'prepare' );
    my $ctes = $sql->{ctes};
    return $qt_table, $qt_columns, $qt_aliases, $ctes;
}


sub __add_slave_with_join_condition {
    my ( $sf, $sql, $data, $tables ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $join_info = $sf->{join_info};
    my $derived_table = $sf->{derived_table};
    my $cte_table = $sf->{cte_table};
    my @choices = map { '- '. $_ } @$tables;
    push @choices, $derived_table if $sf->{o}{enable}{j_derived};
    push @choices, $cte_table     if $sf->{o}{enable}{j_cte};
    push @choices, $join_info;
    my $old_idx_slave = 0;

    SLAVE: while ( 1 ) {
        my @pre = ( undef );
        my $menu = [ @pre, @choices ];
        my $info = $ax->get_sql_info( $sql );
        # Choose
        my $idx_slave = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_v}}, info => $info, prompt => 'Add table:', index => 1,
              default => $old_idx_slave, undef => $sf->{i}{_reset} }
        );
        $ax->print_sql_info( $info );
        if ( ! defined $idx_slave || ! defined $menu->[$idx_slave] ) {
            return;
        }
        if ( $sf->{o}{G}{menu_memory} ) {
            if ( $old_idx_slave == $idx_slave && ! $ENV{TC_RESET_AUTO_UP} ) {
                $old_idx_slave = 0;
                next SLAVE;
            }
            $old_idx_slave = $idx_slave;
        }
        if ( $menu->[$idx_slave] eq $join_info ) {
            $sf->__get_join_info();
            $sf->__print_join_info();
            next SLAVE;
        }
        my $slave = $menu->[$idx_slave];
        my $bu_data = $ax->clone_data( $data );
        my $qt_slave;
        if ( $slave eq $derived_table ) {
            my $sq = App::DBBrowser::Subqueries->new( $sf->{i}, $sf->{o}, $sf->{d} );
            $slave = $sq->subquery( $sql );
            if ( ! defined $slave ) {
                next SLAVE;
            }
            $qt_slave = $slave;
        }
        elsif ( $slave eq $cte_table ) {
            my $sq = App::DBBrowser::Subqueries->new( $sf->{i}, $sf->{o}, $sf->{d} );
            $slave = $sq->choose_cte( $sql );
            if ( ! defined $slave ) {
                next SLAVE;
            }
            $qt_slave = $slave;
        }
        else {
            $slave =~ s/^-\s//;
            $qt_slave = $ax->quote_table( $sf->{d}{tables_info}{$slave} );
        }
        push @{$data->{used_tables}}, $slave;
        # Alias
        my $slave_alias = $ax->alias( $sql, 'tables_in_join', $qt_slave, ++$data->{default_alias} );
        $sql->{join_data}[-1]{table} = $qt_slave . " " . $ax->quote_alias( $slave_alias );
        push @{$data->{aliases}}, [ $slave, $slave_alias ];
        ( $data->{col_names}{$slave}, undef ) = $ax->column_names_and_types( $qt_slave . " " . $ax->quote_alias( $slave_alias ), $sql->{ctes} );
        if ( ! defined $data->{col_names}{$slave} ) {
            $sf->__reset_to_backuped_join_data( $sql, $data, $bu_data );
            next SLAVE;
        }
        if ( $sql->{join_data}[-1]{join_type} ne 'CROSS JOIN' ) {
            my $ok = $sf->__add_join_condition( $sql, $data );
            if ( ! $ok ) {
                $sf->__reset_to_backuped_join_data( $sql, $data, $bu_data );
                next SLAVE;
            }
        }
        $ax->print_sql_info( $ax->get_sql_info( $sql ) );
        return 1;
    }
}


sub __reset_to_backuped_join_data {
     my ( $sf, $sql, $data, $bu_data ) = @_;
    $sql->{join_data}[-1] = { join_type => $sql->{join_data}[-1]{join_type} };
    delete @{$data}{ keys %$data };
    # copy by key, so that $data still refers to the original hash:
    for my $key ( keys %$bu_data ) {
        $data->{$key} = $bu_data->{$key};
    }
}


sub __add_join_condition {
    my ( $sf, $sql, $data ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $sb = App::DBBrowser::Table::Substatements->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $aliases_hash = {};
    for my $ref ( @{$data->{aliases}} ) {
        push @{$aliases_hash->{$ref->[0]}}, $ref->[1];
    }
    my $cols_join_condition = [];
    for my $used_table ( uniq @{$data->{used_tables}} ) {           # self join: a table name is used more than once
        for my $table_alias ( @{$aliases_hash->{$used_table}} ) {   # self join: a table has more than one alias
            for my $col ( @{$data->{col_names}{$used_table}} ) {
                push @$cols_join_condition, $ax->quote_column( $table_alias, $col );
            }
        }
    }
    $sql->{cols_join_condition} = $cols_join_condition;
    my $ret = $sb->add_condition( $sql, 'on', $cols_join_condition );
    if ( $ret && length $sql->{on_stmt} ) {
        $sql->{join_data}[-1]{condition} = $sql->{on_stmt};
        $sql->{on_stmt} = '';
        return 1;
    }
    else {
        $sql->{on_stmt} = '';
        return;
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
