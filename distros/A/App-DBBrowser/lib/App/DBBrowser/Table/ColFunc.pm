package # hide from PAUSE
App::DBBrowser::Table::ColFunc;

use warnings;
use strict;
use 5.008003;
no warnings 'utf8';

our $VERSION = '1.058';

use Clone           qw( clone );
use List::MoreUtils qw( first_index );
use Term::Choose    qw();

use App::DBBrowser::Auxil;
use App::DBBrowser::DB;


sub new {
    my ( $class, $info, $opt ) = @_;
    bless { info => $info, opt => $opt }, $class;
}


sub __col_function {
    my ( $self, $dbh, $sql, $backup_sql, $qt_columns, $pr_columns, $sql_type ) = @_;
    my $auxil  = App::DBBrowser::Auxil->new( $self->{info} );
    my $stmt_h = Term::Choose->new( $self->{info}{lyt_stmt_h} );
    my @functions = @{$self->{info}{scalar_func_keys}};
    my $stmt_key = '';
    if ( $sql->{select_type} eq '*' ) {
        @{$sql->{quote}{chosen_cols}} = map { $qt_columns->{$_} } @$pr_columns;
        @{$sql->{print}{chosen_cols}} = @$pr_columns;
        $stmt_key = 'chosen_cols';
    }
    elsif ( $sql->{select_type} eq 'chosen_cols' ) {
        $stmt_key = 'chosen_cols';
    }
    if ( $stmt_key eq 'chosen_cols' ) {
        if ( ! $sql->{scalar_func_backup_pr_col}{chosen_cols} ) {
            @{$sql->{scalar_func_backup_pr_col}{'chosen_cols'}} = @{$sql->{print}{chosen_cols}};
        }
    }
    else {
        if ( @{$sql->{print}{aggr_cols}} && ! $sql->{scalar_func_backup_pr_col}{aggr_cols} ) {
            @{$sql->{scalar_func_backup_pr_col}{'aggr_cols'}} = @{$sql->{print}{aggr_cols}};
        }
        if ( @{$sql->{print}{group_by_cols}} && ! $sql->{scalar_func_backup_pr_col}{group_by_cols} ) {
            @{$sql->{scalar_func_backup_pr_col}{'group_by_cols'}} = @{$sql->{print}{group_by_cols}};
        }
    }
    my $changed = 0;

    COL_SCALAR_FUNC: while ( 1 ) {
        my $default = 0;
        my $hidden_2 = 'Your choice:';
        my @pre = ( undef, $self->{info}{_confirm} );
        my $prompt = 'Choose:'; #
        if ( $sql_type eq 'Select' ) {
            unshift @pre, $hidden_2 if ! defined $pre[0] || $pre[0] ne $hidden_2;
            $prompt = '';
            $default = 1;
        }
        my @cols = $stmt_key eq 'chosen_cols'
            ? ( @{$sql->{print}{chosen_cols}} )
            : ( @{$sql->{print}{aggr_cols}}, @{$sql->{print}{group_by_cols}} );
        my $choices = [ @pre, map( "- $_", @cols ) ];
        $auxil->__print_sql_statement( $sql, $sql_type );
        # Choose
        my $idx = $stmt_h->choose(
            $choices,
            { %{$self->{info}{lyt_stmt_v}}, index => 1, default => $default, prompt => $prompt }
        );
        if ( ! defined $idx || ! defined $choices->[$idx] ) {
            $sql = clone( $backup_sql );
            return;
        }
        if ( $choices->[$idx] eq $hidden_2 ) { # prompt scalar-func-menu
            my @sql_types;
            if ( ! $self->{info}{multi_tbl} ) {
                @sql_types = ( 'Insert', 'Update', 'Delete' );
            }
            elsif ( $self->{info}{multi_tbl} eq 'join' && $self->{info}{db_driver} eq 'mysql' ) {
                @sql_types = ( 'Update' );
            }
            else {
                @sql_types = ();
            }
            if ( ! @sql_types ) {
                next COL_SCALAR_FUNC;
            }
            my $ch_types = [ undef, map( "- $_", @sql_types ) ];
            # Choose
            my $type_choice = $stmt_h->choose(
                $ch_types,
                { %{$self->{info}{lyt_stmt_v}}, prompt => 'Choose SQL type:', default => 0, clear_screen => 1 }
            );
            if ( defined $type_choice ) {
                ( $sql_type = $type_choice ) =~ s/^-\ //;
                $auxil->__reset_sql( $sql );
                return $sql_type;
            }
            return;
        }
        if ( $choices->[$idx] eq $self->{info}{_confirm} ) {
            if ( ! $changed ) {
                $sql = clone( $backup_sql );
                return;
            }
            $sql->{select_type} = $stmt_key if $sql->{select_type} eq '*';
            return $qt_columns, $pr_columns;
        }
        ( my $print_col = $choices->[$idx] ) =~ s/^\-\s//;
        $idx -= @pre;
        if ( $stmt_key ne 'chosen_cols' ) {
            if ( $idx - @{$sql->{print}{aggr_cols}} >= 0 ) {
                $idx -= @{$sql->{print}{aggr_cols}};
                $stmt_key = 'group_by_cols';
            }
            else {
                $stmt_key = 'aggr_cols';
            }
        }
        if ( $sql->{print}{$stmt_key}[$idx] ne $sql->{scalar_func_backup_pr_col}{$stmt_key}[$idx] ) {
            if ( $stmt_key ne 'aggr_cols' ) {
                my $i = first_index { $sql->{print}{$stmt_key}[$idx] eq $_ } @{$sql->{pr_col_with_scalar_func}};
                splice( @{$sql->{pr_col_with_scalar_func}}, $i, 1 );
            }
            $sql->{print}{$stmt_key}[$idx] = $sql->{scalar_func_backup_pr_col}{$stmt_key}[$idx];
            $sql->{quote}{$stmt_key}[$idx] = $qt_columns->{$sql->{scalar_func_backup_pr_col}{$stmt_key}[$idx]};
            $changed++;
            next COL_SCALAR_FUNC;
        }
        $auxil->__print_sql_statement( $sql, $sql_type );
        # Choose
        my $function = $stmt_h->choose(
            [ undef, map( "  $_", @functions ) ],
            { %{$self->{info}{lyt_stmt_v}} }
        );
        if ( ! defined $function ) {
            next COL_SCALAR_FUNC;
        }
        $function =~ s/^\s\s//;
        ( my $quote_col = $qt_columns->{$print_col} ) =~ s/\sAS\s\S+\z//;
        $auxil->__print_sql_statement( $sql, $sql_type );
        my ( $qt_scalar_func, $pr_scalar_func ) = $self->__prepare_col_func( $function, $quote_col, $print_col );
        if ( ! defined $qt_scalar_func ) {
            next COL_SCALAR_FUNC;
        }
        $pr_scalar_func = $auxil->__unambiguous_key( $pr_scalar_func, $pr_columns );
        if ( $stmt_key eq 'group_by_cols' ) {
            $sql->{quote}{$stmt_key}[$idx] = $qt_scalar_func;
            $sql->{print}{$stmt_key}[$idx] = $pr_scalar_func;
            $sql->{quote}{group_by_stmt} = " GROUP BY " . join( ', ', @{$sql->{quote}{$stmt_key}} );
            $sql->{print}{group_by_stmt} = " GROUP BY " . join( ', ', @{$sql->{print}{$stmt_key}} );
        }
        $sql->{quote}{$stmt_key}[$idx] = $qt_scalar_func;
        # alias to get a shorter scalar funtion column name in the tableprint (optional):
        $sql->{quote}{$stmt_key}[$idx] .= ' AS ' . $dbh->quote_identifier( $pr_scalar_func );
        $sql->{print}{$stmt_key}[$idx] = $pr_scalar_func;
        $qt_columns->{$pr_scalar_func} = $qt_scalar_func;
        if ( $stmt_key ne 'aggr_cols' ) { # aggregate functions are not allowed in WHERE clauses
            push @{$sql->{pr_col_with_scalar_func}}, $pr_scalar_func;
        }
        $changed++;
        next COL_SCALAR_FUNC;
    }
}


