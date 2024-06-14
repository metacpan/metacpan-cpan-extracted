package # hide from PAUSE
App::DBBrowser::Table::Extensions::ScalarFunctions;

use warnings;
use strict;
use 5.014;

use Term::Choose           qw();
use Term::Form::ReadLine   qw();

use App::DBBrowser::Auxil;
use App::DBBrowser::Table::Extensions;
use App::DBBrowser::Table::Extensions::ScalarFunctions::EpochToDate;
use App::DBBrowser::Table::Extensions::ScalarFunctions::SQL;
use App::DBBrowser::Table::Substatements;

my $abs                = 'ABS';
my $cast               = 'CAST';
my $ceil               = 'CEIL';
my $char_length        = 'CHAR_LENGTH';
my $coalesce           = 'COALESCE';
my $concat             = 'CONCAT';
my $date_add           = 'DATE_ADD';
my $date_subtract      = 'DATE_SUBTRACT';
my $date_format        = 'DATE_FORMAT';
my $day                = 'DAY';
my $dayofweek          = 'DAYOFWEEK';
my $dayofyear          = 'DAYOFYEAR';
my $epoch_to_date      = 'EPOCH_TO_DATE';
my $epoch_to_datetime  = 'EPOCH_TO_DATETIME';
my $epoch_to_timestamp = 'EPOCH_TO_TIMESTAMP';
my $exp                = 'EXP';
my $extract            = 'EXTRACT';
my $floor              = 'FLOOR';
my $format             = 'FORMAT';
my $hour               = 'HOUR';
my $instr              = 'INSTR';
my $left               = 'LEFT';
my $length             = 'LENGTH';
my $lengthb            = 'LENGTHB';
my $ln                 = 'LN';
my $locate             = 'LOCATE';
my $lower              = 'LOWER';
my $lpad               = 'LPAD';
my $ltrim              = 'LTRIM';
my $minute             = 'MINUTE';
my $mod                = 'MOD';
my $month              = 'MONTH';
my $now                = 'NOW';
my $octet_length       = 'OCTET_LENGTH';
my $position           = 'POSITION';
my $power              = 'POWER';
my $quarter            = 'QUARTER';
my $rand               = 'RAND';
my $replace            = 'REPLACE';
my $reverse            = 'REVERSE';
my $right              = 'RIGHT';
my $round              = 'ROUND';
my $rpad               = 'RPAD';
my $rtrim              = 'RTRIM';
my $second             = 'SECOND';
my $sign               = 'SIGN';
my $sqrt               = 'SQRT';
my $strftime           = 'STRFTIME';
my $str_to_date        = 'STR_TO_DATE';
my $substring          = 'SUBSTRING';
my $substr             = 'SUBSTR';
my $to_char            = 'TO_CHAR';
my $to_date            = 'TO_DATE';
my $to_number          = 'TO_NUMBER';
my $to_timestamp       = 'TO_TIMESTAMP';
my $to_timestamp_tz    = 'TO_TIMESTAMP_TZ';
my $to_epoch           = 'TO_EPOCH';
my $trim               = 'TRIM';
my $truncate           = 'TRUNCATE';
my $trunc              = 'TRUNC';
my $upper              = 'UPPER';
my $week               = 'WEEK';
my $year               = 'YEAR';


sub new {
    my ( $class, $info, $options, $d ) = @_;
    bless {
        i => $info,
        o => $options,
        d => $d
    }, $class;
}


