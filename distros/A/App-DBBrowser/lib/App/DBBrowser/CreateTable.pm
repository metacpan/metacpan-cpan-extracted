package # hide from PAUSE
App::DBBrowser::CreateTable;

use warnings;
use strict;
use 5.008003;
no warnings 'utf8';

our $VERSION = '2.006';

use File::Basename qw( basename );
use List::Util     qw( none any );

use Term::Choose       qw( choose );
use Term::Choose::Util qw( choose_a_number );
use Term::Form         qw();
use Term::TablePrint   qw( print_table );

use App::DBBrowser::Auxil;
use App::DBBrowser::DB;
use App::DBBrowser::Opt;
use App::DBBrowser::Table;
use App::DBBrowser::Table::Insert;


sub new {
    my ( $class, $info, $opt ) = @_;
    bless { i => $info, o => $opt }, $class;
}


sub delete_table {
    my ( $sf, $dbh, $data ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o} );
    my $lyt_3 = Term::Choose->new( $sf->{i}{lyt_3} );
    my $sql = {};
    my $prompt = '"' . basename( $data->{db} ) . '"' . "\n" . 'Drop table';
    # Choose
    my $table = $lyt_3->choose( #
        [ undef, map { "- $_" } @{$data->{user_tbls}} ],
        { prompt => $prompt }
    );
    if ( ! defined $table || ! length $table ) {
        return;
    }
    $table =~ s/\-\s//;
    $sql->{table} = $ax->quote_table( $dbh, $data->{tables}{$table} );
    my $sth = $dbh->prepare( "SELECT * FROM " . $sql->{table} );
    $sth->execute();
    my $col_names = $sth->{NAME}; # mysql: before fetchall_arrayref
    my $all_arrayref = $sth->fetchall_arrayref;
    my $row_count = @$all_arrayref;
    unshift @$all_arrayref, $col_names;
    my $prompt_pt = "ENTER to continue\n$sql->{table}:";
    print_table( $all_arrayref, { %{$sf->{o}{table}}, prompt => $prompt_pt, max_rows => 0, table_expand => 0 } );
    $prompt = sprintf 'DROP TABLE %s  (%d %s)', $sql->{table}, $row_count, $row_count == 1 ? 'row' : 'rows';
    $prompt .= "\n\nCONFIRM:";
    # Choose
    my $choice = choose( #
        [ undef, 'YES' ],
        { %{$sf->{i}{lyt_m}}, prompt => $prompt, undef => 'NO' }
    );
    if ( defined $choice && $choice eq 'YES' ) {
        $dbh->do( "DROP TABLE $sql->{table}" ) or die "DROP TABLE $sql->{table} failed!";
        return 1;
    }
    return;
}


sub __table_name {
    my ( $sf, $sql, $dbh, $stmt_typeS, $data ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o} );
    my $table;
    my $c = 0;

    TABLENAME: while ( 1 ) {
        my $trs = Term::Form->new( 'tn' );
        my $info;
        if ( defined $data->{file_name} ) {
            $info = sprintf "File: '%s'\n", basename( delete $data->{file_name} );
        }
        # Readline
        $table = $trs->readline( 'Table name: ', { info => $info } );
        if ( ! length $table ) {
            return;
        }
        my $tmp_td = [ undef, $data->{schema}, $table ];
        $sql->{table} = $ax->quote_table( $dbh, $tmp_td );
        if ( none { $sql->{table} eq $ax->quote_table( $dbh, $data->{tables}{$_} ) } keys %{$data->{tables}} ) {
            return 1;
        }
        $ax->print_sql( $sql, $stmt_typeS );
        my $prompt = "Table $sql->{table} already exists.";
        my $choice = choose(
            [ undef, 'New name' ],
            { %{$sf->{i}{lyt_stmt_h}}, prompt => $prompt, undef => 'BACK', layout => 3, justify => 0 }
        );
        if ( ! defined $choice ) {
            return;
        }
    }
}


