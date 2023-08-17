package # hide from PAUSE
App::DBBrowser::Table::InsertUpdateDelete;

use warnings;
use strict;
use 5.014;

use Term::Choose       qw();
use Term::Choose::Util qw();

use App::DBBrowser::Auxil;
use App::DBBrowser::Table::CommitWriteSQL;
#use App::DBBrowser::GetContent; # required
use App::DBBrowser::Table::Substatements;


sub new {
    my ( $class, $info, $options, $d ) = @_;
    my $sf = {
        i => $info,
        o => $options,
        d => $d
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
    if ( ! $sf->{d}{special_table} ) {
        push @stmt_types, 'Insert' if $sf->{o}{enable}{insert_into};
        push @stmt_types, 'Update' if $sf->{o}{enable}{update};
        push @stmt_types, 'Delete' if $sf->{o}{enable}{delete};
    }
    elsif ( $sf->{d}{special_table} eq 'join' && $sf->{i}{driver} =~ /^(?:mysql|MariaDB)\z/ ) {
        push @stmt_types, 'Update' if $sf->{o}{enable}{update};
    }
    if ( ! @stmt_types ) {
        return;
    }
    my $old_idx = 0;

    STMT_TYPE: while ( 1 ) {
        my $prompt = 'Choose SQL type:';
        my @pre = ( undef );
        my $menu = [ @pre, map( "- $_", @stmt_types ) ];
        # Choose
        my $idx = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_v}}, prompt => $prompt, index => 1, default => $old_idx }
        );
        if ( ! defined $idx || ! defined $menu->[$idx] ) {
            return;
        }
        if ( $sf->{o}{G}{menu_memory} ) {
            if ( $old_idx == $idx && ! $ENV{TC_RESET_AUTO_UP} ) {
                $old_idx = 0;
                next STMT_TYPE;
            }
            $old_idx = $idx;
        }
        my $stmt_type = $menu->[$idx];
        $stmt_type =~ s/^-\ //;
        $sf->{d}{stmt_types} = [ $stmt_type ];
        $ax->reset_sql( $sql );
        if ( $stmt_type eq 'Insert' ) {
            my $ok = $sf->__build_insert_stmt( $sql );
            if ( $ok ) {
                $ok = $cs->commit_sql( $sql );
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
    my $source = {};

    REQUIRED_COLS: while ( 1 ) {
        my $cols_ok = $sf->__insert_into_stmt_columns( $sql );
        if ( ! $cols_ok ) {
            return;
        }
        my $ok = $gc->get_content( $sql, $source, 0 );
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
    $sql->{insert_col_names} = [];
    my @cols = ( @{$sql->{cols}} );
    if ( $sf->__first_column_is_autoincrement( $sql ) ) {
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
    $sql->{insert_col_names} = [ @cols[@$idxs] ];
    return 1;
}


sub __first_column_is_autoincrement { ##
    my ( $sf, $sql ) = @_;
    my $dbh = $sf->{d}{dbh};
    my $schema = $sf->{d}{schema};
    my $table = $sf->{d}{tables_info}{$sf->{d}{table_key}}[2];
    my $driver = $sf->{i}{driver};
    if ( $driver eq 'SQLite' ) {
        my $stmt = "SELECT sql FROM sqlite_master WHERE name = ?";
        my ( $row ) = $sf->{d}{dbh}->selectrow_array( $stmt, {}, $table );
        my $qt_table = $sql->{table};
        my $sth = $dbh->prepare( "SELECT * FROM " . $qt_table . " LIMIT 0" );
        my $col = $sth->{NAME}[0];
        my $qt_col = $dbh->quote_identifier( $col );
        if ( $row =~ /^\s*CREATE\s+TABLE\s+(?:\Q$table\E|\Q$qt_table\E)\s+\(\s*(?:\Q$col\E|\Q$qt_col\E)\s+INTEGER\s+PRIMARY\s+KEY[^,]*,/i ) {
            return 1;
        }
    }
    elsif ( $driver =~ /^(?:mysql|MariaDB)\z/ ) {
        my $stmt = "SELECT COUNT(*) FROM information_schema.columns WHERE
                    TABLE_SCHEMA = ?
                AND TABLE_NAME = ?
                AND ORDINAL_POSITION = 1
                AND DATA_TYPE = 'int'
                AND COLUMN_DEFAULT IS NULL
                AND IS_NULLABLE = 'NO'
                AND EXTRA like '%auto_increment%'";
        my ( $first_col_is_autoincrement ) = $dbh->selectrow_array( $stmt, {}, $schema, $table );
        return $first_col_is_autoincrement;
    }
    elsif ( $driver eq 'Pg' ) {
        my $stmt = "SELECT COUNT(*) FROM information_schema.columns WHERE
                    TABLE_SCHEMA = ?
                AND TABLE_NAME = ?
                AND ORDINAL_POSITION = 1
                AND DATA_TYPE = 'integer'
                AND IS_NULLABLE = 'NO'
                AND (
                       UPPER(column_default) LIKE 'NEXTVAL%'
                    OR UPPER(identity_generation) = 'BY DEFAULT'
                )";
        my ( $first_col_is_autoincrement ) = $dbh->selectrow_array( $stmt, {}, $schema, $table );
        return $first_col_is_autoincrement;
    }
    elsif ( $driver eq 'Firebird' ) {
        my $stmt = "SELECT COUNT(*) FROM RDB\$RELATION_FIELDS WHERE
                RDB\$RELATION_NAME = ?
            AND RDB\$FIELD_POSITION = 0
            AND (
                   RDB\$IDENTITY_TYPE = 0
                OR RDB\$IDENTITY_TYPE = 1
            )";
        my ( $first_col_is_autoincrement ) = $dbh->selectrow_array( $stmt, {}, $table );
        return $first_col_is_autoincrement;
    }
    elsif ( $driver eq 'DB2' ) {
        my $stmt = "SELECT COUNT(*) FROM SYSCAT.COLUMNS WHERE
                TABSCHEMA = ?
            AND TABNAME = ?
            AND COLNO = 0
            AND TYPENAME = 'INTEGER'
            AND NULLS = 'N'
            AND KEYSEQ = 1
            AND GENERATED = 'A'
            AND IDENTITY = 'Y'";
        my ( $first_col_is_autoincrement ) = $dbh->selectrow_array( $stmt, {}, $schema, $table );
        return $first_col_is_autoincrement;
    }
    elsif ( $driver eq 'Oracle' ) {
        my $stmt = "SELECT COUNT(*) FROM SYS.ALL_TAB_COLUMNS WHERE
                OWNER = ?
            AND TABLE_NAME = ?
            AND DATA_TYPE = 'NUMBER'
            AND NULLABLE = 'N'
            AND COLUMN_ID = 1
            AND IDENTITY_COLUMN = 'YES'";
        my ( $first_col_is_autoincrement ) = $dbh->selectrow_array( $stmt, {}, $schema, $table );
        return $first_col_is_autoincrement;
    }
    return;
}



1;


__END__
