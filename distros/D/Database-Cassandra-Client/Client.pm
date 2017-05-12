package Database::Cassandra::Client;

use utf8;
use strict;
use vars qw($AUTOLOAD $VERSION $ABSTRACT @ISA @EXPORT);

BEGIN {
	$VERSION = 1.0;
	$ABSTRACT = "Cassandra client (XS for libcassandra v1.0)";
	
	@ISA = qw(Exporter DynaLoader);
	@EXPORT = qw(
		cass_true cass_false
		CASS_CONSISTENCY_ANY CASS_CONSISTENCY_ONE CASS_CONSISTENCY_TWO CASS_CONSISTENCY_THREE
		CASS_CONSISTENCY_QUORUM CASS_CONSISTENCY_ALL CASS_CONSISTENCY_LOCAL_QUORUM CASS_CONSISTENCY_EACH_QUORUM
		CASS_CONSISTENCY_SERIAL CASS_CONSISTENCY_LOCAL_SERIAL CASS_CONSISTENCY_LOCAL_ONE
		
		CASS_VALUE_TYPE_UNKNOWN CASS_VALUE_TYPE_CUSTOM CASS_VALUE_TYPE_ASCII CASS_VALUE_TYPE_BIGINT
		CASS_VALUE_TYPE_BLOB CASS_VALUE_TYPE_BOOLEAN CASS_VALUE_TYPE_COUNTER CASS_VALUE_TYPE_DECIMAL
		CASS_VALUE_TYPE_DOUBLE CASS_VALUE_TYPE_FLOAT CASS_VALUE_TYPE_INT CASS_VALUE_TYPE_TEXT
		CASS_VALUE_TYPE_TIMESTAMP CASS_VALUE_TYPE_UUID CASS_VALUE_TYPE_VARCHAR CASS_VALUE_TYPE_VARINT
		CASS_VALUE_TYPE_TIMEUUID CASS_VALUE_TYPE_INET CASS_VALUE_TYPE_LIST CASS_VALUE_TYPE_MAP CASS_VALUE_TYPE_SET
		
		CASS_COLLECTION_TYPE_LIST CASS_COLLECTION_TYPE_MAP CASS_COLLECTION_TYPE_SET
		CASS_BATCH_TYPE_LOGGED CASS_BATCH_TYPE_UNLOGGED CASS_BATCH_TYPE_COUNTER
		CASS_LOG_DISABLED CASS_LOG_CRITICAL CASS_LOG_ERROR CASS_LOG_WARN CASS_LOG_INFO CASS_LOG_DEBUG CASS_LOG_LAST_ENTRY
		CASS_ERROR_SOURCE_NONE CASS_ERROR_SOURCE_LIB CASS_ERROR_SOURCE_SERVER CASS_ERROR_SOURCE_SSL CASS_ERROR_SOURCE_COMPRESSION
		
		CASS_OK CASS_ERROR_LIB_BAD_PARAMS CASS_ERROR_LIB_NO_STREAMS CASS_ERROR_LIB_UNABLE_TO_INIT CASS_ERROR_LIB_MESSAGE_ENCODE
		CASS_ERROR_LIB_HOST_RESOLUTION CASS_ERROR_LIB_UNEXPECTED_RESPONSE CASS_ERROR_LIB_REQUEST_QUEUE_FULL
		CASS_ERROR_LIB_NO_AVAILABLE_IO_THREAD CASS_ERROR_LIB_WRITE_ERROR CASS_ERROR_LIB_NO_HOSTS_AVAILABLE
		CASS_ERROR_LIB_INDEX_OUT_OF_BOUNDS CASS_ERROR_LIB_INVALID_ITEM_COUNT CASS_ERROR_LIB_INVALID_VALUE_TYPE
		CASS_ERROR_LIB_REQUEST_TIMED_OUT CASS_ERROR_LIB_UNABLE_TO_SET_KEYSPACE CASS_ERROR_LIB_CALLBACK_ALREADY_SET
		CASS_ERROR_INVALID_STATEMENT_TYPE CASS_ERROR_NAME_DOES_NOT_EXIST CASS_ERROR_UNABLE_TO_DETERMINE_PROTOCOL
		CASS_ERROR_LIB_NULL_VALUE CASS_ERROR_SERVER_SERVER_ERROR CASS_ERROR_SERVER_PROTOCOL_ERROR CASS_ERROR_SERVER_BAD_CREDENTIALS
		CASS_ERROR_SERVER_UNAVAILABLE CASS_ERROR_SERVER_OVERLOADED CASS_ERROR_SERVER_IS_BOOTSTRAPPING CASS_ERROR_SERVER_TRUNCATE_ERROR
		CASS_ERROR_SERVER_WRITE_TIMEOUT CASS_ERROR_SERVER_READ_TIMEOUT CASS_ERROR_SERVER_SYNTAX_ERROR CASS_ERROR_SERVER_UNAUTHORIZED
		CASS_ERROR_SERVER_INVALID_QUERY CASS_ERROR_SERVER_CONFIG_ERROR CASS_ERROR_SERVER_ALREADY_EXISTS CASS_ERROR_SERVER_UNPREPARED
		CASS_ERROR_SSL_CERT CASS_ERROR_SSL_CA_CERT CASS_ERROR_SSL_PRIVATE_KEY CASS_ERROR_SSL_CRL CASS_ERROR_LAST_ENTRY
	);
};

bootstrap Database::Cassandra::Client $VERSION;

use DynaLoader ();
use Exporter ();

1;


__END__

=head1 NAME

Database::Cassandra::Client - Cassandra client (XS for libcassandra v1.0.x)

=head1 SYNOPSIS