sub __reset_create_table_sql {
    my ( $sf, $sql ) = @_;
    $sql->{table} = undef;
    $sql->{insert_into_args} = [];
    $sql->{insert_into_cols} = [];
}

sub create_new_table {
    my ( $sf, $dbh, $data ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o} );
    my $sql = {};
    $sf->__reset_create_table_sql( $sql );
    my @cu_keys = ( qw/create_table_plain create_table_form_copy create_table_form_file settings/ );
    my %cu = ( create_table_plain      => '- plain',
               create_table_form_copy  => '- Copy & Paste',
               create_table_form_file  => '- From File',
               settings                => '  SETTINGS'
    );
    my $old_idx = 0;

    MENU: while ( 1 ) {
        my $stmt_typeS = [ 'Create_table' ];
        my $choices = [ undef, @cu{@cu_keys} ];
        my $prompt = 'Create table';
        # Choose
        $ENV{TC_RESET_AUTO_UP} = 0;
        my $idx = choose(
            $choices,
            { %{$sf->{i}{lyt_3}}, index => 1, default => $old_idx, prompt => $prompt }
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
            $old_idx = $idx;
        }
        delete $ENV{TC_RESET_AUTO_UP};
        if ( $custom eq $cu{settings} ) {
            my $obj_opt = App::DBBrowser::Opt->new( $sf->{i}, $sf->{o} );
            $obj_opt->config_insert();
            next MENU;
        }
        $ax->reset_sql( $sql ); #
        if ( $custom eq $cu{create_table_plain} ) {
            my $ok = $sf->__data_from_plain( $sql, $dbh, $stmt_typeS, $data );
            if ( ! $ok ) {
                $sf->__reset_create_table_sql( $sql );
                next MENU;
            }
        }
        else {
            if ( $custom eq $cu{create_table_form_copy} ) {
                push @$stmt_typeS, 'Insert';
                my $tbl_in = App::DBBrowser::Table::Insert->new( $sf->{i}, $sf->{o} );
                my $ok = $tbl_in->from_copy_and_paste( $sql, $stmt_typeS );
                if ( ! $ok ) {
                    $sf->__reset_create_table_sql( $sql );
                    next MENU;
                }
            }
            elsif ( $custom eq $cu{create_table_form_file} ) {
                push @$stmt_typeS, 'Insert';
                my $tbl_in = App::DBBrowser::Table::Insert->new( $sf->{i}, $sf->{o} );
                my $file_name = $tbl_in->from_file( $sql, $stmt_typeS );
                if ( ! $file_name ) {
                    $sf->__reset_create_table_sql( $sql );
                    next MENU;
                }
                $data->{file_name} = $file_name;
            }
            my $ok = $sf->__table_name( $sql, $dbh, $stmt_typeS, $data );
            if ( ! $ok ) {
                $sf->__reset_create_table_sql( $sql );
                next MENU;
            }
            # Columns
            my ( $first_row, $user_input ) = ( '- First row', '- Add row' );
            $ax->print_sql( $sql, $stmt_typeS );
            # Choose
            my $choice = choose(
                [ undef, $first_row, $user_input ],
                { %{$sf->{i}{lyt_stmt_v}}, prompt => 'Header:' }
            );
            if ( ! defined $choice ) {
                $sf->__reset_create_table_sql( $sql );
                next MENU;
            }
            if ( $choice eq $first_row ) {
                $sql->{insert_into_cols} = shift @{$sql->{insert_into_args}}; # not quoted
            }
            else {
                my $c = 0;
                $sql->{insert_into_cols} = [ map { 'c' . ++$c } @{$sql->{insert_into_args}->[0]} ]; # not quoted
            }
            my $trs = Term::Form->new( 'cols' );
            $ax->print_sql( $sql, $stmt_typeS );
            # Fill_form
            my $c = 0;
            my $form = $trs->fill_form(
                [ map { [ ++$c, defined $_ ? "$_" : '' ] } @{$sql->{insert_into_cols}} ], #
                { prompt => 'Col names:', auto_up => 2, confirm => '  CONFIRM', back => '  BACK   ' }
            );
            if ( ! $form ) {
                $sf->__reset_create_table_sql( $sql );
                next MENU;
            }
            $sql->{insert_into_cols} = [ map { $_->[1] } @$form ]; # not quoted
        }
        die "Column with no name!" if any { ! length } @{$sql->{insert_into_cols}};
        my @cols = @{$sql->{insert_into_cols}}; #
        $sql->{insert_into_cols} = $ax->quote_simple_many( $dbh, $sql->{insert_into_cols} );
        # Datatypes
        my $trs = Term::Form->new( 'cols' );
        $ax->print_sql( $sql, $stmt_typeS );
        # Fill_form
        my $col_name_and_type = $trs->fill_form( # look
            [ map { [ $_, $sf->{o}{insert}{default_data_type} ] } @cols ],
            { prompt => 'Data types:', auto_up => 2, confirm => 'CONFIRM', back => 'BACK        ' }
        );
        if ( ! $col_name_and_type ) {
            $sf->__reset_create_table_sql( $sql );
            next MENU;
        }
        my $qt_table = $sql->{table};
        for my $i ( 0 .. $#{$sql->{insert_into_cols}} ) {
            $sql->{create_table_cols}[$i] = $sql->{insert_into_cols}[$i] . ' ' . $col_name_and_type->[$i][1];
        }
        # Create table
        $ax->print_sql( $sql, $stmt_typeS );
        # Choose
        my $create_table_ok = choose(
            [ undef, 'YES' ],
            { %{$sf->{i}{lyt_m}}, prompt => "Create table $qt_table?", undef => 'NO', index => 1 }
        );
        if ( ! defined $create_table_ok || ! $create_table_ok ) {
            $sf->__reset_create_table_sql( $sql );
            next MENU;
        }
        my $ct = sprintf "CREATE TABLE $qt_table (%s)", join( ', ', @{$sql->{create_table_cols}} );
        $dbh->do( $ct ) or die "$ct failed!";
        delete $sql->{create_table_cols};
        my $sth = $dbh->prepare( "SELECT * FROM $qt_table LIMIT 0" );
        $sth->execute() if $sf->{i}{driver} ne 'SQLite';
        if ( $stmt_typeS->[-1] eq 'Insert' ) {
            $stmt_typeS = [ $stmt_typeS->[-1] ];
            my @columns = @{$sth->{NAME}};
            $sth->finish();
            $sql->{insert_into_cols} = $ax->quote_simple_many( $dbh, \@columns );
            my $obj_table = App::DBBrowser::Table->new( $sf->{i}, $sf->{o} );
            my $commit_ok = $obj_table->commit_sql( $sql, $stmt_typeS, $dbh );
        }
        return 1;
    }
}


sub __data_from_plain {
    my ( $sf, $sql, $dbh, $stmt_typeS, $data ) = @_;
    my $ok = $sf->__table_name( $sql, $dbh, $stmt_typeS, $data );
    if ( ! $ok ) {
        return;
    }
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o} );
    $ax->print_sql( $sql, $stmt_typeS );
    my $col_count = choose_a_number( 3, { small => 1, confirm => 'Confirm', mouse => $sf->{o}{table}{mouse},
                                          back => 'Back', name => 'Number of columns: ', clear_screen => 0 } );
    if ( ! $col_count ) {
        return;
    }
    $ax->print_sql( $sql, $stmt_typeS );
    my $info = 'Enter column names:';
    my $trs = Term::Form->new();
    my $col_names = $trs->fill_form(
        [ map { [ $_, ] } 1 .. $col_count ],
        { info => $info, confirm => 'OK', back => '<<', auto_up => 2 }
    );
    if ( ! defined $col_names ) {
        return;
    }
    $sql->{insert_into_cols} = [ map { $_->[1] } @$col_names ]; # not quoted
    $ax->print_sql( $sql, $stmt_typeS );
    return 1;
}




1;

__END__