sub __prepare_col_func {
    my ( $self, $func, $quote_col, $print_col ) = @_;
    my $obj_db = App::DBBrowser::DB->new( $self->{info}, $self->{opt} );
    my $obj_ch = Term::Choose->new();
    my ( $quote_f, $print_f );
    $print_f = $self->{info}{scalar_func_h}{$func} . '(' . $print_col . ')';
    if ( $func =~ /^Epoch_to_Date(?:Time)?\z/ ) {
        my $prompt = "$print_f\nInterval:";
        my ( $microseconds, $milliseconds, $seconds ) = (
            '  ****************   Micro-Second',
            '  *************      Milli-Second',
            '  **********               Second' );
        my $choices = [ undef, $microseconds, $milliseconds, $seconds ];
        # Choose
        my $interval = $obj_ch->choose(
            $choices,
            { %{$self->{info}{lyt_stmt_v}}, prompt => $prompt }
        );
        return if ! defined $interval;
        my $div = $interval eq $microseconds ? 1000000 :
                  $interval eq $milliseconds ? 1000 : 1;
        if ( $func eq 'Epoch_to_DateTime' ) {
            $quote_f = $obj_db->epoch_to_datetime( $quote_col, $div );
        }
        else {
            $quote_f = $obj_db->epoch_to_date( $quote_col, $div );
        }
    }
    elsif ( $func eq 'Truncate' ) {
        my $prompt = "TRUNC $print_col\nDecimal places:";
        my $choices = [ undef, 0 .. 9 ];
        # Choose
        my $precision = $obj_ch->choose(
            $choices,
            { %{$self->{info}{lyt_stmt_h}}, prompt => $prompt }
        );
        return if ! defined $precision;
        $quote_f = $obj_db->truncate( $quote_col, $precision );
    }
    elsif ( $func eq 'Bit_Length' ) {
        $quote_f = $obj_db->bit_length( $quote_col );
    }
    elsif ( $func eq 'Char_Length' ) {
        $quote_f = $obj_db->char_length( $quote_col );
    }
    return $quote_f, $print_f;
}





1;


__END__
