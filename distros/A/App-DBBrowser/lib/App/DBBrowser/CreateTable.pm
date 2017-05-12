package # hide from PAUSE
App::DBBrowser::CreateTable;

use warnings;
use strict;
use 5.008003;
no warnings 'utf8';

our $VERSION = '1.053';

use List::Util qw( none any );

use Term::Choose     qw();
use Term::Form       qw();
use Term::TablePrint qw( print_table );

use App::DBBrowser::DB;
use App::DBBrowser::Auxil;
use App::DBBrowser::Opt;
use App::DBBrowser::Table;
use App::DBBrowser::Table::Insert;



sub new {
    my ( $class, $info, $opt ) = @_;
    bless { info => $info, opt => $opt }, $class;
}


sub __delete_table {
    my ( $self, $sql, $dbh ) = @_;
    my $sql_type = 'Drop_table';
    my $schema = $sql->{print}{schema};
    my $obj_db = App::DBBrowser::DB->new( $self->{info}, $self->{opt} );
    my $lyt_3 = Term::Choose->new( $self->{info}{lyt_3} );
    my $backup_opt_metadata = $self->{metadata};
    $self->{metadata} = 0;
    my ( $user_tbl, $system_tbl ) = $obj_db->get_table_names( $dbh, $schema );
    $self->{metadata} = $backup_opt_metadata;
    # Choose
    my $table = $lyt_3->choose(
        [ undef, map { "* $_" } @$user_tbl ],
        { undef => $self->{info}{_back} }
    );
    return if ! length $table;
    $table =~ s/.\s//;
    my $qt_table = $dbh->quote_identifier( undef, $schema, $table );
    $sql->{print}{table} = $table;
    $sql->{quote}{table} = $qt_table;
    my $delete_ok = $self->__delete_table_confirm( $sql, $dbh, $table, $qt_table, $sql_type );
    if ( $delete_ok ) {
        $dbh->do( "DROP TABLE $qt_table" ) or die "DROP TABLE $qt_table failed!";
    }
    return 1;
}


sub __delete_table_confirm {
    my ( $self, $sql, $dbh, $table, $qt_table, $sql_type ) = @_;
    my $stmt = "SELECT * FROM " . $qt_table;
    $stmt .= " LIMIT " . $self->{opt}{table}{max_rows};
    my $sth = $dbh->prepare( $stmt );
    $sth->execute();
    my $col_names = $sth->{NAME};
    my $all_arrayref = $sth->fetchall_arrayref;
    my $table_rows = @$all_arrayref;
    unshift @$all_arrayref, $col_names;
    my $prompt_pt = "Table '$table'  -  Close with ENTER";
    print_table( $all_arrayref, { %{$self->{opt}{table}}, prompt => $prompt_pt } );
    my $auxil = App::DBBrowser::Auxil->new( $self->{info} );
    my $lyt_1 = Term::Choose->new( $self->{info}{lyt_1} );
    my $prompt = sprintf 'Drop table \'%s\' (%d %s)?', $table, $table_rows, $table_rows == 1 ? 'row' : 'rows';
    $auxil->__print_sql_statement( $sql, $sql_type );
    # Choose
    my $choice = $lyt_1->choose(
        [ undef, 'YES' ],
        { prompt => $prompt, undef => 'NO', clear_screen => 0 }
    );
    if ( defined $choice && $choice eq 'YES' ) {
        return 1;
    }
    else {
        return;
    }
}