Simple API:

 use Database::Cassandra::Client;
 
 my $cass = Database::Cassandra::Client->cluster_new();
 
 my $status = $cass->sm_connect("node1.domainame.com,node2.domainame.com");
 die $cass->error_desc($status) if $status != CASS_OK;
 
 # insert
 {
 	my $prepare = $cass->sm_prepare("INSERT INTO tw.docs (yauid, body) VALUES (?,?);", $status);
 	die $cass->error_desc($status) if $status != CASS_OK;
 	
	for my $id (1..15)
	{
		my $statement = $cass->prepared_bind($prepare);
		
		$cass->statement_bind_int64($statement, 0, $id);
		$cass->statement_bind_string($statement, 1, "test body bind: $id");
		
		$status = $cass->sm_execute_query($statement);
		die $cass->error_desc($status) if $status != CASS_OK;
		
		$cass->statement_free($statement);
	}
	
	$cass->sm_finish_query($prepare);
 }
 
 # get row
 {
 	my $prepare = $cass->sm_prepare("SELECT * FROM tw.docs where yauid=?", $status);
 	die $cass->error_desc($status) if $status != CASS_OK;
 	
	for my $id (1..15)
	{
		my $statement = $cass->prepared_bind($prepare);
		
		$cass->statement_bind_int64($statement, 0, $id);
		
		my $data = $cass->sm_select_query($statement, $status);
		die $cass->error_desc($status) if $status != CASS_OK;
		
		print $data->[0]->{yauid}, ": ", $data->[0]->{body}, "\n"
			if ref $data && exists $data->[0];
		
		$cass->statement_free($statement);
 	}
	
	$cass->sm_finish_query($prepare);
 }
 
 $cass->sm_destroy();
 

=head1 DESCRIPTION

This is glue for Cassandra C/C++ Driver library version 1.0.x

Please, before install this module make Cassandra library v1.0.x

See https://github.com/datastax/cpp-driver/tree/1.0


=head1 METHODS

=head2 simple

=head3 sm_connect

 my $int_CassError = $cass->sm_connect($contact_points);

Return: CASS_OK if successful, otherwise an error occurred


=head3 sm_execute_query

 my $int_CassError = $cass->sm_execute_query($statement);

Return: CASS_OK if successful, otherwise an error occurred


=head3 sm_execute_query_no_wait

 my $obj_CassFuture = $cass->sm_execute_query_no_wait($statement);

Return: obj_CassFuture


=head3 sm_prepare

 my $obj_CassPrepared = $cass->sm_prepare($query, $out_status);

Return: obj_CassPrepared


=head3 sm_select_query

 my $res = $cass->sm_select_query($statement, $out_status);

Return: variable


=head3 sm_result_from_future

 my $res = $cass->sm_result_from_future($future, $out_status);

Return: variable


=head3 sm_finish_query

 $cass->sm_finish_query($prepared);

Return: undef


=head3 sm_destroy

 $cass->sm_destroy();

Return: undef


=head3 sm_get_session

 my $obj_CassSession = $cass->sm_get_session();

Return: obj_CassSession


=head2 Cluster

=head3 cluster_new

 my $cassandra_object = cluster_new($name);

Creates a new cluster. 

Return: cassandra_object


=head3 cluster_free

 $cass->cluster_free();

Frees a cluster instance. 

Return: undef


=head3 cluster_set_contact_points

 my $int_CassError = $cass->cluster_set_contact_points($contact_points);

Sets/Appends contact points. This *MUST* be set. The first call sets the contact points and any subsequent calls appends additional contact points. Passing an empty string will clear the contact points. White space is striped from the contact points.  Examples: "127.0.0.1" "127.0.0.1,127.0.0.2", "server1.domain.com" 

Return: CASS_OK if successful, otherwise an error occurred


=head3 cluster_set_port

 my $int_CassError = $cass->cluster_set_port($port);

Sets the port.  Default: 9042 

Return: CASS_OK if successful, otherwise an error occurred


=head3 cluster_set_ssl

 $cass->cluster_set_ssl($ssl);

Sets the SSL context and enables SSL. 

Return: undef


=head3 cluster_set_protocol_version

 my $int_CassError = $cass->cluster_set_protocol_version($protocol_version);

Sets the protocol version. This will automatically downgrade if to protocol version 1.  Default: 2 

Return: CASS_OK if successful, otherwise an error occurred


=head3 cluster_set_num_threads_io

 $cass->cluster_set_num_threads_io($num_threads);

Sets the number of IO threads. This is the number of threads that will handle query requests.  Default: 1 

Return: undef


=head3 cluster_set_queue_size_io

 my $int_CassError = $cass->cluster_set_queue_size_io($queue_size);

Sets the size of the the fixed size queue that stores pending requests.  Default: 4096 

Return: CASS_OK if successful, otherwise an error occurred


=head3 cluster_set_queue_size_event

 my $int_CassError = $cass->cluster_set_queue_size_event($queue_size);

Sets the size of the the fixed size queue that stores events.  Default: 4096 

Return: CASS_OK if successful, otherwise an error occurred


=head3 cluster_set_queue_size_log

 my $int_CassError = $cass->cluster_set_queue_size_log($queue_size);

Sets the size of the the fixed size queue that stores log messages.  Default: 4096 

Return: CASS_OK if successful, otherwise an error occurred


=head3 cluster_set_core_connections_per_host

 my $int_CassError = $cass->cluster_set_core_connections_per_host($num_connections);

Sets the number of connections made to each server in each IO thread.  Default: 1 

Return: CASS_OK if successful, otherwise an error occurred


=head3 cluster_set_max_connections_per_host

 my $int_CassError = $cass->cluster_set_max_connections_per_host($num_connections);

Sets the maximum number of connections made to each server in each IO thread.  Default: 2 

Return: CASS_OK if successful, otherwise an error occurred


=head3 cluster_set_reconnect_wait_time

 $cass->cluster_set_reconnect_wait_time($wait_time);

Sets the amount of time to wait before attempting to reconnect.  Default: 2000 milliseconds 

Return: undef


=head3 cluster_set_max_concurrent_creation

 my $int_CassError = $cass->cluster_set_max_concurrent_creation($num_connections);

