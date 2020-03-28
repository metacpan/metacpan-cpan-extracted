package # hide from PAUSE
App::DBBrowser::Table::WriteAccess;

use warnings;
use strict;
use 5.010001;

use Term::Choose       qw();
use Term::Choose::Util qw( insert_sep );
use Term::TablePrint   qw();

use App::DBBrowser::Auxil;
use App::DBBrowser::DB;
#use App::DBBrowser::GetContent; # required
#use App::DBBrowser::Opt::Set;   # required
use App::DBBrowser::Table::Substatements;


sub new {
    my ( $class, $info, $options, $data ) = @_;
    my $sf = {
        i => $info,
        o => $options,
        d => $data,
    };
    bless $sf, $class;
}


sub table_write_access {
    my ( $sf, $sql ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $sb = App::DBBrowser::Table::Substatements->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my @stmt_types;
    if ( ! $sf->{i}{special_table} ) {
        push @stmt_types, 'Insert' if $sf->{o}{enable}{insert_into};
        push @stmt_types, 'Update' if $sf->{o}{enable}{update};
        push @stmt_types, 'Delete' if $sf->{o}{enable}{delete};
    }
    elsif ( $sf->{i}{special_table} eq 'join' && $sf->{i}{driver} eq 'mysql' ) {
        push @stmt_types, 'Update' if $sf->{o}{G}{enable}{update};
    }
    if ( ! @stmt_types ) {
        return;
    }
    my $old_idx = 1;

    STMT_TYPE: while ( 1 ) {
        my $hidden = 'Choose SQL type:';
        my @pre = ( $hidden, undef );
        my $menu = [ @pre, map( "- $_", @stmt_types ) ];
        # Choose
        my $idx = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_v_clear}}, prompt => '', index => 1, default => $old_idx }
        );
        if ( ! defined $idx || ! defined $menu->[$idx] ) {
            return;
        }
        if ( $sf->{o}{G}{menu_memory} ) {
            if ( $old_idx == $idx && ! $ENV{TC_RESET_AUTO_UP} ) {
                $old_idx = 1;
                next STMT_TYPE;
            }
            $old_idx = $idx;
        }
        my $stmt_type = $menu->[$idx];
        if ( $stmt_type eq $hidden ) {
            require App::DBBrowser::Opt::Set;
            my $opt_set = App::DBBrowser::Opt::Set->new( $sf->{i}, $sf->{o} );
            my $groups = [ { name => 'group_insert', text => '' } ];
            $opt_set->set_options( $groups );
            next STMT_TYPE;
        }
        $stmt_type =~ s/^-\ //;
        $sf->{i}{stmt_types} = [ $stmt_type ];
        $ax->reset_sql( $sql );
        if ( $stmt_type eq 'Insert' ) {
            my $ok = $sf->__build_insert_stmt( $sql );
            if ( $ok ) {
                $ok = $sf->commit_sql( $sql );
            }
            next STMT_TYPE;
        }
        my $sub_stmts = {
            Delete => [ qw( commit     where ) ],
            Update => [ qw( commit set where ) ],
        };
        my %cu = (
            commit => '  CONFIRM Stmt',
            set    => '- SET',
            where  => '- WHERE',
        );
        my $old_idx = 0;

        CUSTOMIZE: while ( 1 ) {
            my $menu = [ undef, @cu{@{$sub_stmts->{$stmt_type}}} ];
            $ax->print_sql( $sql );
            # Choose
            my $idx = $tc->choose(
                $menu,
                { %{$sf->{i}{lyt_v}}, prompt => 'Customize:', index => 1, default => $old_idx }
            );
            if ( ! defined $idx || ! defined $menu->[$idx] ) {
                next STMT_TYPE;
            }
            my $custom = $menu->[$idx];
            if ( $sf->{o}{G}{menu_memory} ) {
                if ( $old_idx == $idx && ! $ENV{TC_RESET_AUTO_UP} ) {
                    $old_idx = 0;
                    next CUSTOMIZE;
                }
                $old_idx = $idx;
            }
            my $backup_sql = $ax->backup_href( $sql );
            if ( $custom eq $cu{'set'} ) {
                my $ok = $sb->set( $sql );
                if ( ! $ok ) {
                    $sql = $backup_sql;
                }
            }
            elsif ( $custom eq $cu{'where'} ) {
                my $ok = $sb->where( $sql );
                if ( ! $ok ) {
                    $sql = $backup_sql;
                }
            }
            elsif ( $custom eq $cu{'commit'} ) {
                my $ok = $sf->commit_sql( $sql );
                next STMT_TYPE;
            }
            else {
                die "$custom: no such value in the hash \%cu";
            }
        }
    }
}