sub __format_history {
    my ( $sf, $func ) = @_;
    my $driver = $sf->{i}{driver};
    if ( $driver eq 'SQLite' ) {
        return [ '%Y-%m-%d %H:%M:%f', '%Y-%m-%d %H:%M:%S' ] if $func eq $strftime;
    }
    elsif ( $driver =~ /^(?:mysql|MariaDB)\z/ ) {
        return [ '%Y-%m-%d %H:%i:%S.%f', '%a %d %b %Y %h:%i:%S %p' ] if $func eq $date_format;
        return [ '%Y-%m-%d %H:%i:%S.%f', '%a %d %b %Y %h:%i:%S %p' ] if $func eq $str_to_date;
        return [                                                   ] if $func eq $format;
    }
    elsif ( $driver eq 'Pg' ) {
        return [ 'YYYY-MM-DD HH24:MI:SS.FF6TZH:TZM', 'Dy DD Mon YYYY HH:MI:SS AM TZ OF' ] if $func eq $to_char; # TZ and OF only in to_char
        return [ 'YYYY-MM-DD'                                                           ] if $func eq $to_date;
        return [ 'YYYY-MM-DD HH24:MI:SS.FF6TZH:TZM', 'Dy DD Mon YYYY HH:MI:SS AM'       ] if $func eq $to_timestamp;
        return [                                                                        ] if $func eq $to_number;
    }
    elsif ( $driver eq 'DB2' ) {
        return [ 'YYYY-MM-DD HH24:MI:SS.FF6', 'Dy DD Mon YYYY HH:MI:SS AM' ] if $func eq $to_char;
        return [ 'YYYY-MM-DD HH24:MI:SS.FF6', 'Dy DD Mon YYYY HH:MI:SS AM' ] if $func eq $to_date;
        return [                                                           ] if $func eq $to_number;
    }
    elsif ( $driver eq 'Informix' ) {
        return [ '%Y-%m-%d %H:%M:%S.%F5', '%a %d %b %Y %I:%M:%S %p' ] if $func eq $to_char;
        return [ '%Y-%m-%d %H:%M:%S.%F5', '%a %d %b %Y %I:%M:%S %p' ] if $func eq $to_date;
        return [                                                    ] if $func eq $to_number;
    }
    elsif ( $driver eq 'Oracle' ) {
        return [ 'YYYY-MM-DD HH24:MI:SS.FF9TZH:TZM', 'Dy DD Mon YYYY HH:MI:SSXFF AM TZR TZD' ] if $func eq $to_char;
        return [ 'YYYY-MM-DD HH24:MI:SS'           , 'Dy DD Mon YYYY HH:MI:SS AM'            ] if $func eq $to_date; # not in the DATE format: FF, TZD, TZH, TZM, and TZR.  Max length 22
        return [ 'YYYY-MM-DD HH24:MI:SS.FF'        , 'Dy DD Mon YYYY HH:MI:SS AM'            ] if $func eq $to_timestamp;
        return [ 'YYYY-MM-DD HH24:MI:SS.FFTZH:TZM' , 'Dy DD Mon YYYY HH:MI:SS AM TZD'        ] if $func eq $to_timestamp_tz;
        return [                                                                             ] if $func eq $to_number;
    }
    else {
        return [];
    }
}


