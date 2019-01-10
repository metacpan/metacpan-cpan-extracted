package # hide from PAUSE
App::DBBrowser::Join;

use warnings;
use strict;
use 5.008003;

use List::MoreUtils qw( any );

use Term::Choose     qw( choose );
use Term::TablePrint qw( print_table );

use App::DBBrowser::Auxil;


sub new {
    my ( $class, $info, $options, $data ) = @_;
    my $sf = {
        i => $info,
        o => $options,
        d => $data,
    };
    if ( $data->{driver} eq 'SQLite' ) {
        $sf->{join_types} = [ 'INNER JOIN', 'LEFT OUTER JOIN', 'CROSS JOIN' ];
    }
    elsif ( $data->{driver} =~ /^(?:mysql|MariaDB)\z/ ) {
        $sf->{join_types} = [ 'INNER JOIN', 'LEFT OUTER JOIN', 'RIGHT OUTER JOIN', 'CROSS JOIN' ];
    }
    else {
        $sf->{join_types} = [ 'INNER JOIN', 'LEFT OUTER JOIN', 'RIGHT OUTER JOIN', 'FULL OUTER JOIN', 'CROSS JOIN' ];
    }
    $sf->{joined_join_types} = join '|', map { quotemeta } @{$sf->{join_types}};
    bless $sf, $class;
}


