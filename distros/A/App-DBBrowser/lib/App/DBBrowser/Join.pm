package # hide from PAUSE
App::DBBrowser::Join;

use warnings;
use strict;
use 5.010001;

use List::MoreUtils qw( any );

use Term::Choose     qw( choose );
use Term::Form       qw();
use Term::TablePrint qw( print_table );

use App::DBBrowser::Auxil;
#use App::DBBrowser::Subqueries; # required

sub new {
    my ( $class, $info, $options, $data ) = @_;
    my $sf = {
        i => $info,
        o => $options,
        d => $data,
    };
    if ( $data->{driver} eq 'SQLite' ) {
        $sf->{join_types} = [ 'INNER JOIN', 'LEFT JOIN', 'CROSS JOIN' ];
    }
    elsif ( $data->{driver} =~ /^(?:mysql|MariaDB)\z/ ) {
        $sf->{join_types} = [ 'INNER JOIN', 'LEFT JOIN', 'RIGHT JOIN', 'CROSS JOIN' ];
    }
    else {
        $sf->{join_types} = [ 'INNER JOIN', 'LEFT JOIN', 'RIGHT JOIN', 'FULL JOIN', 'CROSS JOIN' ];
    }
    $sf->{i}{stmt_types} = [ 'Join' ];
    bless $sf, $class;
}


sub join_tables {
    my ( $sf ) = @_;
    my $stmt_v = Term::Choose->new( $sf->{i}{lyt_stmt_v} );
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tables = [ sort keys %{$sf->{d}{tables_info}} ];
    ( $sf->{d}{col_names}, $sf->{d}{col_types} ) = $ax->column_names_and_types( $tables );
    my $join = {};

    MASTER: while ( 1 ) {
        $join = {};
        $join->{stmt} = "SELECT * FROM";
        $join->{used_tables}  = [];
        $join->{aliases}      = [];
        $ax->print_sql( $join );
        my $info = '  INFO';
        my $from_subquery = '  Derived';
        my @choices = map { "- $_" } @$tables;
        push @choices, $from_subquery if $sf->{o}{enable}{j_derived};
        push @choices, $info;
        my @pre = ( undef );
        # Choose
        my $master = $stmt_v->choose(
            [ @pre, @choices ],
            { prompt => 'Choose MASTER table:' }
        );
        if ( ! defined $master ) {
            return;
        }
        elsif ( $master eq $info ) {
            $sf->__get_join_info();
            $sf->__print_join_info();
            next MASTER;
        }
        my $qt_master;
        if ( $master eq $from_subquery ) {
            require App::DBBrowser::Subqueries;
            my $sq = App::DBBrowser::Subqueries->new( $sf->{i}, $sf->{o}, $sf->{d} );
            $master = $sq->choose_subquery( $join );
            if ( ! defined $master ) {
                next MASTER;
            }
            $qt_master = $master;
        }
        else {
            $master =~ s/^-\s//;
            $qt_master = $ax->quote_table( $sf->{d}{tables_info}{$master} );
        }
        push @{$join->{used_tables}}, $master;
        $join->{default_alias} = 'A';
        $ax->print_sql( $join );
        # Readline
        my $master_alias = $ax->alias( 'join', $qt_master, $join->{default_alias} );
        push @{$join->{aliases}}, [ $master, $master_alias ];
        $join->{stmt} .= " " . $qt_master;
        $join->{stmt} .= " AS " . $ax->quote_col_qualified( [ $master_alias ] );
        if ( $master eq $qt_master ) {
            my $sth = $sf->{d}{dbh}->prepare( "SELECT * FROM " . $qt_master . " AS " . $master_alias . " LIMIT 0" );
            $sth->execute() if $sf->{i}{driver} ne 'SQLite';
            $sf->{d}{col_names}{$master} = $sth->{NAME};
        }
        my @bu;

        JOIN: while ( 1 ) {
            $ax->print_sql( $join );
            my $backup_join = $ax->backup_href( $join );
            my $enough_tables = '  Enough TABLES';
            my @pre = ( undef, $enough_tables );
            # Choose
            my $join_type = $stmt_v->choose(
                [ @pre, map { "- $_" } @{$sf->{join_types}} ],
                { prompt => 'Choose Join Type:' }
            );
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
            my $ok = $sf->__add_slave_with_join_condition( $join, $tables, $join_type, $info );
            if ( ! $ok ) {
                ( $join->{stmt}, $join->{default_alias}, $join->{aliases}, $join->{used_tables} ) = @{pop @bu};
            }
        }
        last MASTER;
    }

    my $aliases_by_tables = {};
    for my $ref ( @{$join->{aliases}} ) {
        push @{$aliases_by_tables->{$ref->[0]}}, $ref->[1];
    }
    my $qt_columns = [];
    for my $table ( @{$join->{used_tables}} ) {
        for my $alias ( @{$aliases_by_tables->{$table}} ) {
            for my $col ( @{$sf->{d}{col_names}{$table}} ) {
                my $col_qt = $ax->quote_col_qualified( [ undef, $alias, $col ] );
                if ( any { $_ eq $col_qt } @$qt_columns ) {
                    next;
                }
                push @$qt_columns, $col_qt;
            }
        }
    }
    my ( $qt_table ) = $join->{stmt} =~ /^SELECT\s\*\sFROM\s(.*)\z/;
    return $qt_table, $qt_columns;
}


