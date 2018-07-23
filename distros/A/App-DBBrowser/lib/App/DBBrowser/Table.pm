package # hide from PAUSE
App::DBBrowser::Table;

use warnings;
use strict;
use 5.008003;
no warnings 'utf8';

use Term::Choose            qw( choose );
use Term::Choose::Constants qw( :screen );
use Term::TablePrint        qw( print_table );

use if $^O eq 'MSWin32', 'Win32::Console::ANSI';

use App::DBBrowser::Auxil;
use App::DBBrowser::DB;
use App::DBBrowser::Table::Functions;
#use App::DBBrowser::Table::Insert;  # "require"-d
use App::DBBrowser::Table::Substatements;



sub new {
    my ( $class, $info, $options, $data ) = @_;
    bless {
        i => $info,
        o => $options,
        d => $data
    }, $class;
}


sub on_table {
    my ( $sf, $sql ) = @_;
    my $stmt_h = Term::Choose->new( $sf->{i}{lyt_stmt_h} );
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $sb = App::DBBrowser::Table::Substatements->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $sub_stmts = [ qw( print_tbl columns aggregate distinct where group_by having order_by limit functions lock ) ];
    my $lk = [ '  Lk0', '  Lk1' ];
    my %cu = (
        hidden          => 'Customize:',
        print_tbl       => 'Print TABLE',
        columns         => '- SELECT',
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
    if ( $sf->{i}{lock} == 0 ) {
        $ax->reset_sql( $sql );
    }
    my $stmt_type = 'Select';
    my $old_idx = 1;

    CUSTOMIZE: while ( 1 ) {
        my $choices = [ $cu{hidden}, undef, @cu{@$sub_stmts} ];
        $ax->print_sql( $sql, [ $stmt_type ] );
        # Choose
        $ENV{TC_RESET_AUTO_UP} = 0;
        my $idx = choose(
            $choices,
            { %{$sf->{i}{lyt_stmt_v}}, prompt => '', index => 1, default => $old_idx, undef => $sf->{i}{back} }
        );
        if ( ! defined $idx || ! defined $choices->[$idx] ) {
            last CUSTOMIZE;
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
            my $tmp = $sb->columns( $stmt_h, $sql, $stmt_type );
            if ( defined $tmp ) {
                $sql->{$_} = $tmp->{$_} for keys %$tmp;
            }
        }
        elsif ( $custom eq $cu{'distinct'} ) {
            my $tmp = $sb->distinct( $stmt_h, $sql, $stmt_type );
            if ( defined $tmp ) {
                $sql->{$_} = $tmp->{$_} for keys %$tmp;
            }
        }
        elsif ( $custom eq $cu{'aggregate'} ) {
            my $tmp = $sb->aggregate( $stmt_h, $sql, $stmt_type );
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
        elsif ( $custom eq $cu{'hidden'} ) {
            my $backup_sql = $ax->backup_href( $sql );
            $sf->__table_write_access( $sql );
            $stmt_type = 'Select';
            $old_idx = 1;
            $sql = $backup_sql;
        }
        elsif ( $custom eq $cu{'functions'} ) {
            my $nh = App::DBBrowser::Table::Functions->new( $sf->{i}, $sf->{o}, $sf->{d} );
            my $backup_sql = $ax->backup_href( $sql );
            my $ok = $nh->col_function( $sql, $stmt_type );
            if ( ! $ok ) {
                $sql = $backup_sql;
            }
        }
        elsif ( $custom eq $cu{'print_tbl'} ) {
            my $select = $ax->get_stmt( $sql, 'Select', 'prepare' );
            if ( $sf->{o}{G}{max_rows} && ! $sql->{limit_stmt} ) {
                $select .= " LIMIT " . $sf->{o}{G}{max_rows};
                $sf->{o}{table}{max_rows} = $sf->{o}{G}{max_rows};
            }
            else {
                $sf->{o}{table}{max_rows} = 0;
            }
            my @arguments = ( @{$sql->{where_args}}, @{$sql->{having_args}} );
            if ( $sf->{i}{subqueries} ) {
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
            my $sth = $sf->{d}{dbh}->prepare( $select );
            print HIDE_CURSOR;
            print 'Computing:' . "\n" if $sf->{o}{table}{progress_bar};
            $sth->execute( @arguments );
            my $col_names = $sth->{NAME}; # not quoted
            my $all_arrayref = $sth->fetchall_arrayref;
            unshift @$all_arrayref, $col_names;
            print $sf->{i}{clear_screen};
            # return $sql explicitly since after a restore backup it refers to a different hash.
            return $all_arrayref, $sql;
        }
        else {
            die "$custom: no such value in the hash \%cu";
        }
    }
}


sub __table_write_access {
    my ( $sf, $sql ) = @_;
    my $stmt_h = Term::Choose->new( $sf->{i}{lyt_stmt_h} );
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $sb = App::DBBrowser::Table::Substatements->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my @stmt_types;
    if ( ! $sf->{i}{multi_tbl} ) {
        push @stmt_types, 'Insert' if $sf->{o}{G}{insert_ok};
        push @stmt_types, 'Update' if $sf->{o}{G}{update_ok};
        push @stmt_types, 'Delete' if $sf->{o}{G}{delete_ok};
    }
    elsif ( $sf->{i}{multi_tbl} eq 'join' && $sf->{d}{driver} eq 'mysql' ) {
        push @stmt_types, 'Update' if $sf->{o}{G}{update_ok};
    }
    if ( ! @stmt_types ) {
        return;
    }
    STMT_TYPE: while ( 1 ) {
        # Choose
        my $stmt_type = choose(
            [ undef, map( "- $_", @stmt_types ) ],
            { %{$sf->{i}{lyt_3}}, prompt => 'Choose SQL type:' }
        );
        if ( ! defined $stmt_type ) {
            return;
        }
        $stmt_type =~ s/^-\ //;
        $ax->reset_sql( $sql );
        if ( $stmt_type eq 'Insert' ) {
            require App::DBBrowser::Table::Insert;
            my $tbl_in = App::DBBrowser::Table::Insert->new( $sf->{i}, $sf->{o}, $sf->{d} );
            my $ok = $tbl_in->build_insert_stmt( $sql, [ $stmt_type ] );
            if ( $ok ) {
                $ok = $sf->commit_sql( $sql, [ $stmt_type ] );
            }
            next STMT_TYPE;
        }
        my $sub_stmts = {
            Delete => [ qw( commit     where functions ) ],
            Update => [ qw( commit set where functions ) ],
        };
        my %cu = (
            commit    => '  CONFIRM Stmt',
            set       => '- SET',
            where     => '- WHERE',
            functions => '  Func',
        );
        my $old_idx = 0;

        CUSTOMIZE: while ( 1 ) {
            my $choices = [ undef, @cu{@{$sub_stmts->{$stmt_type}}} ];
            $ax->print_sql( $sql, [ $stmt_type ] );
            # Choose
            $ENV{TC_RESET_AUTO_UP} = 0;
            my $idx = choose(
                $choices,
                { %{$sf->{i}{lyt_stmt_v}}, prompt => 'Customize:', index => 1, default => $old_idx, undef => $sf->{i}{_back} }
            );
            if ( ! defined $idx || ! defined $choices->[$idx] ) {
                next STMT_TYPE;
            }
            my $custom = $choices->[$idx];
            if ( $sf->{o}{G}{menu_memory} ) {
                if ( $old_idx == $idx && ! $ENV{TC_RESET_AUTO_UP} ) {
                    $old_idx = 0;
                    next CUSTOMIZE;
                }
                else {
                    $old_idx = $idx;
                }
            }
            delete $ENV{TC_RESET_AUTO_UP};
            if ( $custom eq $cu{'set'} ) {
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
            elsif ( $custom eq $cu{'functions'} ) {
                my $nh = App::DBBrowser::Table::Functions->new( $sf->{i}, $sf->{o}, $sf->{d} );
                my $backup_sql = $ax->backup_href( $sql ); ##
                my $ok = $nh->col_function( $sql, $stmt_type );
                if ( ! $ok ) {
                    $sql = $backup_sql;
                }
            }
            elsif ( $custom eq $cu{'commit'} ) {
                my $ok = $sf->commit_sql( $sql, [ $stmt_type ] );
                next STMT_TYPE;
            }
            else {
                die "$custom: no such value in the hash \%cu";
            }
        }
    }
}


sub commit_sql {
    my ( $sf, $sql, $stmt_typeS ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $stmt_v = Term::Choose->new( $sf->{i}{lyt_stmt_v} );
    my $dbh = $sf->{d}{dbh};
    local $| = 1;
    print $sf->{i}{clear_screen};
    print 'DB work ...' . "\n" if $sf->{o}{table}{progress_bar}; #
    my $stmt_type = $stmt_typeS->[-1];
    my $rows_to_execute = [];
    my $row_count;
    if ( $stmt_type eq 'Insert' ) {
        return 1 if ! @{$sql->{insert_into_args}};
        $rows_to_execute = $sql->{insert_into_args};
        $row_count = @$rows_to_execute;
    }
    else {
        $rows_to_execute = [ [ @{$sql->{set_args}}, @{$sql->{where_args}} ] ];
        my $all_arrayref = [];
        if ( ! eval {
            my $sth = $dbh->prepare( "SELECT * FROM " . $sql->{table} . $sql->{where_stmt} );
            $sth->execute( @{$sql->{where_args}} );
            my $col_names = $sth->{NAME};
            $all_arrayref = $sth->fetchall_arrayref;
            $row_count = @$all_arrayref;
            unshift @$all_arrayref, $col_names;
            1 }
        ) {
            $ax->print_error_message( "$@Fetching info: affected records ...\n", $stmt_type );
        }
        my $prompt;
        if ( $stmt_type eq 'Update' ) {
            my $filled = $sql->{set_stmt};
            for my $val ( @{$sql->{set_args}} ) {
                $filled =~ s/(?<=\ \=\ )\?/$val/;
            }
            $filled =~ s/^\s+//;
            $prompt = "These records will be updated with [ $filled ]:\n";
        }
        else {
            $prompt = "These records will be deleted:\n";
        }
        if ( @$all_arrayref > 1 ) {
            print_table( $all_arrayref, { %{$sf->{o}{table}}, prompt => $prompt, max_rows => 0, keep_header => 0 } ); #
        }
    }
    my $transaction;
    eval {
        $dbh->{AutoCommit} = 1;
        $transaction = $dbh->begin_work;
    } or do {
        $dbh->{AutoCommit} = 1;
        $transaction = 0;
    };
    if ( $transaction ) {
        my $rolled_back;
        if ( ! eval {
            my $sth = $dbh->prepare(
                $ax->get_stmt( $sql, $stmt_type, 'prepare' )
            );
            for my $values ( @$rows_to_execute ) {
                $sth->execute( @$values );
            }
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
            my $sth = $dbh->prepare(
                $ax->get_stmt( $sql, $stmt_type, 'prepare' )
            );
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


1;


__END__
