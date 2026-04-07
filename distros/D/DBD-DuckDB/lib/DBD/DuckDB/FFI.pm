package DBD::DuckDB::FFI;

use strict;
use warnings;
use v5.10;

use FFI::Platypus 2.00;
use FFI::CheckLib qw(find_lib_or_die);

use Exporter 'import';

#<<<
my %DUCKDB_FUNCTIONS = (

    # Open Connect

    duckdb_create_instance_cache => [[] => 'duckdb_instance_cache'],
    duckdb_get_or_create_from_cache => [['duckdb_instance_cache', 'string', 'duckdb_database*', 'duckdb_config', 'string*'] => 'duckdb_state'],
    duckdb_destroy_instance_cache => [['duckdb_instance_cache*'] => 'void'],
    duckdb_open => [['string', 'duckdb_database*'] => 'duckdb_state'],
    duckdb_open_ext => [['string', 'duckdb_database*', 'duckdb_config', 'string*'] => 'duckdb_state'],
    duckdb_close => [['duckdb_database*'] => 'void'],
    duckdb_connect => [['duckdb_database', 'duckdb_connection*'] => 'duckdb_state'],
    duckdb_interrupt => [['duckdb_connection'] => 'void'],
    duckdb_query_progress => [['duckdb_connection'] => 'duckdb_query_progress_type'],
    duckdb_disconnect => [['duckdb_connection*'] => 'void'],
    duckdb_connection_get_client_context => [['duckdb_connection', 'duckdb_client_context*'] => 'void'],
    duckdb_connection_get_arrow_options => [['duckdb_connection', 'duckdb_arrow_options*'] => 'void'],
    duckdb_client_context_get_connection_id => [['duckdb_client_context'] => 'idx_t'],
    duckdb_destroy_client_context => [['duckdb_client_context*'] => 'void'],
    duckdb_destroy_arrow_options => [['duckdb_arrow_options*'] => 'void'],
    duckdb_library_version => [[] => 'string'],
    duckdb_get_table_names => [['duckdb_connection', 'string', 'bool'] => 'duckdb_value'],

    # Configuration

    duckdb_create_config => [['duckdb_config*'] => 'duckdb_state'],
    duckdb_config_count => [[] => 'size_t'],
    duckdb_get_config_flag => [['size_t', 'string*', 'string*'] => 'duckdb_state'],
    duckdb_set_config => [['duckdb_config', 'string', 'string'] => 'duckdb_state'],
    duckdb_destroy_config => [['duckdb_config*'] => 'void'],

    # Error Data

    duckdb_create_error_data => [['duckdb_error_type', 'string'] => 'duckdb_error_data'],
    duckdb_destroy_error_data => [['duckdb_error_data*'] => 'void'],
    duckdb_error_data_error_type => [['duckdb_error_data'] => 'duckdb_error_type'],
    duckdb_error_data_message => [['duckdb_error_data'] => 'string'],
    duckdb_error_data_has_error => [['duckdb_error_data'] => 'bool'],

    # Query Execution

    duckdb_query => [['duckdb_connection', 'string', 'duckdb_result*'] => 'duckdb_state'],
    duckdb_destroy_result => [['duckdb_result*'] => 'void'],
    duckdb_column_name => [['duckdb_result*', 'idx_t'] => 'string'],
    duckdb_column_type => [['duckdb_result*', 'idx_t'] => 'duckdb_type'],
    duckdb_result_statement_type => [['duckdb_result'] => 'duckdb_statement_type'],
    duckdb_column_logical_type => [['duckdb_result*', 'idx_t'] => 'duckdb_logical_type'],
    duckdb_result_get_arrow_options => [['duckdb_result*'] => 'duckdb_arrow_options'],
    duckdb_column_count => [['duckdb_result*'] => 'idx_t'],
    duckdb_row_count => [['duckdb_result*'] => 'idx_t'],
    duckdb_rows_changed => [['duckdb_result*'] => 'idx_t'],
    duckdb_column_data => [['duckdb_result*', 'idx_t'] => 'opaque'], # DEPRECATED
    duckdb_nullmask_data => [['duckdb_result*', 'idx_t'] => 'opaque'], # DEPRECATED
    duckdb_result_error => [['duckdb_result*'] => 'string'],
    duckdb_result_error_type => [['duckdb_result*'] => 'duckdb_error_type'],

    # Result Functions

    duckdb_result_get_chunk => [['duckdb_result', 'idx_t'] => 'duckdb_data_chunk'],
    duckdb_result_is_streaming => [['duckdb_result'] => 'bool'],
    duckdb_result_chunk_count => [['duckdb_result'] => 'idx_t'],
    duckdb_result_return_type => [['duckdb_result'] => 'duckdb_result_type'],

    # Safe Fetch Functions

    duckdb_value_boolean => [['duckdb_result*', 'idx_t', 'idx_t'] => 'bool'],
    duckdb_value_int8 => [['duckdb_result*', 'idx_t', 'idx_t'] => 'int8_t'],
    duckdb_value_int16 => [['duckdb_result*', 'idx_t', 'idx_t'] => 'int16_t'],
    duckdb_value_int32 => [['duckdb_result*', 'idx_t', 'idx_t'] => 'int32_t'],
    duckdb_value_int64 => [['duckdb_result*', 'idx_t', 'idx_t'] => 'int64_t'],
    duckdb_value_hugeint => [['duckdb_result*', 'idx_t', 'idx_t'] => 'duckdb_hugeint'],
    duckdb_value_uhugeint => [['duckdb_result*', 'idx_t', 'idx_t'] => 'duckdb_uhugeint'],
    duckdb_value_decimal => [['duckdb_result*', 'idx_t', 'idx_t'] => 'duckdb_decimal'],
    duckdb_value_uint8 => [['duckdb_result*', 'idx_t', 'idx_t'] => 'uint8_t'],
    duckdb_value_uint16 => [['duckdb_result*', 'idx_t', 'idx_t'] => 'uint16_t'],
    duckdb_value_uint32 => [['duckdb_result*', 'idx_t', 'idx_t'] => 'uint32_t'],
    duckdb_value_uint64 => [['duckdb_result*', 'idx_t', 'idx_t'] => 'uint64_t'],
    duckdb_value_float => [['duckdb_result*', 'idx_t', 'idx_t'] => 'float'],
    duckdb_value_double => [['duckdb_result*', 'idx_t', 'idx_t'] => 'double'],
    duckdb_value_date => [['duckdb_result*', 'idx_t', 'idx_t'] => 'duckdb_date'],
    duckdb_value_time => [['duckdb_result*', 'idx_t', 'idx_t'] => 'duckdb_time'],
    duckdb_value_timestamp => [['duckdb_result*', 'idx_t', 'idx_t'] => 'duckdb_timestamp'],
    duckdb_value_interval => [['duckdb_result*', 'idx_t', 'idx_t'] => 'duckdb_interval'],
    duckdb_value_varchar => [['duckdb_result*', 'idx_t', 'idx_t'] => 'string'], # DEPRECATED
    duckdb_value_string => [['duckdb_result*', 'idx_t', 'idx_t'] => 'duckdb_string'],
    duckdb_value_varchar_internal => [['duckdb_result*', 'idx_t', 'idx_t'] => 'string'], # DEPRECATED
    duckdb_value_string_internal => [['duckdb_result*', 'idx_t', 'idx_t'] => 'duckdb_string'], # DEPRECATED
    duckdb_value_blob => [['duckdb_result*', 'idx_t', 'idx_t'] => 'duckdb_blob'],
    duckdb_value_is_null => [['duckdb_result*', 'idx_t', 'idx_t'] => 'bool'],

    # Helpers

    duckdb_malloc => [['size_t'] => 'opaque'],
    duckdb_free => [['opaque'] => 'void'],
    duckdb_vector_size => [[] => 'idx_t'],
    duckdb_string_is_inlined => [['duckdb_string_t'] => 'bool'],
    duckdb_string_t_length => [['duckdb_string_t'] => 'uint32_t'],
    duckdb_string_t_data => [['duckdb_string_t*'] => 'string'],

    # Date Time Timestamp Helpers

    duckdb_from_date => [['duckdb_date'] => 'duckdb_date_struct'],
    duckdb_to_date => [['duckdb_date_struct'] => 'duckdb_date'],
    duckdb_is_finite_date => [['duckdb_date'] => 'bool'],
    duckdb_from_time => [['duckdb_time'] => 'duckdb_time_struct'],
    duckdb_create_time_tz => [['int64_t', 'int32_t'] => 'duckdb_time_tz'],
    duckdb_from_time_tz => [['duckdb_time_tz'] => 'duckdb_time_tz_struct'],
    duckdb_to_time => [['duckdb_time_struct'] => 'duckdb_time'],
    duckdb_from_timestamp => [['duckdb_timestamp'] => 'duckdb_timestamp_struct'],
    duckdb_to_timestamp => [['duckdb_timestamp_struct'] => 'duckdb_timestamp'],
    duckdb_is_finite_timestamp => [['duckdb_timestamp'] => 'bool'],
    duckdb_is_finite_timestamp_s => [['duckdb_timestamp_s'] => 'bool'],
    duckdb_is_finite_timestamp_ms => [['duckdb_timestamp_ms'] => 'bool'],
    duckdb_is_finite_timestamp_ns => [['duckdb_timestamp_ns'] => 'bool'],

    # Hugeint Helpers

    duckdb_hugeint_to_double => [['duckdb_hugeint'] => 'double'],
    duckdb_double_to_hugeint => [['double'] => 'duckdb_hugeint'],

    # Unsigned Hugeint Helpers

    duckdb_uhugeint_to_double => [['duckdb_uhugeint'] => 'double'],
    duckdb_double_to_uhugeint => [['double'] => 'duckdb_uhugeint'],

    # Decimal Helpers

    duckdb_double_to_decimal => [['double', 'uint8_t', 'uint8_t'] => 'duckdb_decimal'],
    duckdb_decimal_to_double => [['duckdb_decimal'] => 'double'],

    # Prepared Statements

    duckdb_prepare => [['duckdb_connection', 'string', 'duckdb_prepared_statement*'] => 'duckdb_state'],
    duckdb_destroy_prepare => [['duckdb_prepared_statement*'] => 'void'],
    duckdb_prepare_error => [['duckdb_prepared_statement'] => 'string'],
    duckdb_nparams => [['duckdb_prepared_statement'] => 'idx_t'],
    duckdb_parameter_name => [['duckdb_prepared_statement', 'idx_t'] => 'string'],
    duckdb_param_type => [['duckdb_prepared_statement', 'idx_t'] => 'duckdb_type'],
    duckdb_param_logical_type => [['duckdb_prepared_statement', 'idx_t'] => 'duckdb_logical_type'],
    duckdb_clear_bindings => [['duckdb_prepared_statement'] => 'duckdb_state'],
    duckdb_prepared_statement_type => [['duckdb_prepared_statement'] => 'duckdb_statement_type'],
    duckdb_prepared_statement_column_count => [['duckdb_prepared_statement'] => 'idx_t'],
    duckdb_prepared_statement_column_name => [['duckdb_prepared_statement', 'idx_t'] => 'string'],
    duckdb_prepared_statement_column_logical_type => [['duckdb_prepared_statement', 'idx_t'] => 'duckdb_logical_type'],
    duckdb_prepared_statement_column_type => [['duckdb_prepared_statement', 'idx_t'] => 'duckdb_type'],

    # Bind Values to Prepared Statements

    duckdb_bind_value => [['duckdb_prepared_statement', 'idx_t', 'duckdb_value'] => 'duckdb_state'],
    duckdb_bind_parameter_index => [['duckdb_prepared_statement', 'opaque', 'string'] => 'duckdb_state'],
    duckdb_bind_boolean => [['duckdb_prepared_statement', 'idx_t', 'bool'] => 'duckdb_state'],
    duckdb_bind_int8 => [['duckdb_prepared_statement', 'idx_t', 'int8_t'] => 'duckdb_state'],
    duckdb_bind_int16 => [['duckdb_prepared_statement', 'idx_t', 'int16_t'] => 'duckdb_state'],
    duckdb_bind_int32 => [['duckdb_prepared_statement', 'idx_t', 'int32_t'] => 'duckdb_state'],
    duckdb_bind_int64 => [['duckdb_prepared_statement', 'idx_t', 'int64_t'] => 'duckdb_state'],
    duckdb_bind_hugeint => [['duckdb_prepared_statement', 'idx_t', 'duckdb_hugeint'] => 'duckdb_state'],
    duckdb_bind_uhugeint => [['duckdb_prepared_statement', 'idx_t', 'duckdb_uhugeint'] => 'duckdb_state'],
    duckdb_bind_decimal => [['duckdb_prepared_statement', 'idx_t', 'duckdb_decimal'] => 'duckdb_state'],
    duckdb_bind_uint8 => [['duckdb_prepared_statement', 'idx_t', 'uint8_t'] => 'duckdb_state'],
    duckdb_bind_uint16 => [['duckdb_prepared_statement', 'idx_t', 'uint16_t'] => 'duckdb_state'],
    duckdb_bind_uint32 => [['duckdb_prepared_statement', 'idx_t', 'uint32_t'] => 'duckdb_state'],
    duckdb_bind_uint64 => [['duckdb_prepared_statement', 'idx_t', 'uint64_t'] => 'duckdb_state'],
    duckdb_bind_float => [['duckdb_prepared_statement', 'idx_t', 'float'] => 'duckdb_state'],
    duckdb_bind_double => [['duckdb_prepared_statement', 'idx_t', 'double'] => 'duckdb_state'],
    duckdb_bind_date => [['duckdb_prepared_statement', 'idx_t', 'duckdb_date'] => 'duckdb_state'],
    duckdb_bind_time => [['duckdb_prepared_statement', 'idx_t', 'duckdb_time'] => 'duckdb_state'],
    duckdb_bind_timestamp => [['duckdb_prepared_statement', 'idx_t', 'duckdb_timestamp'] => 'duckdb_state'],
    duckdb_bind_timestamp_tz => [['duckdb_prepared_statement', 'idx_t', 'duckdb_timestamp'] => 'duckdb_state'],
    duckdb_bind_interval => [['duckdb_prepared_statement', 'idx_t', 'duckdb_interval'] => 'duckdb_state'],
    duckdb_bind_varchar => [['duckdb_prepared_statement', 'idx_t', 'string'] => 'duckdb_state'],
    duckdb_bind_varchar_length => [['duckdb_prepared_statement', 'idx_t', 'string', 'idx_t'] => 'duckdb_state'],
    duckdb_bind_blob => [['duckdb_prepared_statement', 'idx_t', 'opaque', 'idx_t'] => 'duckdb_state'],
    duckdb_bind_null => [['duckdb_prepared_statement', 'idx_t'] => 'duckdb_state'],

    # Execute Prepared Statements

    duckdb_execute_prepared => [['duckdb_prepared_statement', 'duckdb_result*'] => 'duckdb_state'],
    duckdb_execute_prepared_streaming => [['duckdb_prepared_statement', 'duckdb_result*'] => 'duckdb_state'],

    # Extract Statements

    duckdb_extract_statements => [['duckdb_connection', 'string', 'duckdb_extracted_statements*'] => 'idx_t'],
    duckdb_prepare_extracted_statement => [['duckdb_connection', 'duckdb_extracted_statements', 'idx_t', 'duckdb_prepared_statement*'] => 'duckdb_state'],
    duckdb_extract_statements_error => [['duckdb_extracted_statements'] => 'string'],
    duckdb_destroy_extracted => [['duckdb_extracted_statements*'] => 'void'],

    # Pending Result Interface

    duckdb_pending_prepared => [['duckdb_prepared_statement', 'duckdb_pending_result*'] => 'duckdb_state'],
    duckdb_pending_prepared_streaming => [['duckdb_prepared_statement', 'duckdb_pending_result*'] => 'duckdb_state'],
    duckdb_destroy_pending => [['duckdb_pending_result*'] => 'void'],
    duckdb_pending_error => [['duckdb_pending_result'] => 'string'],
    duckdb_pending_execute_task => [['duckdb_pending_result'] => 'duckdb_pending_state'],
    duckdb_pending_execute_check_state => [['duckdb_pending_result'] => 'duckdb_pending_state'],
    duckdb_execute_pending => [['duckdb_pending_result', 'duckdb_result*'] => 'duckdb_state'],
    duckdb_pending_execution_is_finished => [['duckdb_pending_state'] => 'bool'],

    # Value Interface

    duckdb_destroy_value => [['duckdb_value*'] => 'void'],
    duckdb_create_varchar => [['string'] => 'duckdb_value'],
    duckdb_create_varchar_length => [['string', 'idx_t'] => 'duckdb_value'],
    duckdb_create_bool => [['bool'] => 'duckdb_value'],
    duckdb_create_int8 => [['int8_t'] => 'duckdb_value'],
    duckdb_create_uint8 => [['uint8_t'] => 'duckdb_value'],
    duckdb_create_int16 => [['int16_t'] => 'duckdb_value'],
    duckdb_create_uint16 => [['uint16_t'] => 'duckdb_value'],
    duckdb_create_int32 => [['int32_t'] => 'duckdb_value'],
    duckdb_create_uint32 => [['uint32_t'] => 'duckdb_value'],
    duckdb_create_uint64 => [['uint64_t'] => 'duckdb_value'],
    duckdb_create_int64 => [['int64_t'] => 'duckdb_value'],
    duckdb_create_hugeint => [['duckdb_hugeint'] => 'duckdb_value'],
    duckdb_create_uhugeint => [['duckdb_uhugeint'] => 'duckdb_value'],
    duckdb_create_bignum => [['duckdb_bignum'] => 'duckdb_value'],
    duckdb_create_decimal => [['duckdb_decimal'] => 'duckdb_value'],
    duckdb_create_float => [['float'] => 'duckdb_value'],
    duckdb_create_double => [['double'] => 'duckdb_value'],
    duckdb_create_date => [['duckdb_date'] => 'duckdb_value'],
    duckdb_create_time => [['duckdb_time'] => 'duckdb_value'],
    duckdb_create_time_ns => [['duckdb_time_ns'] => 'duckdb_value'],
    duckdb_create_time_tz_value => [['duckdb_time_tz'] => 'duckdb_value'],
    duckdb_create_timestamp => [['duckdb_timestamp'] => 'duckdb_value'],
    duckdb_create_timestamp_tz => [['duckdb_timestamp'] => 'duckdb_value'],
    duckdb_create_timestamp_s => [['duckdb_timestamp_s'] => 'duckdb_value'],
    duckdb_create_timestamp_ms => [['duckdb_timestamp_ms'] => 'duckdb_value'],
    duckdb_create_timestamp_ns => [['duckdb_timestamp_ns'] => 'duckdb_value'],
    duckdb_create_interval => [['duckdb_interval'] => 'duckdb_value'],
    duckdb_create_blob => [['opaque', 'idx_t'] => 'duckdb_value'],
    duckdb_create_bit => [['duckdb_bit'] => 'duckdb_value'],
    duckdb_create_uuid => [['duckdb_uhugeint'] => 'duckdb_value'],
    duckdb_get_bool => [['duckdb_value'] => 'bool'],
    duckdb_get_int8 => [['duckdb_value'] => 'int8_t'],
    duckdb_get_uint8 => [['duckdb_value'] => 'uint8_t'],
    duckdb_get_int16 => [['duckdb_value'] => 'int16_t'],
    duckdb_get_uint16 => [['duckdb_value'] => 'uint16_t'],
    duckdb_get_int32 => [['duckdb_value'] => 'int32_t'],
    duckdb_get_uint32 => [['duckdb_value'] => 'uint32_t'],
    duckdb_get_int64 => [['duckdb_value'] => 'int64_t'],
    duckdb_get_uint64 => [['duckdb_value'] => 'uint64_t'],
    duckdb_get_hugeint => [['duckdb_value'] => 'duckdb_hugeint'],
    duckdb_get_uhugeint => [['duckdb_value'] => 'duckdb_uhugeint'],
    duckdb_get_bignum => [['duckdb_value'] => 'duckdb_bignum'],
    duckdb_get_decimal => [['duckdb_value'] => 'duckdb_decimal'],
    duckdb_get_float => [['duckdb_value'] => 'float'],
    duckdb_get_double => [['duckdb_value'] => 'double'],
    duckdb_get_date => [['duckdb_value'] => 'duckdb_date'],
    duckdb_get_time => [['duckdb_value'] => 'duckdb_time'],
    duckdb_get_time_ns => [['duckdb_value'] => 'duckdb_time_ns'],
    duckdb_get_time_tz => [['duckdb_value'] => 'duckdb_time_tz'],
    duckdb_get_timestamp => [['duckdb_value'] => 'duckdb_timestamp'],
    duckdb_get_timestamp_tz => [['duckdb_value'] => 'duckdb_timestamp'],
    duckdb_get_timestamp_s => [['duckdb_value'] => 'duckdb_timestamp_s'],
    duckdb_get_timestamp_ms => [['duckdb_value'] => 'duckdb_timestamp_ms'],
    duckdb_get_timestamp_ns => [['duckdb_value'] => 'duckdb_timestamp_ns'],
    duckdb_get_interval => [['duckdb_value'] => 'duckdb_interval'],
    duckdb_get_value_type => [['duckdb_value'] => 'duckdb_logical_type'],
    duckdb_get_blob => [['duckdb_value'] => 'duckdb_blob'],
    duckdb_get_bit => [['duckdb_value'] => 'duckdb_bit'],
    duckdb_get_uuid => [['duckdb_value'] => 'duckdb_uhugeint'],
    duckdb_get_varchar => [['duckdb_value'] => 'string'],
    duckdb_create_struct_value => [['duckdb_logical_type', 'duckdb_value*'] => 'duckdb_value'],
    duckdb_create_list_value => [['duckdb_logical_type', 'duckdb_value*', 'idx_t'] => 'duckdb_value'],
    duckdb_create_array_value => [['duckdb_logical_type', 'duckdb_value*', 'idx_t'] => 'duckdb_value'],
    duckdb_create_map_value => [['duckdb_logical_type', 'duckdb_value*', 'duckdb_value*', 'idx_t'] => 'duckdb_value'],
    duckdb_create_union_value => [['duckdb_logical_type', 'idx_t', 'duckdb_value'] => 'duckdb_value'],
    duckdb_get_map_size => [['duckdb_value'] => 'idx_t'],
    duckdb_get_map_key => [['duckdb_value', 'idx_t'] => 'duckdb_value'],
    duckdb_get_map_value => [['duckdb_value', 'idx_t'] => 'duckdb_value'],
    duckdb_is_null_value => [['duckdb_value'] => 'bool'],
    duckdb_create_null_value => [[] => 'duckdb_value'],
    duckdb_get_list_size => [['duckdb_value'] => 'idx_t'],
    duckdb_get_list_child => [['duckdb_value', 'idx_t'] => 'duckdb_value'],
    duckdb_create_enum_value => [['duckdb_logical_type', 'uint64_t'] => 'duckdb_value'],
    duckdb_get_enum_value => [['duckdb_value'] => 'uint64_t'],
    duckdb_get_struct_child => [['duckdb_value', 'idx_t'] => 'duckdb_value'],
    duckdb_value_to_string => [['duckdb_value'] => 'string'],

    # Logical Type Interface

    duckdb_create_logical_type => [['duckdb_type'] => 'duckdb_logical_type'],
    duckdb_logical_type_get_alias => [['duckdb_logical_type'] => 'string'],
    duckdb_logical_type_set_alias => [['duckdb_logical_type', 'string'] => 'void'],
    duckdb_create_list_type => [['duckdb_logical_type'] => 'duckdb_logical_type'],
    duckdb_create_array_type => [['duckdb_logical_type', 'idx_t'] => 'duckdb_logical_type'],
    duckdb_create_map_type => [['duckdb_logical_type', 'duckdb_logical_type'] => 'duckdb_logical_type'],
    duckdb_create_union_type => [['duckdb_logical_type*', 'string*', 'idx_t'] => 'duckdb_logical_type'],
    duckdb_create_struct_type => [['duckdb_logical_type*', 'string*', 'idx_t'] => 'duckdb_logical_type'],
    duckdb_create_enum_type => [['string*', 'idx_t'] => 'duckdb_logical_type'],
    duckdb_create_decimal_type => [['uint8_t', 'uint8_t'] => 'duckdb_logical_type'],
    duckdb_get_type_id => [['duckdb_logical_type'] => 'duckdb_type'],
    duckdb_decimal_width => [['duckdb_logical_type'] => 'uint8_t'],
    duckdb_decimal_scale => [['duckdb_logical_type'] => 'uint8_t'],
    duckdb_decimal_internal_type => [['duckdb_logical_type'] => 'duckdb_type'],
    duckdb_enum_internal_type => [['duckdb_logical_type'] => 'duckdb_type'],
    duckdb_enum_dictionary_size => [['duckdb_logical_type'] => 'uint32_t'],
    duckdb_enum_dictionary_value => [['duckdb_logical_type', 'idx_t'] => 'string'],
    duckdb_list_type_child_type => [['duckdb_logical_type'] => 'duckdb_logical_type'],
    duckdb_array_type_child_type => [['duckdb_logical_type'] => 'duckdb_logical_type'],
    duckdb_array_type_array_size => [['duckdb_logical_type'] => 'idx_t'],
    duckdb_map_type_key_type => [['duckdb_logical_type'] => 'duckdb_logical_type'],
    duckdb_map_type_value_type => [['duckdb_logical_type'] => 'duckdb_logical_type'],
    duckdb_struct_type_child_count => [['duckdb_logical_type'] => 'idx_t'],
    duckdb_struct_type_child_name => [['duckdb_logical_type', 'idx_t'] => 'string'],
    duckdb_struct_type_child_type => [['duckdb_logical_type', 'idx_t'] => 'duckdb_logical_type'],
    duckdb_union_type_member_count => [['duckdb_logical_type'] => 'idx_t'],
    duckdb_union_type_member_name => [['duckdb_logical_type', 'idx_t'] => 'string'],
    duckdb_union_type_member_type => [['duckdb_logical_type', 'idx_t'] => 'duckdb_logical_type'],
    duckdb_destroy_logical_type => [['duckdb_logical_type*'] => 'void'],
    duckdb_register_logical_type => [['duckdb_connection', 'duckdb_logical_type', 'duckdb_create_type_info'] => 'duckdb_state'],

    # Data Chunk Interface

    duckdb_create_data_chunk => [['duckdb_logical_type*', 'idx_t'] => 'duckdb_data_chunk'],
    duckdb_destroy_data_chunk => [['duckdb_data_chunk*'] => 'void'],
    duckdb_data_chunk_reset => [['duckdb_data_chunk'] => 'void'],
    duckdb_data_chunk_get_column_count => [['duckdb_data_chunk'] => 'idx_t'],
    duckdb_data_chunk_get_vector => [['duckdb_data_chunk', 'idx_t'] => 'duckdb_vector'],
    duckdb_data_chunk_get_size => [['duckdb_data_chunk'] => 'idx_t'],
    duckdb_data_chunk_set_size => [['duckdb_data_chunk', 'idx_t'] => 'void'],

    # Vector Interface

    duckdb_create_vector => [['duckdb_logical_type', 'idx_t'] => 'duckdb_vector'],
    duckdb_destroy_vector => [['duckdb_vector*'] => 'void'],
    duckdb_vector_get_column_type => [['duckdb_vector'] => 'duckdb_logical_type'],
    duckdb_vector_get_data => [['duckdb_vector'] => 'opaque'],
    duckdb_vector_get_validity => [['duckdb_vector'] => 'opaque'],
    duckdb_vector_ensure_validity_writable => [['duckdb_vector'] => 'void'],
    duckdb_vector_assign_string_element => [['duckdb_vector', 'idx_t', 'string'] => 'void'],
    duckdb_vector_assign_string_element_len => [['duckdb_vector', 'idx_t', 'string', 'idx_t'] => 'void'],
    duckdb_list_vector_get_child => [['duckdb_vector'] => 'duckdb_vector'],
    duckdb_list_vector_get_size => [['duckdb_vector'] => 'idx_t'],
    duckdb_list_vector_set_size => [['duckdb_vector', 'idx_t'] => 'duckdb_state'],
    duckdb_list_vector_reserve => [['duckdb_vector', 'idx_t'] => 'duckdb_state'],
    duckdb_struct_vector_get_child => [['duckdb_vector', 'idx_t'] => 'duckdb_vector'],
    duckdb_array_vector_get_child => [['duckdb_vector'] => 'duckdb_vector'],
    duckdb_slice_vector => [['duckdb_vector', 'duckdb_selection_vector', 'idx_t'] => 'void'],
    duckdb_vector_copy_sel => [['duckdb_vector', 'duckdb_vector', 'duckdb_selection_vector', 'idx_t', 'idx_t', 'idx_t'] => 'void'],
    duckdb_vector_reference_value => [['duckdb_vector', 'duckdb_value'] => 'void'],
    duckdb_vector_reference_vector => [['duckdb_vector', 'duckdb_vector'] => 'void'],

    # Validity Mask Functions

    duckdb_validity_row_is_valid => [['opaque', 'idx_t'] => 'bool'],
    duckdb_validity_set_row_validity => [['opaque', 'idx_t', 'bool'] => 'void'],
    duckdb_validity_set_row_invalid => [['opaque', 'idx_t'] => 'void'],
    duckdb_validity_set_row_valid => [['opaque', 'idx_t'] => 'void'],

    # Scalar Functions

    duckdb_create_scalar_function => [[] => 'duckdb_scalar_function'],
    duckdb_destroy_scalar_function => [['duckdb_scalar_function*'] => 'void'],
    duckdb_scalar_function_set_name => [['duckdb_scalar_function', 'string'] => 'void'],
    duckdb_scalar_function_set_varargs => [['duckdb_scalar_function', 'duckdb_logical_type'] => 'void'],
    duckdb_scalar_function_set_special_handling => [['duckdb_scalar_function'] => 'void'],
    duckdb_scalar_function_set_volatile => [['duckdb_scalar_function'] => 'void'],
    duckdb_scalar_function_add_parameter => [['duckdb_scalar_function', 'duckdb_logical_type'] => 'void'],
    duckdb_scalar_function_set_return_type => [['duckdb_scalar_function', 'duckdb_logical_type'] => 'void'],
    duckdb_scalar_function_set_extra_info => [['duckdb_scalar_function', 'opaque', 'duckdb_delete_callback_t'] => 'void'],
    duckdb_scalar_function_set_bind => [['duckdb_scalar_function', 'duckdb_scalar_function_bind_t'] => 'void'],
    duckdb_scalar_function_set_bind_data => [['duckdb_bind_info', 'opaque', 'duckdb_delete_callback_t'] => 'void'],
    duckdb_scalar_function_set_bind_data_copy => [['duckdb_bind_info', 'duckdb_copy_callback_t'] => 'void'],
    duckdb_scalar_function_bind_set_error => [['duckdb_bind_info', 'string'] => 'void'],
    duckdb_scalar_function_set_function => [['duckdb_scalar_function', 'duckdb_scalar_function_t'] => 'void'],
    duckdb_register_scalar_function => [['duckdb_connection', 'duckdb_scalar_function'] => 'duckdb_state'],
    duckdb_scalar_function_get_extra_info => [['duckdb_function_info'] => 'opaque'],
    duckdb_scalar_function_bind_get_extra_info => [['duckdb_bind_info'] => 'opaque'],
    duckdb_scalar_function_get_bind_data => [['duckdb_function_info'] => 'opaque'],
    duckdb_scalar_function_get_client_context => [['duckdb_bind_info', 'duckdb_client_context*'] => 'void'],
    duckdb_scalar_function_set_error => [['duckdb_function_info', 'string'] => 'void'],
    duckdb_create_scalar_function_set => [['string'] => 'duckdb_scalar_function_set'],
    duckdb_destroy_scalar_function_set => [['duckdb_scalar_function_set*'] => 'void'],
    duckdb_add_scalar_function_to_set => [['duckdb_scalar_function_set', 'duckdb_scalar_function'] => 'duckdb_state'],
    duckdb_register_scalar_function_set => [['duckdb_connection', 'duckdb_scalar_function_set'] => 'duckdb_state'],
    duckdb_scalar_function_bind_get_argument_count => [['duckdb_bind_info'] => 'idx_t'],
    duckdb_scalar_function_bind_get_argument => [['duckdb_bind_info', 'idx_t'] => 'duckdb_expression'],

    # Selection Vector Interface

    duckdb_create_selection_vector => [['idx_t'] => 'duckdb_selection_vector'],
    duckdb_destroy_selection_vector => [['duckdb_selection_vector'] => 'void'],
    duckdb_selection_vector_get_data_ptr => [['duckdb_selection_vector'] => 'opaque'],

    # Aggregate Functions

    duckdb_create_aggregate_function => [[] => 'duckdb_aggregate_function'],
    duckdb_destroy_aggregate_function => [['duckdb_aggregate_function*'] => 'void'],
    duckdb_aggregate_function_set_name => [['duckdb_aggregate_function', 'string'] => 'void'],
    duckdb_aggregate_function_add_parameter => [['duckdb_aggregate_function', 'duckdb_logical_type'] => 'void'],
    duckdb_aggregate_function_set_return_type => [['duckdb_aggregate_function', 'duckdb_logical_type'] => 'void'],
    duckdb_aggregate_function_set_functions => [['duckdb_aggregate_function', 'duckdb_aggregate_state_size', 'duckdb_aggregate_init_t', 'duckdb_aggregate_update_t', 'duckdb_aggregate_combine_t', 'duckdb_aggregate_finalize_t'] => 'void'],
    duckdb_aggregate_function_set_destructor => [['duckdb_aggregate_function', 'duckdb_aggregate_destroy_t'] => 'void'],
    duckdb_register_aggregate_function => [['duckdb_connection', 'duckdb_aggregate_function'] => 'duckdb_state'],
    duckdb_aggregate_function_set_special_handling => [['duckdb_aggregate_function'] => 'void'],
    duckdb_aggregate_function_set_extra_info => [['duckdb_aggregate_function', 'opaque', 'duckdb_delete_callback_t'] => 'void'],
    duckdb_aggregate_function_get_extra_info => [['duckdb_function_info'] => 'opaque'],
    duckdb_aggregate_function_set_error => [['duckdb_function_info', 'string'] => 'void'],
    duckdb_create_aggregate_function_set => [['string'] => 'duckdb_aggregate_function_set'],
    duckdb_destroy_aggregate_function_set => [['duckdb_aggregate_function_set*'] => 'void'],
    duckdb_add_aggregate_function_to_set => [['duckdb_aggregate_function_set', 'duckdb_aggregate_function'] => 'duckdb_state'],
    duckdb_register_aggregate_function_set => [['duckdb_connection', 'duckdb_aggregate_function_set'] => 'duckdb_state'],

    # Table Functions

    duckdb_create_table_function => [[] => 'duckdb_table_function'],
    duckdb_destroy_table_function => [['duckdb_table_function*'] => 'void'],
    duckdb_table_function_set_name => [['duckdb_table_function', 'string'] => 'void'],
    duckdb_table_function_add_parameter => [['duckdb_table_function', 'duckdb_logical_type'] => 'void'],
    duckdb_table_function_add_named_parameter => [['duckdb_table_function', 'string', 'duckdb_logical_type'] => 'void'],
    duckdb_table_function_set_extra_info => [['duckdb_table_function', 'opaque', 'duckdb_delete_callback_t'] => 'void'],
    duckdb_table_function_set_bind => [['duckdb_table_function', 'duckdb_table_function_bind_t'] => 'void'],
    duckdb_table_function_set_init => [['duckdb_table_function', 'duckdb_table_function_init_t'] => 'void'],
    duckdb_table_function_set_local_init => [['duckdb_table_function', 'duckdb_table_function_init_t'] => 'void'],
    duckdb_table_function_set_function => [['duckdb_table_function', 'duckdb_table_function_t'] => 'void'],
    duckdb_table_function_supports_projection_pushdown => [['duckdb_table_function', 'bool'] => 'void'],
    duckdb_register_table_function => [['duckdb_connection', 'duckdb_table_function'] => 'duckdb_state'],

    # Table Function Bind

    duckdb_bind_get_extra_info => [['duckdb_bind_info'] => 'opaque'],
    duckdb_table_function_get_client_context => [['duckdb_bind_info', 'duckdb_client_context*'] => 'void'],
    duckdb_bind_add_result_column => [['duckdb_bind_info', 'string', 'duckdb_logical_type'] => 'void'],
    duckdb_bind_get_parameter_count => [['duckdb_bind_info'] => 'idx_t'],
    duckdb_bind_get_parameter => [['duckdb_bind_info', 'idx_t'] => 'duckdb_value'],
    duckdb_bind_get_named_parameter => [['duckdb_bind_info', 'string'] => 'duckdb_value'],
    duckdb_bind_set_bind_data => [['duckdb_bind_info', 'opaque', 'duckdb_delete_callback_t'] => 'void'],
    duckdb_bind_set_cardinality => [['duckdb_bind_info', 'idx_t', 'bool'] => 'void'],
    duckdb_bind_set_error => [['duckdb_bind_info', 'string'] => 'void'],

    # Table Function Init

    duckdb_init_get_extra_info => [['duckdb_init_info'] => 'opaque'],
    duckdb_init_get_bind_data => [['duckdb_init_info'] => 'opaque'],
    duckdb_init_set_init_data => [['duckdb_init_info', 'opaque', 'duckdb_delete_callback_t'] => 'void'],
    duckdb_init_get_column_count => [['duckdb_init_info'] => 'idx_t'],
    duckdb_init_get_column_index => [['duckdb_init_info', 'idx_t'] => 'idx_t'],
    duckdb_init_set_max_threads => [['duckdb_init_info', 'idx_t'] => 'void'],
    duckdb_init_set_error => [['duckdb_init_info', 'string'] => 'void'],

    # Table Function

    duckdb_function_get_extra_info => [['duckdb_function_info'] => 'opaque'],
    duckdb_function_get_bind_data => [['duckdb_function_info'] => 'opaque'],
    duckdb_function_get_init_data => [['duckdb_function_info'] => 'opaque'],
    duckdb_function_get_local_init_data => [['duckdb_function_info'] => 'opaque'],
    duckdb_function_set_error => [['duckdb_function_info', 'string'] => 'void'],

    # Replacement Scans

    duckdb_add_replacement_scan => [['duckdb_database', 'duckdb_replacement_callback_t', 'opaque', 'duckdb_delete_callback_t'] => 'void'],
    duckdb_replacement_scan_set_function_name => [['duckdb_replacement_scan_info', 'string'] => 'void'],
    duckdb_replacement_scan_add_parameter => [['duckdb_replacement_scan_info', 'duckdb_value'] => 'void'],
    duckdb_replacement_scan_set_error => [['duckdb_replacement_scan_info', 'string'] => 'void'],

    # Profiling Info

    duckdb_get_profiling_info => [['duckdb_connection'] => 'duckdb_profiling_info'],
    duckdb_profiling_info_get_value => [['duckdb_profiling_info', 'string'] => 'duckdb_value'],
    duckdb_profiling_info_get_metrics => [['duckdb_profiling_info'] => 'duckdb_value'],
    duckdb_profiling_info_get_child_count => [['duckdb_profiling_info'] => 'idx_t'],
    duckdb_profiling_info_get_child => [['duckdb_profiling_info', 'idx_t'] => 'duckdb_profiling_info'],

    # Appender

    duckdb_appender_create => [['duckdb_connection', 'string', 'string', 'duckdb_appender*'] => 'duckdb_state'],
    duckdb_appender_create_ext => [['duckdb_connection', 'string', 'string', 'string', 'duckdb_appender*'] => 'duckdb_state'],
    duckdb_appender_create_query => [['duckdb_connection', 'string', 'idx_t', 'duckdb_logical_type*', 'string', 'string*', 'duckdb_appender*'] => 'duckdb_state'],
    duckdb_appender_column_count => [['duckdb_appender'] => 'idx_t'],
    duckdb_appender_column_type => [['duckdb_appender', 'idx_t'] => 'duckdb_logical_type'],
    duckdb_appender_error => [['duckdb_appender'] => 'string'],
    duckdb_appender_error_data => [['duckdb_appender'] => 'duckdb_error_data'],
    duckdb_appender_flush => [['duckdb_appender'] => 'duckdb_state'],
    duckdb_appender_close => [['duckdb_appender'] => 'duckdb_state'],
    duckdb_appender_destroy => [['duckdb_appender*'] => 'duckdb_state'],
    duckdb_appender_add_column => [['duckdb_appender', 'string'] => 'duckdb_state'],
    duckdb_appender_clear_columns => [['duckdb_appender'] => 'duckdb_state'],
    duckdb_appender_begin_row => [['duckdb_appender'] => 'duckdb_state'],
    duckdb_appender_end_row => [['duckdb_appender'] => 'duckdb_state'],
    duckdb_append_default => [['duckdb_appender'] => 'duckdb_state'],
    duckdb_append_default_to_chunk => [['duckdb_appender', 'duckdb_data_chunk', 'idx_t', 'idx_t'] => 'duckdb_state'],
    duckdb_append_bool => [['duckdb_appender', 'bool'] => 'duckdb_state'],
    duckdb_append_int8 => [['duckdb_appender', 'int8_t'] => 'duckdb_state'],
    duckdb_append_int16 => [['duckdb_appender', 'int16_t'] => 'duckdb_state'],
    duckdb_append_int32 => [['duckdb_appender', 'int32_t'] => 'duckdb_state'],
    duckdb_append_int64 => [['duckdb_appender', 'int64_t'] => 'duckdb_state'],
    duckdb_append_hugeint => [['duckdb_appender', 'duckdb_hugeint'] => 'duckdb_state'],
    duckdb_append_uint8 => [['duckdb_appender', 'uint8_t'] => 'duckdb_state'],
    duckdb_append_uint16 => [['duckdb_appender', 'uint16_t'] => 'duckdb_state'],
    duckdb_append_uint32 => [['duckdb_appender', 'uint32_t'] => 'duckdb_state'],
    duckdb_append_uint64 => [['duckdb_appender', 'uint64_t'] => 'duckdb_state'],
    duckdb_append_uhugeint => [['duckdb_appender', 'duckdb_uhugeint'] => 'duckdb_state'],
    duckdb_append_float => [['duckdb_appender', 'float'] => 'duckdb_state'],
    duckdb_append_double => [['duckdb_appender', 'double'] => 'duckdb_state'],
    duckdb_append_date => [['duckdb_appender', 'duckdb_date'] => 'duckdb_state'],
    duckdb_append_time => [['duckdb_appender', 'duckdb_time'] => 'duckdb_state'],
    duckdb_append_timestamp => [['duckdb_appender', 'duckdb_timestamp'] => 'duckdb_state'],
    duckdb_append_interval => [['duckdb_appender', 'duckdb_interval'] => 'duckdb_state'],
    duckdb_append_varchar => [['duckdb_appender', 'string'] => 'duckdb_state'],
    duckdb_append_varchar_length => [['duckdb_appender', 'string', 'idx_t'] => 'duckdb_state'],
    duckdb_append_blob => [['duckdb_appender', 'opaque', 'idx_t'] => 'duckdb_state'],
    duckdb_append_null => [['duckdb_appender'] => 'duckdb_state'],
    duckdb_append_value => [['duckdb_appender', 'duckdb_value'] => 'duckdb_state'],
    duckdb_append_data_chunk => [['duckdb_appender', 'duckdb_data_chunk'] => 'duckdb_state'],

    # Table Description

    duckdb_table_description_create => [['duckdb_connection', 'string', 'string', 'duckdb_table_description*'] => 'duckdb_state'],
    duckdb_table_description_create_ext => [['duckdb_connection', 'string', 'string', 'string', 'duckdb_table_description*'] => 'duckdb_state'],
    duckdb_table_description_destroy => [['duckdb_table_description*'] => 'void'],
    duckdb_table_description_error => [['duckdb_table_description'] => 'string'],
    duckdb_column_has_default => [['duckdb_table_description', 'idx_t', 'opaque'] => 'duckdb_state'],
    duckdb_table_description_get_column_name => [['duckdb_table_description', 'idx_t'] => 'string'],

    # Arrow Interface

    duckdb_to_arrow_schema => [['duckdb_arrow_options', 'duckdb_logical_type*', 'string*', 'idx_t', 'opaque'] => 'duckdb_error_data'],
    duckdb_data_chunk_to_arrow => [['duckdb_arrow_options', 'duckdb_data_chunk', 'opaque'] => 'duckdb_error_data'],
    duckdb_schema_from_arrow => [['duckdb_connection', 'opaque', 'duckdb_arrow_converted_schema*'] => 'duckdb_error_data'],
    duckdb_data_chunk_from_arrow => [['duckdb_connection', 'opaque', 'duckdb_arrow_converted_schema', 'duckdb_data_chunk*'] => 'duckdb_error_data'],
    duckdb_destroy_arrow_converted_schema => [['duckdb_arrow_converted_schema*'] => 'void'],
    duckdb_query_arrow => [['duckdb_connection', 'string', 'duckdb_arrow*'] => 'duckdb_state'],
    duckdb_query_arrow_schema => [['duckdb_arrow', 'duckdb_arrow_schema*'] => 'duckdb_state'],
    duckdb_prepared_arrow_schema => [['duckdb_prepared_statement', 'duckdb_arrow_schema*'] => 'duckdb_state'],
    duckdb_result_arrow_array => [['duckdb_result', 'duckdb_data_chunk', 'duckdb_arrow_array*'] => 'void'],
    duckdb_query_arrow_array => [['duckdb_arrow', 'duckdb_arrow_array*'] => 'duckdb_state'],
    duckdb_arrow_column_count => [['duckdb_arrow'] => 'idx_t'],
    duckdb_arrow_row_count => [['duckdb_arrow'] => 'idx_t'],
    duckdb_arrow_rows_changed => [['duckdb_arrow'] => 'idx_t'],
    duckdb_query_arrow_error => [['duckdb_arrow'] => 'string'],
    duckdb_destroy_arrow => [['duckdb_arrow*'] => 'void'],
    duckdb_destroy_arrow_stream => [['duckdb_arrow_stream*'] => 'void'],
    duckdb_execute_prepared_arrow => [['duckdb_prepared_statement', 'duckdb_arrow*'] => 'duckdb_state'],
    duckdb_arrow_scan => [['duckdb_connection', 'string', 'duckdb_arrow_stream'] => 'duckdb_state'],
    duckdb_arrow_array_scan => [['duckdb_connection', 'string', 'duckdb_arrow_schema', 'duckdb_arrow_array', 'duckdb_arrow_stream*'] => 'duckdb_state'],

    # Threading Information

    duckdb_execute_tasks => [['duckdb_database', 'idx_t'] => 'void'],
    duckdb_create_task_state => [['duckdb_database'] => 'duckdb_task_state'],
    duckdb_execute_tasks_state => [['duckdb_task_state'] => 'void'],
    duckdb_execute_n_tasks_state => [['duckdb_task_state', 'idx_t'] => 'idx_t'],
    duckdb_finish_execution => [['duckdb_task_state'] => 'void'],
    duckdb_task_state_is_finished => [['duckdb_task_state'] => 'bool'],
    duckdb_destroy_task_state => [['duckdb_task_state'] => 'void'],
    duckdb_execution_is_finished => [['duckdb_connection'] => 'bool'],

    # Streaming Result Interface

    duckdb_stream_fetch_chunk => [['duckdb_result'] => 'duckdb_data_chunk'],
    duckdb_fetch_chunk => [['duckdb_result'] => 'duckdb_data_chunk'],

    # Cast Functions

    duckdb_create_cast_function => [[] => 'duckdb_cast_function'],
    duckdb_cast_function_set_source_type => [['duckdb_cast_function', 'duckdb_logical_type'] => 'void'],
    duckdb_cast_function_set_target_type => [['duckdb_cast_function', 'duckdb_logical_type'] => 'void'],
    duckdb_cast_function_set_implicit_cast_cost => [['duckdb_cast_function', 'int64_t'] => 'void'],
    duckdb_cast_function_set_function => [['duckdb_cast_function', 'duckdb_cast_function_t'] => 'void'],
    duckdb_cast_function_set_extra_info => [['duckdb_cast_function', 'opaque', 'duckdb_delete_callback_t'] => 'void'],
    duckdb_cast_function_get_extra_info => [['duckdb_function_info'] => 'opaque'],
    duckdb_cast_function_get_cast_mode => [['duckdb_function_info'] => 'duckdb_cast_mode'],
    duckdb_cast_function_set_error => [['duckdb_function_info', 'string'] => 'void'],
    duckdb_cast_function_set_row_error => [['duckdb_function_info', 'string', 'idx_t', 'duckdb_vector'] => 'void'],
    duckdb_register_cast_function => [['duckdb_connection', 'duckdb_cast_function'] => 'duckdb_state'],
    duckdb_destroy_cast_function => [['duckdb_cast_function*'] => 'void'],

    # Expression Interface

    duckdb_destroy_expression => [['duckdb_expression*'] => 'void'],
    duckdb_expression_return_type => [['duckdb_expression'] => 'duckdb_logical_type'],
    duckdb_expression_is_foldable => [['duckdb_expression'] => 'bool'],
    duckdb_expression_fold => [['duckdb_client_context', 'duckdb_expression', 'duckdb_value*'] => 'duckdb_error_data'],
);
#>>>

