package # hide from PAUSE
App::DBBrowser::Table::WriteAccess;

use warnings;
use strict;
use 5.008003;

use Term::Choose       qw( choose );
use Term::Choose::Util qw( insert_sep );
use Term::TablePrint   qw( print_table );

use App::DBBrowser::Auxil;
use App::DBBrowser::DB;
#use App::DBBrowser::GetContent; # required
use App::DBBrowser::Opt;


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
            my $ok = $sf->__build_insert_stmt( $sql, [ $stmt_type ] );
            if ( $ok ) {
                $ok = $sf->commit_sql( $sql, [ $stmt_type ] );
            }
            next STMT_TYPE;
        }
        my $sub_stmts = {
            Delete => [ qw( commit     where ) ],
            Update => [ qw( commit set where ) ],
        };
        my %cu = (
            commit    => '  CONFIRM Stmt',
            set       => '- SET',
            where     => '- WHERE',
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
            my $backup_sql = $ax->backup_href( $sql );
            if ( $custom eq $cu{'set'} ) {
                my $ok = $sb->set( $stmt_h, $sql, $stmt_type );
                if ( ! $ok ) {
                    $sql = $backup_sql;
                }
            }
            elsif ( $custom eq $cu{'where'} ) {
                my $ok = $sb->where( $stmt_h, $sql, $stmt_type );
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
    my $waiting = 'DB work ... ';
    $ax->print_sql( $sql, $stmt_typeS, $waiting );
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
        my $prompt = @$all_arrayref == 2 ? 'This record will be ' : 'These records will be ';
        if ( $stmt_type eq 'Update' ) {
            my $filled = $sql->{set_stmt};
            for my $val ( @{$sql->{set_args}} ) {
                $filled =~ s/(?<=\ \=\ )\?/$val/;
            }
            $filled =~ s/^\s*SET\s*//;
            my @items = split( /\s*,\s*/, $filled );
            $prompt .= "updated with:\n";
            if ( @items > 4 ) {
                $prompt .= join ', ', @items;
            }
            else {
                $prompt .= '  ' . join "\n  ", @items;
            }
            $prompt .= "\n";
        }
        else {
            $prompt .= "deleted:\n";
        }
        if ( @$all_arrayref > 1 ) {
            print_table(
                $all_arrayref,
                { %{$sf->{o}{table}}, grid => 2, prompt => $prompt, max_rows => 0, keep_header => 1 }
            );
        }
    }
    $ax->print_sql( $sql, $stmt_typeS, $waiting );
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
            my $commit_ok = sprintf qq(  %s %s "%s"), 'COMMIT', insert_sep( $row_count, $sf->{o}{G}{thsd_sep} ), $stmt_type;
            $ax->print_sql( $sql, $stmt_typeS );
            # Choose
            my $choice = $stmt_v->choose(
                [ undef,  $commit_ok ]
            );
            $ax->print_sql( $sql, $stmt_typeS, $waiting );
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
        my $commit_ok = sprintf qq(  %s %s "%s"), 'EXECUTE', insert_sep( $row_count, $sf->{o}{G}{thsd_sep} ), $stmt_type;
        $ax->print_sql( $sql, $stmt_typeS ); #
        # Choose
        my $choice = $stmt_v->choose(
            [ undef,  $commit_ok ],
            { prompt => '' }
        );
        $ax->print_sql( $sql, $stmt_typeS, $waiting );
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


sub __insert_into_stmt_columns {
    my ( $sf, $sql, $stmt_typeS ) = @_;
    my $ax  = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $plui = App::DBBrowser::DB->new( $sf->{i}, $sf->{o} );
    $sql->{insert_into_cols} = [];
    my @cols = ( @{$sql->{cols}} );
    if ( $plui->first_column_is_autoincrement( $sf->{d}{dbh}, $sf->{d}{schema}, $sf->{d}{table} ) ) {
        shift @cols;
    }
    my $bu_cols = [ @cols ];

    COL_NAMES: while ( 1 ) {
        $ax->print_sql( $sql, $stmt_typeS );
        my @pre = ( undef, $sf->{i}{ok} );
        my $choices = [ @pre, @cols ];
        # Choose
        my @idx = choose(
            $choices,
            { %{$sf->{i}{lyt_stmt_h}}, prompt => 'Columns:', index => 1,
              meta_items => [ 0 .. $#pre ], include_highlighted => 2 }
        );
        if ( ! $idx[0] ) {
            if ( ! @{$sql->{insert_into_cols}} ) {
                return;
            }
            $sql->{insert_into_cols} = [];
            @cols = @$bu_cols;
            next COL_NAMES;
        }
        if ( $idx[0] == 1 ) {
            shift @idx;
            push @{$sql->{insert_into_cols}}, @{$choices}[@idx];
            if ( ! @{$sql->{insert_into_cols}} ) {
                $sql->{insert_into_cols} = $bu_cols;
            }
            return 1;
        }
        push @{$sql->{insert_into_cols}}, @{$choices}[@idx];
        my $c = 0;
        for my $i ( @idx ) {
            last if ! @cols;
            my $ni = $i - ( @pre + $c );
            splice( @cols, $ni, 1 );
            ++$c;
        }
    }
}


sub __build_insert_stmt {
    my ( $sf, $sql, $stmt_typeS ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $plui = App::DBBrowser::DB->new( $sf->{i}, $sf->{o} );
    $ax->reset_sql( $sql );
    my @cu_keys = ( qw/insert_col insert_copy insert_file settings/ );
    my %cu = (
        insert_col  => '- plain',
        insert_file => '- From File',
        insert_copy => '- Copy & Paste',
        settings    => '  Settings'
    );
    my $old_idx = 0;

    MENU: while ( 1 ) {
        my $choices = [ undef, @cu{@cu_keys} ];
        # Choose
        $ENV{TC_RESET_AUTO_UP} = 0;
        my $idx = choose(
            $choices,
            { %{$sf->{i}{lyt_3}}, index => 1, default => $old_idx, prompt => 'Choose:' }
        );
        if ( ! defined $idx || ! defined $choices->[$idx] ) {
            return;
        }
        my $custom = $choices->[$idx];
        if ( $sf->{o}{G}{menu_memory} ) {
            if ( $old_idx == $idx && ! $ENV{TC_RESET_AUTO_UP} ) {
                $old_idx = 0;
                next MENU;
            }
            else {
                $old_idx = $idx;
            }
        }
        delete $ENV{TC_RESET_AUTO_UP};
        if ( $custom eq $cu{settings} ) {
            my $opt = App::DBBrowser::Opt->new( $sf->{i}, $sf->{o} );
            $opt->config_insert;
            next MENU;
        }
        my $cols_ok = $sf->__insert_into_stmt_columns( $sql, $stmt_typeS );
        if ( ! $cols_ok ) {
            next MENU;
        }
        my $insert_ok;
        require App::DBBrowser::GetContent;
        my $gc = App::DBBrowser::GetContent->new( $sf->{i}, $sf->{o}, $sf->{d} );
        if ( $custom eq $cu{insert_col} ) {
            $insert_ok = $gc->from_col_by_col( $sql, $stmt_typeS );
        }
        elsif ( $custom eq $cu{insert_copy} ) {
            $insert_ok = $gc->from_copy_and_paste( $sql, $stmt_typeS );
        }
        elsif ( $custom eq $cu{insert_file} ) {
            $insert_ok = $gc->from_file( $sql, $stmt_typeS );
        }
        if ( ! $insert_ok ) {
            next MENU;
        }
        return 1
    }
}





1;


__END__
