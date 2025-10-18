package DBD::DuckDB::FFI;

use strict;
use warnings;
use v5.10;

use FFI::Platypus 2.00;
use FFI::CheckLib qw(find_lib_or_die);

use Exporter 'import';

our @EXPORT_OK = qw(
    duckdb_append_blob
    duckdb_append_bool
    duckdb_append_date
    duckdb_append_double
    duckdb_append_float
    duckdb_append_hugeint
    duckdb_append_int16
    duckdb_append_int32
    duckdb_append_int64
    duckdb_append_int8
    duckdb_append_interval
    duckdb_append_null
    duckdb_append_time
    duckdb_append_timestamp
    duckdb_append_uhugeint
    duckdb_append_uint16
    duckdb_append_uint32
    duckdb_append_uint64
    duckdb_append_uint8
    duckdb_append_varchar
    duckdb_appender_begin_row
    duckdb_appender_close
    duckdb_appender_create
    duckdb_appender_destroy
    duckdb_appender_end_row
    duckdb_appender_error
    duckdb_appender_flush
    duckdb_array_type_array_size
    duckdb_array_type_child_type
    duckdb_array_vector_get_child
    duckdb_bind_blob
    duckdb_bind_boolean
    duckdb_bind_date
    duckdb_bind_decimal
    duckdb_bind_double
    duckdb_bind_float
    duckdb_bind_hugeint
    duckdb_bind_int16
    duckdb_bind_int32
    duckdb_bind_int64
    duckdb_bind_int8
    duckdb_bind_interval
    duckdb_bind_null
    duckdb_bind_time
    duckdb_bind_timestamp
    duckdb_bind_timestamp_tz
    duckdb_bind_uhugeint
    duckdb_bind_uint16
    duckdb_bind_uint32
    duckdb_bind_uint64
    duckdb_bind_uint8
    duckdb_bind_value
    duckdb_bind_varchar
    duckdb_close
    duckdb_column_count
    duckdb_column_logical_type
    duckdb_column_name
    duckdb_column_type
    duckdb_connect
    duckdb_data_chunk_get_size
    duckdb_data_chunk_get_vector
    duckdb_decimal_internal_type
    duckdb_decimal_scale
    duckdb_decimal_width
    duckdb_destroy_data_chunk
    duckdb_destroy_logical_type
    duckdb_destroy_prepare
    duckdb_destroy_result
    duckdb_disconnect
    duckdb_execute_prepared
    duckdb_fetch_chunk
    duckdb_free
    duckdb_get_type_id
    duckdb_library_version
    duckdb_list_type_child_type
    duckdb_list_vector_get_child
    duckdb_map_type_key_type
    duckdb_map_type_value_type
    duckdb_open
    duckdb_prepare
    duckdb_prepare_error
    duckdb_query
    duckdb_result_error
    duckdb_result_return_type
    duckdb_row_count
    duckdb_rows_changed
    duckdb_struct_type_child_count
    duckdb_struct_type_child_name
    duckdb_struct_type_child_type
    duckdb_struct_vector_get_child
    duckdb_union_type_member_count
    duckdb_union_type_member_type
    duckdb_validity_row_is_valid
    duckdb_vector_get_column_type
    duckdb_vector_get_data
    duckdb_vector_get_validity
);

our %EXPORT_TAGS = (all => [@EXPORT_OK]);

state $ffi = FFI::Platypus->new(api => 2, lib => find_lib_or_die(lib => 'duckdb', alien => 'Alien::DuckDB'));