sub commit_sql {
    my ( $sf, $sql ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $dbh = $sf->{d}{dbh};
    my $waiting = 'DB work ... ';
    $ax->print_sql( $sql, $waiting );
    my $stmt_type = $sf->{i}{stmt_types}[-1]; ##
    my $rows_to_execute = [];
    my $count_affected;
    if ( $stmt_type eq 'Insert' ) {
        return 1 if ! @{$sql->{insert_into_args}};
        $rows_to_execute = $sql->{insert_into_args};
        $count_affected = @$rows_to_execute;
    }
    else {
        $rows_to_execute = [ [ @{$sql->{set_args}}, @{$sql->{where_args}} ] ];
        my $all_arrayref = [];
        if ( ! eval {
            my $sth = $dbh->prepare( "SELECT * FROM " . $sql->{table} . $sql->{where_stmt} );
            $sth->execute( @{$sql->{where_args}} );
            my $col_names = $sth->{NAME};
            $all_arrayref = $sth->fetchall_arrayref;
            $count_affected = @$all_arrayref;
            unshift @$all_arrayref, $col_names;
            1 }
        ) {
            $ax->print_error_message( $@ );
        }
        my $prompt = $ax->print_sql( $sql );
        $prompt .= "Affected records:";
        if ( @$all_arrayref > 1 ) {
            my $tp = Term::TablePrint->new( $sf->{o}{table} );
            $tp->print_table(
                $all_arrayref,
                { grid => 2, prompt => $prompt, max_rows => 0, keep_header => 1,
                  table_expand => $sf->{o}{G}{info_expand} }
            );
        }
    }
    $ax->print_sql( $sql, $waiting );
    my $transaction;
    eval {
        $dbh->{AutoCommit} = 1;
        $transaction = $dbh->begin_work;
    } or do {
        $dbh->{AutoCommit} = 1;
        $transaction = 0;
    };
    if ( $transaction ) {
        return $sf->__transaction( $sql, $stmt_type, $rows_to_execute, $count_affected, $waiting );
    }
    else {
        return $sf->__auto_commit( $sql, $stmt_type, $rows_to_execute, $count_affected, $waiting );
    }
}


sub __transaction {
    my ( $sf, $sql, $stmt_type, $rows_to_execute, $count_affected, $waiting ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $dbh = $sf->{d}{dbh};
    my $rolled_back;
    if ( ! eval {
        my $sth = $dbh->prepare(
            $ax->get_stmt( $sql, $stmt_type, 'prepare' )
        );
        for my $values ( @$rows_to_execute ) {
            $sth->execute( @$values );
        }
        if ( $stmt_type eq 'Insert' && $sf->{i}{stmt_types}[0] eq 'Create_table' ) {
            # already asked for confirmation (create table + insert data) in Create_table
            $dbh->commit;
        }

        else {
            $sf->{i}{occupied_term_height} = 3;
            my $commit_ok = sprintf qq(  %s %s "%s"), 'COMMIT', insert_sep( $count_affected, $sf->{o}{G}{thsd_sep} ), $stmt_type;
            $ax->print_sql( $sql );
            # Choose
            my $choice = $tc->choose(
                [ undef,  $commit_ok ],
                { %{$sf->{i}{lyt_v}} }
            );
            $ax->print_sql( $sql, $waiting );
            if ( ! defined $choice || $choice ne $commit_ok ) {
                # $sth->finish if $sf->{i}{driver} eq 'SQLite'; # finish called automatically when $sth is destroyed ?
                $dbh->rollback;
                $rolled_back = 1;
            }
            else {;
                $dbh->commit;
            }
        }
        1 }
    ) {
        $ax->print_error_message( $@ );
        # $sth->finish if $sf->{i}{driver} eq 'SQLite'; # finish called automatically when $sth is destroyed ?
        $dbh->rollback;
        $rolled_back = 1;
    }
    if ( $rolled_back ) {
        return;
    }
    return 1;
}


sub __auto_commit {
    my ( $sf, $sql, $stmt_type, $rows_to_execute, $count_affected, $waiting ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $dbh = $sf->{d}{dbh};
    if ( $stmt_type eq 'Insert' && $sf->{i}{stmt_types}[0] eq 'Create_table' ) {
        # already asked for confirmation (create table + insert data) in Create_table
    }
    else {
        $sf->{i}{occupied_term_height} = 3;
        my $commit_ok = sprintf qq(  %s %s "%s"), 'EXECUTE', insert_sep( $count_affected, $sf->{o}{G}{thsd_sep} ), $stmt_type;
        $ax->print_sql( $sql ); #
        # Choose
        my $choice = $tc->choose(
            [ undef,  $commit_ok ],
            { %{$sf->{i}{lyt_v}}, prompt => '' }
        );
        $ax->print_sql( $sql, $waiting );
        if ( ! defined $choice || $choice ne $commit_ok ) {
            return;
        }
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
        $ax->print_error_message( $@ );
        return;
    }
    return 1;
}


sub __build_insert_stmt {
    my ( $sf, $sql ) = @_;
    require App::DBBrowser::GetContent;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $gc = App::DBBrowser::GetContent->new( $sf->{i}, $sf->{o}, $sf->{d} );
    $ax->reset_sql( $sql );

    REQUIRED_COLS: while ( 1 ) {
        my $cols_ok = $sf->__insert_into_stmt_columns( $sql );
        if ( ! $cols_ok ) {
            return;
        }
        my $ok = $gc->get_content( $sql, 0 );
        if ( ! $ok ) {
            next REQUIRED_COLS;
        }
        return 1;
    }
}


sub __insert_into_stmt_columns {
    my ( $sf, $sql ) = @_;
    my $tu = Term::Choose::Util->new( $sf->{i}{tcu_default} );
    my $plui = App::DBBrowser::DB->new( $sf->{i}, $sf->{o} );
    $sql->{insert_into_cols} = [];
    my @cols = ( @{$sql->{cols}} );
    if ( $plui->first_column_is_autoincrement( $sf->{d}{dbh}, $sf->{d}{schema}, $sf->{d}{table} ) ) {
        shift @cols;
    }
    my $bu_cols = [ @cols ];
    my $info = "Table $sql->{table}";
    $info .= "\nSelect columns to fill:";
    my $idxs = $tu->choose_a_subset(
        [ @cols ],
        { cs_label => 'Cols: ', layout => 0, order => 0, all_by_default => 1,
          index => 1, confirm => $sf->{i}{ok}, back => '<<', info => $info }
    );
    if ( ! defined $idxs ) {
        return;
    }
    $sql->{insert_into_cols} = [ @cols[@$idxs] ];
    return 1;
}





1;


__END__
