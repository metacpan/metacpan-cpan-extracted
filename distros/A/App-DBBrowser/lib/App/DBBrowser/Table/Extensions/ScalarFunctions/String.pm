package # hide from PAUSE
App::DBBrowser::Table::Extensions::ScalarFunctions::String;

use warnings;
use strict;
use 5.014;

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
    my $driver = $sf->{i}{driver};
    my $ga = App::DBBrowser::Table::Extensions::ScalarFunctions::GetArguments->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $col = $ga->choose_a_column( $sql, $clause, $cols, $r_data );
    if ( ! defined $col ) {
        return;
    }
    if ( $driver eq 'Pg' ) {
        $col = $sf->__pg_col_to_text( $sql, $col );
    }
    my $args_data = [
        { prompt => 'Length: ', is_numeric => 1 }
    ];
    my ( $length ) = $ga->get_arguments( $sql, $clause, $func, $args_data, $r_data );
    if ( ! defined $length ) {
        return;
    }
    if ( $driver eq 'SQLite' ) {
        return "SUBSTR($col,-$length)"   if $func eq 'RIGHT';
        return "SUBSTR($col,1,$length)";
    }
    return "$func($col,$length)";
}


sub function_locate {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    my $ga = App::DBBrowser::Table::Extensions::ScalarFunctions::GetArguments->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $col = $ga->choose_a_column( $sql, $clause, $cols, $r_data );
    if ( ! defined $col ) {
        return;
    }
    my $args_data = [
        { prompt => 'Substring: ', empty_ok => 1 },
        { prompt => 'Start: ', is_numeric => 1 }
    ];
    my ( $substring, $start ) = $ga->get_arguments( $sql, $clause, $func, $args_data, $r_data );
    return                                   if ! defined $substring;
    return "LOCATE($substring,$col)"         if ! defined $start;
    return "LOCATE($substring,$col,$start)";
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
    my $driver = $sf->{i}{driver};
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $ga = App::DBBrowser::Table::Extensions::ScalarFunctions::GetArguments->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $col = $ga->choose_a_column( $sql, $clause, $cols, $r_data );
    if ( ! defined $col ) {
        return;
    }
    if ( $driver eq 'Pg' ) {
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
    if ( $driver eq 'SQLite' ) {
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
    my $driver = $sf->{i}{driver};
    my $ga = App::DBBrowser::Table::Extensions::ScalarFunctions::GetArguments->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $col = $ga->choose_a_column( $sql, $clause, $cols, $r_data );
    if ( ! defined $col ) {
        return;
    }
    if ( $driver eq 'Pg' ) {
        $col = $sf->__pg_col_to_text( $sql, $col );
    }
    my $args_data = [
        { prompt => 'Substring: ', empty_ok => 1 }
    ];
    if ( $driver eq 'Firebird' ) {
        push @$args_data, { prompt => 'Start: ', is_numeric => 1 };
    }
    my ( $substring, $start ) = $ga->get_arguments( $sql, $clause, $func, $args_data, $r_data );
    if ( ! defined $substring ) {
        return;
    }
    if ( $driver eq 'Firebird' ) {
        return "POSITION($substring,$col)"         if ! defined $start;
        return "POSITION($substring,$col,$start)";
    }
    return "POSITION($substring IN $col)";
}


sub function_instr {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    my $driver = $sf->{i}{driver};
    my $ga = App::DBBrowser::Table::Extensions::ScalarFunctions::GetArguments->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $col = $ga->choose_a_column( $sql, $clause, $cols, $r_data );
    if ( ! defined $col ) {
        return;
    }
    my $args_data;
    if ( $driver eq 'SQLite' ) {
        $args_data = [
            { prompt => 'Substring: ', empty_ok => 1 }
        ];
    }
    else {
        # DB2, Informix, Oracle: INSTR(string, substring, start, count)
        $args_data = [
            { prompt => 'Substring: ', empty_ok => 1 },
            { prompt => 'Start: ', is_numeric => 1 },
            { prompt => 'Count: ', is_numeric => 1 }
        ]
    }
    my ( $substring, $start, $count ) = $ga->get_arguments( $sql, $clause, $func, $args_data, $r_data );
    if ( ! defined $substring ) {
        return;
    }
    if ( $driver eq 'SQLite' ) {
        return "INSTR($col,$substring)";
    }
    return "INSTR($col,$substring)"                if ! defined $start;
    return "INSTR($col,$substring,$start)"         if ! defined $count;
    return "INSTR($col,$substring,$start,$count)";
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
    my $driver = $sf->{i}{driver};
    my $ga = App::DBBrowser::Table::Extensions::ScalarFunctions::GetArguments->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $col = $ga->choose_a_column( $sql, $clause, $cols, $r_data );
    if ( ! defined $col ) {
        return;
    }
    if ( $driver eq 'Pg' ) {
        $col = $sf->__pg_col_to_text( $sql, $col );
    }
    my $args_data = [
        { prompt => 'StartPos: ', is_numeric => 1 },
        { prompt => 'Length: ', is_numeric => 1 },
    ];
    my ( $startpos, $length ) = $ga->get_arguments( $sql, $clause, $func, $args_data, $r_data );
    return if ! defined $startpos;
    if ( $func eq 'SUBSTRING' ) {
        return "SUBSTRING($col FROM $startpos)"              if ! defined $length;
        return "SUBSTRING($col FROM $startpos FOR $length)";
    }
    else {
        return "SUBSTR($col,$startpos)"          if ! defined $length;
        return "SUBSTR($col,$startpos,$length)";
    }
}


sub function_replace {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    my $driver = $sf->{i}{driver};
    my $ga = App::DBBrowser::Table::Extensions::ScalarFunctions::GetArguments->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $col = $ga->choose_a_column( $sql, $clause, $cols, $r_data );
    if ( ! defined $col ) {
        return;
    }
    if ( $driver eq 'Pg' ) {
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
    my $driver = $sf->{i}{driver};
    my $ga = App::DBBrowser::Table::Extensions::ScalarFunctions::GetArguments->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $col = $ga->choose_a_column( $sql, $clause, $cols, $r_data );
    if ( ! defined $col ) {
        return;
    }
    if ( $driver eq 'Pg' ) {
        $col = $sf->__pg_col_to_text( $sql, $col );
    }
    my $args_data;
    if ( $driver eq 'SQLite' ) {
        $args_data = [
            { prompt => 'What: ' }
        ];
    }
    else {
        $args_data = [
            { prompt => 'Where: ', history => [ qw(BOTH LEADING TRAILING) ], history_only => 1, unquote => 1, skip_ok => 1 },
            { prompt => 'What: ' }
        ];
    }
    my @args = $ga->get_arguments( $sql, $clause, $func, $args_data, $r_data );
    if ( $driver eq 'SQLite' ) {
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
    my $driver = $sf->{i}{driver};
    my $ga = App::DBBrowser::Table::Extensions::ScalarFunctions::GetArguments->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $chosen_cols = $ga->choose_columns( $sql, $clause, $func, $cols, $r_data );
    if ( ! defined $chosen_cols ) {
        return;
    }
    if ( $driver eq 'Pg' ) {
        for my $col ( @$chosen_cols ) {
            $col = $sf->__pg_col_to_text( $sql, $col );
        }
    }
    my $args_data = [
        { prompt => 'Separator: ', history => [ '-', ' ', '_', ',', '/', '=', '+' ] },
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
    return "CONCAT(" . join( ',', @$arg ) . ")"  if $driver =~ /^(?:mysql|MariaDB)\z/;
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
