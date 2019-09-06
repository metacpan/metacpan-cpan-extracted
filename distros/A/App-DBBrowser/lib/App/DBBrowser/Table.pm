package # hide from PAUSE
App::DBBrowser::Table;

use warnings;
use strict;
use 5.010001;

use Term::Choose         qw();
use Term::Choose::Screen qw( hide_cursor clear_screen );

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
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
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
        my $idx = $tc->choose(
            $choices,
            { %{$sf->{i}{lyt_v}}, prompt => '', index => 1, default => $old_idx, undef => $sf->{i}{back} }
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
            $old_idx = $idx;
        }
        my $backup_sql = $ax->backup_href( $sql );
        if ( $custom eq $cu{'reset'} ) {
            $ax->reset_sql( $sql );
            $old_idx = 1;
        }
        elsif ( $custom eq $cu{'select'} ) {
            my $ok = $sb->select( $sql );
            if ( ! $ok ) {
                $sql = $backup_sql;
            }
        }
        elsif ( $custom eq $cu{'distinct'} ) {
            my $ok = $sb->distinct( $sql );
            if ( ! $ok ) {
                $sql = $backup_sql;
            }
        }
        elsif ( $custom eq $cu{'aggregate'} ) {
            my $ok = $sb->aggregate( $sql );
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
        elsif ( $custom eq $cu{'group_by'} ) {
            my $ok = $sb->group_by( $sql );
            if ( ! $ok ) {
                $sql = $backup_sql;
            }
        }
        elsif ( $custom eq $cu{'having'} ) {
            my $ok = $sb->having( $sql );
            if ( ! $ok ) {
                $sql = $backup_sql;
            }
        }
        elsif ( $custom eq $cu{'order_by'} ) {
            my $ok = $sb->order_by( $sql );
            if ( ! $ok ) {
                $sql = $backup_sql;
            }
        }
        elsif ( $custom eq $cu{'limit'} ) {
            my $ok = $sb->limit_offset( $sql );
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
            $sql = $backup_sql; # so no need for table_write_access to return $sql
        }
        elsif ( $custom eq $cu{'print_tbl'} ) {
            local $| = 1;
            print hide_cursor(); # safety
            print clear_screen();
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
