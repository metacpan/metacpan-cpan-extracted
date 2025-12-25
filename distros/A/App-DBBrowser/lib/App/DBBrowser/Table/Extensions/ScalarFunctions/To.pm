package # hide from PAUSE
App::DBBrowser::Table::Extensions::ScalarFunctions::To;

use warnings;
use strict;
use 5.016;

use App::DBBrowser::Auxil;
use App::DBBrowser::Table::Extensions::ScalarFunctions::GetArguments;
use App::DBBrowser::Table::Extensions::ScalarFunctions::To::EpochTo;


sub new {
    my ( $class, $info, $options, $d ) = @_;
    bless {
        i => $info,
        o => $options,
        d => $d
    }, $class;
}


sub function_to_char {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    return $sf->__format_function( $sql, $clause, $func, $cols, $r_data );
}

sub function_to_date {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    return $sf->__format_function( $sql, $clause, $func, $cols, $r_data );
}

sub function_strftime {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    return $sf->__format_function( $sql, $clause, $func, $cols, $r_data );
}

sub function_strptime {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    return $sf->__format_function( $sql, $clause, $func, $cols, $r_data );
}

sub function_to_timestamp {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    return $sf->__format_function( $sql, $clause, $func, $cols, $r_data );
}

sub function_to_timestamp_tz {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    return $sf->__format_function( $sql, $clause, $func, $cols, $r_data );
}

sub function_to_number {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    return $sf->__format_function( $sql, $clause, $func, $cols, $r_data );
}

sub function_date_format {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    return $sf->__format_function( $sql, $clause, $func, $cols, $r_data );
}

sub function_format {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    return $sf->__format_function( $sql, $clause, $func, $cols, $r_data );
}

sub function_str_to_date {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    return $sf->__format_function( $sql, $clause, $func, $cols, $r_data );
}

sub __format_function {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    my $dbms = $sf->{i}{dbms};
    my $ga = App::DBBrowser::Table::Extensions::ScalarFunctions::GetArguments->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $col = $ga->choose_a_column( $sql, $clause, $cols, $r_data );
    if ( ! defined $col ) {
        return;
    }
    if ( $dbms eq 'DuckDB' && $func eq 'TO_TIMESTAMP' ) {
        return "$func($col)";
    }
    my $args_data = [
        { prompt => 'Format: ', history => $sf->__format_history( $func ) },
    ];
    if ( $func eq 'FORMAT' ) {
        push @$args_data, { prompt => 'Locale: ', history => [] };
    }
    if ( $dbms eq 'Oracle' ) {
        push @$args_data, { prompt => 'nls_parameter: ' };
    }
    elsif ( $dbms eq 'DB2' ) {
        push @$args_data, { prompt => 'Locale: ' }                                              if $func eq 'TO_CHAR';
        push @$args_data, { prompt => 'Decimals: ', is_numeric => 1 }, { prompt => 'Locale: ' } if $func eq 'TO_DATE'
    }
    my ( $format, @args ) = $ga->get_arguments( $sql, $clause, $func, $args_data, $r_data );
    if ( ! defined $format ) {
        return;
    }
    if ( $dbms eq 'SQLite' ) {
        my $modifiers = $ga->sqlite_modifiers( $sql, $r_data );
        return "$func($format,$col,$modifiers)" if length $modifiers;
        return "$func($format,$col)";
    }
    my $additional_args = join ',', grep { length } @args;
    return "$func($col,$format,$additional_args)" if length $additional_args;
    return "$func($col,$format)";
}


