package DBD::DuckDB::GetInfo;

use strict;
use warnings;

use DBD::DuckDB;

# Beware: not officially documented interfaces...
# use DBI::Const::GetInfoType qw(%GetInfoType);
# use DBI::Const::GetInfoReturn qw(%GetInfoReturnTypes %GetInfoReturnValues);

my $dbdversion = $DBD::DuckDB::VERSION;
$dbdversion .= '_00' if $dbdversion =~ /^\d+\.\d+$/;

# SQL_DRIVER_VER should be formatted as dd.dd.dddd
my $sql_driver     = 'DuckDB';
my $sql_driver_ver = sprintf '%02d.%02d.%04d', split(/[\._]/, $dbdversion);

# Taken from:
#
# SELECT UPPER(keyword_name)
#   FROM duckdb_keywords()
#  WHERE keyword_category='reserved'

my @KEYWORDS = qw(
    ALL         CONSTRAINT  FROM        ONLY            SYMMETRIC
    ANALYSE     CREATE      GROUP       OR              TABLE
    ANALYZE     DEFAULT     HAVING      ORDER           THEN
    AND         DEFERRABLE  IN          PIVOT           TO
    ANY         DESC        INITIALLY   PIVOT_LONGER    TRAILING
    ARRAY       DESCRIBE    INTERSECT   PIVOT_WIDER     TRUE
    AS          DISTINCT    INTO        PLACING         UNION
    ASC         DO          LAMBDA      PRIMARY         UNIQUE
    ASYMMETRIC  ELSE        LATERAL     QUALIFY         UNPIVOT
    BOTH        END         LEADING     REFERENCES      USING
    CASE        EXCEPT      LIMIT       RETURNING       VARIADIC
    CAST        FALSE       NOT         SELECT          WHEN
    CHECK       FETCH       NULL        SHOW            WHERE
    COLLATE     FOR         OFFSET      SOME            WINDOW
    COLUMN      FOREIGN     ON          SUMMARIZE       WITH
);

sub sql_dbms_ver {
    my $dbh = shift;
    return $dbh->FETCH('duckdb_version');
}

sub sql_data_source_name {
    my $dbh = shift;
    return "dbi:$sql_driver:" . $dbh->{Name};
}

sub sql_server_name {
    my $dbh = shift;
    return $dbh->{Name};
}

sub sql_keywords {
    return join ',', @KEYWORDS;
}

sub sql_user_name {
    my $dbh = shift;

    # CURRENT_USER is a non-standard attribute, probably undef
    # Username is a standard DBI attribute
    return $dbh->{CURRENT_USER} || $dbh->{Username};
}

sub sql_database_name {
    my $dbh = shift;
    my $res = $dbh->selectrow_hashref('PRAGMA database_list');
    return $res->{name};
}

# https://github.com/duckdb/duckdb-odbc/blob/main/src/connect/connection.cpp
# https://github.com/microsoft/ODBC-Specification/blob/master/Windows/inc/sqlext.h
# https://learn.microsoft.com/en-us/sql/odbc/reference/syntax/sqlgetinfo-function