our @EXPORT_OK = keys %DUCKDB_FUNCTIONS;

our %EXPORT_TAGS = (all => [@EXPORT_OK]);

use constant USE_ALIEN => $ENV{DUCKDB_NO_ALIEN} ? 0 : 1;

state $ffi = FFI::Platypus->new(
    api => 2,
    lib => find_lib_or_die(lib => 'duckdb', alien => (USE_ALIEN ? 'Alien::DuckDB' : undef))
);

sub cast {
    my ($data, $from, $to) = @_;
    $ffi->cast($from, $to, $data);
}

sub init {

    $ffi->type(int      => 'duckdb_result_type');
    $ffi->type(int      => 'duckdb_state');
    $ffi->type(int      => 'duckdb_type');
    $ffi->type(int      => 'duckdb_error_type');
    $ffi->type(int      => 'duckdb_statement_type');
    $ffi->type(int32_t  => 'duckdb_date');
    $ffi->type(int64_t  => 'duckdb_time');
    $ffi->type(int64_t  => 'duckdb_timestamp');
    $ffi->type(opaque   => 'duckdb_appender');
    $ffi->type(opaque   => 'duckdb_client_context');
    $ffi->type(opaque   => 'duckdb_config');
    $ffi->type(opaque   => 'duckdb_connection');
    $ffi->type(opaque   => 'duckdb_create_type_info');
    $ffi->type(opaque   => 'duckdb_data_chunk');
    $ffi->type(opaque   => 'duckdb_database');
    $ffi->type(opaque   => 'duckdb_error_data');
    $ffi->type(opaque   => 'duckdb_instance_cache');
    $ffi->type(opaque   => 'duckdb_logical_type');
    $ffi->type(opaque   => 'duckdb_prepared_statement');
    $ffi->type(opaque   => 'duckdb_query_progress_type');
    $ffi->type(opaque   => 'duckdb_selection_vector');
    $ffi->type(opaque   => 'duckdb_value');
    $ffi->type(opaque   => 'duckdb_vector');
    $ffi->type(opaque   => 'duckdb_aggregate_combine_t');
    $ffi->type(opaque   => 'duckdb_aggregate_destroy_t');
    $ffi->type(opaque   => 'duckdb_aggregate_finalize_t');
    $ffi->type(opaque   => 'duckdb_aggregate_function');
    $ffi->type(opaque   => 'duckdb_aggregate_function_set');
    $ffi->type(opaque   => 'duckdb_aggregate_init_t');
    $ffi->type(opaque   => 'duckdb_aggregate_state_size');
    $ffi->type(opaque   => 'duckdb_aggregate_update_t');
    $ffi->type(opaque   => 'duckdb_arrow');
    $ffi->type(opaque   => 'duckdb_arrow_array');
    $ffi->type(opaque   => 'duckdb_arrow_converted_schema');
    $ffi->type(opaque   => 'duckdb_arrow_options');
    $ffi->type(opaque   => 'duckdb_arrow_schema');
    $ffi->type(opaque   => 'duckdb_arrow_stream');
    $ffi->type(opaque   => 'duckdb_bignum');
    $ffi->type(opaque   => 'duckdb_bind_info');
    $ffi->type(opaque   => 'duckdb_bit');
    $ffi->type(opaque   => 'duckdb_blob');
    $ffi->type(opaque   => 'duckdb_cast_function');
    $ffi->type(opaque   => 'duckdb_cast_function_t');
    $ffi->type(opaque   => 'duckdb_cast_mode');
    $ffi->type(opaque   => 'duckdb_copy_callback_t');
    $ffi->type(opaque   => 'duckdb_delete_callback_t');
    $ffi->type(opaque   => 'duckdb_expression');
    $ffi->type(opaque   => 'duckdb_extracted_statements');
    $ffi->type(opaque   => 'duckdb_function_info');
    $ffi->type(opaque   => 'duckdb_init_info');
    $ffi->type(opaque   => 'duckdb_pending_result');
    $ffi->type(opaque   => 'duckdb_pending_state');
    $ffi->type(opaque   => 'duckdb_profiling_info');
    $ffi->type(opaque   => 'duckdb_replacement_callback_t');
    $ffi->type(opaque   => 'duckdb_replacement_scan_info');
    $ffi->type(opaque   => 'duckdb_scalar_function');
    $ffi->type(opaque   => 'duckdb_scalar_function_bind_t');
    $ffi->type(opaque   => 'duckdb_scalar_function_set');
    $ffi->type(opaque   => 'duckdb_scalar_function_t');
    $ffi->type(opaque   => 'duckdb_string');
    $ffi->type(opaque   => 'duckdb_string_t');
    $ffi->type(opaque   => 'duckdb_table_description');
    $ffi->type(opaque   => 'duckdb_table_function');
    $ffi->type(opaque   => 'duckdb_table_function_bind_t');
    $ffi->type(opaque   => 'duckdb_table_function_init_t');
    $ffi->type(opaque   => 'duckdb_table_function_t');
    $ffi->type(opaque   => 'duckdb_task_state');
    $ffi->type(opaque   => 'duckdb_time_ns');
    $ffi->type(opaque   => 'duckdb_time_tz');
    $ffi->type(opaque   => 'duckdb_timestamp_ms');
    $ffi->type(opaque   => 'duckdb_timestamp_ns');
    $ffi->type(opaque   => 'duckdb_timestamp_s');
    $ffi->type(uint32_t => 'sel_t');
    $ffi->type(uint64_t => 'idx_t');

    # TODO  Use record for duckdb_time, duckdb_date and duckdb_timestamp ???

    $ffi->type('record(DBD::DuckDB::FFI::Decimal)'   => 'duckdb_decimal');
    $ffi->type('record(DBD::DuckDB::FFI::HugeInt)'   => 'duckdb_hugeint');
    $ffi->type('record(DBD::DuckDB::FFI::Interval)'  => 'duckdb_interval');
    $ffi->type('record(DBD::DuckDB::FFI::Result)'    => 'duckdb_result');
    $ffi->type('record(DBD::DuckDB::FFI::uHugeInt)'  => 'duckdb_uhugeint');
    $ffi->type('record(DBD::DuckDB::FFI::TimeTZ)'    => 'duckdb_time_tz_struct');
    $ffi->type('record(DBD::DuckDB::FFI::Time)'      => 'duckdb_time_struct');
    $ffi->type('record(DBD::DuckDB::FFI::Date)'      => 'duckdb_date_struct');
    $ffi->type('record(DBD::DuckDB::FFI::Timestamp)' => 'duckdb_timestamp_struct');

    for my $fn (keys %DUCKDB_FUNCTIONS) {

        my @args = @{$DUCKDB_FUNCTIONS{$fn}};

        eval { $ffi->attach($fn => @args) };

        if (my $error = $@) {
            $error =~ s/ at .* line \d+.*//;
            DBI->trace_msg("    -> [DuckDB] ERROR $error", 2);
        }

    }

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

package    # hide from PAUSE
    DBD::DuckDB::FFI::Time {

    use strict;
    use warnings;
    use FFI::Platypus::Record qw(record_layout_1);

    # C struct (ABI v1.4):
    # typedef struct {
    #     int8_t hour;
    #     int8_t min;
    #     int8_t sec;
    #     int32_t micros;
    # } duckdb_time_struct;
    record_layout_1(int8_t => 'hour', int8_t => 'min', int8_t => 'sec', int32_t => 'micros');

}

package    # hide from PAUSE
    DBD::DuckDB::FFI::TimeTZ {

    use strict;
    use warnings;
    use FFI::Platypus::Record qw(record_layout_1);

    # C struct (ABI v1.4):
    # typedef struct {
    #     duckdb_time_struct time;
    #     int32_t offset;
    # } duckdb_time_tz_struct;
    record_layout_1(int8_t => 'hour', int8_t => 'min', int8_t => 'sec', int32_t => 'micros', int32_t => 'offset');

}

package    # hide from PAUSE
    DBD::DuckDB::FFI::Date {

    use strict;
    use warnings;
    use FFI::Platypus::Record qw(record_layout_1);

    # C struct (ABI v1.4):
    # typedef struct {
    #     int32_t year;
    #     int8_t month;
    #     int8_t day;
    # } duckdb_date_struct;
    record_layout_1(int32_t => 'year', int8_t => 'month', int8_t => 'day');

}

package    # hide from PAUSE
    DBD::DuckDB::FFI::Timestamp {

    use strict;
    use warnings;
    use FFI::Platypus::Record qw(record_layout_1);

    # C struct (ABI v1.4):
    # typedef struct {
    #     duckdb_date_struct date;
    #     duckdb_time_struct time;
    # } duckdb_timestamp_struct;
    record_layout_1(
        int32_t => 'year',
        int8_t  => 'month',
        int8_t  => 'day',
        int8_t  => 'hour',
        int8_t  => 'min',
        int8_t  => 'sec',
        int32_t => 'micros'
    );

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBD::DuckDB::FFI - DuckDB C functions

=head1 SYNOPSIS

    use DBD::DuckDB::FFI qw(:all);

    say duckdb_library_version();


=head1 DESCRIPTION

L<DBD::DuckDB> use L<FFI::Platypus> for access to C<libduckdb> C library.


=head1 FUNCTIONS

=head2 Open Connect

=over

=item * duckdb_create_instance_cache

=item * duckdb_get_or_create_from_cache

=item * duckdb_destroy_instance_cache

=item * duckdb_open

=item * duckdb_open_ext

=item * duckdb_close

=item * duckdb_connect

=item * duckdb_interrupt

=item * duckdb_query_progress

=item * duckdb_disconnect

=item * duckdb_connection_get_client_context

=item * duckdb_connection_get_arrow_options

=item * duckdb_client_context_get_connection_id

=item * duckdb_destroy_client_context

=item * duckdb_destroy_arrow_options

=item * duckdb_library_version

=item * duckdb_get_table_names

=back

=head2 Configuration

=over

=item * duckdb_create_config

=item * duckdb_config_count

=item * duckdb_get_config_flag

=item * duckdb_set_config

=item * duckdb_destroy_config

=back

=head2 Error Data

=over

=item * duckdb_create_error_data

=item * duckdb_destroy_error_data

=item * duckdb_error_data_error_type

=item * duckdb_error_data_message

=item * duckdb_error_data_has_error

=back

=head2 Query Execution

=over

=item * duckdb_query

=item * duckdb_destroy_result

=item * duckdb_column_name

=item * duckdb_column_type

=item * duckdb_result_statement_type

=item * duckdb_column_logical_type

=item * duckdb_result_get_arrow_options

=item * duckdb_column_count

=item * duckdb_row_count

=item * duckdb_rows_changed

=item * duckdb_column_data

=item * duckdb_nullmask_data

=item * duckdb_result_error

=item * duckdb_result_error_type

=back

=head2 Result Functions

=over

=item * duckdb_result_get_chunk

=item * duckdb_result_is_streaming

=item * duckdb_result_chunk_count

=item * duckdb_result_return_type

=back

=head2 Safe Fetch Functions

=over

=item * duckdb_value_boolean

=item * duckdb_value_int8

=item * duckdb_value_int16

=item * duckdb_value_int32

=item * duckdb_value_int64

=item * duckdb_value_hugeint

=item * duckdb_value_uhugeint

=item * duckdb_value_decimal

=item * duckdb_value_uint8

=item * duckdb_value_uint16

=item * duckdb_value_uint32

=item * duckdb_value_uint64

=item * duckdb_value_float

=item * duckdb_value_double

=item * duckdb_value_date

=item * duckdb_value_time

=item * duckdb_value_timestamp

=item * duckdb_value_interval

=item * duckdb_value_varchar

=item * duckdb_value_string

=item * duckdb_value_varchar_internal

=item * duckdb_value_string_internal

=item * duckdb_value_blob

=item * duckdb_value_is_null

=back

=head2 Helpers

=over

=item * duckdb_malloc

=item * duckdb_free

=item * duckdb_vector_size

=item * duckdb_string_is_inlined

=item * duckdb_string_t_length

=item * duckdb_string_t_data

=back

=head2 Date Time Timestamp Helpers

=over

=item * duckdb_from_date

=item * duckdb_to_date

=item * duckdb_is_finite_date

=item * duckdb_from_time

=item * duckdb_create_time_tz

=item * duckdb_from_time_tz

=item * duckdb_to_time

=item * duckdb_from_timestamp

=item * duckdb_to_timestamp

=item * duckdb_is_finite_timestamp

=item * duckdb_is_finite_timestamp_s

=item * duckdb_is_finite_timestamp_ms

=item * duckdb_is_finite_timestamp_ns

=back

=head2 Hugeint Helpers

=over

=item * duckdb_hugeint_to_double

=item * duckdb_double_to_hugeint

=back

=head2 Unsigned Hugeint Helpers

=over

=item * duckdb_uhugeint_to_double

=item * duckdb_double_to_uhugeint

=back

=head2 Decimal Helpers

=over

=item * duckdb_double_to_decimal

=item * duckdb_decimal_to_double

=back

=head2 Prepared Statements

=over

=item * duckdb_prepare

=item * duckdb_destroy_prepare

=item * duckdb_prepare_error

=item * duckdb_nparams

=item * duckdb_parameter_name

=item * duckdb_param_type

=item * duckdb_param_logical_type

=item * duckdb_clear_bindings

=item * duckdb_prepared_statement_type

=item * duckdb_prepared_statement_column_count

=item * duckdb_prepared_statement_column_name

=item * duckdb_prepared_statement_column_logical_type

=item * duckdb_prepared_statement_column_type

=back

=head2 Bind Values to Prepared Statements

=over

=item * duckdb_bind_value

=item * duckdb_bind_parameter_index

=item * duckdb_bind_boolean

=item * duckdb_bind_int8

=item * duckdb_bind_int16

=item * duckdb_bind_int32

=item * duckdb_bind_int64

=item * duckdb_bind_hugeint

=item * duckdb_bind_uhugeint

=item * duckdb_bind_decimal

=item * duckdb_bind_uint8

=item * duckdb_bind_uint16

=item * duckdb_bind_uint32

=item * duckdb_bind_uint64

=item * duckdb_bind_float

=item * duckdb_bind_double

=item * duckdb_bind_date

=item * duckdb_bind_time

=item * duckdb_bind_timestamp

=item * duckdb_bind_timestamp_tz

=item * duckdb_bind_interval

=item * duckdb_bind_varchar

=item * duckdb_bind_varchar_length

=item * duckdb_bind_blob

=item * duckdb_bind_null

=back

=head2 Execute Prepared Statements

=over

=item * duckdb_execute_prepared

=item * duckdb_execute_prepared_streaming

=back

=head2 Extract Statements

=over

=item * duckdb_extract_statements

=item * duckdb_prepare_extracted_statement

=item * duckdb_extract_statements_error

=item * duckdb_destroy_extracted

=back

=head2 Pending Result Interface

=over

=item * duckdb_pending_prepared

=item * duckdb_pending_prepared_streaming

=item * duckdb_destroy_pending

=item * duckdb_pending_error

=item * duckdb_pending_execute_task

=item * duckdb_pending_execute_check_state

=item * duckdb_execute_pending

=item * duckdb_pending_execution_is_finished

=back

=head2 Value Interface

=over

=item * duckdb_destroy_value

=item * duckdb_create_varchar

=item * duckdb_create_varchar_length

=item * duckdb_create_bool

=item * duckdb_create_int8

=item * duckdb_create_uint8

=item * duckdb_create_int16

=item * duckdb_create_uint16

=item * duckdb_create_int32

=item * duckdb_create_uint32

=item * duckdb_create_uint64

=item * duckdb_create_int64

=item * duckdb_create_hugeint

=item * duckdb_create_uhugeint

=item * duckdb_create_bignum

=item * duckdb_create_decimal

=item * duckdb_create_float

=item * duckdb_create_double

=item * duckdb_create_date

=item * duckdb_create_time

=item * duckdb_create_time_ns

=item * duckdb_create_time_tz_value

=item * duckdb_create_timestamp

=item * duckdb_create_timestamp_tz

=item * duckdb_create_timestamp_s

=item * duckdb_create_timestamp_ms

=item * duckdb_create_timestamp_ns

=item * duckdb_create_interval

=item * duckdb_create_blob

=item * duckdb_create_bit

=item * duckdb_create_uuid

=item * duckdb_get_bool

=item * duckdb_get_int8

=item * duckdb_get_uint8

=item * duckdb_get_int16

=item * duckdb_get_uint16

=item * duckdb_get_int32

=item * duckdb_get_uint32

=item * duckdb_get_int64

=item * duckdb_get_uint64

=item * duckdb_get_hugeint

=item * duckdb_get_uhugeint

=item * duckdb_get_bignum

=item * duckdb_get_decimal

=item * duckdb_get_float

=item * duckdb_get_double

=item * duckdb_get_date

=item * duckdb_get_time

=item * duckdb_get_time_ns

=item * duckdb_get_time_tz

=item * duckdb_get_timestamp

=item * duckdb_get_timestamp_tz

=item * duckdb_get_timestamp_s

=item * duckdb_get_timestamp_ms

=item * duckdb_get_timestamp_ns

=item * duckdb_get_interval

=item * duckdb_get_value_type

=item * duckdb_get_blob

=item * duckdb_get_bit

=item * duckdb_get_uuid

=item * duckdb_get_varchar

=item * duckdb_create_struct_value

=item * duckdb_create_list_value

=item * duckdb_create_array_value

=item * duckdb_create_map_value

=item * duckdb_create_union_value

=item * duckdb_get_map_size

=item * duckdb_get_map_key

=item * duckdb_get_map_value

=item * duckdb_is_null_value

=item * duckdb_create_null_value

=item * duckdb_get_list_size

=item * duckdb_get_list_child

=item * duckdb_create_enum_value

=item * duckdb_get_enum_value

=item * duckdb_get_struct_child

=item * duckdb_value_to_string

=back

=head2 Logical Type Interface

=over

=item * duckdb_create_logical_type

=item * duckdb_logical_type_get_alias

=item * duckdb_logical_type_set_alias

=item * duckdb_create_list_type

=item * duckdb_create_array_type

=item * duckdb_create_map_type

=item * duckdb_create_union_type

=item * duckdb_create_struct_type

=item * duckdb_create_enum_type

=item * duckdb_create_decimal_type

=item * duckdb_get_type_id

=item * duckdb_decimal_width

=item * duckdb_decimal_scale

=item * duckdb_decimal_internal_type

=item * duckdb_enum_internal_type

=item * duckdb_enum_dictionary_size

=item * duckdb_enum_dictionary_value

=item * duckdb_list_type_child_type

=item * duckdb_array_type_child_type

=item * duckdb_array_type_array_size

=item * duckdb_map_type_key_type

=item * duckdb_map_type_value_type

=item * duckdb_struct_type_child_count

=item * duckdb_struct_type_child_name

=item * duckdb_struct_type_child_type

=item * duckdb_union_type_member_count

=item * duckdb_union_type_member_name

=item * duckdb_union_type_member_type

=item * duckdb_destroy_logical_type

=item * duckdb_register_logical_type

=back

=head2 Data Chunk Interface

=over

=item * duckdb_create_data_chunk

=item * duckdb_destroy_data_chunk

=item * duckdb_data_chunk_reset

=item * duckdb_data_chunk_get_column_count

=item * duckdb_data_chunk_get_vector

=item * duckdb_data_chunk_get_size

=item * duckdb_data_chunk_set_size

=back

=head2 Vector Interface

=over

=item * duckdb_create_vector

=item * duckdb_destroy_vector

=item * duckdb_vector_get_column_type

=item * duckdb_vector_get_data

=item * duckdb_vector_get_validity

=item * duckdb_vector_ensure_validity_writable

=item * duckdb_vector_assign_string_element

=item * duckdb_vector_assign_string_element_len

=item * duckdb_list_vector_get_child

=item * duckdb_list_vector_get_size

=item * duckdb_list_vector_set_size

=item * duckdb_list_vector_reserve

=item * duckdb_struct_vector_get_child

=item * duckdb_array_vector_get_child

=item * duckdb_slice_vector

=item * duckdb_vector_copy_sel

=item * duckdb_vector_reference_value

=item * duckdb_vector_reference_vector

=back

=head2 Validity Mask Functions

=over

=item * duckdb_validity_row_is_valid

=item * duckdb_validity_set_row_validity

=item * duckdb_validity_set_row_invalid

=item * duckdb_validity_set_row_valid

=back

=head2 Scalar Functions

=over

=item * duckdb_create_scalar_function

=item * duckdb_destroy_scalar_function

=item * duckdb_scalar_function_set_name

=item * duckdb_scalar_function_set_varargs

=item * duckdb_scalar_function_set_special_handling

=item * duckdb_scalar_function_set_volatile

=item * duckdb_scalar_function_add_parameter

=item * duckdb_scalar_function_set_return_type

=item * duckdb_scalar_function_set_extra_info

=item * duckdb_scalar_function_set_bind

=item * duckdb_scalar_function_set_bind_data

=item * duckdb_scalar_function_set_bind_data_copy

=item * duckdb_scalar_function_bind_set_error

=item * duckdb_scalar_function_set_function

=item * duckdb_register_scalar_function

=item * duckdb_scalar_function_get_extra_info

=item * duckdb_scalar_function_bind_get_extra_info

=item * duckdb_scalar_function_get_bind_data

=item * duckdb_scalar_function_get_client_context

=item * duckdb_scalar_function_set_error

=item * duckdb_create_scalar_function_set

=item * duckdb_destroy_scalar_function_set

=item * duckdb_add_scalar_function_to_set

=item * duckdb_register_scalar_function_set

=item * duckdb_scalar_function_bind_get_argument_count

=item * duckdb_scalar_function_bind_get_argument

=back

=head2 Selection Vector Interface

=over

=item * duckdb_create_selection_vector

=item * duckdb_destroy_selection_vector

=item * duckdb_selection_vector_get_data_ptr

=back

=head2 Aggregate Functions

=over

=item * duckdb_create_aggregate_function

=item * duckdb_destroy_aggregate_function

=item * duckdb_aggregate_function_set_name

=item * duckdb_aggregate_function_add_parameter

=item * duckdb_aggregate_function_set_return_type

=item * duckdb_aggregate_function_set_functions

=item * duckdb_aggregate_function_set_destructor

=item * duckdb_register_aggregate_function

=item * duckdb_aggregate_function_set_special_handling

=item * duckdb_aggregate_function_set_extra_info

=item * duckdb_aggregate_function_get_extra_info

=item * duckdb_aggregate_function_set_error

=item * duckdb_create_aggregate_function_set

=item * duckdb_destroy_aggregate_function_set

=item * duckdb_add_aggregate_function_to_set

=item * duckdb_register_aggregate_function_set

=back

=head2 Table Functions

=over

=item * duckdb_create_table_function

=item * duckdb_destroy_table_function

=item * duckdb_table_function_set_name

=item * duckdb_table_function_add_parameter

=item * duckdb_table_function_add_named_parameter

=item * duckdb_table_function_set_extra_info

=item * duckdb_table_function_set_bind

=item * duckdb_table_function_set_init

=item * duckdb_table_function_set_local_init

=item * duckdb_table_function_set_function

=item * duckdb_table_function_supports_projection_pushdown

=item * duckdb_register_table_function

=back

=head2 Table Function Bind

=over

=item * duckdb_bind_get_extra_info

=item * duckdb_table_function_get_client_context

=item * duckdb_bind_add_result_column

=item * duckdb_bind_get_parameter_count

=item * duckdb_bind_get_parameter

=item * duckdb_bind_get_named_parameter

=item * duckdb_bind_set_bind_data

=item * duckdb_bind_set_cardinality

=item * duckdb_bind_set_error

=back

=head2 Table Function Init

=over

=item * duckdb_init_get_extra_info

=item * duckdb_init_get_bind_data

=item * duckdb_init_set_init_data

=item * duckdb_init_get_column_count

=item * duckdb_init_get_column_index

=item * duckdb_init_set_max_threads

=item * duckdb_init_set_error

=back

=head2 Table Function

=over

=item * duckdb_function_get_extra_info

=item * duckdb_function_get_bind_data

=item * duckdb_function_get_init_data

=item * duckdb_function_get_local_init_data

=item * duckdb_function_set_error

=back

=head2 Replacement Scans

=over

=item * duckdb_add_replacement_scan

=item * duckdb_replacement_scan_set_function_name

=item * duckdb_replacement_scan_add_parameter

=item * duckdb_replacement_scan_set_error

=back

=head2 Profiling Info

=over

=item * duckdb_get_profiling_info

=item * duckdb_profiling_info_get_value

=item * duckdb_profiling_info_get_metrics

=item * duckdb_profiling_info_get_child_count

=item * duckdb_profiling_info_get_child

=back

=head2 Appender

=over

=item * duckdb_appender_create

=item * duckdb_appender_create_ext

=item * duckdb_appender_create_query

=item * duckdb_appender_column_count

=item * duckdb_appender_column_type

=item * duckdb_appender_error

=item * duckdb_appender_error_data

=item * duckdb_appender_flush

=item * duckdb_appender_close

=item * duckdb_appender_destroy

=item * duckdb_appender_add_column

=item * duckdb_appender_clear_columns

=item * duckdb_appender_begin_row

=item * duckdb_appender_end_row

=item * duckdb_append_default

=item * duckdb_append_default_to_chunk

=item * duckdb_append_bool

=item * duckdb_append_int8

=item * duckdb_append_int16

=item * duckdb_append_int32

=item * duckdb_append_int64

=item * duckdb_append_hugeint

=item * duckdb_append_uint8

=item * duckdb_append_uint16

=item * duckdb_append_uint32

=item * duckdb_append_uint64

=item * duckdb_append_uhugeint

=item * duckdb_append_float

=item * duckdb_append_double

=item * duckdb_append_date

=item * duckdb_append_time

=item * duckdb_append_timestamp

=item * duckdb_append_interval

=item * duckdb_append_varchar

=item * duckdb_append_varchar_length

=item * duckdb_append_blob

=item * duckdb_append_null

=item * duckdb_append_value

=item * duckdb_append_data_chunk

=back

=head2 Table Description

=over

=item * duckdb_table_description_create

=item * duckdb_table_description_create_ext

=item * duckdb_table_description_destroy

=item * duckdb_table_description_error

=item * duckdb_column_has_default

=item * duckdb_table_description_get_column_name

=back

=head2 Arrow Interface

=over

=item * duckdb_to_arrow_schema

=item * duckdb_data_chunk_to_arrow

=item * duckdb_schema_from_arrow

=item * duckdb_data_chunk_from_arrow

=item * duckdb_destroy_arrow_converted_schema

=item * duckdb_query_arrow

=item * duckdb_query_arrow_schema

=item * duckdb_prepared_arrow_schema

=item * duckdb_result_arrow_array

=item * duckdb_query_arrow_array

=item * duckdb_arrow_column_count

=item * duckdb_arrow_row_count

=item * duckdb_arrow_rows_changed

=item * duckdb_query_arrow_error

=item * duckdb_destroy_arrow

=item * duckdb_destroy_arrow_stream

=item * duckdb_execute_prepared_arrow

=item * duckdb_arrow_scan

=item * duckdb_arrow_array_scan

=back

=head2 Threading Information

=over

=item * duckdb_execute_tasks

=item * duckdb_create_task_state

=item * duckdb_execute_tasks_state

=item * duckdb_execute_n_tasks_state

=item * duckdb_finish_execution

=item * duckdb_task_state_is_finished

=item * duckdb_destroy_task_state

=item * duckdb_execution_is_finished

=back

=head2 Streaming Result Interface

=over

=item * duckdb_stream_fetch_chunk

=item * duckdb_fetch_chunk

=back

=head2 Cast Functions

=over

=item * duckdb_create_cast_function

=item * duckdb_cast_function_set_source_type

=item * duckdb_cast_function_set_target_type

=item * duckdb_cast_function_set_implicit_cast_cost

=item * duckdb_cast_function_set_function

=item * duckdb_cast_function_set_extra_info

=item * duckdb_cast_function_get_extra_info

=item * duckdb_cast_function_get_cast_mode

=item * duckdb_cast_function_set_error

=item * duckdb_cast_function_set_row_error

=item * duckdb_register_cast_function

=item * duckdb_destroy_cast_function

=back

=head2 Expression Interface

=over

=item * duckdb_destroy_expression

=item * duckdb_expression_return_type

=item * duckdb_expression_is_foldable

=item * duckdb_expression_fold

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