sub __format_history {
    my ( $sf, $func ) = @_;
    my $dbms = $sf->{i}{dbms};
    if ( $dbms eq 'SQLite' ) {
        return [ '%Y-%m-%d %H:%M:%f', '%Y-%m-%d %H:%M:%S' ] if $func eq 'STRFTIME';
        return [];
    }
    elsif ( $dbms =~ /^(?:mysql|MariaDB)\z/ ) {
        return [ '%Y-%m-%d %H:%i:%S.%f', '%a %d %b %Y %h:%i:%S %p' ] if $func eq 'DATE_FORMAT';
        return [ '%Y-%m-%d %H:%i:%S.%f', '%a %d %b %Y %h:%i:%S %p' ] if $func eq 'STR_TO_DATE';
        return [                                                   ] if $func eq 'FORMAT';
        return [];
    }
    elsif ( $dbms eq 'Pg' ) {
        return [ 'YYYY-MM-DD HH24:MI:SS.FF6TZH:TZM', 'Dy DD Mon YYYY HH:MI:SS AM TZ OF' ] if $func eq 'TO_CHAR'; # TZ and OF only in to_char
        return [ 'YYYY-MM-DD'                                                           ] if $func eq 'TO_DATE';
        return [ 'YYYY-MM-DD HH24:MI:SS.FF6TZH:TZM', 'Dy DD Mon YYYY HH:MI:SS AM'       ] if $func eq 'TO_TIMESTAMP';
        return [                                                                        ] if $func eq 'TO_NUMBER';
        return [];
    }

    elsif ( $dbms eq 'DuckDB' ) { ##
        return [ '%Y-%m-%d %H:%M:%f', '%Y-%m-%d %H:%M:%S'                               ] if $func eq 'STRFTIME';
        return [ '%Y-%m-%d %H:%M:%f', '%Y-%m-%d %H:%M:%S'                               ] if $func eq 'STRPTIME';
        return [];
    }

    elsif ( $dbms eq 'DB2' ) {
        return [ 'YYYY-MM-DD HH24:MI:SS.FF6', 'Dy DD Mon YYYY HH:MI:SS AM' ] if $func eq 'TO_CHAR';
        return [ 'YYYY-MM-DD HH24:MI:SS.FF6', 'Dy DD Mon YYYY HH:MI:SS AM' ] if $func eq 'TO_DATE';
        return [                                                           ] if $func eq 'TO_NUMBER';
        return [];
    }
    elsif ( $dbms eq 'Informix' ) {
        return [ '%Y-%m-%d %H:%M:%S.%F5', '%a %d %b %Y %I:%M:%S %p' ] if $func eq 'TO_CHAR';
        return [ '%Y-%m-%d %H:%M:%S.%F5', '%a %d %b %Y %I:%M:%S %p' ] if $func eq 'TO_DATE';
        return [                                                    ] if $func eq 'TO_NUMBER';
        return [];
    }
    elsif ( $dbms eq 'Oracle' ) {
        return [ 'YYYY-MM-DD HH24:MI:SS.FF9TZH:TZM', 'Dy DD Mon YYYY HH:MI:SSXFF AM TZR TZD' ] if $func eq 'TO_CHAR';
        return [ 'YYYY-MM-DD HH24:MI:SS'           , 'Dy DD Mon YYYY HH:MI:SS AM'            ] if $func eq 'TO_DATE'; # not in the DATE format: FF, TZD, TZH, TZM, and TZR.  Max length 22
        return [ 'YYYY-MM-DD HH24:MI:SS.FF'        , 'Dy DD Mon YYYY HH:MI:SS AM'            ] if $func eq 'TO_TIMESTAMP';
        return [ 'YYYY-MM-DD HH24:MI:SS.FFTZH:TZM' , 'Dy DD Mon YYYY HH:MI:SS AM TZD'        ] if $func eq 'TO_TIMESTAMP_TZ';
        return [                                                                             ] if $func eq 'TO_NUMBER';
        return [];
    }
    else {
        return [];
    }
}


sub function_str {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    my $ga = App::DBBrowser::Table::Extensions::ScalarFunctions::GetArguments->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $col = $ga->choose_a_column( $sql, $clause, $cols, $r_data );
    if ( ! defined $col ) {
        return;
    }
    my $args_data = [
        { prompt => 'Length: ', is_numeric => 1 },
        { prompt => 'Decimal: ', is_numeric => 1 },
    ];
    my ( $length, $decimal ) = $ga->get_arguments( $sql, $clause, $func, $args_data, $r_data );
    return "$func($col)"                   if ! length $length;
    return "$func($col,$length)"           if ! length $decimal;
    return "$func($col,$length,$decimal)";
}


