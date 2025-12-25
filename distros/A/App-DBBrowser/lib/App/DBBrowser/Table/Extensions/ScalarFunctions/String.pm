package # hide from PAUSE
App::DBBrowser::Table::Extensions::ScalarFunctions::String;

use warnings;
use strict;
use 5.016;

use App::DBBrowser::Auxil;
use App::DBBrowser::Table::Extensions::ScalarFunctions::GetArguments;


sub new {
    my ( $class, $info, $options, $d ) = @_;
    bless {
        i => $info,
        o => $options,
        d => $d
    }, $class;
}


sub function_left {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    $sf->__left_rigtht( $sql, $clause, $func, $cols, $r_data );
}


sub function_right {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    $sf->__left_rigtht( $sql, $clause, $func, $cols, $r_data );
}


sub __left_rigtht {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    my $dbms = $sf->{i}{dbms};
    my $ga = App::DBBrowser::Table::Extensions::ScalarFunctions::GetArguments->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $col = $ga->choose_a_column( $sql, $clause, $cols, $r_data );
    if ( ! defined $col ) {
        return;
    }
    if ( $dbms eq 'Pg' ) {
        $col = $sf->__pg_col_to_text( $sql, $col );
    }
    my $args_data = [
        { prompt => 'Length: ', is_numeric => 1 }
    ];
    my ( $length ) = $ga->get_arguments( $sql, $clause, $func, $args_data, $r_data );
    if ( ! defined $length ) {
        return;
    }
    if ( $dbms eq 'SQLite' ) {
        return "SUBSTR($col,-$length)"   if $func eq 'RIGHT';
        return "SUBSTR($col,1,$length)";
    }
    return "$func($col,$length)";
}


sub function_lpad {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    return $sf->__rpad_lpad( $sql, $clause, $func, $cols, $r_data );
}


sub function_rpad {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    return $sf->__rpad_lpad( $sql, $clause, $func, $cols, $r_data );
}


sub __rpad_lpad {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    my $dbms = $sf->{i}{dbms};
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $ga = App::DBBrowser::Table::Extensions::ScalarFunctions::GetArguments->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $col = $ga->choose_a_column( $sql, $clause, $cols, $r_data );
    if ( ! defined $col ) {
        return;
    }
    if ( $dbms eq 'Pg' ) {
        $col = $sf->__pg_col_to_text( $sql, $col );
    }
    my $args_data = [
        { prompt => 'Length: ', is_numeric => 1 },
        { prompt => 'Fill: ' }
    ];
    my ( $length, $fill ) = $ga->get_arguments( $sql, $clause, $func, $args_data, $r_data );
    if ( ! defined $length ) {
        return;
    }
    if ( $dbms eq 'DuckDB' ) {
        $fill = length $fill ? $fill : "' '";
    }
    if ( $dbms eq 'SQLite' ) {
        $fill = defined $fill ? $ax->unquote_constant( $fill ) : ' ';
        $fill = $sf->{d}{dbh}->quote( $fill x $length );
            return "SUBSTR($fill||$col,-$length,$length)" if $func eq 'LPAD';
            return "SUBSTR($col||$fill,1,$length)";
    }
    else {
        return "$func($col,$length)"        if ! defined $fill;
        return "$func($col,$length,$fill)";
    }
}


sub function_position {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    return $sf->__position_instr_locate_charindex( $sql, $clause, $func, $cols, $r_data );
}


sub function_instr {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    return $sf->__position_instr_locate_charindex( $sql, $clause, $func, $cols, $r_data );
}


sub function_locate {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    return $sf->__position_instr_locate_charindex( $sql, $clause, $func, $cols, $r_data );
}


sub function_charindex {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    return $sf->__position_instr_locate_charindex( $sql, $clause, $func, $cols, $r_data );
}


sub __position_instr_locate_charindex {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    my $dbms = $sf->{i}{dbms};
    my $ga = App::DBBrowser::Table::Extensions::ScalarFunctions::GetArguments->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $col = $ga->choose_a_column( $sql, $clause, $cols, $r_data );
    if ( ! defined $col ) {
        return;
    }
    if ( $dbms eq 'Pg' ) {
        $col = $sf->__pg_col_to_text( $sql, $col );
    }
    my $args_data = [
        { prompt => 'Substring: ', empty_ok => 1 }
    ];
    if ( $func eq 'POSITION' ) {
        if ( $dbms eq 'Firebird' ) {
            push @$args_data, { prompt => 'Start: ', is_numeric => 1 };
        }
    }
    elsif ( $func eq 'INSTR' ) {
        if ( $dbms =~ /^(?:DB2|Informix|Oracle)\z/ ) {
            push @$args_data, { prompt => 'Start: ', is_numeric => 1 }, { prompt => 'Count: ', is_numeric => 1 }; # 'Occurrence:'
        }
    }
    elsif ( $func eq 'LOCATE' ) {
        push @$args_data, { prompt => 'Start: ', is_numeric => 1 };
    }
    elsif ( $func eq 'CHARINDEX' ) {
        push @$args_data, { prompt => 'Start: ', is_numeric => 1 }, { prompt => 'Count: ', is_numeric => 1 }; # 'Occurrence:'
    }
    my ( $substring, $start, $count ) = $ga->get_arguments( $sql, $clause, $func, $args_data, $r_data );
    if ( ! defined $substring ) {
        return;
    }
    if ( $func eq 'POSITION' ) {
        return "$func($substring IN $col)"      if ! length $start;
        return "$func($substring,$col,$start)";
    }
    elsif ( $func eq 'INSTR' ) {
        return "$func($col,$substring)"                if ! defined $start;
        return "$func($col,$substring,$start)"         if ! defined $count;
        return "$func($col,$substring,$start,$count)";
    }
    elsif ( $func eq 'LOCATE' ) {
        return "$func($substring,$col)"         if ! defined $start;
        return "$func($substring,$col,$start)";
    }
    elsif ( $func eq 'CHARINDEX' ) {
        return "$func($substring,$col)"                if ! defined $start;
        return "$func($substring,$col,$start)"         if ! defined $count;
        return "$func($substring,$col,$start,$count)";
    }
}


