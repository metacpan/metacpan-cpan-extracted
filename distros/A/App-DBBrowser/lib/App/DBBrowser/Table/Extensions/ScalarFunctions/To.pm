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
    my $driver = $sf->{i}{driver};
    my $add_args_data;
    if ( $driver eq 'DB2' ) {
        $add_args_data = [ { prompt => 'Locale: ' } ];
    }
    return $sf->__format_function( $sql, $clause, $func, $cols, $r_data, $add_args_data );
}


sub function_to_date {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    my $driver = $sf->{i}{driver};
    my $add_args_data;
    if ( $driver eq 'DB2' ) {
        $add_args_data = [
            { prompt => 'Decimals: ', is_numeric => 1 },
            { prompt => 'Locale: ' }
        ];
    }
    return $sf->__format_function( $sql, $clause, $func, $cols, $r_data );
}


sub function_strftime {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    my $ga = App::DBBrowser::Table::Extensions::ScalarFunctions::GetArguments->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $col = $ga->choose_a_column( $sql, $clause, $cols, $r_data );
    if ( ! defined $col ) {
        return;
    }
    my $args_data = [
        { prompt => 'Format: ', history => $sf->__format_history( $func ) },
    ];
    my ( $format ) = $ga->get_arguments( $sql, $clause, $func, $args_data, $r_data );
    if ( ! defined $format ) {
        return;
    }
    my $modifiers = $ga->sqlite_modifiers( $sql, $r_data );
    return "STRFTIME($col)"             if ! length $modifiers;
    return "STRFTIME($col,$modifiers)";
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
    my $add_args_data = [ { prompt => 'Locale: ', history => [] } ];
    return $sf->__format_function( $sql, $clause, $func, $cols, $r_data, $add_args_data );
}


sub function_str_to_date {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    return $sf->__format_function( $sql, $clause, $func, $cols, $r_data );
}


sub __format_function {
    my ( $sf, $sql, $clause, $func, $cols, $r_data, $add_args_data ) = @_;
    my $driver = $sf->{i}{driver};
    my $ga = App::DBBrowser::Table::Extensions::ScalarFunctions::GetArguments->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $col = $ga->choose_a_column( $sql, $clause, $cols, $r_data );
    if ( ! defined $col ) {
        return;
    }
    my $args_data = [
        { prompt => 'Format: ', history => $sf->__format_history( $func ) },
    ];
    if ( defined $add_args_data ) {
        push @$args_data, @$add_args_data;
    }
    if ( $driver eq 'Oracle' ) {
        push @$args_data, { prompt => 'nls_parameter: ' };
    }
    my ( $format, @args ) = $ga->get_arguments( $sql, $clause, $func, $args_data, $r_data );
    my $additional_args = join ',', grep { length } @args;
    return                                          if ! defined $format;
    return "$func($col,$format)"                    if ! length $additional_args;
    return "$func($col,$format,$additional_args)";
}