Sets the maximum number of connections that will be created concurrently. Connections are created when the current connections are unable to keep up with request throughput.  Default: 1 

Return: CASS_OK if successful, otherwise an error occurred


=head3 cluster_set_max_concurrent_requests_threshold

 my $int_CassError = $cass->cluster_set_max_concurrent_requests_threshold($num_requests);

Sets the threshold for the maximum number of concurrent requests in-flight on a connection before creating a new connection. The number of new connections created will not exceed max_connections_per_host.  Default: 100 

Return: CASS_OK if successful, otherwise an error occurred


=head3 cluster_set_max_requests_per_flush

 my $int_CassError = $cass->cluster_set_max_requests_per_flush($num_requests);

Sets the maximum number of requests processed by an IO worker per flush.  Default: 128 

Return: CASS_OK if successful, otherwise an error occurred


=head3 cluster_set_write_bytes_high_water_mark

 my $int_CassError = $cass->cluster_set_write_bytes_high_water_mark($num_bytes);

Sets the high water mark for the number of bytes outstanding on a connection. Disables writes to a connection if the number of bytes queued exceed this value.  Default: 64 KB 

Return: CASS_OK if successful, otherwise an error occurred


=head3 cluster_set_write_bytes_low_water_mark

 my $int_CassError = $cass->cluster_set_write_bytes_low_water_mark($num_bytes);

Sets the low water mark for number of bytes outstanding on a connection. After exceeding high water mark bytes, writes will only resume once the number of bytes fall below this value.  Default: 32 KB 

Return: CASS_OK if successful, otherwise an error occurred


=head3 cluster_set_pending_requests_high_water_mark

 my $int_CassError = $cass->cluster_set_pending_requests_high_water_mark($num_requests);

Sets the high water mark for the number of requests queued waiting for a connection in a connection pool. Disables writes to a host on an IO worker if the number of requests queued exceed this value.  Default: 128 * max_connections_per_host 

Return: CASS_OK if successful, otherwise an error occurred


=head3 cluster_set_pending_requests_low_water_mark

 my $int_CassError = $cass->cluster_set_pending_requests_low_water_mark($num_requests);

Sets the low water mark for the number of requests queued waiting for a connection in a connection pool. After exceeding high water mark requests, writes to a host will only resume once the number of requests fall below this value.  Default: 64 * max_connections_per_host 

Return: CASS_OK if successful, otherwise an error occurred


=head3 cluster_set_connect_timeout

 $cass->cluster_set_connect_timeout($timeout_ms);

Sets the timeout for connecting to a node.  Default: 5000 milliseconds 

Return: undef


=head3 cluster_set_request_timeout

 $cass->cluster_set_request_timeout($timeout_ms);

Sets the timeout for waiting for a response from a node.  Default: 12000 milliseconds 

Return: undef


=head3 cluster_set_credentials

 $cass->cluster_set_credentials($username, $password);

Sets credentials for plain text authentication. 

Return: undef


=head3 cluster_set_load_balance_round_robin

 $cass->cluster_set_load_balance_round_robin();

Configures the cluster to use round-robin load balancing.  The driver discovers all nodes in a cluster and cycles through them per request. All are considered 'local'. 

Return: undef


=head3 cluster_set_load_balance_dc_aware

 my $int_CassError = $cass->cluster_set_load_balance_dc_aware($local_dc, $used_hosts_per_remote_dc, $allow_remote_dcs_for_local_cl);

Configures the cluster to use DC-aware load balancing. For each query, all live nodes in a primary 'local' DC are tried first, followed by any node from other DCs.  Note: This is the default, and does not need to be called unless switching an existing from another policy or changing settings. Without further configuration, a default local_dc is chosen from the first connected contact point, and no remote hosts are considered in query plans. If relying on this mechanism, be sure to use only contact points from the local DC. 

Return: CASS_OK if successful, otherwise an error occurred


=head3 cluster_set_token_aware_routing

 $cass->cluster_set_token_aware_routing($enabled);

Configures the cluster to use Token-aware request routing, or not.  Default is cass_true (enabled).  This routing policy composes the base routing policy, routing requests first to replicas on nodes considered 'local' by the base load balancing policy. 

Return: undef


=head3 cluster_set_tcp_nodelay

 $cass->cluster_set_tcp_nodelay($enable);

Enable/Disable Nagel's algorithm on connections.  Default: cass_false (disabled). 

Return: undef


=head3 cluster_set_tcp_keepalive

 $cass->cluster_set_tcp_keepalive($enable, $delay_secs);

Enable/Disable TCP keep-alive  Default: cass_false (disabled). 

Return: undef


=head2 Session

=head3 session_new

 my $obj_CassSession = $cass->session_new();

Creates a new session. 

Return: obj_CassSession


=head3 session_free

 $cass->session_free($session);

Frees a session instance. If the session is still connected it will be syncronously closed before being deallocated.  Important: Do not free a session in a future callback. Freeing a session in a future callback will cause a deadlock. 

Return: undef


=head3 session_connect

 my $obj_CassFuture = $cass->session_connect($session);

Connects a session. 

Return: obj_CassFuture


=head3 session_connect_keyspace

 my $obj_CassFuture = $cass->session_connect_keyspace($session, $keyspace);

Connects a session and sets the keyspace. 

Return: obj_CassFuture


=head3 session_close

 my $obj_CassFuture = $cass->session_close($session);

Closes the session instance, outputs a close future which can be used to determine when the session has been terminated. This allows in-flight requests to finish. 

Return: obj_CassFuture


=head3 session_prepare

 my $obj_CassFuture = $cass->session_prepare($session, $query);

Create a prepared statement. 

Return: obj_CassFuture


=head3 session_execute

 my $obj_CassFuture = $cass->session_execute($session, $statement);

Execute a query or bound statement. 

Return: obj_CassFuture


=head3 session_execute_batch

 my $obj_CassFuture = $cass->session_execute_batch($session, $batch);

Execute a batch statement. 