sub __available_functions {
    my ( $sf, $type ) = @_;
    my $functions = {
       string => {
            $char_length        => [  000000 , 'mysql', 'MariaDB', 'Pg', 'Firebird', 'DB2', 'Informix',  000000  ],
            $instr              => [ 'SQLite',  00000 ,  0000000 ,  00 ,  00000000 , 'DB2', 'Informix', 'Oracle' ],
            $concat             => [ 'SQLite', 'mysql', 'MariaDB', 'Pg', 'Firebird', 'DB2', 'Informix', 'Oracle' ],
            $left               => [ 'SQLite', 'mysql', 'MariaDB', 'Pg', 'Firebird', 'DB2', 'Informix',  000000  ],
            $length             => [ 'SQLite',  00000 ,  0000000 ,  00 ,  00000000 ,  000 ,  00000000 , 'Oracle' ], # Pg
            $lengthb            => [  000000 ,  00000 ,  0000000 ,  00 ,  00000000 ,  000 ,  00000000 , 'Oracle' ],
            $locate             => [  000000 , 'mysql', 'MariaDB',  00 ,  00000000 ,  000 ,  00000000 ,  000000  ], # DB2
            $lower              => [ 'SQLite', 'mysql', 'MariaDB', 'Pg', 'Firebird', 'DB2', 'Informix', 'Oracle' ],
            $lpad               => [ 'SQLite', 'mysql', 'MariaDB', 'Pg', 'Firebird', 'DB2', 'Informix', 'Oracle' ],
            $ltrim              => [ 'SQLite', 'mysql', 'MariaDB', 'Pg',  00000000 , 'DB2', 'Informix', 'Oracle' ],
            $octet_length       => [ 'SQLite', 'mysql', 'MariaDB', 'Pg', 'Firebird', 'DB2', 'Informix',  000000  ],
            $position           => [  000000 , 'mysql', 'MariaDB', 'Pg', 'Firebird', 'DB2',  00000000 ,  000000  ],
            $replace            => [ 'SQLite', 'mysql', 'MariaDB', 'Pg', 'Firebird', 'DB2', 'Informix', 'Oracle' ],
            $reverse            => [  000000 , 'mysql', 'MariaDB', 'Pg', 'Firebird',  000 , 'Informix', 'Oracle' ],
            $right              => [ 'SQLite', 'mysql', 'MariaDB', 'Pg', 'Firebird', 'DB2', 'Informix',  000000  ],
            $rpad               => [ 'SQLite', 'mysql', 'MariaDB', 'Pg', 'Firebird', 'DB2', 'Informix', 'Oracle' ],
            $rtrim              => [ 'SQLite', 'mysql', 'MariaDB', 'Pg',  00000000 , 'DB2', 'Informix', 'Oracle' ],
            $substring          => [  000000 ,  00000 ,  0000000 ,  00 , 'Firebird',  000 ,  00000000 ,  000000  ], # mysql, MariaDB, Pg, DB2, Informix
            $substr             => [ 'SQLite', 'mysql', 'MariaDB', 'Pg',  00000000 , 'DB2', 'Informix', 'Oracle' ],
            $trim               => [ 'SQLite', 'mysql', 'MariaDB', 'Pg', 'Firebird', 'DB2', 'Informix', 'Oracle' ],
            $upper              => [ 'SQLite', 'mysql', 'MariaDB', 'Pg', 'Firebird', 'DB2', 'Informix', 'Oracle' ],
        },
        numeric => {
            $abs                => [ 'SQLite', 'mysql', 'MariaDB', 'Pg', 'Firebird', 'DB2', 'Informix', 'Oracle' ],
            $ceil               => [ 'SQLite', 'mysql', 'MariaDB', 'Pg', 'Firebird', 'DB2', 'Informix', 'Oracle' ],
            $exp                => [ 'SQLite', 'mysql', 'MariaDB', 'Pg', 'Firebird', 'DB2', 'Informix', 'Oracle' ],
            $floor              => [ 'SQLite', 'mysql', 'MariaDB', 'Pg', 'Firebird', 'DB2', 'Informix', 'Oracle' ],
            $ln                 => [ 'SQLite', 'mysql', 'MariaDB', 'Pg', 'Firebird', 'DB2', 'Informix', 'Oracle' ],
            $mod                => [ 'SQLite', 'mysql', 'MariaDB', 'Pg', 'Firebird', 'DB2', 'Informix', 'Oracle' ],
            $power              => [ 'SQLite', 'mysql', 'MariaDB', 'Pg', 'Firebird', 'DB2', 'Informix', 'Oracle' ],
            $rand               => [ 'SQLite', 'mysql', 'MariaDB', 'Pg', 'Firebird', 'DB2',  00000000 , 'Oracle' ],
            $round              => [ 'SQLite', 'mysql', 'MariaDB', 'Pg', 'Firebird', 'DB2', 'Informix', 'Oracle' ],
            $sign               => [ 'SQLite', 'mysql', 'MariaDB', 'Pg', 'Firebird', 'DB2', 'Informix', 'Oracle' ],
            $sqrt               => [ 'SQLite', 'mysql', 'MariaDB', 'Pg', 'Firebird', 'DB2', 'Informix', 'Oracle' ],
            $truncate           => [  000000 , 'mysql', 'MariaDB',  00 ,  00000000 , 'DB2',  00000000 ,  000000  ],
            $trunc              => [ 'SQLite',  00000 ,  0000000 , 'Pg', 'Firebird',  000 , 'Informix', 'Oracle' ],
        },
        date => {
            $date_add           => [ 'SQLite', 'mysql', 'MariaDB', 'Pg', 'Firebird', 'DB2', 'Informix', 'Oracle' ],
            $date_subtract      => [ 'SQLite', 'mysql', 'MariaDB', 'Pg', 'Firebird', 'DB2', 'Informix', 'Oracle' ],
            $extract            => [ 'SQLite', 'mysql', 'MariaDB', 'Pg', 'Firebird', 'DB2', 'Informix', 'Oracle' ],
            $now                => [ 'SQLite', 'mysql', 'MariaDB', 'Pg', 'Firebird', 'DB2', 'Informix', 'Oracle' ],
            $year               => [ 'SQLite', 'mysql', 'MariaDB', 'Pg', 'Firebird', 'DB2', 'Informix', 'Oracle' ],
            $quarter            => [ 'SQLite', 'mysql', 'MariaDB', 'Pg', 'Firebird', 'DB2', 'Informix', 'Oracle' ],
            $month              => [ 'SQLite', 'mysql', 'MariaDB', 'Pg', 'Firebird', 'DB2', 'Informix', 'Oracle' ],
            $week               => [ 'SQLite', 'mysql', 'MariaDB', 'Pg', 'Firebird', 'DB2',  00000000 , 'Oracle' ],
            $day                => [ 'SQLite', 'mysql', 'MariaDB', 'Pg', 'Firebird', 'DB2', 'Informix', 'Oracle' ],
            $hour               => [ 'SQLite', 'mysql', 'MariaDB', 'Pg', 'Firebird', 'DB2', 'Informix', 'Oracle' ],
            $minute             => [ 'SQLite', 'mysql', 'MariaDB', 'Pg', 'Firebird', 'DB2', 'Informix', 'Oracle' ],
            $second             => [ 'SQLite', 'mysql', 'MariaDB', 'Pg', 'Firebird', 'DB2', 'Informix', 'Oracle' ],
            $dayofweek          => [ 'SQLite', 'mysql', 'MariaDB', 'Pg', 'Firebird', 'DB2', 'Informix', 'Oracle' ],
            $dayofyear          => [ 'SQLite', 'mysql', 'MariaDB', 'Pg', 'Firebird', 'DB2',  00000000 , 'Oracle' ],

        },
        to => {
            $epoch_to_date      => [ 'SQLite', 'mysql', 'MariaDB', 'Pg', 'Firebird', 'DB2', 'Informix', 'Oracle' ],
            $epoch_to_datetime  => [ 'SQLite', 'mysql', 'MariaDB', 'Pg', 'Firebird', 'DB2', 'Informix', 'Oracle' ],
            $epoch_to_timestamp => [  000000 ,  00000 ,  0000000 , 'Pg', 'Firebird',  000 ,  00000000 , 'Oracle' ],
            $to_char            => [  000000 ,  00000 ,  0000000 , 'Pg',  00000000 , 'DB2', 'Informix', 'Oracle' ], # MariaDB
            $to_date            => [  000000 ,  00000 ,  0000000 , 'Pg',  00000000 , 'DB2', 'Informix', 'Oracle' ], # MariaDB
            $to_timestamp       => [  000000 ,  00000 ,  0000000 , 'Pg',  00000000 ,  000 ,  00000000 , 'Oracle' ], # DB2
            $to_timestamp_tz    => [  000000 ,  00000 ,  0000000 ,  00 ,  00000000 ,  000 ,  00000000 , 'Oracle' ],
            $to_number          => [  000000 ,  00000 , 'MariaDB', 'Pg',  00000000 , 'DB2', 'Informix', 'Oracle' ],
            $to_epoch           => [ 'SQLite', 'mysql', 'MariaDB', 'Pg', 'Firebird', 'DB2',  00000000 , 'Oracle' ],
            $strftime           => [ 'SQLite',  00000 ,  0000000 ,  00 ,  00000000 ,  000 ,  00000000 ,  000000  ],
            $date_format        => [  000000 , 'mysql', 'MariaDB',  00 ,  00000000 ,  000 ,  00000000 ,  000000  ],
            $format             => [  000000 , 'mysql', 'MariaDB',  00 ,  00000000 ,  000 ,  00000000 ,  000000  ],
            $str_to_date        => [  000000 , 'mysql', 'MariaDB',  00 ,  00000000 ,  000 ,  00000000 ,  000000  ],
        },
        other => {
            $cast               => [ 'SQLite', 'mysql', 'MariaDB', 'Pg', 'Firebird', 'DB2', 'Informix', 'Oracle' ],
            $coalesce           => [ 'SQLite', 'mysql', 'MariaDB', 'Pg', 'Firebird', 'DB2', 'Informix', 'Oracle' ],
        },
    };
    my $driver = $sf->{i}{driver};
    my $index = {
        SQLite => 0, mysql => 1, MariaDB => 2, Pg => 3, Firebird => 4, DB2 => 5, Informix => 6, Oracle => 7
    };
    my $avail_functions = [];
    for my $func ( sort keys %{$functions->{$type}} ) {
        if ( ! exists $index->{$driver} ) {
            # return all functions
            push @$avail_functions, $func;
        }
        elsif ( $functions->{$type}{$func}[$index->{$driver}] ) {
            push @$avail_functions, $func;
        }
    }
    return $avail_functions;
}


