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
    my $join = {};

    MASTER: while ( 1 ) {
        $join = {};
        $join->{stmt} = "SELECT * FROM";
        $join->{used_tables}  = [];
        $join->{aliases}      = [];
        my $join_info = '  INFO';
        my $from_subquery = '  Derived';
        my @choices = map { "- $_" } @$tables;
        push @choices, $from_subquery if $sf->{o}{enable}{j_derived};
        push @choices, $join_info;
        my @pre = ( undef );
        my $info = $ax->get_sql_info( $join );
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
        my $master_from_subquery;
        if ( $master eq $from_subquery ) {
            require App::DBBrowser::Subqueries;
            my $sq = App::DBBrowser::Subqueries->new( $sf->{i}, $sf->{o}, $sf->{d} );
            $master = $sq->choose_subquery( $join );
            if ( ! defined $master ) {
                next MASTER;
            }
            $qt_master = $master;
            $master_from_subquery = 1;
        }
        else {
            $master =~ s/^-\s//;
            $qt_master = $ax->quote_table( $sf->{d}{tables_info}{$master} );
        }
        push @{$join->{used_tables}}, $master;
        $join->{default_alias} = 'a';
        # Alias
        my $master_alias = $ax->alias( $join, 'join', $qt_master, $join->{default_alias} );
        push @{$join->{aliases}}, [ $master, $master_alias ];
        $join->{stmt} .= " " . $qt_master;
        $join->{stmt} .= " " . $ax->prepare_identifier( $master_alias );
        $sf->{d}{col_names}{$master} //= $ax->column_names( $qt_master . " " . $ax->prepare_identifier( $master_alias ) ); ##

        my @bu;

        JOIN: while ( 1 ) {
            my $enough_tables = '  Enough TABLES';
            my @pre = ( undef, $enough_tables );
            my $info = $ax->get_sql_info( $join );
            # Choose
            my $join_type = $tc->choose(
                [ @pre, map( "- $_", @{$sf->{join_types}} ) ],
                { %{$sf->{i}{lyt_v}}, info => $info, prompt => 'Choose Join Type:' }
            );
            $ax->print_sql_info( $info );
            if ( ! defined $join_type ) {
                if ( @bu ) {
                    ( $join->{stmt}, $join->{default_alias}, $join->{aliases}, $join->{used_tables} ) = @{pop @bu};
                    next JOIN;
                }
                next MASTER;
            }
            elsif ( $join_type eq $enough_tables ) {
                if ( @{$join->{used_tables}} == 1 ) {
                    return;
                }
                last JOIN;
            }
            $join_type =~ s/^-\s//;
            push @bu, [ $join->{stmt}, $join->{default_alias}, [ @{$join->{aliases}} ], [ @{$join->{used_tables}} ] ];
            $join->{stmt} .= " " . $join_type;
            my $ok = $sf->__add_slave_with_join_condition( $join, $tables, $join_type, $join_info );
            if ( ! $ok ) {
                ( $join->{stmt}, $join->{default_alias}, $join->{aliases}, $join->{used_tables} ) = @{pop @bu};
            }
        }
        last MASTER;
    }

    my $aliases_hash = {};
    for my $ref ( @{$join->{aliases}} ) {
        push @{$aliases_hash->{$ref->[0]}}, $ref->[1];
    }
    my %col_names;
    for my $table ( @{$join->{used_tables}} ) {
        for my $col ( @{$sf->{d}{col_names}{$table}} ) {
            ++$col_names{$col};
        }
    }
    my $qt_columns = [];
    my $qt_aliases = {};
    for my $table ( @{$join->{used_tables}} ) {
        for my $alias ( @{$aliases_hash->{$table}} ) {
            for my $col ( @{$sf->{d}{col_names}{$table}} ) {
                my $col_qt = $ax->prepare_identifier( $alias, $col );
                if ( any { $_ eq $col_qt } @$qt_columns ) {
                    next;
                }
                if ( $col_names{$col} > 1 ) {
                    #$col_names{$col}--; ##
                    #next;
                    $qt_aliases->{$col_qt} = $ax->prepare_identifier( $alias . '_' . $col );
                }
                push @$qt_columns, $col_qt;
            }
        }
    }
    my $qt_table = $join->{stmt} =~ s/^SELECT\s\*\sFROM\s//r;
    return $qt_table, $qt_columns, $qt_aliases;
}