Return: obj_CassFuture


=head3 session_get_schema

 my $obj_CassSchema = session_get_schema($session);

Gets a copy of this session's schema metadata. The returned copy of the schema metadata is not updated. This function must be called again to retrieve any schema changes since the previous call. 

Return: obj_CassSchema


=head2 Schema metadata

=head3 schema_free

 $cass->schema_free($schema);

Frees a schema instance. 

Return: undef


=head3 schema_get_keyspace

 my $obj_CassSchemaMeta = $cass->schema_get_keyspace($schema, $keyspace_name);

Gets a the metadata for the provided keyspace name. 

Return: obj_CassSchemaMeta


=head3 schema_meta_type

 my $int_CassSchemaMetaType = $cass->schema_meta_type($meta);

Gets the type of the specified schema metadata. 

Return: int_CassSchemaMetaType


=head3 schema_meta_get_entry

 my $obj_CassSchemaMeta = $cass->schema_meta_get_entry($meta, $name);

Gets a metadata entry for the provided table/column name. 

Return: obj_CassSchemaMeta


=head3 schema_meta_get_field

 my $obj_CassSchemaMetaField = $cass->schema_meta_get_field($meta, $name);

Gets a metadata field for the provided name. 

Return: obj_CassSchemaMetaField


=head3 schema_meta_field_name

 my $res = $cass->schema_meta_field_name($field);

Gets the name for a schema metadata field 

Return: variable


=head3 schema_meta_field_value

 my $obj_CassValue = $cass->schema_meta_field_value($field);

Gets the value for a schema metadata field 

Return: obj_CassValue


=head2 SSL

=head3 ssl_new

 my $obj_CassSsl = ssl_new($void);

Creates a new SSL context. 

Return: obj_CassSsl


=head3 ssl_free

 $cass->ssl_free($ssl);

Frees a SSL context instance. 

Return: undef


=head3 ssl_add_trusted_cert

 my $int_CassError = $cass->ssl_add_trusted_cert($ssl, $tcert_string);

Adds a trusted certificate. This is used to verify the peer's certificate. 

Return: CASS_OK if successful, otherwise an error occurred


=head3 ssl_set_verify_flags

 $cass->ssl_set_verify_flags($ssl, $flags);

Sets verifcation performed on the peer's certificate.  CASS_SSL_VERIFY_NONE - No verification is performed CASS_SSL_VERIFY_PEER_CERT - Certificate is present and valid CASS_SSL_VERIFY_PEER_IDENTITY - IP address matches the certificate's common name or one of its subject alternative names. This implies the certificate is also present.  Default: CASS_SSL_VERIFY_PEER_CERT 

Return: undef


=head3 ssl_set_cert

 my $int_CassError = $cass->ssl_set_cert($ssl, $cert);

Set client-side certificate chain. This is used to authenticate the client on the server-side. This should contain the entire Certificate chain starting with the certificate itself. 

Return: CASS_OK if successful, otherwise an error occurred


=head3 ssl_set_private_key

 my $int_CassError = $cass->ssl_set_private_key($ssl, $key, $password);

Set client-side private key. This is used to authenticate the client on the server-side. 

Return: CASS_OK if successful, otherwise an error occurred


=head2 Future

=head3 future_free

 $cass->future_free($future);

Frees a future instance. A future can be freed anytime. 

Return: undef


=head3 future_set_callback

 my $int_CassError = $cass->future_set_callback($future, $callback, $data);

Sets a callback that is called when a future is set 

Return: CASS_OK if successful, otherwise an error occurred


=head3 future_ready

 my $res = $cass->future_ready($future);

Gets the set status of the future. 

Return: variable


=head3 future_wait

 my $res = $cass->future_wait($future);

Wait for the future to be set with either a result or error.  Important: Do not wait in a future callback. Waiting in a future callback will cause a deadlock. 

Return: variable


=head3 future_wait_timed

 my $res = $cass->future_wait_timed($future, $timeout);

Wait for the future to be set or timeout. 

Return: variable


=head3 future_get_result

 my $obj_CassResult = $cass->future_get_result($future);

Gets the result of a successful future. If the future is not ready this method will wait for the future to be set. The first successful call consumes the future, all subsequent calls will return NULL. 

Return: obj_CassResult


=head3 future_get_prepared

 my $obj_CassPrepared = $cass->future_get_prepared($future);

Gets the result of a successful future. If the future is not ready this method will wait for the future to be set. The first successful call consumes the future, all subsequent calls will return NULL. 

Return: obj_CassPrepared


=head3 future_error_code

 my $int_CassError = $cass->future_error_code($future);

Gets the error code from future. If the future is not ready this method will wait for the future to be set. 

Return: CASS_OK if successful, otherwise an error occurred


=head3 future_error_message

 my $res = $cass->future_error_message($future);

Gets the error message from future. If the future is not ready this method will wait for the future to be set. 

Return: variable


=head2 Statement

=head3 statement_new

 my $obj_CassStatement = $cass->statement_new($query, $parameter_count);

Creates a new query statement. 

Return: obj_CassStatement


=head3 statement_free

 $cass->statement_free($statement);

Frees a statement instance. Statements can be immediately freed after being prepared, executed or added to a batch. 

Return: undef


=head3 statement_add_key_index

 my $int_CassError = $cass->statement_add_key_index($statement, $index);

Adds a key index specifier to this a statement. When using token-aware routing, this can be used to tell the driver which parameters within a non-prepared, parameterized statement are part of the partition key.  Use consecutive calls for composite partition keys.  This is not necessary for prepared statements, as the key parameters are determined in the metadata processed in the prepare phase. 

Return: CASS_OK if successful, otherwise an error occurred


=head3 statement_set_keyspace

 my $int_CassError = $cass->statement_set_keyspace($statement, $keyspace);

Sets the statement's keyspace for use with token-aware routing.  This is not necessary for prepared statements, as the keyspace is determined in the metadata processed in the prepare phase. 

