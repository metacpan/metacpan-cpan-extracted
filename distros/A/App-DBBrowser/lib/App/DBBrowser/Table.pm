package # hide from PAUSE
App::DBBrowser::Table;

use warnings;
use strict;
use 5.008003;
no warnings 'utf8';

our $VERSION = '2.006';

use List::MoreUtils qw( any first_index );

use Term::Choose     qw( choose );
use Term::Form       qw();
#use Term::TablePrint qw(print_table);

use if $^O eq 'MSWin32', 'Win32::Console::ANSI';

use App::DBBrowser::Auxil;
use App::DBBrowser::DB;
use App::DBBrowser::Table::Functions;
#use App::DBBrowser::Table::Insert;  # "require"-d
use App::DBBrowser::Table::Substatements;


sub new {
    my ( $class, $info, $opt ) = @_;
    bless { i => $info, o => $opt }, $class;
}


sub on_table {
    my ( $sf, $sql, $dbh ) = @_;
    my $stmt_h = Term::Choose->new( $sf->{i}{lyt_stmt_h} );
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o} );
    my $sb = App::DBBrowser::Table::Substatements->new( $sf->{i}, $sf->{o} );
    my $sub_stmts = {
        Select => [ qw( print_tbl columns aggregate distinct where group_by having order_by limit functions lock ) ],
        Delete => [ qw( commit     where functions ) ],
        Update => [ qw( commit set where functions ) ],
    };
    my $lk = [ '  Lk0', '  Lk1' ];
    my %cu = (
        commit          => '  CONFIRM Stmt',
        hidden          => 'Customize:',
        print_tbl       => 'Print TABLE',
        columns         => '- SELECT',
        set             => '- SET',
        aggregate       => '- AGGREGATE',
        distinct        => '- DISTINCT',
        where           => '- WHERE',
        group_by        => '- GROUP BY',
        having          => '- HAVING',
        order_by        => '- ORDER BY',
        limit           => '- LIMIT',
        lock            => $lk->[$sf->{i}{lock}],
        functions       => '  Func',
    );
    my @aggregate = ( "AVG(X)", "COUNT(X)", "COUNT(*)", "MAX(X)", "MIN(X)", "SUM(X)" ); #
    my ( $DISTINCT, $ALL, $ASC, $DESC, $AND, $OR ) = ( "DISTINCT", "ALL", "ASC", "DESC", "AND", "OR" ); #
    if ( $sf->{i}{lock} == 0 ) {
        $ax->reset_sql( $sql );
    }
    my $stmt_type = 'Select';
    my $backup_sql;
    my $old_idx = 1;
    my @pre = ( undef, $sf->{i}{ok} );

    CUSTOMIZE: while ( 1 ) {
        $backup_sql = $ax->backup_href( $sql ) if $stmt_type eq 'Select'; #
        my $choices = [ $cu{hidden}, undef, @cu{@{$sub_stmts->{$stmt_type}}} ];
        $ax->print_sql( $sql, [ $stmt_type ] );
        # Choose
        $ENV{TC_RESET_AUTO_UP} = 0;
        my $idx = choose(
            $choices,
            { %{$sf->{i}{lyt_stmt_v}}, prompt => '', index => 1, default => $old_idx,
            undef => $stmt_type ne 'Select' ? $sf->{i}{_back} : $sf->{i}{back} }
        );
        if ( ! defined $idx || ! defined $choices->[$idx] ) {
            if ( $stmt_type eq 'Select'  ) {
                last CUSTOMIZE;
            }
            elsif( $stmt_type eq 'Delete' || $stmt_type eq 'Update' ) {
                if ( $sql->{where_stmt} || $sql->{set_stmt} ) {
                    $ax->reset_sql( $sql );
                }
                else {
                    $stmt_type = 'Select';
                    $old_idx = 1;
                    $sql = $backup_sql;
                }
                next CUSTOMIZE;
            }
            else { die $stmt_type }
        }
        my $custom = $choices->[$idx];
        if ( $sf->{o}{G}{menu_memory} ) {
            if ( $old_idx == $idx && ! $ENV{TC_RESET_AUTO_UP} ) {
                $old_idx = 1;
                next CUSTOMIZE;
            }
            else {
                $old_idx = $idx;
            }
        }
        delete $ENV{TC_RESET_AUTO_UP};
        if ( $custom eq $cu{'lock'} ) {
            $sf->{i}{lock} = ! $sf->{i}{lock};
            $cu{lock} = $lk->[ $sf->{i}{lock} ];
            if ( ! $sf->{i}{lock} ) {
                $ax->reset_sql( $sql );
            }
        }
        elsif ( $custom eq $cu{'columns'} ) {
            if ( ! ( $sql->{select_type} eq '*' || $sql->{select_type} eq 'chosen_cols' ) ) {
                $ax->reset_sql( $sql );
            }
            my $tmp = $sb->columns( $dbh, $stmt_h, $sql, $stmt_type );
            if ( defined $tmp ) {
                $sql->{$_} = $tmp->{$_} for keys %$tmp;
            }
        }
        elsif ( $custom eq $cu{'distinct'} ) {
            my $tmp = $sb->distinc( $stmt_h, $sql, $stmt_type );
            if ( defined $tmp ) {
                $sql->{$_} = $tmp->{$_} for keys %$tmp;
            }
        }
        elsif ( $custom eq $cu{'aggregate'} ) {
            if ( $sql->{select_type} eq '*' || $sql->{select_type} eq 'chosen_cols' ) {
                $ax->reset_sql( $sql );
            }
            my $tmp = $sb->aggregate( $dbh, $stmt_h, $sql, $stmt_type );
            if ( defined $tmp ) {
                $sql->{$_} = $tmp->{$_} for keys %$tmp;
            }
        }
        elsif ( $custom eq $cu{'set'} ) {
            my $tmp = $sb->set( $stmt_h, $sql, $stmt_type );
            if ( defined $tmp ) {
                $sql->{$_} = $tmp->{$_} for keys %$tmp;
            }
        }
        elsif ( $custom eq $cu{'where'} ) {
            my $tmp = $sb->where( $stmt_h, $sql, $stmt_type );
            if ( defined $tmp ) {
                $sql->{$_} = $tmp->{$_} for keys %$tmp;
            }
        }
        elsif ( $custom eq $cu{'group_by'} ) {
            if ( $sql->{select_type} eq '*' || $sql->{select_type} eq 'chosen_cols' ) {
                $ax->reset_sql( $sql );
            }
            my $tmp = $sb->group_by( $stmt_h, $sql, $stmt_type );
            if ( defined $tmp ) {
                $sql->{$_} = $tmp->{$_} for keys %$tmp;
            }
        }
        elsif ( $custom eq $cu{'having'} ) {
            my $tmp = $sb->having( $stmt_h, $sql, $stmt_type );
            if ( defined $tmp ) {
                $sql->{$_} = $tmp->{$_} for keys %$tmp;
            }
        }
        elsif ( $custom eq $cu{'order_by'} ) {
            my $tmp = $sb->order_by( $stmt_h, $sql, $stmt_type );
            if ( defined $tmp ) {
                $sql->{$_} = $tmp->{$_} for keys %$tmp;
            }
        }
        elsif ( $custom eq $cu{'limit'} ) {
            my $tmp = $sb->limit_offset( $stmt_h, $sql, $stmt_type );
            if ( defined $tmp ) {
                $sql->{$_} = $tmp->{$_} for keys %$tmp;
            }
        }
        elsif ( $custom eq $cu{'hidden'} ) { # insert/update/delete
            $stmt_type = $sf->__table_write_access( $sql, $stmt_type );
            if ( $stmt_type eq 'Insert' ) {
                require App::DBBrowser::Table::Insert;
                my $tbl_in = App::DBBrowser::Table::Insert->new( $sf->{i}, $sf->{o} );
                my $ok = $tbl_in->build_insert_stmt( $sql, [ $stmt_type ], $dbh );
                if ( $ok ) {
                    $ok = $sf->commit_sql( $sql, [ $stmt_type ], $dbh );
                }
                $stmt_type = 'Select';
                $sql = $backup_sql;
                next CUSTOMIZE;
            }
            $old_idx = 1;
        }
        elsif ( $custom eq $cu{'functions'} ) {
            my $nh = App::DBBrowser::Table::Functions->new( $sf->{i}, $sf->{o} );
            my $ok = $nh->col_function( $dbh, $sql, $stmt_type ); #
            if ( ! $ok ) {
                $sql = $backup_sql;
                next CUSTOMIZE;
            }
        }
        elsif ( $custom eq $cu{'print_tbl'} ) {
            my $cols_sql = " ";
            if ( $sql->{select_type} eq '*' ) {
                if ( $sf->{i}{multi_tbl} eq 'join' ) {          # ?
                    $cols_sql .= join( ', ', @{$sql->{cols}} ); #
                }                                               #
                else {
                    $cols_sql .= "*";
                }
            }
            elsif ( $sql->{select_type} eq 'chosen_cols' ) {
                $cols_sql .= $ax->__cols_as_string( $sql, 'chosen_cols' );
            }
            elsif ( @{$sql->{aggr_cols}} || @{$sql->{group_by_cols}} ) {
                $cols_sql .= $ax->__cols_as_string( $sql, 'aggr_and_group_by_cols' ); #
            }
            #else {
            #    $cols_sql .= "*";
            #}
            my $select .= "SELECT" . $sql->{distinct_stmt} . $cols_sql;
            $select .= " FROM " . $sql->{table};
            $select .= $sql->{where_stmt};
            $select .= $sql->{group_by_stmt};
            $select .= $sql->{having_stmt};
            $select .= $sql->{order_by_stmt};
            $select .= $sql->{limit_stmt};
            $select .= $sql->{offset_stmt};
            if ( $sf->{o}{G}{max_rows} && ! $sql->{limit_stmt} ) {
                $select .= sprintf " LIMIT %d", $sf->{o}{G}{max_rows};
                $sf->{o}{table}{max_rows} = $sf->{o}{G}{max_rows};
            }
            else {
                $sf->{o}{table}{max_rows} = 0;
            }
            my @arguments = ( @{$sql->{select_sq_args}}, @{$sql->{where_args}}, @{$sql->{having_args}} ); # select_args
            if ( $sf->{o}{G}{expert_subqueries} ) {
                my $tmp;
                if ( @{$sf->{i}{stmt_history}||[]} ) {
                    if ( $select . join( ',', @arguments ) ne $sf->{i}{stmt_history}[0] . join( ',', @{$sf->{i}{stmt_history}[1]||[]} ) ) {
                        $tmp = $select;
                    }
                }
                else {
                    $tmp = $select;
                }
                if ( $sf->{o}{G}{max_rows} && ! $sql->{limit_stmt} ) {
                    $tmp =~ s/ LIMIT \Q$sf->{o}{G}{max_rows}\E\z//;
                }
                unshift @{$sf->{i}{stmt_history}}, [ $tmp, \@arguments ];
                $#{$sf->{i}{stmt_history}} = 19 if $#{$sf->{i}{stmt_history}} > 19;
            }
            local $| = 1;
            print $sf->{i}{clear_screen};
            my $sth = $dbh->prepare( $select );
            print 'Execute ...' . "\n" if $sf->{o}{table}{progress_bar};
            $sth->execute( @arguments );
            my $col_names = $sth->{NAME}; # not quoted
            my $all_arrayref = $sth->fetchall_arrayref;
            unshift @$all_arrayref, $col_names;
            print $sf->{i}{clear_screen};
            # return $sql explicitly since after a restore backup refers to a different hash. ?
            return $all_arrayref, $sql;
        }
        elsif ( $custom eq $cu{'commit'} ) {
            my $ok = $sf->commit_sql( $sql, [ $stmt_type ], $dbh );
            $stmt_type = 'Select';
            $old_idx = 1;
            $sql = $backup_sql;
            next CUSTOMIZE;
        }
        else {
            die "$custom: no such value in the hash \%cu";
        }
    }
    return;
}


