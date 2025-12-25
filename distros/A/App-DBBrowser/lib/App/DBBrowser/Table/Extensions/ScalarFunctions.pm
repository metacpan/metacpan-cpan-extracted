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

my $charindex          = 'CHARINDEX';
my $char_length        = 'CHAR_LENGTH';
my $concat             = 'CONCAT';
my $datalength         = 'DATALENGTH';
my $instr              = 'INSTR';
my $left               = 'LEFT';
my $len                = 'LEN';
my $length             = 'LENGTH';
my $lengthb            = 'LENGTHB';
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
my $ceiling            = 'CEILING';
my $exp                = 'EXP';
my $floor              = 'FLOOR';
my $ln                 = 'LN';
my $log                = 'LOG';
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
my $date               = 'DATE';
my $datediff           = 'DATEDIFF';
my $datetime           = 'DATETIME';
my $date_add           = 'DATE_ADD';
my $date_part          = 'DATE_PART';
my $date_subtract      = 'DATE_SUBTRACT';
my $date_trunc         = 'DATE_TRUNC';
my $day                = 'DAY';
my $days               = 'DAYS';
my $dayname            = 'DAYNAME';
my $dayofweek          = 'DAYOFWEEK';
my $dayofweek_iso      = 'DAYOFWEEK_ISO';
my $dayofyear          = 'DAYOFYEAR';
my $extract            = 'EXTRACT';
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
my $week               = 'WEEK';
my $weekday            = 'WEEKDAY';
my $week_iso           = 'WEEK_ISO';
my $year               = 'YEAR';