Return: CASS_OK if successful, otherwise an error occurred


=head3 statement_set_consistency

 my $int_CassError = $cass->statement_set_consistency($statement, $consistency);

Sets the statement's consistency level.  Default: CASS_CONSISTENCY_ONE 

Return: CASS_OK if successful, otherwise an error occurred


=head3 statement_set_serial_consistency

 my $int_CassError = $cass->statement_set_serial_consistency($statement, $serial_consistency);

Sets the statement's serial consistency level.  Default: Not set 

Return: CASS_OK if successful, otherwise an error occurred


=head3 statement_set_paging_size

 my $int_CassError = $cass->statement_set_paging_size($statement, $page_size);

Sets the statement's page size.  Default: -1 (Disabled) 

Return: CASS_OK if successful, otherwise an error occurred


=head3 statement_set_paging_state

 my $int_CassError = $cass->statement_set_paging_state($statement, $result);

Sets the statement's paging state. 

Return: CASS_OK if successful, otherwise an error occurred


=head3 statement_bind_null

 my $int_CassError = $cass->statement_bind_null($statement, $index);

Binds null to a query or bound statement at the specified index. 

Return: CASS_OK if successful, otherwise an error occurred


=head3 statement_bind_int32

 my $int_CassError = $cass->statement_bind_int32($statement, $index, $value);

Binds an "int" to a query or bound statement at the specified index. 

Return: CASS_OK if successful, otherwise an error occurred


=head3 statement_bind_int64

 my $int_CassError = $cass->statement_bind_int64($statement, $index, $value);

Binds a "bigint", "counter" or "timestamp" to a query or bound statement at the specified index. 

Return: CASS_OK if successful, otherwise an error occurred


=head3 statement_bind_float

 my $int_CassError = $cass->statement_bind_float($statement, $index, $value);

Binds a "float" to a query or bound statement at the specified index. 

Return: CASS_OK if successful, otherwise an error occurred


=head3 statement_bind_double

 my $int_CassError = $cass->statement_bind_double($statement, $index, $value);

Binds a "double" to a query or bound statement at the specified index. 

Return: CASS_OK if successful, otherwise an error occurred


=head3 statement_bind_bool

 my $int_CassError = $cass->statement_bind_bool($statement, $index, $value);

Binds a "boolean" to a query or bound statement at the specified index. 

Return: CASS_OK if successful, otherwise an error occurred


=head3 statement_bind_string

 my $int_CassError = $cass->statement_bind_string($statement, $index, $value);

Binds a "ascii", "text" or "varchar" to a query or bound statement at the specified index. 

Return: CASS_OK if successful, otherwise an error occurred


=head3 statement_bind_bytes

 my $int_CassError = $cass->statement_bind_bytes($statement, $index, $value);

Binds a "blob" or "varint" to a query or bound statement at the specified index. 

Return: CASS_OK if successful, otherwise an error occurred


=head3 statement_bind_uuid

 my $int_CassError = $cass->statement_bind_uuid($statement, $index, $value);

Binds a "uuid" or "timeuuid" to a query or bound statement at the specified index. 

Return: CASS_OK if successful, otherwise an error occurred


=head3 statement_bind_inet

 my $int_CassError = $cass->statement_bind_inet($statement, $index, $value);

Binds an "inet" to a query or bound statement at the specified index. 

Return: CASS_OK if successful, otherwise an error occurred


=head3 statement_bind_decimal

 my $int_CassError = $cass->statement_bind_decimal($statement, $index, $myhash);

Bind a "decimal" to a query or bound statement at the specified index. 

Return: CASS_OK if successful, otherwise an error occurred


=head3 statement_bind_custom

 my $int_CassError = $cass->statement_bind_custom($statement, $index, $data);

Binds any type to a query or bound statement at the specified index. A value can be copied into the resulting output buffer. This is normally reserved for large values to avoid extra memory copies. 

Return: CASS_OK if successful, otherwise an error occurred


=head3 statement_bind_collection

 my $int_CassError = $cass->statement_bind_collection($statement, $index, $collection);

Bind a "list", "map", or "set" to a query or bound statement at the specified index. 

Return: CASS_OK if successful, otherwise an error occurred


=head3 statement_bind_int32_by_name

 my $int_CassError = $cass->statement_bind_int32_by_name($statement, $name, $value);

Binds an "int" to all the values with the specified name.  This can only be used with statements created by $cass->prepared_bind(). 

Return: CASS_OK if successful, otherwise an error occurred


=head3 statement_bind_int64_by_name

 my $int_CassError = $cass->statement_bind_int64_by_name($statement, $name, $value);

Binds a "bigint", "counter" or "timestamp" to all values with the specified name.  This can only be used with statements created by $cass->prepared_bind(). 

Return: CASS_OK if successful, otherwise an error occurred


=head3 statement_bind_float_by_name

 my $int_CassError = $cass->statement_bind_float_by_name($statement, $name, $value);

Binds a "float" to all the values with the specified name.  This can only be used with statements created by $cass->prepared_bind(). 

Return: CASS_OK if successful, otherwise an error occurred


=head3 statement_bind_double_by_name

 my $int_CassError = $cass->statement_bind_double_by_name($statement, $name, $value);

Binds a "double" to all the values with the specified name.  This can only be used with statements created by $cass->prepared_bind(). 

Return: CASS_OK if successful, otherwise an error occurred


=head3 statement_bind_bool_by_name

 my $int_CassError = $cass->statement_bind_bool_by_name($statement, $name, $value);

Binds a "boolean" to all the values with the specified name.  This can only be used with statements created by $cass->prepared_bind(). 

Return: CASS_OK if successful, otherwise an error occurred


=head3 statement_bind_string_by_name

 my $int_CassError = $cass->statement_bind_string_by_name($statement, $name, $value);

Binds a "ascii", "text" or "varchar" to all the values with the specified name.  This can only be used with statements created by $cass->prepared_bind(). 

