package # hide from PAUSE
App::DBBrowser::Table::Extensions::ScalarFunctions;

use warnings;
use strict;
use 5.016;

use Term::Choose qw();

use App::DBBrowser::Auxil;
use App::DBBrowser::Table::Extensions;
use App::DBBrowser::Table::Extensions::ScalarFunctions::Date;
use App::DBBrowser::Table::Extensions::ScalarFunctions::Numeric;
use App::DBBrowser::Table::Extensions::ScalarFunctions::Other;
use App::DBBrowser::Table::Extensions::ScalarFunctions::String;
use App::DBBrowser::Table::Extensions::ScalarFunctions::To;
use App::DBBrowser::Table::Extensions::ScalarFunctions::GetArguments;

my $char_length        = 'CHAR_LENGTH';
my $concat             = 'CONCAT';
my $instr              = 'INSTR';
my $left               = 'LEFT';
my $lengthb            = 'LENGTHB';
my $length             = 'LENGTH';
my $locate             = 'LOCATE';
my $lower              = 'LOWER';
my $lpad               = 'LPAD';
my $ltrim              = 'LTRIM';
my $octet_length       = 'OCTET_LENGTH';
my $position           = 'POSITION';
my $replace            = 'REPLACE';
my $reverse            = 'REVERSE';
my $right              = 'RIGHT';
my $rpad               = 'RPAD';
my $rtrim              = 'RTRIM';
my $substring          = 'SUBSTRING';
my $substr             = 'SUBSTR';
my $trim               = 'TRIM';
my $truncate           = 'TRUNCATE';
my $trunc              = 'TRUNC';
my $upper              = 'UPPER';

my $abs                = 'ABS';
my $ceil               = 'CEIL';
my $exp                = 'EXP';
my $floor              = 'FLOOR';
my $ln                 = 'LN';
my $mod                = 'MOD';
my $power              = 'POWER';
my $rand               = 'RAND';
my $round              = 'ROUND';
my $sign               = 'SIGN';
my $sqrt               = 'SQRT';

my $age                = 'AGE';
my $current            = 'CURRENT';
my $current_date       = 'CURRENT_DATE';
my $current_timestamp  = 'CURRENT_TIMESTAMP';
my $current_time       = 'CURRENT_TIME';
my $date_add           = 'DATE_ADD';
my $date_trunc         = 'DATE_TRUNC';
my $date               = 'DATE';
my $datediff           = 'DATEDIFF';
my $date_part          = 'DATE_PART';
my $date_subtract      = 'DATE_SUBTRACT';
my $datetime           = 'DATETIME';
my $day                = 'DAY';
my $days               = 'DAYS';
my $dayname            = 'DAYNAME';
my $dayofweek          = 'DAYOFWEEK';
my $dayofweek_iso      = 'DAYOFWEEK_ISO';
my $dayofyear          = 'DAYOFYEAR';
my $extract            = 'EXTRACT';
my $julianday          = 'JULIANDAY';
my $julian_day         = 'JULIAN_DAY';
my $last_day           = 'LAST_DAY';
my $month              = 'MONTH';
my $monthname          = 'MONTHNAME';
my $months_between     = 'MONTHS_BETWEEN';
my $now                = 'NOW';
my $quarter            = 'QUARTER';
my $timediff           = 'TIMEDIFF';
my $timestampdiff      = 'TIMESTAMPDIFF';
my $time               = 'TIME';
my $unixepoch          = 'UNIXEPOCH';
my $week               = 'WEEK';
my $weekday            = 'WEEKDAY';
my $week_iso           = 'WEEK_ISO';
my $year               = 'YEAR';

my $date_format        = 'DATE_FORMAT';
my $epoch_to_date      = 'EPOCH_TO_DATE';
my $epoch_to_datetime  = 'EPOCH_TO_DATETIME';
my $epoch_to_timestamp = 'EPOCH_TO_TIMESTAMP';
my $format             = 'FORMAT';
my $strftime           = 'STRFTIME';
my $str_to_date        = 'STR_TO_DATE';
my $to_char            = 'TO_CHAR';
my $to_date            = 'TO_DATE';
my $to_epoch           = 'TO_EPOCH';
my $to_number          = 'TO_NUMBER';
my $to_timestamp       = 'TO_TIMESTAMP';
my $to_timestamp_tz    = 'TO_TIMESTAMP_TZ';

my $cast               = 'CAST';
my $coalesce           = 'COALESCE';


