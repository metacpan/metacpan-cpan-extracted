package # hide from PAUSE
App::DBBrowser::Join_Union;

use warnings;
use strict;
use 5.008003;
no warnings 'utf8';

our $VERSION = '1.056';

use Clone                  qw( clone );
use List::MoreUtils        qw( any );
use Term::Choose           qw();
use Term::Choose::LineFold qw( line_fold );
use Term::Choose::Util     qw( term_width );

use if $^O eq 'MSWin32', 'Win32::Console::ANSI';

use App::DBBrowser::DB;



sub new {
    my ( $class, $info, $opt ) = @_;
    bless { info => $info, opt => $opt }, $class;
}


sub __union_tables {
    my ( $self, $sql, $dbh, $data ) = @_;
    my $db     = $sql->{print}{db};
    my $schema = $sql->{print}{schema};
    my $no_lyt = Term::Choose->new();
    my $u = $data;
    if ( ! defined $u->{col_names} || ! defined $u->{col_types} ) {
        my $obj_db = App::DBBrowser::DB->new( $self->{info}, $self->{opt} );
        ( $u->{col_names}, $u->{col_types} ) = $obj_db->column_names_and_types( $dbh, $db, $schema, $u->{tables} ); # ###
    }
    my $union = {
        unused_tables => [ map { "- $_" } @{$u->{tables}} ],
        used_tables   => [],
        used_cols     => {},
        saved_cols    => [],
    };

    UNION_TABLE: while ( 1 ) {
        my $enough_tables = '  Enough TABLES';
        my $all_tables    = '  All Tables';
        my $info          = '  INFO';
        my @pre_tbl  = ( undef, $enough_tables );
        my @post_tbl = ( $all_tables, $info );
        my $prompt   = $self->{union_all} ? 'One UNION table for cols:' : 'Choose UNION table:';
        my $choices  = [ @pre_tbl, map( "+ $_", @{$union->{used_tables}} ), @{$union->{unused_tables}}, @post_tbl ];
        $self->__print_union_statement( $union );
        # Choose
        my $idx_tbl = $no_lyt->choose(
            $choices,
            { %{$self->{info}{lyt_stmt_v}}, prompt => $prompt, index => 1 }
        );
        if ( ! defined $idx_tbl || ! defined $choices->[$idx_tbl] ) {
            return;
        }
        my $union_table = $choices->[$idx_tbl];
        if ( $union_table eq $info ) {
            if ( ! defined $u->{tables_info} ) {
                $u->{tables_info} = $self->__get_tables_info( $dbh, $db, $schema, $u, 'union' );
            }
            my $tbl_info = $self->__print_tables_info( $u );
            # Choose
            $no_lyt->choose(
                $tbl_info,
                { %{$self->{info}{lyt_3}}, prompt => '' }
            );
            next UNION_TABLE;
        }
        elsif ( $union_table eq $enough_tables ) {
            return if ! @{$union->{used_tables}};
            last UNION_TABLE;
        }
        elsif ( $union_table eq $all_tables ) {
            $union = {
                unused_tables => [ map { "- $_" } @{$u->{tables}} ],
                used_tables   => [],
                used_cols     => {},
                saved_cols    => [],
            };
            $self->{union_all} = 1;
            next UNION_TABLE;
        }
        my $backup_union = clone( $union );
        $union_table =~ s/^[-+]\s//;
        my $check_idx = $idx_tbl - ( @pre_tbl + @{$union->{used_tables}} );
        if ( $check_idx < 0 ) {
            my $idx_used_table = $idx_tbl - @pre_tbl;
            delete $union->{used_cols}{$union_table};
            $self->{idx_reset_used_tables} = $idx_used_table;
        }
        else {
            my $idx_unused_table = $check_idx;
            splice( @{$union->{unused_tables}}, $idx_unused_table, 1 );
            push @{$union->{used_tables}}, $union_table;
            $self->{idx_reset_used_tables} = -1;
        }

        UNION_COLUMN: while ( 1 ) {
            my ( $all_cols, $privious_cols, $void ) = ( q['*'], q['^'], q[' '] );
            my @short_cuts = ( ( @{$union->{saved_cols}} ? $privious_cols : $void ), $all_cols );
            my @pre_col = ( $self->{info}{ok}, @short_cuts );
            my $choices = [ @pre_col, @{$u->{col_names}{$union_table}} ];
            $self->__print_union_statement( $union );
            # Choose
            my @col = $no_lyt->choose(
                $choices,
                { %{$self->{info}{lyt_stmt_h}}, prompt => 'Choose Column:', no_spacebar => [ 0 .. $#pre_col ] }
            );
            if ( ! defined $col[0] ) {
                if ( defined $union->{used_cols}{$union_table} ) {
                    delete $union->{used_cols}{$union_table};
                    next UNION_COLUMN;
                }
                else {
                    delete $self->{union_all} if $self->{union_all};
                    $union = clone( $backup_union );
                    last UNION_COLUMN;
                }
            }
            elsif ( $col[0] eq $void ) {
                next UNION_COLUMN;
            }
            elsif ( $col[0] eq $privious_cols ) {
                $union->{used_cols}{$union_table} = $union->{saved_cols};
                last UNION_COLUMN;
            }
            elsif ( $col[0] eq $all_cols ) {
                @{$union->{used_cols}{$union_table}} = @{$u->{col_names}{$union_table}};
                $union->{saved_cols} = $union->{used_cols}{$union_table};
                last UNION_COLUMN;
            }
            elsif ( $col[0] eq $self->{info}{ok} ) {
                shift @col;
                push @{$union->{used_cols}{$union_table}}, @col;
                if ( ! @{$union->{used_cols}{$union_table}} ) {
                    my $table = splice( @{$union->{used_tables}}, $self->{idx_reset_used_tables}, 1 );
                    push @{$union->{unused_tables}}, "- $table";
                    delete $self->{idx_reset_used_tables};
                    delete $self->{union_all} if $self->{union_all};
                    next UNION_TABLE;
                }
                $union->{saved_cols} = $union->{used_cols}{$union_table};
                last UNION_COLUMN;
            }
            else {
                push @{$union->{used_cols}{$union_table}}, @col;
            }
        }
        if ( $self->{union_all} ) {
            my @selected_cols = @{$union->{used_cols}{$union_table}};
            $union = {
                unused_tables => [],
                used_tables   => [ @{$u->{tables}} ],
                used_cols     => {},
                saved_cols    => [],
            };
            for my $union_table ( @{$union->{used_tables}} ) {
                @{$union->{used_cols}{$union_table}} = @selected_cols;
            }
            last UNION_TABLE;
        }
    }


    # column names in the result-set of a UNION are taken from the first query.
    my $first_table = $union->{used_tables}[0];
    $sql->{print}{columns} = $union->{used_cols}{$first_table};
    for my $col ( @{$sql->{print}{columns}} ) {
        $sql->{quote}{columns}{$col} = $dbh->quote_identifier( $col );
    }
    my $c;
    $sql->{quote}{table} = "(";
    for my $table ( @{$union->{used_tables}} ) {
        $c++;
        $sql->{quote}{table} .= " SELECT ";
        $sql->{quote}{table} .= join( ', ', map { $dbh->quote_identifier( $_ ) } @{$union->{used_cols}{$table}} );
        $sql->{quote}{table} .= " FROM " . $dbh->quote_identifier( undef, $schema, $table );
        $sql->{quote}{table} .= $c < @{$union->{used_tables}} ? " UNION ALL " : " )";
    }
    if ( $self->{union_all} ) {  # alias: required if mysql, Pg, ...
        $sql->{quote}{table} .= " AS UNION_ALL_TABLES";
    }
    else {
        $sql->{quote}{table} .= " AS UNION_SELECTED_TABLES";
    }
    return 1;
}


sub __print_union_statement {
    my ( $self, $union ) = @_;
    my $str;
    if ( $self->{union_all} ) {
        $str = 'UNION ALL TABLES';
        if ( @{$union->{used_tables}} ) {
            $str .= "\n" . 'Cols: ';
            my $table = $union->{used_tables}[0];
            if ( defined $union->{used_cols}{$table} && @{$union->{used_cols}{$table}} ) { #
                $str .= join( ', ', @{$union->{used_cols}{$table}} );
            }
        }
        $str .= "\n";
    }
    else {
        $str = "SELECT * FROM (\n";
        if ( @{$union->{used_tables}} ) {
            my $c = 0;
            for my $table ( @{$union->{used_tables}} ) {
                ++$c;
                $str .= "  SELECT ";
                if ( defined $union->{used_cols}{$table} && @{$union->{used_cols}{$table}} ) { #
                    $str .= join( ', ', @{$union->{used_cols}{$table}} );
                }
                else {
                    $str .= '?';
                }
                $str .= " FROM $table";
                $str .= $c < @{$union->{used_tables}} ? " UNION ALL\n" : "\n";
            }
            $str .= ") AS ";
            $str .= 'Selected_Tables';
            $str .= " \n";
        }
    }
    $str .= "\n";
    print $self->{info}{clear_screen};
    print line_fold( $str, term_width() - 2, '', ' ' x $self->{info}{stmt_init_tab} );
}


sub __get_tables_info {
    my ( $self, $dbh, $db, $schema, $u_or_j, $type ) = @_;
    my $tables_info = {};
    my $obj_db = App::DBBrowser::DB->new( $self->{info}, $self->{opt} );
    my ( $pk, $fk ) = $obj_db->primary_and_foreign_keys( $dbh, $db, $schema, $u_or_j->{tables} ); # ###
    for my $table ( @{$u_or_j->{tables}} ) {
        push @{$tables_info->{$table}}, 'Table => ' . $table;
        if ( defined $u_or_j->{col_types}{$table} ) {
            push @{$tables_info->{$table}}, join( ' | ', map {
                            lc( $u_or_j->{col_types}{$table}[$_] )
                        . ' ' . $u_or_j->{col_names}{$table}[$_]   } 0 .. $#{$u_or_j->{col_names}{$table}} );
        }
        else {
            push @{$tables_info->{$table}}, join ' | ',  @{$u_or_j->{col_names}{$table}};
        }
        if ( $type eq 'join' ) {
            if ( defined $pk && @{$pk->{$table}} ) {
                push @{$tables_info->{$table}}, 'PK: primary key (' . join( ',', @{$pk->{$table}} ) . ')';
            }
            if ( defined $fk ) {
                for my $fk_name ( sort keys %{$fk->{$table}} ) {
                    if ( $fk->{$table}{$fk_name} ) {
                        push @{$tables_info->{$table}}, 'FK: '
                            . 'foreign key (' . join( ',', @{$fk->{$table}{$fk_name}{foreign_key_col}} )
                            . ') references ' . $fk->{$table}{$fk_name}{reference_table}
                            . '(' . join( ',', @{$fk->{$table}{$fk_name}{reference_key_col}} )
                            . ')';
                    }
                }
            }
        }
    }
    return $tables_info;
}


sub __print_tables_info {
    my ( $self, $ref ) = @_;
    my $col_max = term_width() - 1;
    my $ch_info = [ 'Close with ENTER' ];
    for my $table ( @{$ref->{tables}} ) {
        push @{$ch_info}, " ";
        for my $line ( @{$ref->{tables_info}{$table}} ) {
            my $text = line_fold( $line, $col_max, '', '' );
            push @{$ch_info}, split /\R+/, $text;
        }
    }
    return $ch_info;
}


sub __join_tables {
    my ( $self, $sql, $dbh, $data ) = @_;
    my $db     = $sql->{print}{db};
    my $schema = $sql->{print}{schema};
    my $stmt_v = Term::Choose->new( $self->{info}{lyt_stmt_v} );
    my $j = $data;
    if ( ! defined $j->{col_names} || ! defined $j->{col_types} ) {
        my $obj_db = App::DBBrowser::DB->new( $self->{info}, $self->{opt} );
        ( $j->{col_names}, $j->{col_types} ) = $obj_db->column_names_and_types( $dbh, $db, $schema, $j->{tables} ); # ###
    }
    my $join = {};

    MASTER: while ( 1 ) {
        $join = {};
        $join->{quote}{stmt} = "SELECT * FROM";
        $join->{print}{stmt} = "SELECT * FROM";
        $join->{primary_keys} = [];
        $join->{foreign_keys} = [];
        my @tables = map { "- $_" } @{$j->{tables}};
        my $info = '  INFO';
        my @pre = ( undef );
        my $choices = [ @pre, @tables, $info ];
        $self->__print_join_statement( $join->{print}{stmt} );
        # Choose
        my $idx = $stmt_v->choose(
            $choices,
            { prompt => 'Choose MASTER table:', index => 1 }
        );
        if ( ! defined $idx || ! defined $choices->[$idx] ) {
            return;
        }
        if ( $choices->[$idx] eq $info ) {
            if ( ! defined $j->{tables_info} ) {
                $j->{tables_info} = $self->__get_tables_info( $dbh, $db, $schema, $j, 'join' );
            }
            my $tbl_info = $self->__print_tables_info( $j );
            # Choose
            $stmt_v->choose(
                $tbl_info,
                { %{$self->{info}{lyt_3}}, prompt => '' }
            );
            next MASTER;
        }
        $idx -= @pre;
        ( my $master = splice( @tables, $idx, 1 ) ) =~ s/^-\s//;
        $join->{used_tables}  = [ $master ];
        $join->{avail_tables} = [ @tables ];
        $join->{table_alias} = 'a';
        $join->{quote}{stmt}  = "SELECT * FROM " . $dbh->quote_identifier( undef, $schema, $master ) . " AS " . $join->{table_alias};
        $join->{print}{stmt}  = "SELECT * FROM " .                 $master . " AS " . $join->{table_alias};
        $join->{alias}{$master} = $join->{table_alias};
        my $backup_master = clone( $join );

        JOIN: while ( 1 ) {
            my $idx;
            my $enough_slaves = '  Enough TABLES';
            my @pre = ( undef, $enough_slaves );
            my $backup_join = clone( $join );

            SLAVE: while ( 1 ) {
                my $choices = [ @pre, @{$join->{avail_tables}}, $info ];
                $self->__print_join_statement( $join->{print}{stmt} );
                # Choose
                $idx = $stmt_v->choose(
                    $choices,
                    { prompt => 'Add a SLAVE table:', index => 1, undef => $self->{info}{_reset} }
                );
                if ( ! defined $idx || ! defined $choices->[$idx] ) {
                    if ( @{$join->{used_tables}} == 1 ) {
                        next MASTER;
                    }
                    else {
                        $join = clone( $backup_master );
                        next JOIN;
                    }
                }
                elsif ( $choices->[$idx] eq $enough_slaves ) {
                    last JOIN;
                }
                elsif ( $choices->[$idx] eq $info ) {
                    if ( ! defined $j->{tables_info} ) {
                        $j->{tables_info} = $self->__get_tables_info( $dbh, $db, $schema, $j, 'join' );
                    }
                    my $tbl_info = $self->__print_tables_info( $j );
                    # Choose
                    $stmt_v->choose(
                        $tbl_info,
                        { %{$self->{info}{lyt_3}}, prompt => '' }
                    );
                    next SLAVE;
                }
                else {
                    last SLAVE;
                }
            }
            $idx -= @pre;
            ( my $slave = splice( @{$join->{avail_tables}}, $idx, 1 ) ) =~ s/^-\s//;
            $join->{table_alias}++;
            $join->{quote}{stmt} .= " LEFT OUTER JOIN " . $dbh->quote_identifier( undef, $schema, $slave ) . " AS " . $join->{table_alias} . " ON";
            $join->{print}{stmt} .= " LEFT OUTER JOIN " .                                         $slave .   " AS " . $join->{table_alias} . " ON";
            $join->{alias}{$slave} = $join->{table_alias};
            my %avail_pk_cols;
            for my $used_table ( @{$join->{used_tables}} ) {
                for my $col ( @{$j->{col_names}{$used_table}} ) {
                    $avail_pk_cols{ $join->{alias}{$used_table} . '.' . $col } = $dbh->quote_identifier( undef, $join->{alias}{$used_table}, $col );
                }
            }
            my %avail_fk_cols;
            for my $col ( @{$j->{col_names}{$slave}} ) {
                $avail_fk_cols{ $join->{alias}{$slave} . '.' . $col } = $dbh->quote_identifier( undef, $join->{alias}{$slave}, $col );
            }
            my $AND = '';

            ON: while ( 1 ) {
                my @pre = ( undef );
                $self->__print_join_statement( $join->{print}{stmt} );
                push @pre, $self->{info}{_continue} if $AND;
                # Choose
                my $pk_col = $stmt_v->choose(
                    [ @pre, map( "- $_", sort keys %avail_pk_cols ) ],
                    { prompt => 'Choose PRIMARY KEY column:', undef => $self->{info}{_reset} }
                );
                if ( ! defined $pk_col ) {
                    $join = clone( $backup_join );
                    next JOIN;
                }
                if ( $pk_col eq $self->{info}{_continue} ) {
                    if ( @{$join->{primary_keys}} == @{$backup_join->{primary_keys}} ) {
                        $join = clone( $backup_join );
                        next JOIN;
                    }
                    last ON;
                }
                $pk_col =~ s/^-\s//;
                push @{$join->{primary_keys}}, $avail_pk_cols{$pk_col};
                $join->{quote}{stmt} .= $AND;
                $join->{print}{stmt} .= $AND;
                $join->{quote}{stmt} .= ' ' . $avail_pk_cols{$pk_col} . " =";
                $join->{print}{stmt} .= ' ' .                $pk_col  . " =";
                $self->__print_join_statement( $join->{print}{stmt} );
                # Choose
                my $fk_col = $stmt_v->choose(
                    [ undef, map( "- $_", sort keys %avail_fk_cols ) ],
                    { prompt => 'Choose FOREIGN KEY column:', undef => $self->{info}{_reset} }
                );
                if ( ! defined $fk_col ) {
                    $join = clone( $backup_join );
                    next JOIN;
                }
                $fk_col =~ s/^-\s//;
                push @{$join->{foreign_keys}}, $avail_fk_cols{$fk_col};
                $join->{quote}{stmt} .= ' ' . $avail_fk_cols{$fk_col};
                $join->{print}{stmt} .= ' ' .                $fk_col;
                $AND = " AND";
            }
            push @{$join->{used_tables}}, $slave;
        }
        last MASTER;
    }

    for my $table ( @{$join->{used_tables}} ) {
        for my $col ( @{$j->{col_names}{$table}} ) {
            my $col_qt = $dbh->quote_identifier( undef, $join->{alias}{$table}, $col );
            if ( any { $_ eq $col_qt } @{$join->{foreign_keys}} ) {
                next;
            }
            my $col_pr = $join->{alias}{$table} . '.' . $col;
            #if ( any { $_ eq $col_pr } @not_unique_col ) {
                $col_qt .= " AS " . $dbh->quote_identifier( $col . '-' . $table );
            #}
            push @{$sql->{print}{columns}}, $col_pr;
            $sql->{quote}{columns}{$col_pr} = $col_qt;
        }
    }
    my ( $qt_table ) = $join->{quote}{stmt} =~ /^SELECT\s\*\sFROM\s(.*)\z/;
    $sql->{quote}{table} = $qt_table;
    return 1;
}


sub __print_join_statement {
    my ( $self, $join_stmt_pr ) = @_;
    $join_stmt_pr =~ s/(?=\sLEFT\sOUTER\sJOIN)/\n\ /g;
    $join_stmt_pr .= "\n\n";
    print $self->{info}{clear_screen};
    print line_fold( $join_stmt_pr, term_width() - 2, '', ' ' x $self->{info}{stmt_init_tab} );
}





1;

__END__