Return: CASS_OK if successful, otherwise an error occurred


=head3 statement_bind_bytes_by_name

 my $int_CassError = $cass->statement_bind_bytes_by_name($statement, $name, $value);

Binds a "blob" or "varint" to all the values with the specified name.  This can only be used with statements created by $cass->prepared_bind(). 

Return: CASS_OK if successful, otherwise an error occurred


=head3 statement_bind_uuid_by_name

 my $int_CassError = $cass->statement_bind_uuid_by_name($statement, $name, $value);

Binds a "uuid" or "timeuuid" to all the values with the specified name.  This can only be used with statements created by $cass->prepared_bind(). 

Return: CASS_OK if successful, otherwise an error occurred


=head3 statement_bind_inet_by_name

 my $int_CassError = $cass->statement_bind_inet_by_name($statement, $name, $value);

Binds an "inet" to all the values with the specified name.  This can only be used with statements created by $cass->prepared_bind(). 

Return: CASS_OK if successful, otherwise an error occurred


=head3 statement_bind_decimal_by_name

 my $int_CassError = $cass->statement_bind_decimal_by_name($statement, $name, $myhash);

Binds a "decimal" to all the values with the specified name.  This can only be used with statements created by $cass->prepared_bind(). 

Return: CASS_OK if successful, otherwise an error occurred


=head3 statement_bind_custom_by_name

 my $int_CassError = $cass->statement_bind_custom_by_name($statement, $name, $data);

Binds any type to all the values with the specified name. A value can be copied into the resulting output buffer. This is normally reserved for large values to avoid extra memory copies.  This can only be used with statements created by $cass->prepared_bind(). 

Return: CASS_OK if successful, otherwise an error occurred


=head3 statement_bind_collection_by_name

 my $int_CassError = $cass->statement_bind_collection_by_name($statement, $name, $collection);

Bind a "list", "map", or "set" to all the values with the specified name.  This can only be used with statements created by $cass->prepared_bind(). 

Return: CASS_OK if successful, otherwise an error occurred


=head2 Prepared

=head3 prepared_free

 $cass->prepared_free($prepared);

Frees a prepared instance. 

Return: undef


=head3 prepared_bind

 my $obj_CassStatement = $cass->prepared_bind($prepared);

Creates a bound statement from a pre-prepared statement. 

Return: obj_CassStatement


=head2 Batch

=head3 batch_new

 my $obj_CassBatch = $cass->batch_new($type);

Creates a new batch statement with batch type. 

Return: obj_CassBatch


=head3 batch_free

 $cass->batch_free($batch);

Frees a batch instance. Batches can be immediately freed after being executed. 

Return: undef


=head3 batch_set_consistency

 my $int_CassError = $cass->batch_set_consistency($batch, $consistency);

Sets the batch's consistency level 

Return: CASS_OK if successful, otherwise an error occurred


=head3 batch_add_statement

 my $int_CassError = $cass->batch_add_statement($batch, $statement);

Adds a statement to a batch. 

Return: CASS_OK if successful, otherwise an error occurred


=head2 Collection

=head3 collection_new

 my $obj_CassCollection = $cass->collection_new($type, $item_count);

Creates a new collection. 

Return: obj_CassCollection


=head3 collection_free

 $cass->collection_free($collection);

Frees a collection instance. 

Return: undef


=head3 collection_append_int32

 my $int_CassError = $cass->collection_append_int32($collection, $value);

Appends an "int" to the collection. 

Return: CASS_OK if successful, otherwise an error occurred


=head3 collection_append_int64

 my $int_CassError = $cass->collection_append_int64($collection, $value);

Appends a "bigint", "counter" or "timestamp" to the collection. 

Return: CASS_OK if successful, otherwise an error occurred


=head3 collection_append_float

 my $int_CassError = $cass->collection_append_float($collection, $value);

Appends a "float" to the collection. 

Return: CASS_OK if successful, otherwise an error occurred


=head3 collection_append_double

 my $int_CassError = $cass->collection_append_double($collection, $value);

Appends a "double" to the collection. 

Return: CASS_OK if successful, otherwise an error occurred


=head3 collection_append_bool

 my $int_CassError = $cass->collection_append_bool($collection, $value);

Appends a "boolean" to the collection. 

Return: CASS_OK if successful, otherwise an error occurred


=head3 collection_append_string

 my $int_CassError = $cass->collection_append_string($collection, $value);

Appends a "ascii", "text" or "varchar" to the collection. 

Return: CASS_OK if successful, otherwise an error occurred


=head3 collection_append_bytes

 my $int_CassError = $cass->collection_append_bytes($collection, $value);

Appends a "blob" or "varint" to the collection. 

Return: CASS_OK if successful, otherwise an error occurred


=head3 collection_append_uuid

 my $int_CassError = $cass->collection_append_uuid($collection, $value);

Appends a "uuid" or "timeuuid"  to the collection. 

Return: CASS_OK if successful, otherwise an error occurred


=head3 collection_append_inet

 my $int_CassError = $cass->collection_append_inet($collection, $value);

Appends an "inet" to the collection. 

Return: CASS_OK if successful, otherwise an error occurred


=head3 collection_append_decimal

 my $int_CassError = $cass->collection_append_decimal($collection, $myhash);

Appends a "decimal" to the collection. 

Return: CASS_OK if successful, otherwise an error occurred


=head2 Result

=head3 result_free

 $cass->result_free($result);

Frees a result instance.  This method invalidates all values, rows, and iterators that were derived from this result. 

Return: undef


=head3 result_row_count

 my $res = $cass->result_row_count($result);

Gets the number of rows for the specified result. 

Return: variable


=head3 result_column_count

 my $res = $cass->result_column_count($result);

Gets the number of columns per row for the specified result. 

Return: variable


=head3 result_column_name

 my $res = $cass->result_column_name($result, $index);

Gets the column name at index for the specified result. 

Return: variable


=head3 result_column_type

 my $res = $cass->result_column_type($result, $index);

