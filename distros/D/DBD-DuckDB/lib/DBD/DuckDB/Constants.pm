package DBD::DuckDB::Constants;

use strict;
use warnings;
use utf8;
use v5.10;

use Exporter 'import';

our @DUCKDB_TYPES = qw(
    DUCKDB_TYPE_INVALID
    DUCKDB_TYPE_BOOLEAN
    DUCKDB_TYPE_TINYINT
    DUCKDB_TYPE_SMALLINT
    DUCKDB_TYPE_INTEGER
    DUCKDB_TYPE_BIGINT
    DUCKDB_TYPE_UTINYINT
    DUCKDB_TYPE_USMALLINT
    DUCKDB_TYPE_UINTEGER
    DUCKDB_TYPE_UBIGINT
    DUCKDB_TYPE_FLOAT
    DUCKDB_TYPE_DOUBLE
    DUCKDB_TYPE_TIMESTAMP
    DUCKDB_TYPE_DATE
    DUCKDB_TYPE_TIME
    DUCKDB_TYPE_INTERVAL
    DUCKDB_TYPE_HUGEINT
    DUCKDB_TYPE_VARCHAR
    DUCKDB_TYPE_BLOB
    DUCKDB_TYPE_DECIMAL
    DUCKDB_TYPE_TIMESTAMP_S
    DUCKDB_TYPE_TIMESTAMP_MS
    DUCKDB_TYPE_TIMESTAMP_NS
    DUCKDB_TYPE_ENUM
    DUCKDB_TYPE_LIST
    DUCKDB_TYPE_STRUCT
    DUCKDB_TYPE_MAP
    DUCKDB_TYPE_UUID
    DUCKDB_TYPE_UNION
    DUCKDB_TYPE_BIT
    DUCKDB_TYPE_TIME_TZ
    DUCKDB_TYPE_TIMESTAMP_TZ
    DUCKDB_TYPE_UHUGEINT
    DUCKDB_TYPE_ARRAY
    DUCKDB_TYPE_ANY
    DUCKDB_TYPE_BIGNUM
    DUCKDB_TYPE_SQLNULL
    DUCKDB_TYPE_STRING_LITERAL
    DUCKDB_TYPE_INTEGER_LITERAL
    DUCKDB_TYPE_TIME_NS
);

our @DUCKDB_RESULT_TYPES = qw(
    DUCKDB_RESULT_TYPE_INVALID
    DUCKDB_RESULT_TYPE_CHANGED_ROWS
    DUCKDB_RESULT_TYPE_NOTHING
    DUCKDB_RESULT_TYPE_QUERY_RESULT
);

our @EXPORT = (@DUCKDB_TYPES, @DUCKDB_RESULT_TYPES);

our %EXPORT_TAGS = (all => \@EXPORT, duckdb_types => \@DUCKDB_TYPES, duckdb_result_types => \@DUCKDB_RESULT_TYPES);

# enum duckdb_type
use constant {
    DUCKDB_TYPE_INVALID         => 0,
    DUCKDB_TYPE_BOOLEAN         => 1,     # bool
    DUCKDB_TYPE_TINYINT         => 2,     # int8_t
    DUCKDB_TYPE_SMALLINT        => 3,     # int16_t
    DUCKDB_TYPE_INTEGER         => 4,     # int32_t
    DUCKDB_TYPE_BIGINT          => 5,     # int64_t
    DUCKDB_TYPE_UTINYINT        => 6,     # uint8_t
    DUCKDB_TYPE_USMALLINT       => 7,     # uint16_t
    DUCKDB_TYPE_UINTEGER        => 8,     # uint32_t
    DUCKDB_TYPE_UBIGINT         => 9,     # uint64_t
    DUCKDB_TYPE_FLOAT           => 10,    # float
    DUCKDB_TYPE_DOUBLE          => 11,    # double
    DUCKDB_TYPE_TIMESTAMP       => 12,    # duckdb_timestamp (microseconds)
    DUCKDB_TYPE_DATE            => 13,    # duckdb_date
    DUCKDB_TYPE_TIME            => 14,    # duckdb_time
    DUCKDB_TYPE_INTERVAL        => 15,    # duckdb_interval
    DUCKDB_TYPE_HUGEINT         => 16,    # duckdb_hugeint
    DUCKDB_TYPE_VARCHAR         => 17,    # const char*
    DUCKDB_TYPE_BLOB            => 18,    # duckdb_blob
    DUCKDB_TYPE_DECIMAL         => 19,    # duckdb_decimal
    DUCKDB_TYPE_TIMESTAMP_S     => 20,    # duckdb_timestamp_s (seconds)
    DUCKDB_TYPE_TIMESTAMP_MS    => 21,    # duckdb_timestamp_ms (milliseconds)
    DUCKDB_TYPE_TIMESTAMP_NS    => 22,    # duckdb_timestamp_ns (nanoseconds)
    DUCKDB_TYPE_ENUM            => 23,    # enum type, only useful as logical type
    DUCKDB_TYPE_LIST            => 24,    # list type, only useful as logical type
    DUCKDB_TYPE_STRUCT          => 25,    # struct type, only useful as logical type
    DUCKDB_TYPE_MAP             => 26,    # map type, only useful as logical type
    DUCKDB_TYPE_UUID            => 27,    # duckdb_hugeint
    DUCKDB_TYPE_UNION           => 28,    # union type, only useful as logical type
    DUCKDB_TYPE_BIT             => 29,    # duckdb_bit
    DUCKDB_TYPE_TIME_TZ         => 30,    # duckdb_time_tz
    DUCKDB_TYPE_TIMESTAMP_TZ    => 31,    # duckdb_timestamp (microseconds)
    DUCKDB_TYPE_UHUGEINT        => 32,    # duckdb_uhugeint
    DUCKDB_TYPE_ARRAY           => 33,    # duckdb_array, only useful as logical type
    DUCKDB_TYPE_ANY             => 34,    # enum type, only useful as logical type
    DUCKDB_TYPE_BIGNUM          => 35,    # duckdb_bignum
    DUCKDB_TYPE_SQLNULL         => 36,    # enum type, only useful as logical type
    DUCKDB_TYPE_STRING_LITERAL  => 37,    # enum type, only useful as logical type
    DUCKDB_TYPE_INTEGER_LITERAL => 38,    # enum type, only useful as logical type
    DUCKDB_TYPE_TIME_NS         => 39,    # duckdb_time_ns (nanoseconds)
};