sub new {
    my ( $class, $info, $options, $d ) = @_;
    bless {
        i => $info,
        o => $options,
        d => $d
    }, $class;
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
            $trunc              => [ 'SQLite',  00000 ,  0000000 , 'Pg', 'Firebird',  000 , 'Informix', 'Oracle' ], # DB2
        },
        date => {
            $age                => [  000000 ,  00000 ,  0000000 , 'Pg',  00000000 , 'DB2',  00000000 ,  000000  ],
            $current            => [  000000 ,  00000 ,  0000000 ,  00 ,  00000000 ,  000 , 'Informix',  000000  ],
            $current_date       => [ 'SQLite', 'mysql', 'MariaDB', 'Pg', 'Firebird', 'DB2',  00000000 , 'Oracle' ],
            $current_time       => [ 'SQLite', 'mysql', 'MariaDB', 'Pg', 'Firebird', 'DB2',  00000000 , 'Oracle' ],
            $current_timestamp  => [ 'SQLite', 'mysql', 'MariaDB', 'Pg', 'Firebird', 'DB2',  00000000 , 'Oracle' ],
            $date_add           => [ 'SQLite', 'mysql', 'MariaDB', 'Pg', 'Firebird', 'DB2', 'Informix', 'Oracle' ],
            $datediff           => [ 'SQLite', 'mysql', 'MariaDB', 'Pg', 'Firebird', 'DB2',  00000000 ,  000000  ],
            $date               => [ 'SQLite', 'mysql', 'MariaDB', 'Pg',  00000000 , 'DB2', 'Informix',  000000  ],
            $date_part          => [  000000 ,  00000 ,  0000000 , 'Pg',  00000000 ,  000 ,  00000000 ,  000000  ], # DB2
            $date_subtract      => [ 'SQLite', 'mysql', 'MariaDB', 'Pg', 'Firebird', 'DB2', 'Informix', 'Oracle' ],
            $datetime           => [ 'SQLite',  00000 ,  0000000 ,  00 ,  00000000 , 'DB2',  00000000 ,  000000  ],
            $date_trunc         => [  000000 ,  00000 ,  0000000 , 'Pg',  00000000 , 'DB2',  00000000 ,  000000  ],
            $day                => [  000000 , 'mysql', 'MariaDB',  00 ,  00000000 , 'DB2', 'Informix',  000000  ],
            $dayname            => [  000000 , 'mysql', 'MariaDB',  00 ,  00000000 , 'DB2',  00000000 ,  000000  ],
            $dayofweek          => [  000000 , 'mysql', 'MariaDB',  00 ,  00000000 , 'DB2',  00000000 ,  000000  ],
            $dayofweek_iso      => [  000000 ,  00000 ,  0000000 ,  00 ,  00000000 , 'DB2',  00000000 ,  000000  ],
            $dayofyear          => [  000000 , 'mysql', 'MariaDB',  00 ,  00000000 , 'DB2',  00000000 ,  000000  ],
            $days               => [  000000 ,  00000 ,  0000000 ,  00 ,  00000000 , 'DB2',  00000000 ,  000000  ],
            $extract            => [ 'SQLite', 'mysql', 'MariaDB', 'Pg', 'Firebird', 'DB2', 'Informix', 'Oracle' ],
            $julian_day         => [  000000 ,  00000 ,  0000000 ,  00 ,  00000000 , 'DB2',  00000000 ,  000000  ],
            $julianday          => [ 'SQLite',  00000 ,  0000000 ,  00 ,  00000000 ,  000 ,  00000000 ,  000000  ],
            $last_day           => [  000000 , 'mysql', 'MariaDB',  00 ,  00000000 , 'DB2', 'Informix', 'Oracle' ], # firebird 4.0
            $month              => [  000000 , 'mysql', 'MariaDB',  00 ,  00000000 , 'DB2', 'Informix',  000000  ],
            $monthname          => [  000000 , 'mysql', 'MariaDB',  00 ,  00000000 , 'DB2',  00000000 ,  000000  ],
            $months_between     => [  000000 ,  00000 ,  0000000 ,  00 ,  00000000 , 'DB2', 'Informix', 'Oracle' ],
            $quarter            => [  000000 , 'mysql', 'MariaDB',  00 ,  00000000 , 'DB2',  00000000 ,  000000  ],
            $timediff           => [ 'SQLite', 'mysql', 'MariaDB',  00 ,  00000000 ,  000 ,  00000000 ,  000000  ],
            $time               => [ 'SQLite', 'mysql', 'MariaDB',  00 ,  00000000 , 'DB2',  00000000 ,  000000  ],
            $timestampdiff      => [  000000 , 'mysql', 'MariaDB',  00 ,  00000000 ,  000 ,  00000000 ,  000000  ], # DB2
            $unixepoch          => [ 'SQLite',  00000 ,  0000000 ,  00 ,  00000000 ,  000 ,  00000000 ,  000000  ],
            $week               => [  000000 , 'mysql', 'MariaDB',  00 ,  00000000 , 'DB2',  00000000 ,  000000  ],
            $weekday            => [  000000 , 'mysql', 'MariaDB',  00 ,  00000000 ,  000 ,  00000000 ,  000000  ],
            $week_iso           => [  000000 ,  00000 ,  0000000 ,  00 ,  00000000 , 'DB2',  00000000 ,  000000  ],
            $year               => [  000000 , 'mysql', 'MariaDB',  00 ,  00000000 , 'DB2', 'Informix',  000000  ],
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


sub scalar_function {
    my ( $sf, $sql, $clause, $cols, $r_data ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $driver = $sf->{i}{driver};
    my $hidden = 'Scalar functions:';
    my $info_sql = $ax->get_sql_info( $sql );
    my $old_idx_cat = 1;

    CATEGORY: while( 1 ) {
        my $info = $info_sql . $ext->nested_func_info( $r_data );
        my @pre = ( $hidden, undef );
        my $menu = [ @pre, '- String', '- Numeric', '- Date', '- To', '- Other' ];
        # Choose
        my $idx_cat = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_v}}, info => $info, prompt => '', index => 1, default => $old_idx_cat, undef => '<=' }
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
            $ext->enable_extended_arguments( $info );
            next CATEGORY;
        }
        my $old_idx_func = 0;

        FUNCTION: while( 1 ) {
            my $type = lc( $choice =~ s/^-\s//r );
            @pre = ( undef );
            my $avail_functions = $sf->__available_functions( $type );
            $menu = [ @pre, map { '- ' . $_ } @$avail_functions ];
            my $prompt = ucfirst( $type ). ' function:';
            # Choose
            my $idx_func = $tc->choose(
                $menu,
                { %{$sf->{i}{lyt_v}}, info => $info, prompt => $prompt, index => 1, default => $old_idx_func, undef => '<=' }
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
            push @$r_data, [ 'scalar', $func ];
            $cols = [ grep { ! /^${func}\(/i } @$cols ];
            my $new_func;
            if ( $type eq 'string' ) {
                $new_func = App::DBBrowser::Table::Extensions::ScalarFunctions::String->new( $sf->{i}, $sf->{o}, $sf->{d} );
            }
            elsif( $type eq 'numeric' ) {
                $new_func = App::DBBrowser::Table::Extensions::ScalarFunctions::Numeric->new( $sf->{i}, $sf->{o}, $sf->{d} );
            }
            elsif( $type eq 'date' ) {
                $new_func = App::DBBrowser::Table::Extensions::ScalarFunctions::Date->new( $sf->{i}, $sf->{o}, $sf->{d} );
            }
            elsif ( $type eq 'to' ) {
                $new_func = App::DBBrowser::Table::Extensions::ScalarFunctions::To->new( $sf->{i}, $sf->{o}, $sf->{d} );
            }
            elsif ( $type eq 'other' ) {
                $new_func = App::DBBrowser::Table::Extensions::ScalarFunctions::Other->new( $sf->{i}, $sf->{o}, $sf->{d} );
            }
            my $method = 'function_' . lc( $func ); ##
            my $function_stmt;
            if ( $new_func->can( $method ) ) {
                $function_stmt = $new_func->$method( $sql, $clause, $func, $cols, $r_data );
                if ( ! defined $function_stmt ) {
                    pop @$r_data;
                    if ( ! @$r_data ) { # no parent
                        next FUNCTION;
                    }
                    return; # return to the parent
                }
            }
            else {
                my $ga = App::DBBrowser::Table::Extensions::ScalarFunctions::GetArguments->new( $sf->{i}, $sf->{o}, $sf->{d} );
                my $col = $ga->choose_a_column( $sql, $clause, $cols, $r_data );
                if ( ! defined $col ) {
                    pop @$r_data;
                    if ( ! @$r_data ) {
                        next FUNCTION;
                    }
                    return;
                }
                if ( $driver eq 'Pg' && $type eq 'string' ) {
                    $col = $ax->pg_column_to_text( $sql, $col );
                }
                $function_stmt = uc( $func ) . "($col)";
            }
            pop @$r_data;
            return $function_stmt;
        }
    }
}



1;
__END__