Gets the column type at index for the specified result. 

Return: variable


=head3 result_first_row

 my $obj_CassRow = $cass->result_first_row($result);

Gets the first row of the result. 

Return: obj_CassRow


=head3 result_has_more_pages

 my $res = $cass->result_has_more_pages($result);

Returns true if there are more pages. 

Return: variable


=head2 Iterator

=head3 iterator_free

 $cass->iterator_free($iterator);

Frees an iterator instance. 

Return: undef


=head3 iterator_type

 my $CassIteratorType = $cass->iterator_type($iterator);

Gets the type of the specified iterator. 

Return: CassIteratorType


=head3 iterator_from_result

 my $obj_CassIterator = $cass->iterator_from_result($result);

Creates a new iterator for the specified result. This can be used to iterate over rows in the result. 

Return: obj_CassIterator


=head3 iterator_from_row

 my $obj_CassIterator = $cass->iterator_from_row($row);

Creates a new iterator for the specified row. This can be used to iterate over columns in a row. 

Return: obj_CassIterator


=head3 iterator_from_collection

 my $obj_CassIterator = $cass->iterator_from_collection($value);

Creates a new iterator for the specified collection. This can be used to iterate over values in a collection. 

Return: obj_CassIterator


=head3 iterator_from_map

 my $obj_CassIterator = $cass->iterator_from_map($value);

Creates a new iterator for the specified map. This can be used to iterate over key/value pairs in a map. 

Return: obj_CassIterator


=head3 iterator_from_schema

 my $obj_CassIterator = $cass->iterator_from_schema($schema);

Creates a new iterator for the specified schema. This can be used to iterate over keyspace entries. 

Return: obj_CassIterator


=head3 iterator_from_schema_meta

 my $obj_CassIterator = $cass->iterator_from_schema_meta($meta);

Creates a new iterator for the specified schema metadata. This can be used to iterate over table/column entries. 

Return: obj_CassIterator


=head3 iterator_fields_from_schema_meta

 my $obj_CassIterator = $cass->iterator_fields_from_schema_meta($meta);

Creates a new iterator for the specified schema metadata. This can be used to iterate over schema metadata fields. 

Return: obj_CassIterator


=head3 iterator_next

 my $res = $cass->iterator_next($iterator);

Advance the iterator to the next row, column, or collection item. 

Return: variable


=head3 iterator_get_row

 my $obj_CassRow = $cass->iterator_get_row($iterator);

Gets the row at the result iterator's current position.  Calling $cass->iterator_next() will invalidate the previous row returned by this method. 

Return: obj_CassRow


=head3 iterator_get_column

 my $obj_CassValue = $cass->iterator_get_column($iterator);

Gets the column value at the row iterator's current position.  Calling $cass->iterator_next() will invalidate the previous column returned by this method. 

Return: obj_CassValue


=head3 iterator_get_value

 my $obj_CassValue = $cass->iterator_get_value($iterator);

Gets the value at the collection iterator's current position.  Calling $cass->iterator_next() will invalidate the previous value returned by this method. 

Return: obj_CassValue


=head3 iterator_get_map_key

 my $obj_CassValue = $cass->iterator_get_map_key($iterator);

Gets the key at the map iterator's current position.  Calling $cass->iterator_next() will invalidate the previous value returned by this method. 

Return: obj_CassValue


=head3 iterator_get_map_value

 my $obj_CassValue = $cass->iterator_get_map_value($iterator);

Gets the value at the map iterator's current position.  Calling $cass->iterator_next() will invalidate the previous value returned by this method. 

Return: obj_CassValue


=head3 iterator_get_schema_meta

 my $obj_CassSchemaMeta = $cass->iterator_get_schema_meta($iterator);

Gets the schema metadata entry at the iterator's current position.  Calling $cass->iterator_next() will invalidate the previous value returned by this method. 

Return: obj_CassSchemaMeta


=head3 iterator_get_schema_meta_field

 my $obj_CassSchemaMetaField = $cass->iterator_get_schema_meta_field($iterator);

Gets the schema metadata field at the iterator's current position.  Calling $cass->iterator_next() will invalidate the previous value returned by this method. 

Return: obj_CassSchemaMetaField


=head2 Row

=head3 row_get_column

 my $obj_CassValue = $cass->row_get_column($row, $index);

Get the column value at index for the specified row. 

Return: obj_CassValue


=head3 row_get_column_by_name

 my $obj_CassValue = $cass->row_get_column_by_name($row, $name);

Get the column value by name for the specified row. 

Return: obj_CassValue


=head2 Value

=head3 value_get_int32

 my $int_CassError = $cass->value_get_int32($value, $output);

Gets an int32 for the specified value. 

Return: CASS_OK if successful, otherwise an error occurred


=head3 value_get_int64

 my $int_CassError = $cass->value_get_int64($value, $output);

Gets an int64 for the specified value. 

Return: CASS_OK if successful, otherwise an error occurred


=head3 value_get_float

 my $int_CassError = $cass->value_get_float($value, $output);

Gets a float for the specified value. 

Return: CASS_OK if successful, otherwise an error occurred


=head3 value_get_double

 my $int_CassError = $cass->value_get_double($value, $output);

Gets a double for the specified value. 

Return: CASS_OK if successful, otherwise an error occurred


=head3 value_get_bool

 my $int_CassError = $cass->value_get_bool($value, $output);

Gets a bool for the specified value. 

Return: CASS_OK if successful, otherwise an error occurred


=head3 value_get_uuid

 my $int_CassError = $cass->value_get_uuid($value, $output);

Gets a UUID for the specified value. 

Return: CASS_OK if successful, otherwise an error occurred


=head3 value_get_inet

 my $int_CassError = $cass->value_get_inet($value, $output);

Gets an INET for the specified value. 

Return: CASS_OK if successful, otherwise an error occurred


=head3 value_get_string

 my $int_CassError = $cass->value_get_string($value, $output);

