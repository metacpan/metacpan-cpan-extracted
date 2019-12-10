use strict;
use Test::More;
use Test::More::UTF8;
use POSIX qw( strftime );
use FindBin::libs;
use DBIx::NamedParams;
use open ':std' => ( $^O eq 'MSWin32' ? ':locale' : ':utf8' );

note("Perl version:\t$]");
note("DBI version:\t${DBI::VERSION}");
note( strftime( "%Y-%m-%d %H:%M:%S", localtime ) );

is_deeply(
    [ DBIx::NamedParams::all_sql_types() ],
    [   qw(
            ALL_TYPES ARRAY ARRAY_LOCATOR BIGINT BINARY BIT BLOB BLOB_LOCATOR
            BOOLEAN CHAR CLOB CLOB_LOCATOR DATE DATETIME DECIMAL DOUBLE FLOAT
            GUID INTEGER INTERVAL INTERVAL_DAY INTERVAL_DAY_TO_HOUR
            INTERVAL_DAY_TO_MINUTE INTERVAL_DAY_TO_SECOND INTERVAL_HOUR
            INTERVAL_HOUR_TO_MINUTE INTERVAL_HOUR_TO_SECOND INTERVAL_MINUTE
            INTERVAL_MINUTE_TO_SECOND INTERVAL_MONTH INTERVAL_SECOND
            INTERVAL_YEAR INTERVAL_YEAR_TO_MONTH LONGVARBINARY LONGVARCHAR
            MULTISET MULTISET_LOCATOR NUMERIC REAL REF ROW SMALLINT TIME
            TIMESTAMP TINYINT TYPE_DATE TYPE_TIME TYPE_TIMESTAMP
            TYPE_TIMESTAMP_WITH_TIMEZONE TYPE_TIME_WITH_TIMEZONE UDT UDT_LOCATOR
            UNKNOWN_TYPE VARBINARY VARCHAR WCHAR WLONGVARCHAR WVARCHAR
            )
    ],
    'all_sql_types()'
) or diag( "sql_types:\n" . join( " ", sort( @{ $DBI::EXPORT_TAGS{sql_types} } ) ) );

done_testing;