sub init {

    $ffi->type(int     => 'duckdb_result_type');
    $ffi->type(int     => 'duckdb_state');
    $ffi->type(int     => 'duckdb_type');
    $ffi->type(int     => 'idx_t');
    $ffi->type(int32_t => 'duckdb_date');
    $ffi->type(int64_t => 'duckdb_time');
    $ffi->type(int64_t => 'duckdb_timestamp');
    $ffi->type(opaque  => 'duckdb_appender');
    $ffi->type(opaque  => 'duckdb_connection');
    $ffi->type(opaque  => 'duckdb_data_chunk');
    $ffi->type(opaque  => 'duckdb_database');
    $ffi->type(opaque  => 'duckdb_error_data');
    $ffi->type(opaque  => 'duckdb_logical_type');
    $ffi->type(opaque  => 'duckdb_prepared_statement');
    $ffi->type(opaque  => 'duckdb_value');
    $ffi->type(opaque  => 'duckdb_vector');

    # TODO  Use record for duckdb_time, duckdb_date and duckdb_timestamp ???

    $ffi->type('record(DBD::DuckDB::FFI::Decimal)'  => 'duckdb_decimal');
    $ffi->type('record(DBD::DuckDB::FFI::HugeInt)'  => 'duckdb_hugeint');
    $ffi->type('record(DBD::DuckDB::FFI::Interval)' => 'duckdb_interval');
    $ffi->type('record(DBD::DuckDB::FFI::Result)'   => 'duckdb_result');
    $ffi->type('record(DBD::DuckDB::FFI::uHugeInt)' => 'duckdb_uhugeint');

    # Open Connect
    $ffi->attach(duckdb_close           => ['duckdb_database*']                      => 'void');
    $ffi->attach(duckdb_connect         => ['duckdb_database', 'duckdb_connection*'] => 'duckdb_state');
    $ffi->attach(duckdb_disconnect      => ['duckdb_connection*']                    => 'void');
    $ffi->attach(duckdb_library_version => []                                        => 'string');
    $ffi->attach(duckdb_open            => ['string', 'duckdb_database*']            => 'duckdb_state');

    # Query Execution
    $ffi->attach(duckdb_column_count        => ['duckdb_result*']          => 'idx_t');
    $ffi->attach(duckdb_column_logical_type => ['duckdb_result*', 'idx_t'] => 'duckdb_logical_type');
    $ffi->attach(duckdb_column_name         => ['duckdb_result*', 'idx_t'] => 'string');
    $ffi->attach(duckdb_column_type         => ['duckdb_result*', 'idx_t'] => 'duckdb_type');
    $ffi->attach(duckdb_destroy_result      => ['duckdb_result*']          => 'void');
    $ffi->attach(duckdb_query               => ['duckdb_connection', 'string', 'duckdb_result*'] => 'duckdb_state');
    $ffi->attach(duckdb_result_error        => ['duckdb_result*']                                => 'string');
    $ffi->attach(duckdb_row_count           => ['duckdb_result*']                                => 'idx_t');
    $ffi->attach(duckdb_rows_changed        => ['duckdb_result*']                                => 'idx_t');

    # Prepared Statements
    $ffi->attach(duckdb_prepare => ['duckdb_connection', 'string', 'duckdb_prepared_statement*'] => 'duckdb_state');
    $ffi->attach(duckdb_prepare_error   => ['duckdb_prepared_statement']                         => 'string');
    $ffi->attach(duckdb_destroy_prepare => ['duckdb_prepared_statement*']                        => 'void');

    # Bind Values to Prepared Statements
    $ffi->attach(duckdb_bind_blob      => ['duckdb_prepared_statement', 'idx_t', 'opaque', 'idx_t'] => 'duckdb_state');
    $ffi->attach(duckdb_bind_boolean   => ['duckdb_prepared_statement', 'idx_t', 'bool']            => 'duckdb_state');
    $ffi->attach(duckdb_bind_date      => ['duckdb_prepared_statement', 'idx_t', 'duckdb_date']     => 'duckdb_state');
    $ffi->attach(duckdb_bind_decimal   => ['duckdb_prepared_statement', 'idx_t', 'duckdb_decimal']  => 'duckdb_state');
    $ffi->attach(duckdb_bind_double    => ['duckdb_prepared_statement', 'idx_t', 'double']          => 'duckdb_state');
    $ffi->attach(duckdb_bind_float     => ['duckdb_prepared_statement', 'idx_t', 'float']           => 'duckdb_state');
    $ffi->attach(duckdb_bind_hugeint   => ['duckdb_prepared_statement', 'idx_t', 'duckdb_hugeint']  => 'duckdb_state');
    $ffi->attach(duckdb_bind_int16     => ['duckdb_prepared_statement', 'idx_t', 'int16_t']         => 'duckdb_state');
    $ffi->attach(duckdb_bind_int32     => ['duckdb_prepared_statement', 'idx_t', 'int32_t']         => 'duckdb_state');
    $ffi->attach(duckdb_bind_int64     => ['duckdb_prepared_statement', 'idx_t', 'int64_t']         => 'duckdb_state');
    $ffi->attach(duckdb_bind_int8      => ['duckdb_prepared_statement', 'idx_t', 'int8_t']          => 'duckdb_state');
    $ffi->attach(duckdb_bind_interval  => ['duckdb_prepared_statement', 'idx_t', 'duckdb_interval'] => 'duckdb_state');
    $ffi->attach(duckdb_bind_null      => ['duckdb_prepared_statement', 'idx_t']                     => 'duckdb_state');
    $ffi->attach(duckdb_bind_time      => ['duckdb_prepared_statement', 'idx_t', 'duckdb_time']      => 'duckdb_state');
    $ffi->attach(duckdb_bind_timestamp => ['duckdb_prepared_statement', 'idx_t', 'duckdb_timestamp'] => 'duckdb_state');
    $ffi->attach(duckdb_bind_timestamp_tz => [qw(duckdb_prepared_statement idx_t duckdb_timestamp)]  => 'duckdb_state');
    $ffi->attach(duckdb_bind_uhugeint => ['duckdb_prepared_statement', 'idx_t', 'duckdb_uhugeint'] => 'duckdb_state');
    $ffi->attach(duckdb_bind_uint16   => ['duckdb_prepared_statement', 'idx_t', 'uint16_t']        => 'duckdb_state');
    $ffi->attach(duckdb_bind_uint32   => ['duckdb_prepared_statement', 'idx_t', 'uint32_t']        => 'duckdb_state');
    $ffi->attach(duckdb_bind_uint64   => ['duckdb_prepared_statement', 'idx_t', 'uint64_t']        => 'duckdb_state');
    $ffi->attach(duckdb_bind_uint8    => ['duckdb_prepared_statement', 'idx_t', 'uint8_t']         => 'duckdb_state');
    $ffi->attach(duckdb_bind_value    => ['duckdb_prepared_statement', 'idx_t', 'duckdb_value']    => 'duckdb_state');
    $ffi->attach(duckdb_bind_varchar  => ['duckdb_prepared_statement', 'idx_t', 'string']          => 'duckdb_state');

    # Execute Prepared Statements
    $ffi->attach('duckdb_execute_prepared' => ['duckdb_prepared_statement', 'duckdb_result*'] => 'duckdb_state');

    # Result Functions
    $ffi->attach(duckdb_fetch_chunk        => ['duckdb_result'] => 'duckdb_data_chunk');
    $ffi->attach(duckdb_result_return_type => ['duckdb_result'] => 'duckdb_result_type');

    # Helpers
    $ffi->attach(duckdb_free => ['opaque'] => 'void');

    # Validity Mask Functions
    $ffi->attach(duckdb_validity_row_is_valid => ['uint64_t', 'idx_t'] => 'bool');

    # Logical Type Interface
    $ffi->attach(duckdb_array_type_array_size   => ['duckdb_logical_type']          => 'idx_t');
    $ffi->attach(duckdb_array_type_child_type   => ['duckdb_logical_type']          => 'duckdb_logical_type');
    $ffi->attach(duckdb_decimal_internal_type   => ['duckdb_logical_type']          => 'duckdb_type');
    $ffi->attach(duckdb_decimal_scale           => ['duckdb_logical_type']          => 'uint8_t');
    $ffi->attach(duckdb_decimal_width           => ['duckdb_logical_type']          => 'uint8_t');
    $ffi->attach(duckdb_destroy_logical_type    => ['duckdb_logical_type*']         => 'void');
    $ffi->attach(duckdb_get_type_id             => ['duckdb_logical_type']          => 'duckdb_type');
    $ffi->attach(duckdb_list_type_child_type    => ['duckdb_logical_type', 'idx_t'] => 'duckdb_logical_type');
    $ffi->attach(duckdb_map_type_key_type       => ['duckdb_logical_type']          => 'duckdb_logical_type');
    $ffi->attach(duckdb_map_type_value_type     => ['duckdb_logical_type']          => 'duckdb_logical_type');
    $ffi->attach(duckdb_struct_type_child_count => ['duckdb_logical_type']          => 'idx_t');
    $ffi->attach(duckdb_struct_type_child_name  => ['duckdb_logical_type', 'idx_t'] => 'string');
    $ffi->attach(duckdb_struct_type_child_type  => ['duckdb_logical_type', 'idx_t'] => 'duckdb_logical_type');
    $ffi->attach(duckdb_union_type_member_count => ['duckdb_logical_type']          => 'idx_t');
    $ffi->attach(duckdb_union_type_member_type  => ['duckdb_logical_type', 'idx_t'] => 'duckdb_logical_type');

    # Data Chunk Interface
    $ffi->attach(duckdb_data_chunk_get_size   => ['duckdb_data_chunk']          => 'idx_t');
    $ffi->attach(duckdb_data_chunk_get_vector => ['duckdb_data_chunk', 'idx_t'] => 'opaque');
    $ffi->attach(duckdb_destroy_data_chunk    => ['duckdb_data_chunk*']         => 'void');

    # Vector Interface
    $ffi->attach(duckdb_array_vector_get_child  => ['duckdb_vector']          => 'duckdb_vector');
    $ffi->attach(duckdb_list_vector_get_child   => ['duckdb_vector']          => 'duckdb_vector');
    $ffi->attach(duckdb_struct_vector_get_child => ['duckdb_vector', 'idx_t'] => 'duckdb_vector');
    $ffi->attach(duckdb_vector_get_column_type  => ['duckdb_vector']          => 'duckdb_logical_type');
    $ffi->attach(duckdb_vector_get_data         => ['duckdb_vector']          => 'opaque');
    $ffi->attach(duckdb_vector_get_validity     => ['duckdb_vector']          => 'uint64_t');

    # Appender
    $ffi->attach(duckdb_append_blob        => ['duckdb_appender', 'opaque', 'idx_t'] => 'duckdb_state');
    $ffi->attach(duckdb_append_bool        => ['duckdb_appender', 'bool']            => 'duckdb_state');
    $ffi->attach(duckdb_append_date        => ['duckdb_appender', 'duckdb_date']     => 'duckdb_state');
    $ffi->attach(duckdb_append_double      => ['duckdb_appender', 'double']          => 'duckdb_state');
    $ffi->attach(duckdb_append_float       => ['duckdb_appender', 'float']           => 'duckdb_state');
    $ffi->attach(duckdb_append_hugeint     => ['duckdb_appender', 'duckdb_hugeint']  => 'duckdb_state');
    $ffi->attach(duckdb_append_int16       => ['duckdb_appender', 'int16_t']         => 'duckdb_state');
    $ffi->attach(duckdb_append_int32       => ['duckdb_appender', 'int32_t']         => 'duckdb_state');
    $ffi->attach(duckdb_append_int64       => ['duckdb_appender', 'int64_t']         => 'duckdb_state');
    $ffi->attach(duckdb_append_int8        => ['duckdb_appender', 'int8_t']          => 'duckdb_state');
    $ffi->attach(duckdb_append_interval    => ['duckdb_appender', 'duckdb_interval'] => 'duckdb_state');
    $ffi->attach(duckdb_append_null        => ['duckdb_appender'] => 'duckdb_state');
    $ffi->attach(duckdb_append_time        => ['duckdb_appender', 'duckdb_time']      => 'duckdb_state');
    $ffi->attach(duckdb_append_timestamp   => ['duckdb_appender', 'duckdb_timestamp'] => 'duckdb_state');
    $ffi->attach(duckdb_append_uhugeint    => ['duckdb_appender', 'duckdb_uhugeint']  => 'duckdb_state');
    $ffi->attach(duckdb_append_uint16      => ['duckdb_appender', 'uint16_t']         => 'duckdb_state');
    $ffi->attach(duckdb_append_uint32      => ['duckdb_appender', 'uint32_t']         => 'duckdb_state');
    $ffi->attach(duckdb_append_uint64      => ['duckdb_appender', 'uint64_t']         => 'duckdb_state');
    $ffi->attach(duckdb_append_uint8       => ['duckdb_appender', 'uint8_t']          => 'duckdb_state');
    $ffi->attach(duckdb_append_varchar     => ['duckdb_appender', 'string']           => 'duckdb_state');
    $ffi->attach(duckdb_appender_begin_row => ['duckdb_appender']                                    => 'duckdb_state');
    $ffi->attach(duckdb_appender_close     => ['duckdb_appender']                                    => 'duckdb_state');
    $ffi->attach(duckdb_appender_create    => [qw(duckdb_connection string string duckdb_appender*)] => 'duckdb_state');
    $ffi->attach(duckdb_appender_destroy   => ['duckdb_appender*']                                   => 'duckdb_state');
    $ffi->attach(duckdb_appender_end_row   => ['duckdb_appender']                                    => 'duckdb_state');
    $ffi->attach(duckdb_appender_error     => ['duckdb_appender']                                    => 'string');
    $ffi->attach(duckdb_appender_flush     => ['duckdb_appender']                                    => 'duckdb_state');

    return 1;

}