sub function_to_epoch {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    #my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $dbms = $sf->{i}{dbms};
    my $ga = App::DBBrowser::Table::Extensions::ScalarFunctions::GetArguments->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $col = $ga->choose_a_column( $sql, $clause, $cols, $r_data );
    if ( ! defined $col ) {
        return;
    }
    if ( $dbms eq 'SQLite' ) {
        return "UNIXEPOCH($col,'utc','subsec')"; # subsec: sqlite 3.42.0
    }
    elsif ( $dbms =~ /^(?:mysql|MariaDB)\z/ ) {
        return "UNIX_TIMESTAMP($col)";
    }
    elsif ( $dbms eq 'Pg' ) {
        return "EXTRACT(EPOCH FROM ${col}::timestamp with time zone)";
    }
    elsif ( $dbms eq 'DuckDB' ) { ##
        return "EPOCH(${col}::timestamp with time zone)";
        #return "EPOCH($col)";
    }
    elsif ( $dbms eq 'Firebird' ) {
        #my $firebird_major_version = $ax->major_server_version();
        my $firebird_major_version = 3; ##
        return "DATEDIFF(SECOND,TIMESTAMP '1970-01-01 00:00:00 UTC',$col)" if $firebird_major_version >= 4;
        return "DATEDIFF(SECOND,TIMESTAMP '1970-01-01 00:00:00',$col)"; # no timezone
        #return "DATEDIFF(MILLISECOND,TIMESTAMP '1970-01-01 00:00:00',$col) * 0.001";   # * 0.001 doesn't work in version 4 ##
    }
    elsif ( $dbms eq 'DB2' ) {
        return "EXTRACT(EPOCH FROM $col)"; # no timezone
    }
    elsif ( $dbms eq 'Oracle' ) {
        my $args_data = [
            { prompt => 'Column type: ', unquote => 1, history => [ qw(DATE TIMESTAMP TIMESTAMP_TZ) ], history_only => 1 } ##
        ];
        my ( $column_type ) = $ga->get_arguments( $sql, $clause, $func, $args_data, $r_data );
        $column_type = uc $column_type;
        return "TRUNC((CAST($col AT TIME ZONE 'UTC' AS DATE) - DATE '1970-01-01') * 86400)"                                             if $column_type eq 'TIMESTAMP_TZ';
        return "TRUNC((CAST(FROM_TZ($col,SESSIONTIMEZONE) AT TIME ZONE 'UTC' AS DATE) - DATE '1970-01-01') * 86400)"                    if $column_type eq 'TIMESTAMP';
        return "TRUNC((CAST(FROM_TZ(CAST($col AS TIMESTAMP),SESSIONTIMEZONE) AT TIME ZONE 'UTC' AS DATE) - DATE '1970-01-01') * 86400)" if $column_type eq 'DATE';
    }
    elsif ( $dbms eq 'MSSQL' ) {
        return "CAST(DATEDIFF(s,'1970-01-01 00:00:00',$col)AS BIGINT)";
    }
}


sub function_unixepoch {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    my $ga = App::DBBrowser::Table::Extensions::ScalarFunctions::GetArguments->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $col = $ga->choose_a_column( $sql, $clause, $cols, $r_data );
    if ( ! defined $col ) {
        return;
    }
    my $modifiers = $ga->sqlite_modifiers( $sql, $r_data );
    return "$func($col,$modifiers)" if length $modifiers;
    return "$func($col)";
}


sub function_epoch_to_date {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    my $ga = App::DBBrowser::Table::Extensions::ScalarFunctions::GetArguments->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $col = $ga->choose_a_column( $sql, $clause, $cols, $r_data );
    if ( ! defined $col ) {
        return;
    }
    my $new_et = App::DBBrowser::Table::Extensions::ScalarFunctions::To::EpochTo->new( $sf->{i}, $sf->{o}, $sf->{d} );
    return $new_et->epoch_to( $sql, $col, $func );
}



sub function_epoch_to_datetime {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    my $ga = App::DBBrowser::Table::Extensions::ScalarFunctions::GetArguments->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $col = $ga->choose_a_column( $sql, $clause, $cols, $r_data );
    if ( ! defined $col ) {
        return;
    }
    my $new_et = App::DBBrowser::Table::Extensions::ScalarFunctions::To::EpochTo->new( $sf->{i}, $sf->{o}, $sf->{d} );
    return $new_et->epoch_to( $sql, $col, $func );
}


sub function_epoch_to_timestamp {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    my $ga = App::DBBrowser::Table::Extensions::ScalarFunctions::GetArguments->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $col = $ga->choose_a_column( $sql, $clause, $cols, $r_data );
    if ( ! defined $col ) {
        return;
    }
    my $new_et = App::DBBrowser::Table::Extensions::ScalarFunctions::To::EpochTo->new( $sf->{i}, $sf->{o}, $sf->{d} );
    return $new_et->epoch_to( $sql, $col, $func );
}





1;