sub __create_new_table {
    my ( $self, $sql, $dbh ) = @_;
    my $auxil = App::DBBrowser::Auxil->new( $self->{info} );
    my $lyt_h = Term::Choose->new( $self->{info}{lyt_stmt_h} );
    my $obj_db = App::DBBrowser::DB->new( $self->{info}, $self->{opt} );
    my $sql_type = 'Create_table';
    my $db_plugin = $self->{info}{db_plugin};
    my $schema = $sql->{print}{schema};
    my $old_idx = 1;
    $auxil->__reset_sql( $sql );
    $sql->{print}{table} = '...';
    print "\n";
    my $table;
    my $overwrite_ok;
    my $c = 0;

    TABLENAME: while ( 1 ) {
        my $trs = Term::Form->new( 'tn' );
        $auxil->__print_sql_statement( $sql, $sql_type );
        # Readline
        $table = $trs->readline( 'Table name: ' );
        return if ! length $table;
        my $backup_opt_metadata = $self->{metadata};
        $self->{metadata} = 1;
        my ( $user_tables, $system_tables ) = $obj_db->get_table_names( $dbh, $schema );
        $self->{metadata} = $backup_opt_metadata;
        my $qt_table = $dbh->quote_identifier( undef, $schema, $table );
        if ( none { $_ eq $table } @$user_tables, @$system_tables ) {
            $sql->{print}{table} = $table;
            $sql->{quote}{table} = $qt_table;
            last TABLENAME;
        }
        my $prompt .= "Overwrite '$table'?";
        $auxil->__print_sql_statement( $sql, $sql_type );
        # Choose
        $overwrite_ok = $lyt_h->choose(
            [ undef, 'YES' ],
            { prompt => $prompt, undef => 'NO', layout => 1 }
        );
        if ( $overwrite_ok ) {
            $overwrite_ok = $self->__delete_table_confirm( $sql, $dbh, $table, $qt_table, $sql_type );
            if ( $overwrite_ok ) {
                $sql->{print}{table} = $table;
                $sql->{quote}{table} = $qt_table;
                last TABLENAME;
            }
        }
        else {
            $c++;
            return if $c > 3;
        }
    }

    MENU: while ( 1 ) {
        my ( $hidden, $commit, $create ) = ( 'Customize:', '  Confirm Stmt', '  Build   Stmt' );
        my $choices = [ $hidden, undef, $create ];
        splice @$choices, 2, 0, $commit if $sql_type eq 'Insert';
        $auxil->__print_sql_statement( $sql, $sql_type );
        # Choose
        my $idx = $lyt_h->choose(
            $choices,
            { %{$self->{info}{lyt_stmt_v}}, prompt => '', index => 1, default => $old_idx,
            undef => $self->{info}{back} }
        );
        if ( ! defined $idx || ! defined $choices->[$idx] ) {
            return;
        }
        my $choice = $choices->[$idx];
        if ( $self->{opt}{G}{menu_sql_memory} ) {
            if ( $old_idx == $idx ) {
                $old_idx = 1;
                next MENU;
            }
            else {
                $old_idx = $idx;
            }
        }
        if ( $choice eq $hidden ) { # prompt "build-stmt-menu" (insert)
            my $obj_opt = App::DBBrowser::Opt->new( $self->{info}, $self->{opt}, {} );
            $obj_opt->__config_insert();
            next MENU;
        }
        elsif ( $choice eq $create ) {
            $sql_type = 'Create_table';
            $auxil->__reset_sql( $sql );
            my $tbl_in = App::DBBrowser::Table::Insert->new( $self->{info}, $self->{opt} );
            my $ok = $tbl_in->__get_insert_values( $sql, $sql_type );
            next MENU if ! $ok;

            # Columns
            $auxil->__print_sql_statement( $sql, $sql_type );
            # Choose
            my $first_row_to_colnames = $lyt_h->choose(
                [ undef, 'YES' ],
                { prompt => 'Use first row as column names?', undef => 'NO' }
            );
            if ( $first_row_to_colnames ) {
                $sql->{print}{insert_cols} = shift @{$sql->{quote}{insert_into_args}};
            }
            else {
                my $c = 1;
                $sql->{print}{insert_cols} = [ map { 'col_' . $c++ } @{$sql->{quote}{insert_into_args}->[0]} ];
            }
            my $c = 1;
            my $tmp_cols = [ map { [ $c++, defined $_ ? "$_" : '' ] } @{$sql->{print}{insert_cols}} ];
            my $add_pk_auto;
            my $id_pk_name = $self->{opt}{insert}{id_col_name};
            my $pk_auto_stmt = $obj_db->primary_key_auto();
            my $prompt = 'Add auto increment primary key?';
            if ( $pk_auto_stmt ) {
                $auxil->__print_sql_statement( $sql, $sql_type );
                # Choose
                $add_pk_auto = $lyt_h->choose(
                    [ undef, 'YES' ],
                    { prompt => $prompt, undef => 'NO' }
                );
                if ( $add_pk_auto ) {
                    unshift @$tmp_cols, [ 0, $id_pk_name ];
                    $sql->{print}{id_pk_auto} = $id_pk_name;
                }
            }
            my $trs = Term::Form->new( 'cols' );
            $auxil->__print_sql_statement( $sql, $sql_type );
            # Fill_form
            my $cols = $trs->fill_form(
                $tmp_cols,
                { prompt => 'Col names:', auto_up => 2, confirm => '  CONFIRM', back => '  BACK   ' }
            );
            if ( ! $cols ) {
                $sql->{print}{insert_cols} = [];
                delete $sql->{print}{id_pk_auto};
                next MENU;
            }
            $sql->{print}{insert_cols} = [ map { $_->[1] } @$cols ];
            if ( $add_pk_auto ) {
                $sql->{print}{id_pk_auto} = shift @{$sql->{print}{insert_cols}};
            }
            die "Column with no name!" if any { ! length } map { $_->[1] } @$cols;

            # Datatypes
            my $datatype = $self->{opt}{insert}{default_data_type};
            my $choices = [ map { [ $_, $datatype ] } @{$sql->{print}{insert_cols}} ];
            if ( $add_pk_auto ) {
                unshift @$choices, [ $id_pk_name, $pk_auto_stmt ];
            }
            $auxil->__print_sql_statement( $sql, $sql_type );
            # Fill_form
            my $col_name_and_type = $trs->fill_form(
                $choices,
                { prompt => 'Data types:', auto_up => 2, confirm => '  CREATE-TABLE',
                  back => '  BACK        ', ro => $add_pk_auto ? [ 0 ] : undef }
            );
            return if ! $col_name_and_type;

            # Create table
            my $qt_table = $sql->{quote}{table};
            if ( $overwrite_ok ) {
                $dbh->do( "DROP TABLE $qt_table" ) or die "DROP TABLE $qt_table failed!";
            }
            my @qt_col_name_and_type = map { [ $dbh->quote_identifier( $_->[0] ), $_->[1] ] } @$col_name_and_type;
            my $ct = sprintf "CREATE TABLE $qt_table ( %s )", join ', ', map { join ' ', @$_ } @qt_col_name_and_type;
            $dbh->do( $ct ) or die "$ct failed!";

            my $sth = $dbh->prepare( "SELECT * FROM $qt_table LIMIT 0" );
            $sth->execute();
            my @columns = @{$sth->{NAME}};
            $sth->finish();
            if ( $add_pk_auto  ) {
                $sql->{print}{id_pk_auto} = shift @columns;
            }
            $sql->{print}{insert_cols} = [];
            $sql->{quote}{insert_cols} = [];
            for my $col ( @columns ) {
                push @{$sql->{print}{insert_cols}}, $col;
                push @{$sql->{quote}{insert_cols}}, $dbh->quote_identifier( $col );
            }
            $sql_type = 'Insert';
            $old_idx = 1;
        }
        elsif ( $choice eq $commit ) {
            my $obj_table = App::DBBrowser::Table->new( $self->{info}, $self->{opt} );
            my $ok = $obj_table->__commit_sql( $sql, $sql_type, $dbh );
            delete $sql->{print}{id_pk_auto};
            if ( ! $ok ) {
                $auxil->__reset_sql( $sql );
                next MENU;
            }
            last MENU;
        }
    }
    return $table;
}


1;

__END__