# enum duckdb_result_type
use constant {
    DUCKDB_RESULT_TYPE_INVALID      => 0,
    DUCKDB_RESULT_TYPE_CHANGED_ROWS => 1,
    DUCKDB_RESULT_TYPE_NOTHING      => 2,
    DUCKDB_RESULT_TYPE_QUERY_RESULT => 3,
};

my $_i = 0;
our %DUCKDB_TYPE_IDS = map { $_i++ => $_ } @DUCKDB_TYPES;

sub DUCKDB_TYPE { $DUCKDB_TYPE_IDS{$_[1]} }


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBD::DuckDB::Constants - Constants for DuckDB

    use DBI;
    use DBD::DuckDB::Constants qw(:duckdb_types);

=head1 CONSTANTS

=head2 :duckdb_types

=over

=item DUCKDB_TYPE_INVALID

=item DUCKDB_TYPE_BOOLEAN

=item DUCKDB_TYPE_TINYINT

=item DUCKDB_TYPE_SMALLINT

=item DUCKDB_TYPE_INTEGER

=item DUCKDB_TYPE_BIGINT

=item DUCKDB_TYPE_UTINYINT

=item DUCKDB_TYPE_USMALLINT

=item DUCKDB_TYPE_UINTEGER

=item DUCKDB_TYPE_UBIGINT

=item DUCKDB_TYPE_FLOAT

=item DUCKDB_TYPE_DOUBLE

=item DUCKDB_TYPE_TIMESTAMP

=item DUCKDB_TYPE_DATE

=item DUCKDB_TYPE_TIME

=item DUCKDB_TYPE_INTERVAL

=item DUCKDB_TYPE_HUGEINT

=item DUCKDB_TYPE_UHUGEINT

=item DUCKDB_TYPE_VARCHAR

=item DUCKDB_TYPE_BLOB

=item DUCKDB_TYPE_DECIMAL

=item DUCKDB_TYPE_TIMESTAMP_S

=item DUCKDB_TYPE_TIMESTAMP_MS

=item DUCKDB_TYPE_TIMESTAMP_NS

=item DUCKDB_TYPE_ENUM

=item DUCKDB_TYPE_LIST

=item DUCKDB_TYPE_STRUCT

=item DUCKDB_TYPE_MAP

=item DUCKDB_TYPE_ARRAY

=item DUCKDB_TYPE_UUID

=item DUCKDB_TYPE_UNION

=item DUCKDB_TYPE_BIT

=item DUCKDB_TYPE_TIME_TZ

=item DUCKDB_TYPE_TIMESTAMP_TZ

=item DUCKDB_TYPE_ANY

=item DUCKDB_TYPE_BIGNUM

=item DUCKDB_TYPE_SQLNULL

=item DUCKDB_TYPE_STRING_LITERAL

=item DUCKDB_TYPE_INTEGER_LITERAL

=item DUCKDB_TYPE_TIME_NS

=back

=head2 :duckdb_result_types

=over

=item DUCKDB_RESULT_TYPE_INVALID

=item DUCKDB_RESULT_TYPE_CHANGED_ROWS

=item DUCKDB_RESULT_TYPE_NOTHING

=item DUCKDB_RESULT_TYPE_QUERY_RESULT

=back


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