our %info = (

    20    => 'N',                       # SQL_ACCESSIBLE_PROCEDURES
    19    => 'Y',                       # SQL_ACCESSIBLE_TABLES
    0     => 0,                         # SQL_ACTIVE_CONNECTIONS
    116   => 0,                         # SQL_ACTIVE_ENVIRONMENTS
    1     => 0,                         # SQL_ACTIVE_STATEMENTS
    169   => 127,                       # SQL_AGGREGATE_FUNCTIONS
    117   => 0,                         # SQL_ALTER_DOMAIN
    86    => 5096,                      # SQL_ALTER_TABLE
    10021 => 0,                         # SQL_ASYNC_MODE
    120   => 2,                         # SQL_BATCH_ROW_COUNT
    121   => 3,                         # SQL_BATCH_SUPPORT
    82    => 0,                         # SQL_BOOKMARK_PERSISTENCE
    114   => 1,                         # SQL_CATALOG_LOCATION
    10003 => 'Y',                       # SQL_CATALOG_NAME
    41    => '.',                       # SQL_CATALOG_NAME_SEPARATOR
    42    => '',                        # SQL_CATALOG_TERM
    92    => 5,                         # SQL_CATALOG_USAGE
    10004 => 'UTF-8',                   # SQL_COLLATING_SEQUENCE
    10004 => 'UTF-8',                   # SQL_COLLATION_SEQ
    87    => 'Y',                       # SQL_COLUMN_ALIAS
    22    => 1,                         # SQL_CONCAT_NULL_BEHAVIOR
    53    => 29695,                     # SQL_CONVERT_BIGINT
    54    => 265985,                    # SQL_CONVERT_BINARY
    55    => 29465,                     # SQL_CONVERT_BIT
    56    => 2097151,                   # SQL_CONVERT_CHAR
    57    => 164609,                    # SQL_CONVERT_DATE
    58    => 1074175,                   # SQL_CONVERT_DECIMAL
    59    => 25599,                     # SQL_CONVERT_DOUBLE
    60    => 25599,                     # SQL_CONVERT_FLOAT
    48    => 2,                         # SQL_CONVERT_FUNCTIONS
    173   => 0,                         # SQL_CONVERT_GUID
    61    => 29695,                     # SQL_CONVERT_INTEGER
    123   => 1139481,                   # SQL_CONVERT_INTERVAL_DAY_TIME
    124   => 549657,                    # SQL_CONVERT_INTERVAL_YEAR_MONTH
    71    => 265985,                    # SQL_CONVERT_LONGVARBINARY
    62    => 2097151,                   # SQL_CONVERT_LONGVARCHAR
    63    => 1074175,                   # SQL_CONVERT_NUMERIC
    64    => 25599,                     # SQL_CONVERT_REAL
    65    => 29695,                     # SQL_CONVERT_SMALLINT
    66    => 1114881,                   # SQL_CONVERT_TIME
    67    => 230145,                    # SQL_CONVERT_TIMESTAMP
    68    => 29695,                     # SQL_CONVERT_TINYINT
    69    => 265985,                    # SQL_CONVERT_VARBINARY
    70    => 2097151,                   # SQL_CONVERT_VARCHAR
    122   => 0,                         # SQL_CONVERT_WCHAR
    125   => 0,                         # SQL_CONVERT_WLONGVARCHAR
    126   => 0,                         # SQL_CONVERT_WVARCHAR
    74    => 2,                         # SQL_CORRELATION_NAME
    127   => 0,                         # SQL_CREATE_ASSERTION
    128   => 0,                         # SQL_CREATE_CHARACTER_SET
    129   => 0,                         # SQL_CREATE_COLLATION
    130   => 0,                         # SQL_CREATE_DOMAIN
    131   => 1,                         # SQL_CREATE_SCHEMA
    132   => 15889,                     # SQL_CREATE_TABLE
    133   => 0,                         # SQL_CREATE_TRANSLATION
    134   => 3,                         # SQL_CREATE_VIEW
    23    => 2,                         # SQL_CURSOR_COMMIT_BEHAVIOR
    24    => 1,                         # SQL_CURSOR_ROLLBACK_BEHAVIOR
    10001 => 1,                         # SQL_CURSOR_SENSITIVITY
    16    => \&sql_database_name,       # SQL_DATABASE_NAME
    2     => \&sql_data_source_name,    # SQL_DATA_SOURCE_NAME
    25    => 'N',                       # SQL_DATA_SOURCE_READ_ONLY
    119   => 65535,                     # SQL_DATETIME_LITERALS
    17    => 'DuckDB',                  # SQL_DBMS_NAME
    18    => \&sql_dbms_ver,            # SQL_DBMS_VER
    18    => \&sql_dbms_ver,            # SQL_DBMS_VERSION
    170   => 0,                         # SQL_DDL_INDEX
    26    => 8,                         # SQL_DEFAULT_TRANSACTION_ISOLATION
    26    => 8,                         # SQL_DEFAULT_TXN_ISOLATION
    10002 => 'Y',                       # SQL_DESCRIBE_PARAMETER

#   171 => undef,                         # SQL_DM_VER
#     3 => undef,                         # SQL_DRIVER_HDBC
#   135 => undef,                         # SQL_DRIVER_HDESC
#     4 => undef,                         # SQL_DRIVER_HENV
#    76 => undef,                         # SQL_DRIVER_HLIB
#     5 => undef,                         # SQL_DRIVER_HSTMT

    6   => 'DBD/DuckDB.pm',             # SQL_DRIVER_NAME
    77  => '03.51',                     # SQL_DRIVER_ODBC_VER
    7   => $sql_driver_ver,             # SQL_DRIVER_VER
    136 => 0,                           # SQL_DROP_ASSERTION
    137 => 0,                           # SQL_DROP_CHARACTER_SET
    138 => 0,                           # SQL_DROP_COLLATION
    139 => 0,                           # SQL_DROP_DOMAIN
    140 => 7,                           # SQL_DROP_SCHEMA
    141 => 7,                           # SQL_DROP_TABLE
    142 => 0,                           # SQL_DROP_TRANSLATION
    143 => 7,                           # SQL_DROP_VIEW
    144 => 7,                           # SQL_DYNAMIC_CURSOR_ATTRIBUTES1
    145 => 0,                           # SQL_DYNAMIC_CURSOR_ATTRIBUTES2
    27  => 'Y',                         # SQL_EXPRESSIONS_IN_ORDERBY

#     8 => undef,                         # SQL_FETCH_DIRECTION

    84  => 0,                           # SQL_FILE_USAGE
    146 => 1,                           # SQL_FORWARD_ONLY_CURSOR_ATTRIBUTES1
    147 => 0,                           # SQL_FORWARD_ONLY_CURSOR_ATTRIBUTES2
    81  => 15,                          # SQL_GETDATA_EXTENSIONS
    88  => 3,                           # SQL_GROUP_BY
    28  => 2,                           # SQL_IDENTIFIER_CASE
    29  => '"',                         # SQL_IDENTIFIER_QUOTE_CHAR
    148 => 0,                           # SQL_INDEX_KEYWORDS
    149 => 0,                           # SQL_INFO_SCHEMA_VIEWS
    172 => 1,                           # SQL_INSERT_STATEMENT
    73  => 'N',                         # SQL_INTEGRITY

#   150 => undef,                         # SQL_KEYSET_CURSOR_ATTRIBUTES1

    151 => 0,                           # SQL_KEYSET_CURSOR_ATTRIBUTES2
    89  => \&sql_keywords,              # SQL_KEYWORDS
    113 => 'Y',                         # SQL_LIKE_ESCAPE_CLAUSE

#    78 => undef,                         # SQL_LOCK_TYPES

    34    => 0,                         # SQL_MAXIMUM_CATALOG_NAME_LENGTH
    97    => 0,                         # SQL_MAXIMUM_COLUMNS_IN_GROUP_BY
    98    => 0,                         # SQL_MAXIMUM_COLUMNS_IN_INDEX
    99    => 0,                         # SQL_MAXIMUM_COLUMNS_IN_ORDER_BY
    100   => 0,                         # SQL_MAXIMUM_COLUMNS_IN_SELECT
    101   => 0,                         # SQL_MAXIMUM_COLUMNS_IN_TABLE
    30    => 0,                         # SQL_MAXIMUM_COLUMN_NAME_LENGTH
    1     => 0,                         # SQL_MAXIMUM_CONCURRENT_ACTIVITIES
    31    => 0,                         # SQL_MAXIMUM_CURSOR_NAME_LENGTH
    0     => 1,                         # SQL_MAXIMUM_DRIVER_CONNECTIONS
    10005 => 0,                         # SQL_MAXIMUM_IDENTIFIER_LENGTH
    102   => 0,                         # SQL_MAXIMUM_INDEX_SIZE
    104   => 0,                         # SQL_MAXIMUM_ROW_SIZE
    32    => 0,                         # SQL_MAXIMUM_SCHEMA_NAME_LENGTH
    105   => 0,                         # SQL_MAXIMUM_STATEMENT_LENGTH

# 20000 => undef,                         # SQL_MAXIMUM_STMT_OCTETS
# 20001 => undef,                         # SQL_MAXIMUM_STMT_OCTETS_DATA
# 20002 => undef,                         # SQL_MAXIMUM_STMT_OCTETS_SCHEMA

    106   => 0,                         # SQL_MAXIMUM_TABLES_IN_SELECT
    35    => 0,                         # SQL_MAXIMUM_TABLE_NAME_LENGTH
    107   => 0,                         # SQL_MAXIMUM_USER_NAME_LENGTH
    10022 => 0,                         # SQL_MAX_ASYNC_CONCURRENT_STATEMENTS
    112   => 0,                         # SQL_MAX_BINARY_LITERAL_LEN
    34    => 0,                         # SQL_MAX_CATALOG_NAME_LEN
    108   => 0,                         # SQL_MAX_CHAR_LITERAL_LEN
    97    => 0,                         # SQL_MAX_COLUMNS_IN_GROUP_BY
    98    => 0,                         # SQL_MAX_COLUMNS_IN_INDEX
    99    => 0,                         # SQL_MAX_COLUMNS_IN_ORDER_BY
    100   => 0,                         # SQL_MAX_COLUMNS_IN_SELECT
    101   => 0,                         # SQL_MAX_COLUMNS_IN_TABLE
    30    => 0,                         # SQL_MAX_COLUMN_NAME_LEN
    1     => 0,                         # SQL_MAX_CONCURRENT_ACTIVITIES
    31    => 0,                         # SQL_MAX_CURSOR_NAME_LEN
    0     => 1,                         # SQL_MAX_DRIVER_CONNECTIONS
    10005 => 0,                         # SQL_MAX_IDENTIFIER_LEN
    102   => 0,                         # SQL_MAX_INDEX_SIZE
    32    => 0,                         # SQL_MAX_OWNER_NAME_LEN
    33    => 0,                         # SQL_MAX_PROCEDURE_NAME_LEN
    34    => 0,                         # SQL_MAX_QUALIFIER_NAME_LEN
    104   => 0,                         # SQL_MAX_ROW_SIZE
    103   => 'Y',                       # SQL_MAX_ROW_SIZE_INCLUDES_LONG
    32    => 0,                         # SQL_MAX_SCHEMA_NAME_LEN
    105   => 0,                         # SQL_MAX_STATEMENT_LEN
    106   => 0,                         # SQL_MAX_TABLES_IN_SELECT
    35    => 0,                         # SQL_MAX_TABLE_NAME_LEN
    107   => 0,                         # SQL_MAX_USER_NAME_LEN
    36    => 'N',                       # SQL_MULT_RESULT_SETS
    111   => 'Y',                       # SQL_NEED_LONG_DATA_LEN
    75    => 1,                         # SQL_NON_NULLABLE_COLUMNS
    85    => 2,                         # SQL_NULL_COLLATION
    49    => 8257535,                   # SQL_NUMERIC_FUNCTIONS
    9     => 1,                         # SQL_ODBC_API_CONFORMANCE
    152   => 1,                         # SQL_ODBC_INTERFACE_CONFORMANCE
    12    => 0,                         # SQL_ODBC_SAG_CLI_CONFORMANCE
    15    => 0,                         # SQL_ODBC_SQL_CONFORMANCE -- ???
    73    => 'N',                       # SQL_ODBC_SQL_OPT_IEF
    10    => '03.52',                   # SQL_ODBC_VER
    115   => 103,                       # SQL_OJ_CAPABILITIES
    90    => 'Y',                       # SQL_ORDER_BY_COLUMNS_IN_SELECT

#    38 => undef,                         # SQL_OUTER_JOINS

    115 => 103,                         # SQL_OUTER_JOIN_CAPABILITIES
    39  => 'schema',                    # SQL_OWNER_TERM
    91  => 5,                           # SQL_OWNER_USAGE
    153 => 1,                           # SQL_PARAM_ARRAY_ROW_COUNTS
    154 => 1,                           # SQL_PARAM_ARRAY_SELECTS

#    80 => undef,                         # SQL_POSITIONED_STATEMENTS

    79  => 0,                           # SQL_POS_OPERATIONS
    21  => 'N',                         # SQL_PROCEDURES
    40  => '',                          # SQL_PROCEDURE_TERM
    114 => 1,                           # SQL_QUALIFIER_LOCATION
    41  => '.',                         # SQL_QUALIFIER_NAME_SEPARATOR
    42  => '',                          # SQL_QUALIFIER_TERM
    92  => 5,                           # SQL_QUALIFIER_USAGE
    93  => 3,                           # SQL_QUOTED_IDENTIFIER_CASE
    11  => 'N',                         # SQL_ROW_UPDATES
    39  => 'schema',                    # SQL_SCHEMA_TERM
    91  => 5,                           # SQL_SCHEMA_USAGE

#    43 => undef,                         # SQL_SCROLL_CONCURRENCY

    44    => 44,                                 # SQL_SCROLL_OPTIONS -- ???
    14    => '\\',                               # SQL_SEARCH_PATTERN_ESCAPE
    13    => '',                                 # SQL_SERVER_NAME
    94    => q{"!%&'()*+,-./;:<=>?@[]^{}|~"},    # SQL_SPECIAL_CHARACTERS
    155   => 7,                                  # SQL_SQL92_DATETIME_FUNCTIONS
    156   => 0,                                  # SQL_SQL92_FOREIGN_KEY_DELETE_RULE
    157   => 0,                                  # SQL_SQL92_FOREIGN_KEY_UPDATE_RULE
    158   => 0,                                  # SQL_SQL92_GRANT
    159   => 57,                                 # SQL_SQL92_NUMERIC_VALUE_FUNCTIONS
    160   => 7687,                               # SQL_SQL92_PREDICATES
    161   => 474,                                # SQL_SQL92_RELATIONAL_JOIN_OPERATORS
    162   => 0,                                  # SQL_SQL92_REVOKE
    163   => 15,                                 # SQL_SQL92_ROW_VALUE_CONSTRUCTOR
    164   => 239,                                # SQL_SQL92_STRING_FUNCTIONS
    165   => 15,                                 # SQL_SQL92_VALUE_EXPRESSIONS
    118   => 1,                                  # SQL_SQL_CONFORMANCE
    166   => 0,                                  # SQL_STANDARD_CLI_CONFORMANCE
    167   => 7,                                  # SQL_STATIC_CURSOR_ATTRIBUTES1
    168   => 0,                                  # SQL_STATIC_CURSOR_ATTRIBUTES2
    83    => 0,                                  # SQL_STATIC_SENSITIVITY
    50    => 540669,                             # SQL_STRING_FUNCTIONS
    95    => 31,                                 # SQL_SUBQUERIES
    51    => 0,                                  # SQL_SYSTEM_FUNCTIONS
    45    => 'table',                            # SQL_TABLE_TERM
    109   => 511,                                # SQL_TIMEDATE_ADD_INTERVALS
    110   => 511,                                # SQL_TIMEDATE_DIFF_INTERVALS
    52    => 2072061,                            # SQL_TIMEDATE_FUNCTIONS
    46    => 2,                                  # SQL_TRANSACTION_CAPABLE
    72    => 8,                                  # SQL_TRANSACTION_ISOLATION_OPTION
    46    => 2,                                  # SQL_TXN_CAPABLE
    72    => 8,                                  # SQL_TXN_ISOLATION_OPTION
    96    => 3,                                  # SQL_UNION
    96    => 3,                                  # SQL_UNION_STATEMENT
    47    => \&sql_user_name,                    # SQL_USER_NAME
    10000 => 1992,                               # SQL_XOPEN_CLI_YEAR

);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBD::DuckDB::GetInfo - Wrapper to get DuckDB information

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-DBD-DuckDB/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-DBD-DuckDB>

    git clone https://github.com/giterlizzi/perl-DBD-DuckDB.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2024-2025 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