sub col_function {
    my ( $sf, $sql, $clause, $qt_cols, $r_data ) = @_;
    if ( ! defined $r_data->{nested_func} ) {
        # reset recursion data other than nested_func
        # at the first call of col_function
        $r_data = { nested_func => [] };
    }
    my $parent;
    if ( ref $r_data->{nested_func}[0] eq 'ARRAY' ) {
        # because called from a multi-col function
        $parent = shift @{$r_data->{nested_func}};
        $parent = $parent->[0];
        # $r_data->{nested_func} is now empty
    }
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $driver = $sf->{i}{driver};
    my $rx_func_only        = join( '|', $now, $rand );
    my $rx_func_multi_col   = join( '|', $concat, $coalesce );
    my $rx_func_to_format   = join( '|', $to_char, $to_date, $to_timestamp, $to_timestamp_tz, $to_number, $strftime, $date_format, $format, $str_to_date );
    my $hidden = 'Scalar functions:';
    my $info = $ax->get_sql_info( $sql );
    my $old_idx_cat = 1;

    CATEGORY: while( 1 ) {
        my $tmp_info = $info;
        if ( length $parent ) {
            # $parent only available at the first recursion after parent
            $tmp_info .= "\n" . $parent;
        }
        if ( @{$r_data->{nested_func}} ) {
            $tmp_info .= "\n" . $sf->__nested_func_info( $r_data->{nested_func}, '?' );
        }
        my @pre = ( $hidden, undef );
        my $menu = [ @pre, '- String', '- Numeric', '- Date', '- To', '- Other' ];
        # Choose
        my $idx_cat = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_v}}, info => $tmp_info, prompt => '', index => 1, default => $old_idx_cat, undef => '<=' }
        );
        if ( ! defined $idx_cat || ! defined $menu->[$idx_cat] ) {
            return;
        }
        if ( $sf->{o}{G}{menu_memory} ) {
            if ( $old_idx_cat == $idx_cat && ! $ENV{TC_RESET_AUTO_UP} ) {
                $old_idx_cat = 1;
                next CATEGORY;
            }
            $old_idx_cat = $idx_cat;
        }
        my $choice = $menu->[$idx_cat];
        if ( $choice eq $hidden ) {
            $ext->enable_extended_arguments( $tmp_info );
            next CATEGORY;
        }
        my $old_idx_func = 0;

        FUNCTION: while( 1 ) {
            my $type = lc( $choice =~ s/^-\s//r );
            @pre = ( undef );
            my $avail_functions = $sf->__available_functions( $type );
            $menu = [ @pre, map { '- ' . $_ } @$avail_functions ];
            # Choose
            my $idx_func = $tc->choose(
                $menu,
                { %{$sf->{i}{lyt_v}}, info => $tmp_info, prompt => '', index => 1, default => $old_idx_func, undef => '<=' }
            );
            if ( ! defined $idx_func || ! defined $menu->[$idx_func] ) {
                next CATEGORY;
            }
            if ( $sf->{o}{G}{menu_memory} ) {
                if ( $old_idx_func == $idx_func && ! $ENV{TC_RESET_AUTO_UP} ) {
                    $old_idx_func = 0;
                    next FUNCTION;
                }
                $old_idx_func = $idx_func;
            }
            my $func = $menu->[$idx_func] =~ s/^-\s//r;
            push @{$r_data->{nested_func}}, $func;
            my $function_stmt;
            if ( $func =~ /^(?:$rx_func_only)\z/ ) {
                $function_stmt =  $sf->__func_with_no_col( $func );
            }
            elsif ( $func =~ /^(?:$rx_func_multi_col)\z/ ) {
                my $chosen_cols = $sf->__choose_columns( $sql, $clause, $info, $qt_cols, $r_data );
                if ( ! defined $chosen_cols ) {
                    if ( @{$r_data->{nested_func}} == 1 ) {
                        $r_data->{nested_func} = [];
                        next FUNCTION;
                    }
                    pop @{$r_data->{nested_func}};
                    return;
                }
                if ( $func eq $concat ) {
                    $function_stmt = $sf->__func_Concat( $sql, $clause, $info, $func, $chosen_cols );
                }
                elsif ( $func eq $coalesce ) {
                    $function_stmt = $sf->__func_Coalesce( $sql, $func, $chosen_cols );
                }
            }
            else {
                my $chosen_col = $sf->__choose_a_column( $sql, $clause, $info, $qt_cols, $r_data );
                if ( ! defined $chosen_col ) {
                    if ( @{$r_data->{nested_func}} == 1 ) {
                        $r_data->{nested_func} = [];
                        next FUNCTION;
                    }
                    pop @{$r_data->{nested_func}};
                    return;
                }
                if ( $func =~ /^EPOCH_TO_/ ) {
                    my $dt = App::DBBrowser::Table::Extensions::ScalarFunctions::EpochToDate->new( $sf->{i}, $sf->{o}, $sf->{d} );
                    $function_stmt = $dt->func_Date_Time( $sql, $chosen_col, $func, $info );
                }
                else {
                    my $args_data = [];
                    if ( $func eq $cast ) {
                        $args_data = [
                            { prompt => 'Data type: ', history => [ sort qw(VARCHAR CHAR TEXT INT DECIMAL DATE DATETIME TIME TIMESTAMP) ], unquote => 1 },
                        ];
                    }
                    elsif ( $func =~ /^(?:$rx_func_to_format)\z/ ) {
                        $args_data = [
                            { prompt => 'Format: ', history => $sf->__format_history( $func ) },
                        ];
                        if ( $func eq $strftime ) {
                            push @$args_data, { prompt => 'Modifiers: ', history => [], unquote => 1 };
                        }
                        if ( $func eq $format ) {
                            push @$args_data, { prompt => 'Locale: ', history => [] };
                        }
                    }
                    elsif ( $func eq $extract ) {
                        $args_data = [
                            { prompt => 'Field: ', history => [ qw(YEAR QUARTER MONTH WEEK DAY HOUR MINUTE SECOND DAYOFWEEK DAYOFYEAR) ], unquote => 1 },
                        ];
                    }
                    elsif ( $func =~ /^(?:$round|$trunc|$truncate)\z/ ) {
                        $args_data = [
                            { prompt => 'Decimal places: ', is_numeric => 1 },
                        ];
                    }
                    elsif ( $func =~ /^(?:$position|$instr|$locate)\z/ ) {
                        $args_data = [
                            { prompt => 'Substring: ' },
                        ];
                        if ( $func eq $instr ) {
                            push @$args_data, { prompt => 'Start: ', is_numeric => 1 }, { prompt => 'Count: ', is_numeric => 1 };
                        }
                        if ( $func eq $locate ) {
                            push @$args_data, { prompt => 'Start: ', is_numeric => 1 };
                        }
                    }
                    elsif ( $func =~ /^(?:$left|$right)\z/ ) {
                        $args_data = [
                            { prompt => 'Length: ', is_numeric => 1 },
                        ];
                    }
                    elsif ( $func eq $mod ) {
                        $args_data = [
                            { prompt => 'Divider: ', is_numeric => 1 },
                        ];
                    }
                    elsif ( $func eq $power ) {
                        $args_data = [
                            { prompt => 'Exponent: ', is_numeric => 1 },
                        ];
                    }
                    elsif ( $func eq $replace ) {
                        $args_data = [
                            { prompt => 'From string: ' },
                            { prompt => 'To string: ' },
                        ];
                    }
                    elsif ( $func =~ /^(?:$substr|$substring)\z/ ) {
                        $args_data = [
                            { prompt => 'StartPos: ', is_numeric => 1 },
                            { prompt => 'Length: ', is_numeric => 1 },
                        ];
                    }
                    elsif ( $func =~ /^(?:$lpad|$rpad)\z/ ) {
                        $args_data = [
                            { prompt => 'Length: ', is_numeric => 1 },
                            { prompt => 'Fill: ' },
                        ];
                    }
                    elsif ( $func eq $trim ) {
                        $args_data = [
                            { prompt => 'Where: ', history => [ qw(BOTH LEADING TRAILING) ], unquote => 1 },
                            { prompt => 'What: ' },
                        ];
                    }
                    elsif ( $func =~ /^(?:$date_add|$date_subtract)\z/ ) {
                        $args_data = [
                            { prompt => 'Amount: ', is_numeric => 1 },
                            { prompt => 'Unit: ', history => [ qw(YEAR MONTH DAY HOUR MINUTE SECOND) ], unquote => 1 },
                        ];
                    }
                    else {
                        $args_data = [];
                    }
                    if ( $driver eq 'SQLite' ) {
                        $args_data = [ { prompt => 'What: ' } ]      if $func eq $trim;
                        $args_data = [ { prompt => 'Substring: ' } ] if $func eq $instr;
                    }
                    elsif ( $driver eq 'Firebird' ) {
                        push @$args_data, { prompt => 'Start: ', is_numeric => 1 } if $func eq $position;
                    }
                    elsif ( $driver eq 'DB2' ) {
                        if ( $func eq $to_char ) {
                            push @$args_data, { prompt => 'Locale: ' };
                        }
                        elsif ( $func eq $to_date ) {
                            push @$args_data, { prompt => 'Decimals: ', is_numeric => 1 }, { prompt => 'Locale: ' };
                        }
                        # string units: $position, $instr, $locate, $left, $right, $length, $substring, $upper, $lower
                        # $round datetime: locale
                    }
                    elsif ( $driver eq 'Informix' ) {
                        if ( $func eq $extract ) {
                            $args_data->{history} = [ grep { ! /^(?:WEEK|DAYOFYEAR)\z/ } @{$args_data->{history}} ];
                        }
                    }
                    elsif ( $driver eq 'Oracle' ) {
                        if ( $func eq $to_epoch ) {
                            push @$args_data, { prompt => 'Column type: ', history => [ qw(DATE TIMESTAMP TIMESTAMP_TZ) ], unquote => 1 };
                        }
                        elsif ( $func =~ /^(?:$rx_func_to_format)\z/ ) {
                            push @$args_data, { prompt => 'nls_parameter: ' };
                        }
                    }
                    $function_stmt = $sf->__func_with_one_col( $sql, $clause, $info, $func, $chosen_col, $args_data );
                }
            }
            if ( ! $function_stmt ) {
                return;
            }
            return $function_stmt;
        }
    }
}