sub commit_sql {
    my ( $sf, $sql, $stmt_typeS, $dbh ) = @_;
    my $ax  = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o} );
    my $stmt_v = Term::Choose->new( $sf->{i}{lyt_stmt_v} );
    local $| = 1;
    print $sf->{i}{clear_screen};
    print 'DB work ...' . "\n" if $sf->{o}{table}{progress_bar}; #
    my $transaction;
    eval { $transaction = $dbh->begin_work } or do { $dbh->{AutoCommit} = 1; $transaction = 0 };
    my $rows_to_execute = [];
    #my $row_count;
    my $stmt;
    my $stmt_type = $stmt_typeS->[-1];
    if ( $stmt_type eq 'Insert' ) {
        if ( ! @{$sql->{insert_into_args}} ) {
            return 1; #
        }
        $stmt  = sprintf "INSERT INTO %s (%s) VALUES(%s)",
                            $sql->{table},
                            join( ', ', @{$sql->{insert_into_cols}} ),
                            join( ', ', ( '?' ) x @{$sql->{insert_into_cols}} );
        $rows_to_execute = $sql->{insert_into_args};
        #$row_count = @$rows_to_execute;
    }
    else {
        my %map_stmt_types = (
            Update => "UPDATE",
            Delete => "DELETE",
        );
        $stmt  = $map_stmt_types{$stmt_type};
        $stmt .= " FROM"               if $map_stmt_types{$stmt_type} eq "DELETE";
        $stmt .= ' ' . $sql->{table};
        $stmt .= $sql->{set_stmt}      if $sql->{set_stmt};
        $stmt .= $sql->{where_stmt}    if $sql->{where_stmt};
        $rows_to_execute->[0] = [ @{$sql->{set_args}}, @{$sql->{where_args}} ];
        #if ( ! eval {
        #    my $sth = $dbh->prepare( "SELECT * FROM " . $sql->{table} . ( $sql->{where_stmt} ? $sql->{where_stmt} : '' ) );
        #    $sth->execute( @{$sql->{where_args}} );
        #    my $col_names = $sth->{NAME};
        #    my $all_arrayref = $sth->fetchall_arrayref;
        #    $row_count = @$all_arrayref;
        #    unshift @$all_arrayref, $col_names;
        #    my $prompt_pt = "ENTER to continue\n$stmt_type - affected records:\n";
        #    print_table( $all_arrayref, { %{$sf->{o}{table}}, prompt => $prompt_pt, max_rows => 0, table_expand => 0 } ); #
        #    die "'row_count' undefined" if ! defined $row_count;
        #    1 }
        #) {
        #    $ax->print_error_message( "$@Fetching info: affected records ...\n", $stmt_type );
        #}
    }
    if ( $transaction ) {
        my $rolled_back;
        if ( ! eval {
            my $sth = $dbh->prepare( $stmt );
            for my $values ( @$rows_to_execute ) {
                $sth->execute( @$values );
            }
            my $row_count = $stmt_type eq 'Insert' ? @$rows_to_execute : $sth->rows;
            my $commit_ok = sprintf qq(  %s %d "%s"), 'COMMIT', $row_count, $stmt_type;
            $ax->print_sql( $sql, $stmt_typeS );
            # Choose
            my $choice = $stmt_v->choose(
                [ undef,  $commit_ok ]
            );
            if ( ! defined $choice || $choice ne $commit_ok ) {
                $dbh->rollback;
                $rolled_back = 1;
            }
            else {;
                $dbh->commit;
            }
            1 }
        ) {
            $ax->print_error_message( "$@Rolling back ...\n", 'Commit' );
            $dbh->rollback;
            $rolled_back = 1;
        }
        if ( $rolled_back ) {
            return;
        }
        return 1;
    }
    else {
#
        my $row_count;
        if ( $stmt_type eq 'Insert' ) {
            $row_count = @$rows_to_execute;
        }
        else {
            my $count_stmt;
            $count_stmt .= "SELECT COUNT(*) FROM " . $sql->{table};
            $count_stmt .= $sql->{where_stmt};
            ( $row_count ) = $dbh->selectrow_array( $count_stmt, undef, @{$sql->{where_args}} );
        }
#
        my $commit_ok = sprintf qq(  %s %d "%s"), 'EXECUTE', $row_count, $stmt_type;
        $ax->print_sql( $sql, $stmt_typeS ); #
        # Choose
        my $choice = $stmt_v->choose(
            [ undef,  $commit_ok ],
            { prompt => '' }
        );
        if ( ! defined $choice || $choice ne $commit_ok ) {
            return;
        }
        if ( ! eval {
            my $sth = $dbh->prepare( $stmt );
            for my $values ( @$rows_to_execute ) {
                $sth->execute( @$values );
            }
            1 }
        ) {
            $ax->print_error_message( $@, 'Commit' );
            return;
        }
        return 1;
    }
}


sub __table_write_access {
    my ( $sf, $sql, $stmt_type ) = @_;
    my @stmt_types;
    if ( ! $sf->{i}{multi_tbl} ) {
        push @stmt_types, 'Insert' if $sf->{o}{G}{insert_ok};
        push @stmt_types, 'Update' if $sf->{o}{G}{update_ok};
        push @stmt_types, 'Delete' if $sf->{o}{G}{delete_ok};
    }
    elsif ( $sf->{i}{multi_tbl} eq 'join' && $sf->{i}{driver} eq 'mysql' ) {
        push @stmt_types, 'Update' if $sf->{o}{G}{update_ok};
    }
    if ( ! @stmt_types ) {
        return $stmt_type; #
    }
    # Choose
    my $type_choice = choose(
        [ undef, map( "- $_", @stmt_types ) ],
        { %{$sf->{i}{lyt_3}}, prompt => 'Choose SQL type:' }
    );
    if ( defined $type_choice ) {
        ( $stmt_type = $type_choice ) =~ s/^-\ //;
        my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o} );
        $ax->reset_sql( $sql );
    }
    return $stmt_type;
}


1;


__END__