package    # hide from PAUSE
    DBD::DuckDB::FFI::Result {

    use strict;
    use warnings;
    use FFI::Platypus::Record qw(record_layout_1);

    # C struct (ABI v1.4):
    # //! A query result consists of a pointer to its internal data.
    # //! Must be freed with 'duckdb_destroy_result'.
    # typedef struct {
    #     // Deprecated, use `duckdb_column_count`.
    #     idx_t deprecated_column_count;
    #     // Deprecated, use `duckdb_row_count`.
    #     idx_t deprecated_row_count;
    #     // Deprecated, use `duckdb_rows_changed`.
    #     idx_t deprecated_rows_changed;
    #     // Deprecated, use `duckdb_column_*`-family of functions.
    #     duckdb_column *deprecated_columns;
    #     // Deprecated, use `duckdb_result_error`.
    #     char *deprecated_error_message;
    #     void *internal_data;
    # } duckdb_result;
    record_layout_1(
        size_t => 'deprecated_column_count',
        size_t => 'deprecated_row_count',
        size_t => 'deprecated_rows_changed',
        opaque => 'deprecated_columns',
        opaque => 'deprecated_error_message',
        opaque => 'internal_data',
    );

}


package    # hide from PAUSE
    DBD::DuckDB::FFI::HugeInt {

    use strict;
    use warnings;
    use FFI::Platypus::Record qw(record_layout_1);

    # C struct (ABI v1.4):
    # //! HUGEINT is composed of a lower and upper component.
    # //! Its value is upper * 2^64 + lower.
    # //! For simplified usage, use `duckdb_hugeint_to_double` and `duckdb_double_to_hugeint`.
    # typedef struct {
    #     uint64_t lower;
    #     int64_t upper;
    # } duckdb_hugeint;
    record_layout_1(uint64_t => 'lower', int64_t => 'upper');

}