sub __func_with_no_col {
    my ( $sf, $func ) = @_;
    my $fsql = App::DBBrowser::Table::Extensions::ScalarFunctions::SQL->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $function_stmt = $fsql->function_with_no_col( $func );
    return $function_stmt;
}


sub __func_with_one_col {
    my ( $sf, $sql, $clause, $info, $func, $chosen_col, $args_data ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $fsql = App::DBBrowser::Table::Extensions::ScalarFunctions::SQL->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tail = ',?)';
    $info .= "\n" . $func . '(' . $chosen_col . $tail;
    my $args = [];

    for my $arg_data ( @$args_data ) {
        # Readline
        my $arg = $ext->argument(
            $sql, $clause,
            { info => $info, history => $arg_data->{history}, prompt => $arg_data->{prompt},
              is_numeric => $arg_data->{is_numeric} }
        );
        #last if ! defined $arg; ##
        if ( ! length $arg || $arg eq "''" ) {
            if ( $func eq $replace && @$args == 1 ) {
                # replacement_string: an empty string is a valid argument
                $arg = "''";
            }
            elsif ( $func =~ /^(?:$position|$instr|$locate)\z/ && @$args == 0 ) {
                # substring: an empty string is a valid argument
                $arg = "''";
            }
            elsif ( $func eq $trim ) {
                # an unset argument does not close the function
                next;
            }
            else {
                my $function_stmt = $fsql->function_with_one_col( $func, $chosen_col, $args );
                return $function_stmt;
            }
        }
        if ( $arg_data->{unquote} ) {
            $arg = $ax->unquote_constant( $arg );
        }
        push @$args, $arg;
        $info =~ s/\Q$tail\E\z/,${arg}${tail}/;
    }
    my $function_stmt = $fsql->function_with_one_col( $func, $chosen_col, $args );
    return $function_stmt;
}


sub __func_Concat {
    my ( $sf, $sql, $clause, $info, $func, $chosen_cols ) = @_;
    my $fsql = App::DBBrowser::Table::Extensions::ScalarFunctions::SQL->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
    $info .= "\n" . 'Concat(' . join( ',', @$chosen_cols ) . ')';
    my $history = [ '-', ' ', '_', ',', '/', '=', '+' ];
    # Readline
    my $sep = $ext->argument( $sql, $clause, { info => $info, history => $history, prompt => 'Separator: ' } );
    if ( ! defined $sep ) {
        return;
    }
    my $function_stmt = $fsql->concatenate( $chosen_cols, $sep );
    return $function_stmt;
}


sub __func_Coalesce {
    my ( $sf, $sql, $func, $chosen_cols ) = @_;
    my $fsql = App::DBBrowser::Table::Extensions::ScalarFunctions::SQL->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $function_stmt = $fsql->coalesce( $chosen_cols );
    return $function_stmt;
}


sub __choose_columns {
    my ( $sf, $sql, $clause, $info, $qt_cols, $r_data ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $tr = Term::Form::ReadLine->new( $sf->{i}{tr_default} );
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $const = '[value]';
    my @pre = ( undef, $sf->{i}{ok}, $sf->{i}{menu_addition}, $const );
    my $menu = [ @pre, @$qt_cols ];
    my $subset = [];
    my @bu;

    COLUMNS: while ( 1 ) {
        my $fill_string = join( ',', @$subset, '?' );
        $fill_string =~ s/,\?/ ?/;
        my $tmp_info = $info . "\n" . $sf->__nested_func_info( $r_data->{nested_func}, $fill_string );
        # Choose
        my @idx = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_h}}, info => $tmp_info, prompt => 'Columns:', meta_items => [ 0 .. $#pre - 1 ], ##
              no_spacebar => [ $#pre ], include_highlighted => 2, index => 1 }
        );
        if ( ! $idx[0] ) {
            if ( @bu ) {
                $subset = pop @bu;
                next COLUMNS;
            }
            return;
        }
        if ( $menu->[$idx[0]] eq $sf->{i}{ok} ) {
            shift @idx;
            push @$subset, @{$menu}[@idx];
            if ( ! @$subset ) {
                return;
            }
            return $subset;
        }
        elsif ( $menu->[$idx[0]] eq $sf->{i}{menu_addition} ) {
            # recursion
            my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
            my $bu_nested_func = $ax->clone_data( $r_data );
            # reset nested_func and add an array-ref so the child function knows that the parent is a multi-col function.
            # Children of a  multi-col function start with an empty nested_func. Only whenn they return to
            # the parent multi-col function their results are integrated in the parent nested_func.
            $r_data->{nested_func} = [ [ $sf->__nested_func_info( $r_data->{nested_func}, $fill_string ) ] ];
            my $complex_col = $ext->column(
                $sql, $clause, $r_data,
                { info => $tmp_info }
            );
            $r_data = $bu_nested_func;
            if ( ! defined $complex_col ) {
                next COLUMNS;
            }
            push @bu, [ @$subset ];
            push @$subset, $complex_col;
        }
        elsif ( $menu->[$idx[0]] eq $const ) {
            my $value = $tr->readline(
                'Value: ',
                { info => $tmp_info }
            );
            if ( ! defined $value ) {
                next COLUMNS;
            }
            push @bu, [ @$subset ];
            push @$subset, $ax->quote_constant( $value );
        }
        else {
            push @bu, [ @$subset ];
            if ( $sql->{aggregate_mode} && $clause =~ /^(?:having|order_by)\z/ ) {
                my $sb = App::DBBrowser::Table::Substatements->new( $sf->{i}, $sf->{o}, $sf->{d} );
                push @$subset, grep { length } map { $sb->get_prepared_aggr_func( $sql, $clause, $_ ) } @{$menu}[@idx];
            }
            else {
                push @$subset, @{$menu}[@idx];
            }
        }
    }
}


sub __choose_a_column {
    my ( $sf, $sql, $clause, $info, $qt_cols, $r_data ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    $info .= "\n" . $sf->__nested_func_info( $r_data->{nested_func}, '?' );
    my @pre = ( undef, $sf->{i}{menu_addition} );

    while ( 1 ) {
        # Choose
        my $choice = $tc->choose(
            [ @pre, @$qt_cols ],
            { %{$sf->{i}{lyt_h}}, info => $info, prompt => 'Column:' }
        );
        if ( ! defined $choice ) {
            return;
        }
        elsif ( $choice eq $sf->{i}{menu_addition} ) {
            # recursion
            my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
            my $complex_col = $ext->column(
                $sql, $clause, $r_data,
                { info => $info }
            );
            if ( ! defined $complex_col ) {
                next;
            }
            return $complex_col;
        }
        if ( $sql->{aggregate_mode} && $clause =~ /^(?:having|order_by)\z/ ) {
            my $sb = App::DBBrowser::Table::Substatements->new( $sf->{i}, $sf->{o}, $sf->{d} );
            return $sb->get_prepared_aggr_func( $sql, $clause, $choice );
        }
        return $choice;
    }
}


sub __nested_func_info {
    my ( $sf, $nested_func, $fill_string ) = @_;
    return join( '', map { $_ . '(' } @$nested_func ) . ( $fill_string // '' ) . ( ')' x @$nested_func );
}




1;


__END__