my $date_format        = 'DATE_FORMAT';
my $epoch_to_date      = 'EPOCH_TO_DATE';
my $epoch_to_datetime  = 'EPOCH_TO_DATETIME';
my $epoch_to_timestamp = 'EPOCH_TO_TIMESTAMP';
my $format             = 'FORMAT';
my $str                = 'STR';
my $strftime           = 'STRFTIME';
my $strptime           = 'STRPTIME';
my $str_to_date        = 'STR_TO_DATE';
my $to_char            = 'TO_CHAR';
my $to_date            = 'TO_DATE';
my $to_epoch           = 'TO_EPOCH';
my $to_number          = 'TO_NUMBER';
my $to_timestamp       = 'TO_TIMESTAMP';
my $to_timestamp_tz    = 'TO_TIMESTAMP_TZ';
my $unixepoch          = 'UNIXEPOCH';

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
            $charindex          => [  undef  ,  undef ,  undef   ,  undef,  undef  ,  undef    ,  undef,  undef    ,  undef  , 'MSSQL' ],
            $char_length        => [  undef  , 'mysql', 'MariaDB', 'Pg'  , 'DuckDB', 'Firebird', 'DB2' , 'Informix',  undef  ,  undef  ],
            $concat             => [ 'SQLite', 'mysql', 'MariaDB', 'Pg'  , 'DuckDB', 'Firebird', 'DB2' , 'Informix', 'Oracle', 'MSSQL' ],
            $datalength         => [  undef  ,  undef ,  undef   ,  undef,  undef  ,  undef    ,  undef,  undef    ,  undef  , 'MSSQL' ],
            $instr              => [ 'SQLite',  undef ,  undef   ,  undef,  undef  ,  undef    , 'DB2' , 'Informix', 'Oracle',  undef  ], # DuckDB
            $left               => [ 'SQLite', 'mysql', 'MariaDB', 'Pg'  , 'DuckDB', 'Firebird', 'DB2' , 'Informix',  undef  , 'MSSQL' ],
            $len                => [  undef  ,  undef ,  undef   ,  undef,  undef  ,  undef    ,  undef,  undef    ,  undef  , 'MSSQL' ],
            $length             => [ 'SQLite',  undef ,  undef   ,  undef,  undef  ,  undef    ,  undef,  undef    , 'Oracle',  undef  ], # Pg, DuckDB
            $lengthb            => [  undef  ,  undef ,  undef   ,  undef,  undef  ,  undef    ,  undef,  undef    , 'Oracle',  undef  ],
            $locate             => [  undef  , 'mysql', 'MariaDB',  undef,  undef  ,  undef    ,  undef,  undef    ,  undef  ,  undef  ], # DB2
            $lower              => [ 'SQLite', 'mysql', 'MariaDB', 'Pg'  , 'DuckDB', 'Firebird', 'DB2' , 'Informix', 'Oracle', 'MSSQL' ],
            $lpad               => [ 'SQLite', 'mysql', 'MariaDB', 'Pg'  , 'DuckDB', 'Firebird', 'DB2' , 'Informix', 'Oracle',  undef  ],
            $ltrim              => [ 'SQLite', 'mysql', 'MariaDB', 'Pg'  , 'DuckDB',  undef    , 'DB2' , 'Informix', 'Oracle', 'MSSQL' ],
            $octet_length       => [ 'SQLite', 'mysql', 'MariaDB', 'Pg'  ,  undef  , 'Firebird', 'DB2' , 'Informix',  undef  ,  undef  ], # DuckDB: bit_length('abc')
            $position           => [  undef  , 'mysql', 'MariaDB', 'Pg'  , 'DuckDB', 'Firebird', 'DB2' ,  undef    ,  undef  ,  undef  ],
            $replace            => [ 'SQLite', 'mysql', 'MariaDB', 'Pg'  , 'DuckDB', 'Firebird', 'DB2' , 'Informix', 'Oracle', 'MSSQL' ],
            $reverse            => [  undef  , 'mysql', 'MariaDB', 'Pg'  , 'DuckDB', 'Firebird',  undef, 'Informix', 'Oracle', 'MSSQL' ],
            $right              => [ 'SQLite', 'mysql', 'MariaDB', 'Pg'  , 'DuckDB', 'Firebird', 'DB2' , 'Informix',  undef  , 'MSSQL' ],
            $rpad               => [ 'SQLite', 'mysql', 'MariaDB', 'Pg'  , 'DuckDB', 'Firebird', 'DB2' , 'Informix', 'Oracle',  undef  ],
            $rtrim              => [ 'SQLite', 'mysql', 'MariaDB', 'Pg'  , 'DuckDB',  undef    , 'DB2' , 'Informix', 'Oracle', 'MSSQL' ],
            $substring          => [  undef  ,  undef ,  undef   ,  undef,  undef  , 'Firebird',  undef,  undef    ,  undef  , 'MSSQL' ], # mysql, MariaDB, Pg, DB2, Informix, DuckDB
            $substr             => [ 'SQLite', 'mysql', 'MariaDB', 'Pg'  , 'DuckDB',  undef    , 'DB2' , 'Informix', 'Oracle',  undef  ],
            $trim               => [ 'SQLite', 'mysql', 'MariaDB', 'Pg'  , 'DuckDB', 'Firebird', 'DB2' , 'Informix', 'Oracle', 'MSSQL' ],
            $upper              => [ 'SQLite', 'mysql', 'MariaDB', 'Pg'  , 'DuckDB', 'Firebird', 'DB2' , 'Informix', 'Oracle', 'MSSQL' ],
        },
        numeric => {
            $abs                => [ 'SQLite', 'mysql', 'MariaDB', 'Pg'  , 'DuckDB', 'Firebird', 'DB2' , 'Informix', 'Oracle', 'MSSQL' ],
            $ceil               => [ 'SQLite', 'mysql', 'MariaDB', 'Pg'  , 'DuckDB', 'Firebird', 'DB2' , 'Informix', 'Oracle',  undef  ],
            $ceiling            => [  undef  ,  undef ,  undef   ,  undef,  undef  ,  undef    ,  undef,  undef    ,  undef  , 'MSSQL' ],
            $exp                => [ 'SQLite', 'mysql', 'MariaDB', 'Pg'  , 'DuckDB', 'Firebird', 'DB2' , 'Informix', 'Oracle', 'MSSQL' ],
            $floor              => [ 'SQLite', 'mysql', 'MariaDB', 'Pg'  , 'DuckDB', 'Firebird', 'DB2' , 'Informix', 'Oracle', 'MSSQL' ],
            $ln                 => [ 'SQLite', 'mysql', 'MariaDB', 'Pg'  , 'DuckDB', 'Firebird', 'DB2' , 'Informix', 'Oracle',  undef  ],
            $log                => [  undef  ,  undef ,  undef   ,  undef,  undef  ,  undef    ,  undef,  undef    ,  undef  , 'MSSQL' ],
            $mod                => [ 'SQLite', 'mysql', 'MariaDB', 'Pg'  , 'DuckDB', 'Firebird', 'DB2' , 'Informix', 'Oracle', 'MSSQL' ],
            $power              => [ 'SQLite', 'mysql', 'MariaDB', 'Pg'  , 'DuckDB', 'Firebird', 'DB2' , 'Informix', 'Oracle', 'MSSQL' ],
            $rand               => [ 'SQLite', 'mysql', 'MariaDB', 'Pg'  , 'DuckDB', 'Firebird', 'DB2' ,  undef    , 'Oracle', 'MSSQL' ],
            $round              => [ 'SQLite', 'mysql', 'MariaDB', 'Pg'  , 'DuckDB', 'Firebird', 'DB2' , 'Informix', 'Oracle', 'MSSQL' ],
            $sign               => [ 'SQLite', 'mysql', 'MariaDB', 'Pg'  , 'DuckDB', 'Firebird', 'DB2' , 'Informix', 'Oracle', 'MSSQL' ],
            $sqrt               => [ 'SQLite', 'mysql', 'MariaDB', 'Pg'  , 'DuckDB', 'Firebird', 'DB2' , 'Informix', 'Oracle', 'MSSQL' ],
            $truncate           => [  undef  , 'mysql', 'MariaDB',  undef,  undef  ,  undef    , 'DB2' ,  undef    ,  undef  ,  undef  ],
            $trunc              => [ 'SQLite',  undef ,  undef   , 'Pg'  , 'DuckDB', 'Firebird',  undef, 'Informix', 'Oracle', 'MSSQL' ], # DB2
        },
        date => {
            $age                => [  undef  ,  undef ,  undef   , 'Pg'  , 'DuckDB',  undef    , 'DB2' ,  undef    ,  undef  ,  undef  ],
            $current            => [  undef  ,  undef ,  undef   ,  undef,  undef  ,  undef    ,  undef, 'Informix',  undef  ,  undef  ],
            $current_date       => [ 'SQLite', 'mysql', 'MariaDB', 'Pg'  , 'DuckDB', 'Firebird', 'DB2' ,  undef    , 'Oracle', 'MSSQL' ],
            $current_time       => [ 'SQLite', 'mysql', 'MariaDB', 'Pg'  , 'DuckDB', 'Firebird', 'DB2' ,  undef    , 'Oracle',  undef  ],
            $current_timestamp  => [ 'SQLite', 'mysql', 'MariaDB', 'Pg'  , 'DuckDB', 'Firebird', 'DB2' ,  undef    , 'Oracle', 'MSSQL' ],
            $date               => [ 'SQLite', 'mysql', 'MariaDB', 'Pg'  , 'DuckDB',  undef    , 'DB2' , 'Informix',  undef  ,  undef  ],
            $datediff           => [ 'SQLite', 'mysql', 'MariaDB', 'Pg'  , 'DuckDB', 'Firebird', 'DB2' ,  undef    ,  undef  , 'MSSQL' ],
            $datetime           => [ 'SQLite',  undef ,  undef   ,  undef,  undef  ,  undef    , 'DB2' ,  undef    ,  undef  ,  undef  ],
            $date_add           => [ 'SQLite', 'mysql', 'MariaDB', 'Pg'  , 'DuckDB', 'Firebird', 'DB2' , 'Informix', 'Oracle', 'MSSQL' ],
            $date_part          => [  undef  ,  undef ,  undef   , 'Pg'  , 'DuckDB',  undef    ,  undef,  undef    ,  undef  , 'MSSQL' ], # DB2
            $date_subtract      => [ 'SQLite', 'mysql', 'MariaDB', 'Pg'  , 'DuckDB', 'Firebird', 'DB2' , 'Informix', 'Oracle', 'MSSQL' ],
            $date_trunc         => [  undef  ,  undef ,  undef   , 'Pg'  , 'DuckDB',  undef    , 'DB2' ,  undef    ,  undef  , 'MSSQL' ],
            $day                => [  undef  , 'mysql', 'MariaDB',  undef, 'DuckDB',  undef    , 'DB2' , 'Informix',  undef  , 'MSSQL' ],
            $dayname            => [  undef  , 'mysql', 'MariaDB',  undef, 'DuckDB',  undef    , 'DB2' ,  undef    ,  undef  ,  undef  ],
            $dayofweek          => [  undef  , 'mysql', 'MariaDB',  undef, 'DuckDB',  undef    , 'DB2' ,  undef    ,  undef  ,  undef  ],
            $dayofweek_iso      => [  undef  ,  undef ,  undef   ,  undef,  undef  ,  undef    , 'DB2' ,  undef    ,  undef  ,  undef  ],
            $dayofyear          => [  undef  , 'mysql', 'MariaDB',  undef, 'DuckDB',  undef    , 'DB2' ,  undef    ,  undef  ,  undef  ],
            $days               => [  undef  ,  undef ,  undef   ,  undef,  undef  ,  undef    , 'DB2' ,  undef    ,  undef  ,  undef  ],
            $extract            => [ 'SQLite', 'mysql', 'MariaDB', 'Pg'  , 'DuckDB', 'Firebird', 'DB2' , 'Informix', 'Oracle',  undef  ],
            $julian_day         => [ 'SQLite',  undef ,  undef   ,  undef, 'DuckDB',  undef    , 'DB2' ,  undef    ,  undef  ,  undef  ],
            $last_day           => [  undef  , 'mysql', 'MariaDB',  undef, 'DuckDB',  undef    , 'DB2' , 'Informix', 'Oracle',  undef  ], # firebird 4.0
            $month              => [  undef  , 'mysql', 'MariaDB',  undef, 'DuckDB',  undef    , 'DB2' , 'Informix',  undef  , 'MSSQL' ],
            $monthname          => [  undef  , 'mysql', 'MariaDB',  undef, 'DuckDB',  undef    , 'DB2' ,  undef    ,  undef  ,  undef  ],
            $months_between     => [  undef  ,  undef ,  undef   ,  undef,  undef  ,  undef    , 'DB2' , 'Informix', 'Oracle',  undef  ],
            $quarter            => [  undef  , 'mysql', 'MariaDB',  undef, 'DuckDB',  undef    , 'DB2' ,  undef    ,  undef  ,  undef  ],
            $time               => [ 'SQLite', 'mysql', 'MariaDB',  undef,  undef  ,  undef    , 'DB2' ,  undef    ,  undef  ,  undef  ],
            $timediff           => [ 'SQLite', 'mysql', 'MariaDB',  undef,  undef  ,  undef    ,  undef,  undef    ,  undef  ,  undef  ],
            $timestampdiff      => [  undef  , 'mysql', 'MariaDB',  undef,  undef  ,  undef    ,  undef,  undef    ,  undef  ,  undef  ], # DB2
            $week               => [  undef  , 'mysql', 'MariaDB',  undef, 'DuckDB',  undef    , 'DB2' ,  undef    ,  undef  ,  undef  ],
            $weekday            => [  undef  , 'mysql', 'MariaDB',  undef, 'DuckDB',  undef    ,  undef,  undef    ,  undef  ,  undef  ],
            $week_iso           => [  undef  ,  undef ,  undef   ,  undef,  undef  ,  undef    , 'DB2' ,  undef    ,  undef  ,  undef  ],
            $year               => [  undef  , 'mysql', 'MariaDB',  undef, 'DuckDB',  undef    , 'DB2' , 'Informix',  undef  , 'MSSQL' ],
        },
        to => {
            $epoch_to_date      => [ 'SQLite', 'mysql', 'MariaDB', 'Pg'  , 'DuckDB', 'Firebird', 'DB2' , 'Informix', 'Oracle', 'MSSQL' ],
            $epoch_to_datetime  => [ 'SQLite', 'mysql', 'MariaDB', 'Pg'  , 'DuckDB', 'Firebird', 'DB2' , 'Informix', 'Oracle', 'MSSQL' ], ##
            $epoch_to_timestamp => [  undef  ,  undef ,  undef   , 'Pg'  , 'DuckDB', 'Firebird',  undef,  undef    , 'Oracle', 'MSSQL' ],
            $to_char            => [  undef  ,  undef ,  undef   , 'Pg'  ,  undef  ,  undef    , 'DB2' , 'Informix', 'Oracle',  undef  ], # MariaDB
            $to_date            => [  undef  ,  undef ,  undef   , 'Pg'  ,  undef  ,  undef    , 'DB2' , 'Informix', 'Oracle',  undef  ], # MariaDB
            $to_timestamp       => [  undef  ,  undef ,  undef   , 'Pg'  , 'DuckDB',  undef    ,  undef,  undef    , 'Oracle',  undef  ], # DB2 # DuckDB: epoch to timestamp
            $to_timestamp_tz    => [  undef  ,  undef ,  undef   ,  undef,  undef  ,  undef    ,  undef,  undef    , 'Oracle',  undef  ],
            $to_number          => [  undef  ,  undef , 'MariaDB', 'Pg'  ,  undef  ,  undef    , 'DB2' , 'Informix', 'Oracle',  undef  ],
            $to_epoch           => [ 'SQLite', 'mysql', 'MariaDB', 'Pg'  , 'DuckDB', 'Firebird', 'DB2' ,  undef    , 'Oracle', 'MSSQL' ],
            $str                => [  undef  ,  undef ,  undef   ,  undef,  undef  ,  undef    ,  undef,  undef    ,  undef  , 'MSSQL' ],
            $strftime           => [ 'SQLite',  undef ,  undef   ,  undef, 'DuckDB',  undef    ,  undef,  undef    ,  undef  ,  undef  ],
            $strptime           => [  undef  ,  undef ,  undef   ,  undef, 'DuckDB',  undef    ,  undef,  undef    ,  undef  ,  undef  ],
            $date_format        => [  undef  , 'mysql', 'MariaDB',  undef,  undef  ,  undef    ,  undef,  undef    ,  undef  ,  undef  ],
            $format             => [  undef  , 'mysql', 'MariaDB',  undef,  undef  ,  undef    ,  undef,  undef    ,  undef  , 'MSSQL' ], # DuckDB: construct formatted strings
            $str_to_date        => [  undef  , 'mysql', 'MariaDB',  undef,  undef  ,  undef    ,  undef,  undef    ,  undef  ,  undef  ],
            $unixepoch          => [ 'SQLite',  undef ,  undef   ,  undef,  undef  ,  undef    ,  undef,  undef    ,  undef  ,  undef  ],
        },
        other => {
            $cast               => [ 'SQLite', 'mysql', 'MariaDB', 'Pg'  , 'DuckDB', 'Firebird', 'DB2' , 'Informix', 'Oracle', 'MSSQL' ],
            $coalesce           => [ 'SQLite', 'mysql', 'MariaDB', 'Pg'  , 'DuckDB', 'Firebird', 'DB2' , 'Informix', 'Oracle', 'MSSQL' ],
        },
    };

    my $dbms = $sf->{i}{dbms};
    my $index = {
        SQLite => 0, mysql => 1, MariaDB => 2, Pg => 3, DuckDB => 4, Firebird => 5, DB2 => 6, Informix => 7, Oracle => 8, MSSQL => 9,
    };
    my $avail_functions = [];
    for my $func ( sort keys %{$functions->{$type}} ) {
        if ( ! exists $index->{$dbms} ) {
            # return all functions
            push @$avail_functions, $func;
        }
        elsif ( $functions->{$type}{$func}[$index->{$dbms}] ) {
            push @$avail_functions, $func;
        }
    }
    if ( $sf->{i}{driver} eq 'ODBC' && $dbms eq 'SQLite' ) {
        $avail_functions = [ grep { ! /^(?:$trunc|$octet_length)\z/ } @$avail_functions ]; # sqlite_create_functions
    }
    return $avail_functions;
}


sub scalar_function {
    my ( $sf, $sql, $clause, $cols, $r_data ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $ext = App::DBBrowser::Table::Extensions->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $dbms = $sf->{i}{dbms};
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
                if ( $dbms eq 'Pg' && $type eq 'string' ) {
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