sub __format_history {
    my ( $sf, $func ) = @_;
    my $driver = $sf->{i}{driver};
    if ( $driver eq 'SQLite' ) {
        return [ '%Y-%m-%d %H:%M:%f', '%Y-%m-%d %H:%M:%S' ] if $func eq 'STRFTIME';
    }
    elsif ( $driver =~ /^(?:mysql|MariaDB)\z/ ) {
        return [ '%Y-%m-%d %H:%i:%S.%f', '%a %d %b %Y %h:%i:%S %p' ] if $func eq 'DATE_FORMAT';
        return [ '%Y-%m-%d %H:%i:%S.%f', '%a %d %b %Y %h:%i:%S %p' ] if $func eq 'STR_TO_DATE';
        return [                                                   ] if $func eq 'FORMAT';
    }
    elsif ( $driver eq 'Pg' ) {
        return [ 'YYYY-MM-DD HH24:MI:SS.FF6TZH:TZM', 'Dy DD Mon YYYY HH:MI:SS AM TZ OF' ] if $func eq 'TO_CHAR'; # TZ and OF only in to_char
        return [ 'YYYY-MM-DD'                                                           ] if $func eq 'TO_DATE';
        return [ 'YYYY-MM-DD HH24:MI:SS.FF6TZH:TZM', 'Dy DD Mon YYYY HH:MI:SS AM'       ] if $func eq 'TO_TIMESTAMP';
        return [                                                                        ] if $func eq 'TO_NUMBER';
    }
    elsif ( $driver eq 'DB2' ) {
        return [ 'YYYY-MM-DD HH24:MI:SS.FF6', 'Dy DD Mon YYYY HH:MI:SS AM' ] if $func eq 'TO_CHAR';
        return [ 'YYYY-MM-DD HH24:MI:SS.FF6', 'Dy DD Mon YYYY HH:MI:SS AM' ] if $func eq 'TO_DATE';
        return [                                                           ] if $func eq 'TO_NUMBER';
    }
    elsif ( $driver eq 'Informix' ) {
        return [ '%Y-%m-%d %H:%M:%S.%F5', '%a %d %b %Y %I:%M:%S %p' ] if $func eq 'TO_CHAR';
        return [ '%Y-%m-%d %H:%M:%S.%F5', '%a %d %b %Y %I:%M:%S %p' ] if $func eq 'TO_DATE';
        return [                                                    ] if $func eq 'TO_NUMBER';
    }
    elsif ( $driver eq 'Oracle' ) {
        return [ 'YYYY-MM-DD HH24:MI:SS.FF9TZH:TZM', 'Dy DD Mon YYYY HH:MI:SSXFF AM TZR TZD' ] if $func eq 'TO_CHAR';
        return [ 'YYYY-MM-DD HH24:MI:SS'           , 'Dy DD Mon YYYY HH:MI:SS AM'            ] if $func eq 'TO_DATE'; # not in the DATE format: FF, TZD, TZH, TZM, and TZR.  Max length 22
        return [ 'YYYY-MM-DD HH24:MI:SS.FF'        , 'Dy DD Mon YYYY HH:MI:SS AM'            ] if $func eq 'TO_TIMESTAMP';
        return [ 'YYYY-MM-DD HH24:MI:SS.FFTZH:TZM' , 'Dy DD Mon YYYY HH:MI:SS AM TZD'        ] if $func eq 'TO_TIMESTAMP_TZ';
        return [                                                                             ] if $func eq 'TO_NUMBER';
    }
    else {
        return [];
    }
}


sub function_to_epoch {
    my ( $sf, $sql, $clause, $func, $cols, $r_data ) = @_;
    #my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $driver = $sf->{i}{driver};
    my $ga = App::DBBrowser::Table::Extensions::ScalarFunctions::GetArguments->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $col = $ga->choose_a_column( $sql, $clause, $cols, $r_data );
    if ( ! defined $col ) {
        return;
    }
    if ( $driver eq 'SQLite' ) {
        return "UNIXEPOCH($col,'utc','subsec')"; # subsec: sqlite 3.42.0
    }
    elsif ( $driver =~ /^(?:mysql|MariaDB)\z/ ) {
        return "UNIX_TIMESTAMP($col)";
    }
    elsif ( $driver eq 'Pg' ) {
        return "EXTRACT(EPOCH FROM ${col}::timestamp with time zone)";
    }
    elsif ( $driver eq 'Firebird' ) {
        #my $firebird_major_version = $ax->major_server_version();
        my $firebird_major_version = 3; ##
        return "DATEDIFF(SECOND,TIMESTAMP '1970-01-01 00:00:00 UTC',$col)" if $firebird_major_version >= 4;
        return "DATEDIFF(SECOND,TIMESTAMP '1970-01-01 00:00:00',$col)"; # no timezone
        #return "DATEDIFF(MILLISECOND,TIMESTAMP '1970-01-01 00:00:00',$col) * 0.001";   # * 0.001 doesn't work in version 4 ##
    }
    elsif ( $driver eq 'DB2' ) {
        return "EXTRACT(EPOCH FROM $col)"; # no timezone
    }
    elsif ( $driver eq 'Oracle' ) {
        my $args_data = [
            { prompt => 'Column type: ', history => [ qw(DATE TIMESTAMP TIMESTAMP_TZ) ], history_only => 1 }
        ];
        my ( $column_type ) = $ga->get_arguments( $sql, $clause, $func, $args_data, $r_data );
        $column_type = uc $column_type;
        return "TRUNC((CAST($col AT TIME ZONE 'UTC' AS DATE) - DATE '1970-01-01') * 86400)"                                             if $column_type eq 'TIMESTAMP_TZ';
        return "TRUNC((CAST(FROM_TZ($col,SESSIONTIMEZONE) AT TIME ZONE 'UTC' AS DATE) - DATE '1970-01-01') * 86400)"                    if $column_type eq 'TIMESTAMP';
        return "TRUNC((CAST(FROM_TZ(CAST($col AS TIMESTAMP),SESSIONTIMEZONE) AT TIME ZONE 'UTC' AS DATE) - DATE '1970-01-01') * 86400)" if $column_type eq 'DATE';
    }
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
