package # hide from PAUSE
App::DBBrowser::Table;

use warnings;
use strict;
use 5.008003;

use Term::Choose            qw( choose );
use Term::Choose::Constants qw( :screen );

use App::DBBrowser::Auxil;
use App::DBBrowser::Table::Substatements;
#use App::DBBrowser::Table::WriteAccess;  # required


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
    my $sub_stmts = [
        qw( print_tbl select aggregate distinct where group_by having order_by limit reset )
    ];
    my %cu = (
        hidden          => 'Customize:',
        print_tbl       => 'Print TABLE',
        select          => '- SELECT',
        aggregate       => '- AGGREGATE',
        distinct        => '- DISTINCT',
        where           => '- WHERE',
        group_by        => '- GROUP BY',
        having          => '- HAVING',
        order_by        => '- ORDER BY',
        limit           => '- LIMIT',
        reset           => '  Reset',
    );
    $sf->{i}{stmt_types} = [ 'Select' ];
    my $old_idx = 1;

    CUSTOMIZE: while ( 1 ) {
        my $choices = [ $cu{hidden}, undef, @cu{@$sub_stmts} ];
        $ax->print_sql( $sql );
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
        my $backup_sql = $ax->backup_href( $sql );
        if ( $custom eq $cu{'reset'} ) {
            $ax->reset_sql( $sql );
            $old_idx = 1;
        }
        elsif ( $custom eq $cu{'select'} ) {
            my $ok = $sb->select( $stmt_h, $sql );
            if ( ! $ok ) {
                $sql = $backup_sql;
            }
        }
        elsif ( $custom eq $cu{'distinct'} ) {
            my $ok = $sb->distinct( $stmt_h, $sql );
            if ( ! $ok ) {
                $sql = $backup_sql;
            }
        }
        elsif ( $custom eq $cu{'aggregate'} ) {
            my $ok = $sb->aggregate( $stmt_h, $sql );
            if ( ! $ok ) {
                $sql = $backup_sql;
            }
        }
        elsif ( $custom eq $cu{'where'} ) {
            my $ok = $sb->where( $stmt_h, $sql );
            if ( ! $ok ) {
                $sql = $backup_sql;
            }
        }
        elsif ( $custom eq $cu{'group_by'} ) {
            my $ok = $sb->group_by( $stmt_h, $sql );
            if ( ! $ok ) {
                $sql = $backup_sql;
            }
        }
        elsif ( $custom eq $cu{'having'} ) {
            my $ok = $sb->having( $stmt_h, $sql );
            if ( ! $ok ) {
                $sql = $backup_sql;
            }
        }
        elsif ( $custom eq $cu{'order_by'} ) {
            my $ok = $sb->order_by( $stmt_h, $sql );
            if ( ! $ok ) {
                $sql = $backup_sql;
            }
        }
        elsif ( $custom eq $cu{'limit'} ) {
            my $ok = $sb->limit_offset( $stmt_h, $sql );
            if ( ! $ok ) {
                $sql = $backup_sql;
            }
        }
        elsif ( $custom eq $cu{'hidden'} ) {
            require App::DBBrowser::Table::WriteAccess;
            my $write = App::DBBrowser::Table::WriteAccess->new( $sf->{i}, $sf->{o}, $sf->{d} );
            $write->table_write_access( $sql );
            $sf->{i}{stmt_types} = [ 'Select' ];
            $old_idx = 1;
            $sql = $backup_sql;
        }
        elsif ( $custom eq $cu{'print_tbl'} ) {
            local $| = 1;
            print CLEAR_SCREEN;
            print HIDE_CURSOR;
            print 'Computing:' . "\r" if $sf->{o}{table}{progress_bar};
            my $statement = $ax->get_stmt( $sql, 'Select', 'prepare' );
            my @arguments = ( @{$sql->{where_args}}, @{$sql->{having_args}} );
            unshift @{$sf->{i}{history}{ $sf->{d}{db} }{print}}, [ $statement, \@arguments ];
            if ( $#{$sf->{i}{history}{ $sf->{d}{db} }{print}} > 50 ) {
                $#{$sf->{i}{history}{ $sf->{d}{db} }{print}} = 50;
            }
            if ( $sf->{o}{G}{max_rows} && ! $sql->{limit_stmt} ) {
                $statement .= " LIMIT " . $sf->{o}{G}{max_rows};
                $sf->{o}{table}{max_rows} = $sf->{o}{G}{max_rows};
            }
            else {
                $sf->{o}{table}{max_rows} = 0;
            }
            my $sth = $sf->{d}{dbh}->prepare( $statement );
            $sth->execute( @arguments );
            my $col_names = $sth->{NAME}; # not quoted
            my $all_arrayref = $sth->fetchall_arrayref;
            unshift @$all_arrayref, $col_names;
            # return $sql explicitly since after a restore backup it refers to a different hash.
            return $all_arrayref, $sql;
        }
        else {
            die "'$custom': no such value in the hash \%cu";
        }
    }
}



1;


__END__
