package # hide from PAUSE
App::DBBrowser::Table::InsertUpdateDelete;

use warnings;
use strict;
use 5.014;

use Term::Choose       qw();
use Term::Choose::Util qw();

use App::DBBrowser::Auxil;
use App::DBBrowser::Table::CommitWriteSQL;
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
    my $cs = App::DBBrowser::Table::CommitWriteSQL->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $sb = App::DBBrowser::Table::Substatements->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my @stmt_types;
    if ( ! $sf->{i}{special_table} ) {
        push @stmt_types, 'Insert' if $sf->{o}{enable}{insert_into};
        push @stmt_types, 'Update' if $sf->{o}{enable}{update};
        push @stmt_types, 'Delete' if $sf->{o}{enable}{delete};
    }
    elsif ( $sf->{i}{special_table} eq 'join' && $sf->{i}{driver} =~ /^(?:mysql|MariaDB)\z/ ) {
        push @stmt_types, 'Update' if $sf->{o}{enable}{update};
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
            { %{$sf->{i}{lyt_v}}, prompt => '', index => 1, default => $old_idx }
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
            $opt_set->set_options( 'import' );
            next STMT_TYPE;
        }
        $stmt_type =~ s/^-\ //;
        $sf->{i}{stmt_types} = [ $stmt_type ];
        $ax->reset_sql( $sql );
        if ( $stmt_type eq 'Insert' ) {
            my $ok = $sf->__build_insert_stmt( $sql );
            if ( $ok ) {
                $ok = $cs->commit_sql( $sql );
            }
            delete $sf->{i}{ss} if exists $sf->{i}{ss};
            delete $sf->{i}{gc} if exists $sf->{i}{gc};
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
            my $info = $ax->get_sql_info( $sql );
            # Choose
            my $idx = $tc->choose(
                $menu,
                { %{$sf->{i}{lyt_v}}, info => $info, prompt => 'Customize:', index => 1, default => $old_idx }
            );
            $ax->print_sql_info( $info );
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
                my $ok = $cs->commit_sql( $sql );
                next STMT_TYPE;
            }
            else {
                die "$custom: no such value in the hash \%cu";
            }
        }
    }
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
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $plui = App::DBBrowser::DB->new( $sf->{i}, $sf->{o} );
    $sql->{insert_into_cols} = [];
    my @cols = ( @{$sql->{cols}} );
    if ( $plui->first_column_is_autoincrement( $sf->{d}{dbh}, $sf->{d}{schema}, $sf->{d}{table} ) ) {
        shift @cols;
    }
    my $bu_cols = [ @cols ];
    my $prompt = "Select columns to fill:";
    my $info = $sql->{table} . "\n";
    my $idxs = $tu->choose_a_subset(
        [ @cols ],
        { cs_label => 'Cols: ', layout => 0, order => 0, all_by_default => 1,
          index => 1, confirm => $sf->{i}{ok}, back => '<<', info => $info, prompt => $prompt }
    );
    $ax->print_sql_info( $info );
    if ( ! defined $idxs ) {
        return;
    }
    $sql->{insert_into_cols} = [ @cols[@$idxs] ];
    return 1;
}





1;


__END__