Gets a string for the specified value. 

Return: CASS_OK if successful, otherwise an error occurred


=head3 value_get_bytes

 my $int_CassError = $cass->value_get_bytes($value, $output);

Gets the bytes of the specified value. 

Return: CASS_OK if successful, otherwise an error occurred


=head3 value_get_decimal

 my $int_CassError = $cass->value_get_decimal($value, $output);

Gets a decimal for the specified value. 

Return: CASS_OK if successful, otherwise an error occurred


=head3 value_type

 my $res = $cass->value_type($value);

Gets the type of the specified value. 

Return: variable


=head3 value_is_null

 my $res = $cass->value_is_null($value);

Returns true if a specified value is null. 

Return: variable


=head3 value_is_collection

 my $res = $cass->value_is_collection($value);

Returns true if a specified value is a collection. 

Return: variable


=head3 value_item_count

 my $res = $cass->value_item_count($value);

Get the number of items in a collection. Works for all collection types. 

Return: variable


=head3 value_primary_sub_type

 my $res = $cass->value_primary_sub_type($collection);

Get the primary sub-type for a collection. This returns the sub-type for a list or set and the key type for a map. 

Return: variable


=head3 value_secondary_sub_type

 my $res = $cass->value_secondary_sub_type($collection);

Get the secondary sub-type for a collection. This returns the value type for a map. 

Return: variable


=head2 UUID

=head3 uuid_gen_new

 my $CassUuidGen = uuid_gen_new($void);

Creates a new UUID generator.  Note: This object is thread-safe. It is best practice to create and reuse a single object per application.  Note: If unique node information (IP address) is unable to be determined then random node information will be generated. 

Return: CassUuidGen


=head3 uuid_gen_new_with_node

 my $CassUuidGen = uuid_gen_new_with_node($node);

Creates a new UUID generator with custom node information.  Note: This object is thread-safe. It is best practice to create and reuse a single object per application. 

Return: CassUuidGen


=head3 uuid_gen_free

 uuid_gen_free($uuid_gen);

Frees a UUID generator instance. 

Return: undef


=head3 uuid_gen_time

 uuid_gen_time($uuid_gen, $output);

Generates a V1 (time) UUID.  Note: This method is thread-safe 

Return: undef


=head3 uuid_gen_random

 uuid_gen_random($uuid_gen, $output);

Generates a new V4 (random) UUID  Note: This method is thread-safe 

Return: undef


=head3 uuid_gen_from_time

 uuid_gen_from_time($uuid_gen, $timestamp, $output);

Generates a V1 (time) UUID for the specified time.  Note: This method is thread-safe 

Return: undef


=head3 uuid_min_from_time

 uuid_min_from_time($timestamp, $output);

Sets the UUID to the minimum V1 (time) value for the specified time. 

Return: undef


=head3 uuid_max_from_time

 $cass->uuid_max_from_time($time, $output);

Sets the UUID to the maximum V1 (time) value for the specified time. 

Return: undef


=head3 uuid_timestamp

 my $res = uuid_timestamp($uuid);

Gets the timestamp for a V1 UUID 

Return: variable


=head3 uuid_version

 my $res = uuid_version($uuid);

Gets the version for a UUID 

Return: variable


=head3 uuid_string

 uuid_string($uuid, $output);

Returns a null-terminated string for the specified UUID. 

Return: undef


=head3 uuid_from_string

 my $int_CassError = uuid_from_string($uuid_str, $output);

Returns a UUID for the specified string.  Example: "550e8400-e29b-41d4-a716-446655440000" 

Return: CASS_OK if successful, otherwise an error occurred


=head2 Error

=head3 error_desc

 my $res = $cass->error_desc($error_code);

Gets a description for an error code. 

Return: variable


=head2 Log

=head3 log_set_level

 log_set_level($level);

Sets the log level.  Note: This needs to be done before any call that might log, such as any of the $cass->cluster_*() or $cass->ssl_*() functions.  Default: CASS_LOG_WARN 

Return: undef


=head3 log_set_callback

 $cass->log_set_callback($callback, $data);

Sets a callback for handling logging events.  Note: This needs to be done before any call that might log, such as any of the $cass->cluster_*() or $cass->ssl_*() functions.  Default: An internal callback that prints to stderr 

Return: undef


=head3 log_level_string

 my $res = $cass->log_level_string($log_level);

Gets the string for a log level. 

Return: variable


=head2 Inet

=head3 inet_init_v4

 my $res = $cass->inet_init_v4($data);

Constructs an inet v4 object. 

Return: variable


=head3 inet_init_v6

 my $res = $cass->inet_init_v6($data);

Constructs an inet v6 object. 

Return: variable


=head2 Decimal

=head3 decimal_init

 my $res = $cass->decimal_init($scale, $varint);

Constructs a decimal object.  Note: This does not allocate memory. The object wraps the pointer passed into this function. 

Return: variable


=head2 Bytes/String

=head3 bytes_init

 my $res = $cass->bytes_init($data, $size);

Constructs a bytes object.  Note: This does not allocate memory. The object wraps the pointer passed into this function. 

Return: variable


=head3 string_init

 my $res = $cass->string_init($string);

Constructs a string object from a null-terminated string.  Note: This does not allocate memory. The object wraps the pointer passed into this function. 

Return: variable


=head3 string_init2

 my $res = $cass->string_init2($string, $length);

Constructs a string object.  Note: This does not allocate memory. The object wraps the pointer passed into this function. 

Return: variable


=head2 other

=head3 value_type_name_by_code

 my $res = $cass->value_type_name_by_code($vtype);

Return: variable


=head1 DESTROY

 undef $cass;

Free mem and destroy object.

=head1 AUTHOR

Alexander Borisov <lex.borisov@gmail.com>

https://github.com/lexborisov/perl-database-cassandra-client

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Alexander Borisov.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

See libcassandra license and COPYRIGHT https://github.com/datastax/cpp-driver


=cut