sub __add_slave_with_join_condition {
    my ( $sf, $join, $tables, $join_type, $join_info ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $used = ' (used)';
    my $from_subquery = '  Derived';
    my @choices;
    for my $table ( @$tables ) {
        if ( any { $_ eq $table } @{$join->{used_tables}} ) {
            push @choices, '- ' . $table . $used;
        }
        else {
            push @choices, '- ' . $table;
        }
    }
    push @choices, $from_subquery if $sf->{o}{enable}{j_derived};
    push @choices, $join_info;
    my @pre = ( undef );
    my @bu;

    SLAVE: while ( 1 ) {
        my $info = $ax->get_sql_info( $join );
        # Choose
        my $slave = $tc->choose(
            [ @pre, @choices ],
            { %{$sf->{i}{lyt_v}}, info => $info, prompt => 'Add table:', undef => $sf->{i}{_reset} }
        );
        $ax->print_sql_info( $info );
        if ( ! defined $slave ) {
            if ( @bu ) {
                ( $join->{stmt}, $join->{default_alias}, $join->{aliases}, $join->{used_tables} ) = @{pop @bu};
                next SLAVE;
            }
            return;
        }
        elsif ( $slave eq $join_info ) {
            $sf->__get_join_info();
            $sf->__print_join_info();
            next SLAVE;
        }
        my $qt_slave;
        my $slave_from_subquery;
        if ( $slave eq $from_subquery ) {
            require App::DBBrowser::Subqueries;
            my $sq = App::DBBrowser::Subqueries->new( $sf->{i}, $sf->{o}, $sf->{d} );
            $slave = $sq->choose_subquery( $join );
            if ( ! defined $slave ) {
                next SLAVE;
            }
            $qt_slave = $slave;
            $slave_from_subquery = 1;
        }
        else {
            $slave =~ s/^-\s//;
            $slave =~ s/\Q$used\E\z//;
            $qt_slave = $ax->quote_table( $sf->{d}{tables_info}{$slave} );
        }
        push @bu, [ $join->{stmt}, $join->{default_alias}, [ @{$join->{aliases}} ], [ @{$join->{used_tables}} ] ];
        push @{$join->{used_tables}}, $slave;
        # Alias
        my $slave_alias = $ax->alias( $join, 'join', $qt_slave, ++$join->{default_alias} );
        $join->{stmt} .= " " . $qt_slave;
        $join->{stmt} .= " " . $ax->prepare_identifier( $slave_alias );
        push @{$join->{aliases}}, [ $slave, $slave_alias ];
        $sf->{d}{col_names}{$slave} //= $ax->column_names( $qt_slave . " " . $ax->prepare_identifier( $slave_alias ) ); ##
        if ( $join_type ne 'CROSS JOIN' ) {
            my $ok = $sf->__add_join_condition( $join, $tables, $slave, $slave_alias );
            if ( ! $ok ) {
                ( $join->{stmt}, $join->{default_alias}, $join->{aliases}, $join->{used_tables} ) = @{pop @bu};
                next SLAVE;
            }
        }
        $ax->print_sql_info( $ax->get_sql_info( $join ) );
        return 1;
    }
}


sub __add_join_condition {
    my ( $sf, $join, $tables, $slave, $slave_alias ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $aliases_hash = {};
    for my $ref ( @{$join->{aliases}} ) {
        push @{$aliases_hash->{$ref->[0]}}, $ref->[1];
    }
    my %avail_pk_cols;
    for my $used_table ( @{$join->{used_tables}} ) {
        for my $alias ( @{$aliases_hash->{$used_table}} ) {
            if ( $used_table eq $slave && $alias eq $slave_alias ) {
                next;
            }
            for my $col ( @{$sf->{d}{col_names}{$used_table}} ) {
                $avail_pk_cols{ $alias . '.' . $col } = $ax->prepare_identifier( $alias, $col );
            }
        }
    }
    my %avail_fk_cols;
    for my $col ( @{$sf->{d}{col_names}{$slave}} ) {
        $avail_fk_cols{ $slave_alias . '.' . $col } = $ax->prepare_identifier( $slave_alias, $col );
    }
    $join->{stmt} .= " ON";
    my $bu_stmt = $join->{stmt};
    my $AND = '';
    my @bu;

    JOIN_PREDICATE: while ( 1 ) {
        my @pre = ( undef, $AND ? $sf->{i}{_confirm} : () );
        my $fk_pre = '  '; #

        PRIMARY_KEY: while ( 1 ) {
            my $info = $ax->get_sql_info( $join );
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
                    ( $join->{stmt}, $AND ) = @{pop @bu};
                    last PRIMARY_KEY;
                }
                return;
            }
            elsif ( $pk_col eq $sf->{i}{_confirm} ) {
                if ( ! $AND ) {
                    return;
                }
                my $condition = $join->{stmt} =~ s/^\Q$bu_stmt\E\s//r;
                $join->{stmt} = $bu_stmt; # add condition to the info print only after edit (?)
                my $info = $ax->get_sql_info( $join );
                my $tr = Term::Form::ReadLine->new( $sf->{i}{tr_default} );
                # Readline
                $condition = $tr->readline( # conditions are boolean expressions
                    'Edit: ',
                    { info => $info, default => $condition, show_context => 1, history => [] }
                );
                $ax->print_sql_info( $info );
                if ( ! defined $condition ) {
                    return;
                }
                $join->{stmt} = $bu_stmt . " " . $condition;
                return 1;
            }
            elsif ( any { $fk_pre . $_ eq $pk_col } keys %avail_fk_cols ) {
                next PRIMARY_KEY;
            }
            $pk_col =~ s/^-\s//;
            push @bu, [ $join->{stmt}, $AND ];
            $join->{stmt} .= $AND;
            $join->{stmt} .= " " . $avail_pk_cols{$pk_col} . " " . '=';
            last PRIMARY_KEY;
        }

        FOREIGN_KEY: while ( 1 ) {
            my $info = $ax->get_sql_info( $join );
            # Choose
            my $fk_col = $tc->choose(
                [ undef, map( "- $_", sort keys %avail_fk_cols ) ],
                { %{$sf->{i}{lyt_v}}, info => $info, prompt => 'Choose FOREIGN KEY column:' }
            );
            $ax->print_sql_info( $info );
            if ( ! defined $fk_col ) {
                ( $join->{stmt}, $AND ) = @{pop @bu};
                next JOIN_PREDICATE;
            }
            $fk_col =~ s/^-\s//;
            push @bu, [ $join->{stmt}, $AND ];
            $join->{stmt} .= " " . $avail_fk_cols{$fk_col};
            $AND = " AND";
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