package    # hide from PAUSE
    DBD::DuckDB::FFI::uHugeInt {

    use strict;
    use warnings;
    use FFI::Platypus::Record qw(record_layout_1);

    # C struct (ABI v1.4):
    # //! UHUGEINT is composed of a lower and upper component.
    # //! Its value is upper * 2^64 + lower.
    # //! For simplified usage, use `duckdb_uhugeint_to_double` and `duckdb_double_to_uhugeint`.
    # typedef struct {
    #     uint64_t lower;
    #     uint64_t upper;
    # } duckdb_uhugeint;
    record_layout_1(uint64_t => 'lower', uint64_t => 'upper');

}

package    # hide from PAUSE
    DBD::DuckDB::FFI::Interval {

    use strict;
    use warnings;
    use FFI::Platypus::Record qw(record_layout_1);

    # C struct (ABI v1.4):
    # //! INTERVAL is stored in months, days, and micros.
    # typedef struct {
    #     int32_t months;
    #     int32_t days;
    #     int64_t micros;
    # } duckdb_interval;
    record_layout_1(int32_t => 'months', int32_t => 'days', int64_t => 'micros');

}

package    # hide from PAUSE
    DBD::DuckDB::FFI::Decimal {

    use strict;
    use warnings;
    use FFI::Platypus::Record qw(record_layout_1);

    # C struct (ABI v1.4):
    # //! DECIMAL is composed of a width and a scale.
    # //! Their value is stored in a HUGEINT.
    # typedef struct {
    #     uint8_t width;
    #     uint8_t scale;
    #     duckdb_hugeint value;
    # } duckdb_decimal;
    record_layout_1(uint8_t => 'width', uint8_t => 'scale', opaque => 'value');

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBD::DuckDB::FFI - DuckDB C functions

    use DBD::DuckDB::FFI qw(:all);

    say duckdb_library_version();

=head1 DESCRIPTION

L<DBD::DuckDB> use L<FFI::Platypus> for access to C<libduckdb> C library.

=head1 FUNCTIONS

=head2 Open Connect

=over

=item duckdb_close

=item duckdb_connect

=item duckdb_disconnect

=item duckdb_library_version

=item duckdb_open

=back

=head2 Query Execution

=over

=item duckdb_column_count

=item duckdb_column_logical_type

=item duckdb_column_name

=item duckdb_column_type

=item duckdb_destroy_result

=item duckdb_query

=item duckdb_result_error

=item duckdb_row_count

=item duckdb_rows_changed

=back

=head2 Prepared Statements

=over

=item duckdb_prepare

=item duckdb_prepare_error

=item duckdb_destroy_prepare

=back

=head2 Bind Values to Prepared Statements

=over

=item duckdb_bind_blob

=item duckdb_bind_boolean

=item duckdb_bind_date

=item duckdb_bind_decimal

=item duckdb_bind_double

=item duckdb_bind_float

=item duckdb_bind_hugeint

=item duckdb_bind_int16

=item duckdb_bind_int32

=item duckdb_bind_int64

=item duckdb_bind_int8

=item duckdb_bind_interval

=item duckdb_bind_null

=item duckdb_bind_time

=item duckdb_bind_timestamp

=item duckdb_bind_timestamp_tz

=item duckdb_bind_uhugeint

=item duckdb_bind_uint16

=item duckdb_bind_uint32

=item duckdb_bind_uint64

=item duckdb_bind_uint8

=item duckdb_bind_value

=item duckdb_bind_varchar

=back

=head2 Execute Prepared Statements

=over

=item duckdb_execute_prepared

=back

=head2 Result Functions

=over

=item duckdb_fetch_chunk

=item duckdb_result_return_type

=back

=head2 Helpers

=over

=item duckdb_free

=back

=head2 Validity Mask Functions

=over

=item duckdb_validity_row_is_valid

=back

=head2 Logical Type Interface

=over

=item duckdb_array_type_array_size

=item duckdb_array_type_child_type

=item duckdb_destroy_logical_type

=item duckdb_get_type_id

=item duckdb_decimal_internal_type

=item duckdb_decimal_scale

=item duckdb_decimal_width

=item duckdb_list_type_child_type

=item duckdb_map_type_key_type

=item duckdb_map_type_value_type

=item duckdb_struct_type_child_count

=item duckdb_struct_type_child_name

=item duckdb_struct_type_child_type

=item duckdb_union_type_member_count

=item duckdb_union_type_member_type

=back

=head2 Data Chunk Interface

=over

=item duckdb_data_chunk_get_size

=item duckdb_data_chunk_get_vector

=item duckdb_destroy_data_chunk

=back

=head2 Vector Interface

=over

=item duckdb_array_vector_get_child

=item duckdb_list_vector_get_child

=item duckdb_struct_vector_get_child

=item duckdb_vector_get_column_type

=item duckdb_vector_get_data

=item duckdb_vector_get_validity

=back

=head2 Appender

=over

=item duckdb_append_blob

=item duckdb_append_bool

=item duckdb_append_date

=item duckdb_append_double

=item duckdb_append_float

=item duckdb_append_hugeint

=item duckdb_append_int16

=item duckdb_append_int32

=item duckdb_append_int64

=item duckdb_append_int8

=item duckdb_append_interval

=item duckdb_append_null

=item duckdb_append_time

=item duckdb_append_timestamp

=item duckdb_append_uhugeint

=item duckdb_append_uint16

=item duckdb_append_uint32

=item duckdb_append_uint64

=item duckdb_append_uint8

=item duckdb_append_varchar

=item duckdb_appender_begin_row

=item duckdb_appender_close

=item duckdb_appender_create

=item duckdb_appender_destroy

=item duckdb_appender_end_row

=item duckdb_appender_error

=item duckdb_appender_flush

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