sub __add_slave_with_join_condition {
    my ( $sf, $join, $tables, $join_type, $info ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $stmt_v = Term::Choose->new( $sf->{i}{lyt_stmt_v} );
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
    push @choices, $info;
    my @pre = ( undef );
    my @bu;

    SLAVE: while ( 1 ) {
        $ax->print_sql( $join );
        # Choose
        my $slave = $stmt_v->choose(
            [ @pre, @choices ],
            { prompt => 'Add a SLAVE table:', undef => $sf->{i}{_reset} }
        );
        if ( ! defined $slave ) {
            if ( @bu ) {
                ( $join->{stmt}, $join->{default_alias}, $join->{aliases}, $join->{used_tables} ) = @{pop @bu};
                next SLAVE;
            }
            return;
        }
        elsif ( $slave eq $info ) {
            $sf->__get_join_info();
            $sf->__print_join_info();
            next SLAVE;
        }
        my $qt_slave;
        if ( $slave eq $from_subquery ) {
            require App::DBBrowser::Subqueries;
            my $sq = App::DBBrowser::Subqueries->new( $sf->{i}, $sf->{o}, $sf->{d} );
            $slave = $sq->choose_subquery( $join );
            if ( ! defined $slave ) {
                next SLAVE;
            }
            $qt_slave = $slave;
        }
        else {
            $slave =~ s/^-\s//;
            $slave =~ s/\Q$used\E\z//;
            $qt_slave = $ax->quote_table( $sf->{d}{tables_info}{$slave} );
        }
        push @bu, [ $join->{stmt}, $join->{default_alias}, [ @{$join->{aliases}} ], [ @{$join->{used_tables}} ] ];
        push @{$join->{used_tables}}, $slave;
        $ax->print_sql( $join );
        # Readline
        my $slave_alias = $ax->alias( 'join', $qt_slave, ++$join->{default_alias} );
        $join->{stmt} .= " " . $qt_slave;
        $join->{stmt} .= " AS " . $ax->quote_col_qualified( [ $slave_alias ] );
        push @{$join->{aliases}}, [ $slave, $slave_alias ];
        $ax->print_sql( $join );
        if ( $slave eq $qt_slave ) {
            my $sth = $sf->{d}{dbh}->prepare( "SELECT * FROM " . $qt_slave . " AS " . $slave_alias . " LIMIT 0" );
            $sth->execute() if $sf->{i}{driver} ne 'SQLite';
            $sf->{d}{col_names}{$slave} = $sth->{NAME};
        }
        if ( $join_type ne 'CROSS JOIN' ) {
            my $ok = $sf->__add_join_condition( $join, $tables, $slave, $slave_alias );
            if ( ! $ok ) {
                ( $join->{stmt}, $join->{default_alias}, $join->{aliases}, $join->{used_tables} ) = @{pop @bu};
                next SLAVE;
            }
        }
        push @{$join->{used_tables}}, $slave;
        $ax->print_sql( $join );
        return 1;
    }
}


sub __add_join_condition {
    my ( $sf, $join, $tables, $slave, $slave_alias ) = @_;
    my $stmt_v = Term::Choose->new( $sf->{i}{lyt_stmt_v} );
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $aliases_by_tables = {};
    for my $ref ( @{$join->{aliases}} ) {
        push @{$aliases_by_tables->{$ref->[0]}}, $ref->[1];
    }
    my %avail_pk_cols;
    for my $used_table ( @{$join->{used_tables}} ) {
        for my $alias ( @{$aliases_by_tables->{$used_table}} ) {
            next if $used_table eq $slave && $alias eq $slave_alias;
            for my $col ( @{$sf->{d}{col_names}{$used_table}} ) {
                $avail_pk_cols{ $alias . '.' . $col } = $ax->quote_col_qualified( [ undef, $alias, $col ] );
            }
        }
    }
    my %avail_fk_cols;
    for my $col ( @{$sf->{d}{col_names}{$slave}} ) {
        $avail_fk_cols{ $slave_alias . '.' . $col } = $ax->quote_col_qualified( [ undef, $slave_alias, $col ] );
    }
    $join->{stmt} .= " ON";
    my $bu_stmt = $join->{stmt};
    my $AND = '';
    my @bu;

    JOIN_PREDICATE: while ( 1 ) {
        my @pre = ( undef, $AND ? $sf->{i}{_confirm} : () );
        my $fk_pre = '- ';

        PRIMARY_KEY: while ( 1 ) {
            $ax->print_sql( $join );
            # Choose
            my $pk_col = $stmt_v->choose(
                [ @pre,
                  map(    '- ' . $_, sort keys %avail_pk_cols ),
                  map( $fk_pre . $_, sort keys %avail_fk_cols ),
                ],
                { prompt => 'Choose PRIMARY KEY column:', undef => $sf->{i}{_back} }
            );
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
                ( my $condition = $join->{stmt} ) =~ s/^\Q$bu_stmt\E\s//;
                $join->{stmt} = $bu_stmt;
                $ax->print_sql( $join );
                my $tr = Term::Form->new();
                # Readline
                $condition = $tr->readline( 'Edit: ', { default => $condition, show_context => 1 } );
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
            $ax->print_sql( $join );
            # Choose
            my $fk_col = $stmt_v->choose(
                [ undef, map( "- $_", sort keys %avail_fk_cols ) ],
                { prompt => 'Choose FOREIGN KEY column:', undef => $sf->{i}{_back} }
            );
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
    print_table( $aref, { keep_header => 0, tab_width => 3, grid => 1 } );
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
            #push @{$pk->{$table}{KEY_SEQ}},     $ref->{KEY_SEQ} // $ref->{ORDINAL_POSITION};
        }
    }
    my $fk = {};
    for my $table ( @$tables ) {
        my $sth = $sf->{d}{dbh}->foreign_key_info( @{$td->{$table}}, undef, undef, undef );
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
