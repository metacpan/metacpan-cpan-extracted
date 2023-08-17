package # hide from PAUSE
App::DBBrowser::Table::CommitWriteSQL;

use warnings;
use strict;
use 5.014;

use Term::Choose       qw();
use Term::Choose::Util qw( insert_sep );
use Term::TablePrint   qw();

use App::DBBrowser::Auxil;


sub new {
    my ( $class, $info, $options, $d ) = @_;
    my $sf = {
        i => $info,
        o => $options,
        d => $d
    };
    bless $sf, $class;
}


sub commit_sql {
    my ( $sf, $sql ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $dbh = $sf->{d}{dbh};
    my $waiting = 'DB work ... ';
    my $stmt_type = $sf->{d}{stmt_types}[-1];
    my $rows_to_execute = [];
    my $count_affected;
    if ( $stmt_type eq 'Insert' ) {
        if ( ! @{$sql->{insert_args}} ) {
            return 1;
        }
        $ax->print_sql_info( $ax->get_sql_info( $sql ), $waiting );
        $count_affected = @{$sql->{insert_args}};
    }
    else {
        $ax->print_sql_info( $ax->get_sql_info( $sql ), $waiting );
        my $all_arrayref = [];
        if ( ! eval {
            my $sth = $dbh->prepare( "SELECT * FROM $sql->{table} " . $sql->{where_stmt} );
            $sth->execute();
            my $col_names = $sth->{NAME};
            $all_arrayref = $sth->fetchall_arrayref;
            $count_affected = @$all_arrayref;
            unshift @$all_arrayref, $col_names;
            1 }
        ) {
            $ax->print_error_message( $@ );
        }
        my $prompt = "Affected records:";
        my $info = $ax->get_sql_info( $sql );
        if ( @$all_arrayref > 1 ) {
            my $tp = Term::TablePrint->new( $sf->{o}{table} );
            if ( ! $sf->{o}{G}{warnings_table_print} ) {
                local $SIG{__WARN__} = sub {};
                $tp->print_table( $all_arrayref, { info => $info, prompt => $prompt, footer => $sf->{d}{table_footer} } );
            }
            else {
                $tp->print_table( $all_arrayref, { info => $info, prompt => $prompt, footer => $sf->{d}{table_footer} } );
            }
        }
        $ax->print_sql_info( $info, $waiting );
    }
    my $transaction;
    eval {
        $dbh->{AutoCommit} = 1;
        $transaction = $dbh->begin_work;
        # https://metacpan.org/pod/DBI#begin_work
        # begin_work enables transactions by turning AutoCommit off until the next call to commit or rollback.
        # If AutoCommit is already off when begin_work is called then it does nothing except return an error.
        # If the driver does not support transactions then when begin_work attempts to set AutoCommit off the driver will trigger a fatal error.
    } or do {
        $dbh->{AutoCommit} = 1;
        $transaction = 0;
    };
    if ( $transaction ) {
        return $sf->__transaction( $sql, $stmt_type, $count_affected, $waiting );
    }
    else {
        return $sf->__auto_commit( $sql, $stmt_type, $count_affected, $waiting );
    }
}


sub __transaction {
    my ( $sf, $sql, $stmt_type, $count_affected, $waiting ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $dbh = $sf->{d}{dbh};
    $ax->print_sql_info( $ax->get_sql_info( $sql ), $waiting );
    my $rolled_back;
    my $sth;
    if ( ! eval {
        $sth = $dbh->prepare( $ax->get_stmt( $sql, $stmt_type, 'prepare' ) );
        if ( $stmt_type eq 'Insert' ) {
            $sth->execute( @$_ ) for @{$sql->{insert_args}};
        }
        else {
            $sth->execute();
        }
        if ( $stmt_type eq 'Insert' && $sf->{d}{stmt_types}[0] eq 'Create_table' ) {
            # already asked for confirmation (create table + insert data) in Create_table
            $dbh->commit;
        }
        else {
            my $commit_ok = sprintf qq(  %s %s "%s"), 'COMMIT', insert_sep( $count_affected, $sf->{i}{info_thsd_sep} ), $stmt_type;
            my $menu = [ undef,  $commit_ok ];
            my $info = $ax->get_sql_info( $sql );
            # Choose
            my $choice = $tc->choose(
                $menu,
                { %{$sf->{i}{lyt_v}}, info => $info, keep => scalar( @$menu ) }
            );
            $ax->print_sql_info( $info, $waiting );
            if ( ! defined $choice || $choice ne $commit_ok ) {
                $sth->finish if $sf->{i}{driver} eq 'SQLite';
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
        $sth->finish if $sf->{i}{driver} eq 'SQLite';
        $dbh->rollback;
        $rolled_back = 1;
    }
    if ( $rolled_back ) {
        return;
    }
    return 1;
}


sub __auto_commit {
    my ( $sf, $sql, $stmt_type, $count_affected, $waiting ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $dbh = $sf->{d}{dbh};
    if ( $stmt_type eq 'Insert' && $sf->{d}{stmt_types}[0] eq 'Create_table' ) {
        # already asked for confirmation (create table + insert data) in Create_table
    }
    else {
        my $commit_ok = sprintf qq(  %s %s "%s"), 'EXECUTE', insert_sep( $count_affected, $sf->{i}{info_thsd_sep} ), $stmt_type;
        my $menu = [ undef,  $commit_ok ];
        my $info = $ax->get_sql_info( $sql ); #
        # Choose
        my $choice = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_v}}, info => $info, prompt => '', keep => scalar( @$menu ) }
        );
        $ax->print_sql_info( $info, $waiting );
        if ( ! defined $choice || $choice ne $commit_ok ) {
            return;
        }
    }
    if ( ! eval {
        my $sth = $dbh->prepare( $ax->get_stmt( $sql, $stmt_type, 'prepare' ) );
        if ( $stmt_type eq 'Insert' ) {
            $sth->execute( @$_ ) for @{$sql->{insert_args}};
        }
        else {
            $sth->execute();
        }
        1 }
    ) {
        $ax->print_error_message( $@ );
        return;
    }
    return 1;
}





1;


__END__