sub function_substr {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    return $sf->__substr_substring( $sql, $clause, $func, $cols, $r_data );
}


sub function_substring {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    return $sf->__substr_substring( $sql, $clause, $func, $cols, $r_data );
}

sub __substr_substring {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    my $dbms = $sf->{i}{dbms};
    my $ga = App::DBBrowser::Table::Extensions::ScalarFunctions::GetArguments->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $col = $ga->choose_a_column( $sql, $clause, $cols, $r_data );
    if ( ! defined $col ) {
        return;
    }
    if ( $dbms eq 'Pg' ) {
        $col = $sf->__pg_col_to_text( $sql, $col );
    }
    my $args_data = [
        { prompt => 'StartPos: ', is_numeric => 1 },
        { prompt => 'Length: ', is_numeric => 1 },
    ];
    my ( $startpos, $length ) = $ga->get_arguments( $sql, $clause, $func, $args_data, $r_data );
    return if ! defined $startpos;
    if ( $func eq 'SUBSTRING' ) {
        if ( $dbms eq 'Firebird' ) {
            return "SUBSTRING($col FROM $startpos)" if ! defined $length;
            return "SUBSTRING($col FROM $startpos FOR $length)";
        }
        else {
            return "SUBSTRING($col, $startpos)" if ! defined $length;
            return "SUBSTRING($col, $startpos, $length)";
        }
    }
    else {
        return "SUBSTR($col,$startpos)" if ! defined $length;
        return "SUBSTR($col,$startpos,$length)";
    }
}


sub function_replace {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    my $dbms = $sf->{i}{dbms};
    my $ga = App::DBBrowser::Table::Extensions::ScalarFunctions::GetArguments->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $col = $ga->choose_a_column( $sql, $clause, $cols, $r_data );
    if ( ! defined $col ) {
        return;
    }
    if ( $dbms eq 'Pg' ) {
        $col = $sf->__pg_col_to_text( $sql, $col );
    }
    my $args_data = [
        { prompt => 'From string: ' },
        { prompt => 'New string: ', empty_ok => 1 },
    ];
    my ( $from_string, $new_string ) = $ga->get_arguments( $sql, $clause, $func, $args_data, $r_data );
    if ( ! defined $from_string || ! defined $new_string ) {
        return;
    }
    return "REPLACE($col,$from_string,$new_string)";
}


sub function_trim {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    my $dbms = $sf->{i}{dbms};
    my $ga = App::DBBrowser::Table::Extensions::ScalarFunctions::GetArguments->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $col = $ga->choose_a_column( $sql, $clause, $cols, $r_data );
    if ( ! defined $col ) {
        return;
    }
    if ( $dbms eq 'Pg' ) {
        $col = $sf->__pg_col_to_text( $sql, $col );
    }
    my $args_data;
    if ( $dbms eq 'SQLite' ) {
        $args_data = [
            { prompt => 'What: ' }
        ];
    }
    else {
        $args_data = [
            { prompt => 'Where: ', unquote => 1, history => [ qw(BOTH LEADING TRAILING) ], history_only => 1, skip_ok => 1 },
            { prompt => 'What: ' }
        ];
    }
    my @args = $ga->get_arguments( $sql, $clause, $func, $args_data, $r_data );
    if ( $dbms eq 'SQLite' ) {
        my ( $what ) = @args;
        return "TRIM($col)"        if ! defined $what;
        return "TRIM($col,$what)";
    }
    else {
        my ( $where, $what ) = @args;
        my $tmp = join ' ', grep { length } $where, $what;
        return "TRIM($col)"            if ! length $tmp;
        return "TRIM($tmp FROM $col)";
    }
}


sub function_concat {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    my $dbms = $sf->{i}{dbms};
    my $ga = App::DBBrowser::Table::Extensions::ScalarFunctions::GetArguments->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $chosen_cols = $ga->choose_columns( $sql, $clause, $func, $cols, $r_data );
    if ( ! defined $chosen_cols ) {
        return;
    }
    if ( $dbms eq 'Pg' ) {
        for my $col ( @$chosen_cols ) {
            $col = $sf->__pg_col_to_text( $sql, $col );
        }
    }
    my $args_data = [
        { prompt => 'Separator: ', history => [ '-', ' ', '_', ',', '/', '=', '+', '|' ] },
    ];
    my ( $sep ) = $ga->get_arguments( $sql, $clause, $func, $args_data, $r_data );
    my $arg;
    if ( length $sep ) {
        for ( @$chosen_cols ) {
            push @$arg, $_, $sep;
        }
        pop @$arg;
    }
    else {
        $arg = $chosen_cols
    }
    return "CONCAT(" . join( ',', @$arg ) . ")"  if $dbms =~ /^(?:mysql|MariaDB|MSSQL)\z/;
    return join( " || ", @$arg );  # ansi 2003
}


sub __pg_col_to_text {
    my ( $sf, $sql, $col ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    return $ax->pg_column_to_text( $sql, $col );
}


# string units: $position, $instr, $locate, $left, $right, $length, $substring, $upper, $lower ##
# $round datetime: locale

1;
