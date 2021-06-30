package # hide from PAUSE
App::DBBrowser::Table::CommitWriteSQL;

use warnings;
use strict;
use 5.010001;

use Term::Choose       qw();
use Term::Choose::Util qw( insert_sep );
use Term::TablePrint   qw();

use App::DBBrowser::Auxil;


sub new {
    my ( $class, $info, $options, $data ) = @_;
    my $sf = {
        i => $info,
        o => $options,
        d => $data,
    };
    bless $sf, $class;
}


sub commit_sql {
    my ( $sf, $sql ) = @_;
    if ( exists $sf->{i}{fi} ) {
        delete $sf->{i}{fi};
    }
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $dbh = $sf->{d}{dbh};
    my $waiting = 'DB work ... ';
    my $occupied_term_height;
    my $stmt_type = $sf->{i}{stmt_types}[-1];
    my $rows_to_execute = [];
    my $count_affected;
    if ( $stmt_type eq 'Insert' ) {
        if ( ! @{$sql->{insert_into_args}} ) {
            return 1;
        }
        # cosmetics - when printing the $waiting string, the sql info string should not change and the $waiting-string
        # should be at the level of the previous prompt line:
        if ( @{$sf->{i}{stmt_types}} == 2 ) {
            $occupied_term_height = 6;
        }
        else {
            $occupied_term_height = 4;
        }
        $sf->{i}{occupied_term_height} = $occupied_term_height;
        $ax->print_sql_info( $ax->get_sql_info( $sql ), $waiting );
        $rows_to_execute = $sql->{insert_into_args};
        $count_affected = @$rows_to_execute;
    }
    else {
        $ax->print_sql_info( $ax->get_sql_info( $sql ), $waiting );
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
        my $prompt = "Affected records:";
        my $info = $ax->get_sql_info( $sql );
        if ( @$all_arrayref > 1 ) {
            my $tp = Term::TablePrint->new( $sf->{o}{table} );
            $tp->print_table(
                $all_arrayref,
                { info => $info, prompt => $prompt, max_rows => 0, table_name => "     '" . $sf->{d}{table} . "'     " }
            );
        }
        $ax->print_sql_info( $info, $waiting );
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
        return $sf->__transaction( $sql, $stmt_type, $rows_to_execute, $count_affected, $waiting, $occupied_term_height );
    }
    else {
        return $sf->__auto_commit( $sql, $stmt_type, $rows_to_execute, $count_affected, $waiting );
    }
}


sub __transaction {
    my ( $sf, $sql, $stmt_type, $rows_to_execute, $count_affected, $waiting, $occupied_term_height ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $dbh = $sf->{d}{dbh};
    if ( $occupied_term_height ) {
        $sf->{i}{occupied_term_height} = $occupied_term_height;
    }
    $ax->print_sql_info( $ax->get_sql_info( $sql ), $waiting );
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
            my $commit_ok = sprintf qq(  %s %s "%s"), 'COMMIT', insert_sep( $count_affected, $sf->{o}{G}{thsd_sep} ), $stmt_type;
            my $menu = [ undef,  $commit_ok ];
            $sf->{i}{occupied_term_height} = @$menu + 2; # prompt, trailing empty line
            my $info = $ax->get_sql_info( $sql );
            # Choose
            my $choice = $tc->choose(
                $menu,
                { %{$sf->{i}{lyt_v}}, info => $info, keep => scalar( @$menu ) }
            );
            $ax->print_sql_info( $info, $waiting );
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
        my $commit_ok = sprintf qq(  %s %s "%s"), 'EXECUTE', insert_sep( $count_affected, $sf->{o}{G}{thsd_sep} ), $stmt_type;
        my $menu = [ undef,  $commit_ok ];
        $sf->{i}{occupied_term_height} = @$menu + 1;
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





1;


__END__
