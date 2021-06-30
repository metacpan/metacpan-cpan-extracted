package # hide from PAUSE
App::DBBrowser::Table;

use warnings;
use strict;
use 5.010001;

use Term::Choose         qw();
use Term::Choose::Screen qw( hide_cursor clear_screen );
use Term::TablePrint     qw();

use App::DBBrowser::Auxil;
use App::DBBrowser::Table::Substatements;
#use App::DBBrowser::Table::InsertUpdateDelete;  # required


sub new {
    my ( $class, $info, $options, $data ) = @_;
    bless {
        i => $info,
        o => $options,
        d => $data
    }, $class;
}



sub browse_the_table {
    my ( $sf, $qt_table, $qt_columns ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $sql = {};
    $ax->reset_sql( $sql );
    $sql->{table} = $qt_table;
    $sql->{cols} = $qt_columns;
    $sf->{i}{stmt_types} = [ 'Select' ];
    $ax->print_sql_info( $ax->get_sql_info( $sql ) );

    PRINT_TABLE: while ( 1 ) {
        my $all_arrayref;
        if ( ! eval {
            ( $all_arrayref, $sql ) = $sf->__on_table( $sql );
            1 }
        ) {
            $ax->print_error_message( $@ );
            last PRINT_TABLE;
        }
        if ( ! defined $all_arrayref ) {
            last PRINT_TABLE;
        }

        my $tp = Term::TablePrint->new( $sf->{o}{table} );
        $tp->print_table(
            $all_arrayref,
            { table_name => "     '" . $sf->{d}{table} . "'     " }
        );

        delete $sf->{o}{table}{max_rows}   if exists $sf->{o}{table}{max_rows};
        delete $sf->{o}{table}{table_name} if exists $sf->{o}{table}{table_name};
    }
}


sub __on_table {
    my ( $sf, $sql ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $sb = App::DBBrowser::Table::Substatements->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $hidden = 'Customize:';
    my ( $print_table, $select, $aggregate, $distinct, $where, $group_by, $having, $order_by, $limit, $reset ) =
       ( 'Print TABLE',
         '- SELECT',
         '- AGGREGATE',
         '- DISTINCT',
         '- WHERE',
         '- GROUP BY',
         '- HAVING',
         '- ORDER BY',
         '- LIMIT',
         '  Reset',
    );
    my @pre = ( $hidden, undef );
    my @choices = ( $print_table, $select, $aggregate, $distinct, $where, $group_by, $having, $order_by, $limit, $reset );
    $sf->{i}{stmt_types} = [ 'Select' ];
    my $old_idx = 1;

    CUSTOMIZE: while ( 1 ) {
        my $menu = [ @pre, @choices ];
        my $info = $ax->get_sql_info( $sql );
        # Choose
        my $idx = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_v}}, info => $info, prompt => '', index => 1, default => $old_idx, undef => $sf->{i}{back} }
        );
        $ax->print_sql_info( $info );
        if ( ! defined $idx || ! defined $menu->[$idx] ) {
            last CUSTOMIZE;
        }
        my $chosen = $menu->[$idx];
        if ( $sf->{o}{G}{menu_memory} ) {
            if ( $old_idx == $idx && ! $ENV{TC_RESET_AUTO_UP} ) {
                $old_idx = 1;
                next CUSTOMIZE;
            }
            $old_idx = $idx;
        }
        my $backup_sql = $ax->backup_href( $sql );
        if ( $chosen eq $reset ) {
            $ax->reset_sql( $sql );
            $old_idx = 1;
        }
        elsif ( $chosen eq $select ) {
            my $ok = $sb->select( $sql );
            if ( ! $ok ) {
                $sql = $backup_sql;
            }
        }
        elsif ( $chosen eq $distinct ) {
            my $ok = $sb->distinct( $sql );
            if ( ! $ok ) {
                $sql = $backup_sql;
            }
        }
        elsif ( $chosen eq $aggregate ) {
            my $ok = $sb->aggregate( $sql );
            if ( ! $ok ) {
                $sql = $backup_sql;
            }
        }
        elsif ( $chosen eq $where ) {
            my $ok = $sb->where( $sql );
            if ( ! $ok ) {
                $sql = $backup_sql;
            }
        }
        elsif ( $chosen eq $group_by ) {
            my $ok = $sb->group_by( $sql );
            if ( ! $ok ) {
                $sql = $backup_sql;
            }
        }
        elsif ( $chosen eq $having ) {
            my $ok = $sb->having( $sql );
            if ( ! $ok ) {
                $sql = $backup_sql;
            }
        }
        elsif ( $chosen eq $order_by ) {
            my $ok = $sb->order_by( $sql );
            if ( ! $ok ) {
                $sql = $backup_sql;
            }
        }
        elsif ( $chosen eq $limit ) {
            my $ok = $sb->limit_offset( $sql );
            if ( ! $ok ) {
                $sql = $backup_sql;
            }
        }
        elsif ( $chosen eq $hidden ) {
            require App::DBBrowser::Table::InsertUpdateDelete;
            my $write = App::DBBrowser::Table::InsertUpdateDelete->new( $sf->{i}, $sf->{o}, $sf->{d} );
            $write->table_write_access( $sql );
            $sf->{i}{stmt_types} = [ 'Select' ];
            $old_idx = 1;
            $sql = $backup_sql; # so no need for table_write_access to return $sql
        }
        elsif ( $chosen eq $print_table ) {
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
    }
}



1;


__END__