sub join_tables {
    my ( $sf ) = @_;
    my $stmt_v = Term::Choose->new( $sf->{i}{lyt_stmt_v} );
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $j = $sf->{d}; # ###
    my $tables = [ sort keys %{$j->{tables_info}} ];
    ( $j->{col_names}, $j->{col_types} ) = $ax->column_names_and_types( $tables );
    my $join = {};

    MASTER: while ( 1 ) {
        $join = {};
        $join->{stmt} = "SELECT * FROM";
        $join->{primary_keys} = [];
        $join->{foreign_keys} = [];
        $join->{used_tables}  = [];
        $join->{aliases}      = [];
        $ax->print_sql( $join, [ 'Join' ] );
        my $info   = '  INFO';
        my @pre = ( undef );
        my $choices = [ @pre, map( "- $_", @$tables ), $info ];
        # Choose
        my $master = $stmt_v->choose(
            $choices,
            { prompt => 'Choose MASTER table:' }
        );
        if ( ! defined $master ) {
            return;
        }
        if ( $master eq $info ) {
            $sf->__get_join_info();
            $sf->__print_join_info();
            next MASTER;
        }
        $master =~ s/^-\s//;
        push @{$join->{used_tables}}, $master;
        $join->{default_alias} = $sf->{d}{driver} eq 'Pg' ? 'a' : 'A';
        my $qt_master = $ax->quote_table( $j->{tables_info}{$master} );
        $join->{stmt} = "SELECT * FROM " . $qt_master;
        $ax->print_sql( $join, [ 'Join' ] );
        # Readline
        my $alias = $ax->alias( 'join', $qt_master . ' AS: ', $join->{default_alias}, ' ' );
        push @{$join->{aliases}}, [ $master, $alias ];
        $join->{stmt} .= " AS " . $ax->quote_col_qualified( [ $alias ] );
        my @bu;

        JOIN: while ( 1 ) {
            $ax->print_sql( $join, [ 'Join' ] );
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
            my $ok = $sf->__add_slave_and_condition( $j, $join, $tables, $join_type, $info );
            if ( ! $ok ) {
                ( $join->{stmt}, $join->{default_alias}, $join->{aliases}, $join->{used_tables} ) = @{pop @bu};
            }
        }
        last MASTER;
    }

    my $alias = {};
    for my $ref ( @{$join->{aliases}} ) {
        push @{$alias->{$ref->[0]}}, $ref->[1];
    }
    my $qt_columns = [];
    for my $table ( @{$join->{used_tables}} ) {
        for my $alias ( @{$alias->{$table}} ) {
            for my $col ( @{$j->{col_names}{$table}} ) {
                my $col_qt = $ax->quote_col_qualified( [ undef, $alias, $col ] );
                #if ( any { $_ eq $col_qt } @{$join->{foreign_keys}} ) {
                #    next;
                #}
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


sub __add_slave_and_condition {
    my ( $sf, $j, $join, $tables, $join_type, $info ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $stmt_v = Term::Choose->new( $sf->{i}{lyt_stmt_v} );
    my $used = ' (used)';
    my @tmp;
    for my $table ( @$tables ) {
        if ( any { $_ eq $table } @{$join->{used_tables}} ) {
            push @tmp, $table . $used;
        }
        else {
            push @tmp, $table;
        }
    }
    my @pre = ( undef );
    my $choices = [ @pre, map( "- $_", @tmp ), $info ];
    my @bu;

    SLAVE: while ( 1 ) {
        $ax->print_sql( $join, [ 'Join' ] );
        # Choose
        my $slave = $stmt_v->choose(
            $choices,
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
        $slave =~ s/^-\s//;
        $slave =~ s/\Q$used\E\z//;
        push @bu, [ $join->{stmt}, $join->{default_alias}, [ @{$join->{aliases}} ], [ @{$join->{used_tables}} ] ];
        push @{$join->{used_tables}}, $slave;
        my $qt_slave = $ax->quote_table( $j->{tables_info}{$slave} );
        $join->{stmt} .= " " . $qt_slave;
        $ax->print_sql( $join, [ 'Join' ] );
        # Readline
        my $slave_alias = $ax->alias( 'join', $qt_slave . ' AS: ', ++$join->{default_alias}, ' ' );
        $join->{stmt} .= " AS " . $ax->quote_col_qualified( [ $slave_alias ] );
        push @{$join->{aliases}}, [ $slave, $slave_alias ];
        $ax->print_sql( $join, [ 'Join' ] );
        if ( $join_type ne 'CROSS JOIN' ) {
            my $ok = $sf->__add_join_condition( $j, $join, $tables, $slave, $slave_alias );
            if ( ! $ok ) {
                ( $join->{stmt}, $join->{default_alias}, $join->{aliases}, $join->{used_tables} ) = @{pop @bu};
                next SLAVE;
            }
        }
        push @{$join->{used_tables}}, $slave;
        $ax->print_sql( $join, [ 'Join' ] );
        return 1;
    }
}




sub __add_join_condition {
    my ( $sf, $j, $join, $tables, $slave, $slave_alias ) = @_;
    my $stmt_v = Term::Choose->new( $sf->{i}{lyt_stmt_v} );
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $alias = {};
    for my $ref ( @{$join->{aliases}} ) {
        push @{$alias->{$ref->[0]}}, $ref->[1];
    }
    my %avail_pk_cols;
    for my $used_table ( @{$join->{used_tables}} ) {
        for my $alias ( @{$alias->{$used_table}} ) {
            #if ( $used_table eq $slave && $alias eq $slave_alias ) {
            #    # if not next but kept, I can see matching column names when choosing the primary key
            #    next; # or make the key look a little different
            #}
            #else {
                for my $col ( @{$j->{col_names}{$used_table}} ) {
                    $avail_pk_cols{ $alias . '.' . $col } = $ax->quote_col_qualified( [ undef, $alias, $col ] );
                }
            #}
        }
    }
    my %avail_fk_cols;
    for my $col ( @{$j->{col_names}{$slave}} ) {
        $avail_fk_cols{ $slave_alias . '.' . $col } = $ax->quote_col_qualified( [ undef, $slave_alias, $col ] );
    }
    $join->{stmt} .= " ON";
    my $AND = '';
    my @bu_primary_key;
    my @bu_foreign_key;

    JOIN_PREDICATE: while ( 1 ) {
        my @pre = ( undef );
        if ( $AND && @{$join->{primary_keys}} == @{$join->{foreign_keys}} ) {
            push @pre, $sf->{i}{_confirm};
        }

        PRIMARY_KEY: while ( 1 ) {
            $ax->print_sql( $join, [ 'Join' ] );
            # Choose
            my $pk_col = $stmt_v->choose(
                [ @pre, map( "- $_", sort keys %avail_pk_cols ) ],
                { prompt => 'Choose PRIMARY KEY column:', index => 0, undef => $sf->{i}{_back} }
            );
            if ( ! defined $pk_col ) {
                if ( @bu_foreign_key ) {
                    ( $join->{stmt}, $join->{primary_keys}, $join->{foreign_keys}, $AND ) = @{pop @bu_foreign_key};
                    last PRIMARY_KEY;
                }
                return;
            }
            if ( $pk_col eq $sf->{i}{_confirm} ) {
                if ( ! $AND ) {
                    return;
                }
                return 1;
            }
            $pk_col =~ s/^-\s//;
            push @bu_primary_key, [ $join->{stmt}, [ @{$join->{primary_keys}} ], [ @{$join->{foreign_keys}} ], $AND ];
            push @{$join->{primary_keys}}, $avail_pk_cols{$pk_col};
            $join->{stmt} .= $AND;
            $join->{stmt} .= " " . $avail_pk_cols{$pk_col};
            last PRIMARY_KEY;
        }

        FOREIGN_KEY: while ( 1 ) {
            $ax->print_sql( $join, [ 'Join' ] );
            # Choose
            my $fk_col = $stmt_v->choose(
                [ undef, map( "- $_", sort keys %avail_fk_cols ) ],
                { prompt => 'Choose FOREIGN KEY column:', index => 0, undef => $sf->{i}{_back} }
            );
            if ( ! defined $fk_col ) {
                ( $join->{stmt}, $join->{primary_keys}, $join->{foreign_keys}, $AND ) = @{pop @bu_primary_key};
                next JOIN_PREDICATE;
            }
            $fk_col =~ s/^-\s//;
            push @bu_foreign_key, [ $join->{stmt}, [ @{$join->{primary_keys}} ], [ @{$join->{foreign_keys}} ], $AND ];
            push @{$join->{foreign_keys}}, $avail_fk_cols{$fk_col};
            $join->{stmt} .= " = " . $avail_fk_cols{$fk_col};
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
