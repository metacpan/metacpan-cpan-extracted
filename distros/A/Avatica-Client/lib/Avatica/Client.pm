package Avatica::Client;

# ABSTRACT: Client for Apache Calcite Avatica

use strict;
use warnings;
use Carp 'croak';
use HTTP::Tiny;
use Time::HiRes qw/sleep/;

use Google::ProtocolBuffers::Dynamic 0.30;

use constant MAX_RETRIES => 0;
use constant CLASS_REQUEST_PREFIX => 'org.apache.calcite.avatica.proto.Requests$';

our $VERSION = '0.003';

sub new {
  my ($class, %params) = @_;
  croak q{param "url" is required} unless $params{url};
  my $ua = $params{ua} // HTTP::Tiny->new;

  my $self = {
    url => $params{url},
    max_retries => $params{max_retries} // $class->MAX_RETRIES,
    ua => $ua
  };
  return bless $self, $class;
}

sub url { $_[0]->{url} }
sub ua { $_[0]->{ua} }
sub max_retries { $_[0]->{max_retries} }
sub headers { +{'Content-Type' => 'application/x-google-protobuf'} }

sub apply {
  my ($self, $request_name, $request) = @_;

  my $body = $self->wrap_request($request_name, $request);

  my ($status, $response_body) = $self->post_request($body);
  if (int($status / 100) != 2) {
    return 0, $self->parse_error($status, $response_body);
  }
  my $response = $self->unwrap_response($response_body);
  return 1, $response;
}

sub post_request {
  my ($self, $body) = @_;

  my $response;
  my $retry_count = $self->max_retries + 1;
  while ($retry_count > 0) {
    $retry_count--;

    $response = $self->ua->post($self->url, {
      headers => $self->headers,
      content => $body
    });

    unless ($response->{success}) {
      # network errors
      last if $response->{status} == 599;
      # client errors
      last if int($response->{status} / 100) == 4;
      # server errors
      if (int($response->{status} / 100) == 5) {
        sleep(exp -($retry_count - 1)) if $retry_count > 0;
        next;
      }
    }
    last;
  }

  return @$response{qw/status content/};
}

sub wrap_request {
  my ($self, $request_name, $request) = @_;
  my $wire_msg = Avatica::Client::Protocol::WireMessage->new;
  $wire_msg->set_name($self->CLASS_REQUEST_PREFIX . $request_name);
  $wire_msg->set_wrapped_message($request);
  return Avatica::Client::Protocol::WireMessage->encode($wire_msg);
}

sub unwrap_response {
  my ($self, $response_body) = @_;
  my $wire_msg = Avatica::Client::Protocol::WireMessage->decode($response_body);
  return $wire_msg->get_wrapped_message;
}

sub parse_error {
  my ($self, $status, $response) = @_;

  my $msg = $status == 599 ?
      {message => $response} :                 # network errors
      $self->parse_protobuf_error($response);  # other errors from avatica

  $msg->{http_status} = $status;
  return $msg;
}

sub parse_protobuf_error {
  my ($self, $response_body) = @_;
  my $response_encoded = $self->unwrap_response($response_body);
  my $error = Avatica::Client::Protocol::ErrorResponse->decode($response_encoded);
  my $msg = {
    message => $error->get_error_message,
    protocol => {
      message => $error->get_error_message,
      severity => $error->get_severity,
      error_code => $error->get_error_code,
      sql_state => $error->get_sql_state
    }
  };
  $msg->{protocol}{exceptions} = $error->get_exceptions_list if $error->get_has_exceptions;
  return $msg;
}

sub open_connection {
  my ($self, $connection_id, $info) = @_;

  my $c = Avatica::Client::Protocol::OpenConnectionRequest->new;
  $c->set_connection_id($connection_id);
  $c->set_info_map($info) if $info;
  my $msg = Avatica::Client::Protocol::OpenConnectionRequest->encode($c);

  my ($res, $response) = $self->apply('OpenConnectionRequest', $msg);
  return ($res, $response) unless $res;

  $response = Avatica::Client::Protocol::OpenConnectionResponse->decode($response);
  return ($res, $response);
}

sub close_connection {
  my ($self, $connection_id) = @_;

  my $c = Avatica::Client::Protocol::CloseConnectionRequest->new;
  $c->set_connection_id($connection_id);
  my $msg = Avatica::Client::Protocol::CloseConnectionRequest->encode($c);

  my ($res, $response) = $self->apply('CloseConnectionRequest', $msg);
  return ($res, $response) unless $res;

  $response = Avatica::Client::Protocol::CloseConnectionResponse->decode($response);
  return ($res, $response);
}

sub catalog {
  my ($self, $connection_id) = @_;

  my $c = Avatica::Client::Protocol::CatalogsRequest->new;
  $c->set_connection_id($connection_id);
  my $msg = Avatica::Client::Protocol::CatalogsRequest->encode($c);

  my ($res, $response) = $self->apply('CatalogsRequest', $msg);
  return ($res, $response) unless $res;

  $response = Avatica::Client::Protocol::ResultSetResponse->decode($response);
  return ($res, $response);
}

sub columns {
  my ($self, $connection_id, $catalog, $schema_pattern, $table_pattern, $column_pattern) = @_;

  my $c = Avatica::Client::Protocol::ColumnsRequest->new;
  $c->set_connection_id($connection_id);
  if ($catalog) {
    $c->set_catalog($catalog);
    $c->set_has_catalog(1);
  }
  if ($schema_pattern) {
    $c->set_schema_pattern($schema_pattern);
    $c->set_has_schema_pattern(1);
  }
  if ($table_pattern) {
    $c->set_table_name_pattern($table_pattern);
    $c->set_has_table_name_pattern(1);
  }
  if ($column_pattern) {
    $c->set_column_name_pattern($column_pattern);
    $c->set_has_column_name_pattern(1);
  }
  my $msg = Avatica::Client::Protocol::ColumnsRequest->encode($c);

  my ($res, $response) = $self->apply('ColumnsRequest', $msg);
  return ($res, $response) unless $res;

  $response = Avatica::Client::Protocol::ResultSetResponse->decode($response);
  return ($res, $response);
}

sub database_property {
  my ($self, $connection_id) = @_;

  my $d = Avatica::Client::Protocol::DatabasePropertyRequest->new;
  $d->set_connection_id($connection_id);
  my $msg = Avatica::Client::Protocol::DatabasePropertyRequest->encode($d);

  my ($res, $response) = $self->apply('DatabasePropertyRequest', $msg);
  return ($res, $response) unless $res;

  $response = Avatica::Client::Protocol::DatabasePropertyResponse->decode($response);
  return ($res, $response);
}

sub schemas {
  my ($self, $connection_id, $catalog, $schema_pattern) = @_;

  my $s = Avatica::Client::Protocol::SchemasRequest->new;
  $s->set_connection_id($connection_id);
  if ($catalog) {
    $s->set_catalog($catalog);
    $s->set_has_catalog(1);
  }
  if ($schema_pattern) {
    $s->set_schema_pattern($schema_pattern);
    $s->set_has_schema_pattern(1);
  }
  my $msg = Avatica::Client::Protocol::SchemasRequest->encode($s);

  my ($res, $response) = $self->apply('SchemasRequest', $msg);
  return ($res, $response) unless $res;

  $response = Avatica::Client::Protocol::ResultSetResponse->decode($response);
  return ($res, $response);
}

sub tables {
  my ($self, $connection_id, $catalog, $schema_pattern, $table_pattern, $type_list) = @_;

  my $t = Avatica::Client::Protocol::TablesRequest->new;
  $t->set_connection_id($connection_id);
  if ($catalog) {
    $t->set_catalog($catalog);
    $t->set_has_catalog(1);
  }
  if ($schema_pattern) {
    $t->set_schema_pattern($schema_pattern);
    $t->set_has_schema_pattern(1);
  }
  if ($table_pattern) {
    $t->set_table_name_pattern($table_pattern);
    $t->set_has_table_name_pattern(1);
  }
  if ($type_list) {
    $t->set_type_list($type_list);
    $t->set_has_type_list(1);
  }
  my $msg = Avatica::Client::Protocol::TablesRequest->encode($t);

  my ($res, $response) = $self->apply('TablesRequest', $msg);
  return ($res, $response) unless $res;

  $response = Avatica::Client::Protocol::ResultSetResponse->decode($response);
  return ($res, $response);
}

sub type_info {
  my ($self, $connection_id) = @_;

  my $t = Avatica::Client::Protocol::TypeInfoRequest->new;
  $t->set_connection_id($connection_id);
  my $msg = Avatica::Client::Protocol::TypeInfoRequest->encode($t);

  my ($res, $response) = $self->apply('TypeInfoRequest', $msg);
  return ($res, $response) unless $res;

  $response = Avatica::Client::Protocol::ResultSetResponse->decode($response);
  return ($res, $response);
}

sub table_types {
  my ($self, $connection_id) = @_;

  my $t = Avatica::Client::Protocol::TableTypesRequest->new;
  $t->set_connection_id($connection_id);
  my $msg = Avatica::Client::Protocol::TableTypesRequest->encode($t);

  my ($res, $response) = $self->apply('TableTypesRequest', $msg);
  return ($res, $response) unless $res;

  $response = Avatica::Client::Protocol::ResultSetResponse->decode($response);
  return ($res, $response);
}

# return (ret, ResultSetResponse)
sub primary_keys {
  my ($self, $connection_id, $catalog, $schema, $table) = @_;

  my ($res, $statement) = $self->create_statement($connection_id);
  return ($res, $statement) unless $res;

  my $statement_id = $statement->get_statement_id;

  my $qs = Avatica::Client::Protocol::QueryState->new;
  $qs->set_type(Avatica::Client::Protocol::StateType::METADATA());
  $qs->set_op(Avatica::Client::Protocol::MetaDataOperation::GET_PRIMARY_KEYS());
  $qs->set_has_args(1);
  $qs->set_has_op(1);

  for my $arg ($catalog, $schema, $table) {
    my $mdoa = Avatica::Client::Protocol::MetaDataOperationArgument->new;
    if ($arg) {
      $mdoa->set_type(Avatica::Client::Protocol::MetaDataOperationArgument::ArgumentType::STRING());
      $mdoa->set_string_value($arg);
    }
    else {
      $mdoa->set_type(Avatica::Client::Protocol::MetaDataOperationArgument::ArgumentType::NULL());
    }
    $qs->add_args($mdoa);
  }

  ($res, my $sync_res) = $self->sync_results($connection_id, $statement_id, $qs);
  return ($res, $sync_res) unless $res;

  my $s = Avatica::Client::Protocol::Signature->new;
  # IMPORTANT: many databases have additional columns that need to be specified additionally
  $s->add_columns($self->_build_column_metadata(1, 'TABLE_CAT', 12));
  $s->add_columns($self->_build_column_metadata(2, 'TABLE_SCHEM', 12));
  $s->add_columns($self->_build_column_metadata(3, 'TABLE_NAME', 12));
  $s->add_columns($self->_build_column_metadata(4, 'COLUMN_NAME', 12));
  $s->add_columns($self->_build_column_metadata(5, 'KEY_SEQ', 5));
  $s->add_columns($self->_build_column_metadata(6, 'PK_NAME', 12));

  my $f = Avatica::Client::Protocol::Frame->new;
  $f->set_offset(0);
  $f->set_done($sync_res->get_more_results ? 0 : 1);

  my $r = Avatica::Client::Protocol::ResultSetResponse->new;
  $r->set_signature($s);
  $r->set_connection_id($connection_id);
  $r->set_statement_id($statement_id);
  $r->set_own_statement(1);
  $r->set_update_count('18446744073709551615');
  $r->set_metadata($sync_res->get_metadata);
  $r->set_first_frame($f);

  return (1, $r);
}

sub connection_sync {
  my ($self, $connection_id, $props) = @_;

  my $p = Avatica::Client::Protocol::ConnectionProperties->new;
  if (exists $props->{AutoCommit}) {
    $p->set_auto_commit($props->{AutoCommit});
    $p->set_has_auto_commit(1);
  }
  if (exists $props->{ReadOnly}) {
    $p->set_read_only($props->{ReadOnly});
    $p->set_has_read_only(1);
  }
  if (exists $props->{TransactionIsolation}) {
    $p->set_transaction_isolation($props->{TransactionIsolation});
  }
  if (exists $props->{Catalog}) {
    $p->set_catalog($props->{Catalog});
  }
  if (exists $props->{Schema}) {
    $p->set_schema($props->{Schema});
  }

  my $c = Avatica::Client::Protocol::ConnectionSyncRequest->new;
  $c->set_connection_id($connection_id);
  $c->set_conn_props($p);
  my $msg = Avatica::Client::Protocol::ConnectionSyncRequest->encode($c);

  my ($res, $response) = $self->apply('ConnectionSyncRequest', $msg);
  return ($res, $response) unless $res;

  $response = Avatica::Client::Protocol::ConnectionSyncResponse->decode($response);
  return ($res, $response);
}

sub commit {
  my ($self, $connection_id) = @_;

  my $c = Avatica::Client::Protocol::CommitRequest->new;
  $c->set_connection_id($connection_id);
  my $msg = Avatica::Client::Protocol::CommitRequest->encode($c);

  my ($res, $response) = $self->apply('CommitRequest', $msg);
  return ($res, $response) unless $res;

  $response = Avatica::Client::Protocol::CommitResponse->decode($response);
  return ($res, $response);
}

sub rollback {
  my ($self, $connection_id) = @_;

  my $r = Avatica::Client::Protocol::RollbackRequest->new;
  $r->set_connection_id($connection_id);
  my $msg = Avatica::Client::Protocol::RollbackRequest->encode($r);

  my ($res, $response) = $self->apply('RollbackRequest', $msg);
  return ($res, $response) unless $res;

  $response = Avatica::Client::Protocol::RollbackResponse->decode($response);
  return ($res, $response);
}

sub create_statement {
  my ($self, $connection_id) = @_;

  my $s = Avatica::Client::Protocol::CreateStatementRequest->new;
  $s->set_connection_id($connection_id);
  my $msg = Avatica::Client::Protocol::CreateStatementRequest->encode($s);

  my ($res, $response) = $self->apply('CreateStatementRequest', $msg);
  return ($res, $response) unless $res;

  $response = Avatica::Client::Protocol::CreateStatementResponse->decode($response);
  return ($res, $response);
}

sub close_statement {
  my ($self, $connection_id, $statement_id) = @_;

  my $c = Avatica::Client::Protocol::CloseStatementRequest->new;
  $c->set_connection_id($connection_id);
  $c->set_statement_id($statement_id);
  my $msg = Avatica::Client::Protocol::CloseStatementRequest->encode($c);

  my ($res, $response) = $self->apply('CloseStatementRequest', $msg);
  return ($res, $response) unless $res;

  $response = Avatica::Client::Protocol::CloseStatementResponse->decode($response);
  return ($res, $response);
}

sub prepare_and_execute {
  my ($self, $connection_id, $statement_id, $sql, $max_rows_total, $first_frame_max_size) = @_;

  my $pe = Avatica::Client::Protocol::PrepareAndExecuteRequest->new;
  $pe->set_connection_id($connection_id);
  $pe->set_statement_id($statement_id);
  $pe->set_sql($sql);
  $pe->set_max_rows_total($max_rows_total) if $max_rows_total;
  $pe->set_first_frame_max_size($first_frame_max_size) if $first_frame_max_size;
  my $msg = Avatica::Client::Protocol::PrepareAndExecuteRequest->encode($pe);

  my ($res, $response) = $self->apply('PrepareAndExecuteRequest', $msg);
  return ($res, $response) unless $res;

  $response = Avatica::Client::Protocol::ExecuteResponse->decode($response);
  return 0, {message => 'missing statement id'} if $response->get_missing_statement;

  return ($res, $response);
}

sub prepare {
  my ($self, $connection_id, $sql, $max_rows_total) = @_;

  my $p = Avatica::Client::Protocol::PrepareRequest->new;
  $p->set_connection_id($connection_id);
  $p->set_sql($sql);
  $p->set_max_rows_total($max_rows_total) if $max_rows_total;
  my $msg = Avatica::Client::Protocol::PrepareRequest->encode($p);

  my ($res, $response) = $self->apply('PrepareRequest', $msg);
  return ($res, $response) unless $res;

  $response = Avatica::Client::Protocol::PrepareResponse->decode($response);

  return ($res, $response);
}

sub execute {
  my ($self, $connection_id, $statement_id, $signature, $param_values, $first_frame_max_size) = @_;

  my $sh = Avatica::Client::Protocol::StatementHandle->new;
  $sh->set_id($statement_id);
  $sh->set_connection_id($connection_id);
  $sh->set_signature($signature);

  my $e = Avatica::Client::Protocol::ExecuteRequest->new;
  $e->set_statementHandle($sh);
  if ($param_values && @$param_values) {
    $e->set_parameter_values_list($param_values);
    $e->set_has_parameter_values(1);
  } else {
    $e->set_has_parameter_values(0);
  }
  if ($first_frame_max_size) {
    $e->set_first_frame_max_size($first_frame_max_size);
    $e->set_deprecated_first_frame_max_size($first_frame_max_size);
  }

  my $msg = Avatica::Client::Protocol::ExecuteRequest->encode($e);

  my ($res, $response) = $self->apply('ExecuteRequest', $msg);
  return ($res, $response) unless $res;

  $response = Avatica::Client::Protocol::ExecuteResponse->decode($response);
  return 0, {message => 'missing statement id'} if $response->get_missing_statement;

  return ($res, $response);
}

# prepare and execute batch of **UPDATES**
sub prepare_and_execute_batch {
  my ($self, $connection_id, $statement_id, $sqls) = @_;

  my $p = Avatica::Client::Protocol::PrepareAndExecuteBatchRequest->new;
  $p->set_connection_id($connection_id);
  $p->set_statement_id($statement_id);
  for my $sql (@$sqls) {
    $p->add_sql_commands($sql);
  }
  my $msg = Avatica::Client::Protocol::PrepareAndExecuteBatchRequest->encode($p);

  my ($res, $response) = $self->apply('PrepareAndExecuteBatchRequest', $msg);
  return ($res, $response) unless $res;

  $response = Avatica::Client::Protocol::ExecuteBatchResponse->decode($response);
  return 0, {message => 'missing statement id'} if $response->get_missing_statement;
  return ($res, $response);
}

# execute batch of **UPDATES**
sub execute_batch {
  my ($self, $connection_id, $statement_id, $rows) = @_;

  my $eb = Avatica::Client::Protocol::ExecuteBatchRequest->new;
  $eb->set_connection_id($connection_id);
  $eb->set_statement_id($statement_id);
  for my $row (@{$rows // []}) {
    my $ub = Avatica::Client::Protocol::UpdateBatch->new;
    for my $col (@$row) {
      $ub->add_parameter_values($col);
    }
    $eb->add_updates($ub);
  }
  my $msg = Avatica::Client::Protocol::ExecuteBatchRequest->encode($eb);

  my ($res, $response) = $self->apply('ExecuteBatchRequest', $msg);
  return ($res, $response) unless $res;

  $response = Avatica::Client::Protocol::ExecuteBatchResponse->decode($response);
  return 0, {message => 'missing statement id'} if $response->get_missing_statement;
  return ($res, $response);
}

sub fetch {
  my ($self, $connection_id, $statement_id, $offset, $frame_max_size) = @_;

  my $f = Avatica::Client::Protocol::FetchRequest->new;
  $f->set_connection_id($connection_id);
  $f->set_statement_id($statement_id);
  $f->set_offset($offset) if defined $offset;
  $f->set_frame_max_size($frame_max_size) if $frame_max_size;
  my $msg = Avatica::Client::Protocol::FetchRequest->encode($f);

  my ($res, $response) = $self->apply('FetchRequest', $msg);
  return ($res, $response) unless $res;

  $response = Avatica::Client::Protocol::FetchResponse->decode($response);

  return 0, {message => 'missing statement id'} if $response->get_missing_statement;
  return 0, {message => 'missing result set'} if $response->get_missing_results;

  return ($res, $response);
}

sub sync_results {
  my ($self, $connection_id, $statement_id, $state, $offset) = @_;

  my $s = Avatica::Client::Protocol::SyncResultsRequest->new;
  $s->set_connection_id($connection_id);
  $s->set_statement_id($statement_id);
  $s->set_state($state);
  $s->set_offset($offset) if defined $offset;
  my $msg = Avatica::Client::Protocol::SyncResultsRequest->encode($s);

  my ($res, $response) = $self->apply('SyncResultsRequest', $msg);
  return ($res, $response) unless $res;

  $response = Avatica::Client::Protocol::SyncResultsResponse->decode($response);
  return 0, {message => 'missing statement id'} if $response->get_missing_statement;
  return ($res, $response);
}

sub _build_column_metadata {
  my ($self_or_class, $ordinal, $column_name, $jdbc_type_id) = @_;
  my $t = Avatica::Client::Protocol::AvaticaType->new;
  $t->set_id($jdbc_type_id);
  my $cmd = Avatica::Client::Protocol::ColumnMetaData->new;
  $cmd->set_ordinal($ordinal);
  $cmd->set_column_name($column_name);
  $cmd->set_nullable(2);
  $cmd->set_type($t);
  return $cmd;
}

sub _data_section {
  my $class = shift;
  my $handle = do { no strict 'refs'; \*{"${class}::DATA"} };
  return unless fileno $handle;
  seek $handle, 0, 0;
  local $/ = undef;
  my $data = <$handle>;
  $data =~ s/^.*\n__DATA__\r?\n//s;
  $data =~ s/\r?\n__END__\r?\n.*$//s;
  return $data;
}

my $dynamic = Google::ProtocolBuffers::Dynamic->new;
$dynamic->load_string("avatica.proto", _data_section(__PACKAGE__));
$dynamic->map({ package => 'Avatica.Client.Protocol', prefix => 'Avatica::Client::Protocol' });

1;

=pod

=encoding UTF-8

=head1 NAME

Avatica::Client - Client for Apache Calcite Avatica

=head1 VERSION

version 0.003

=head1 AUTHOR

Alexey Stavrov <logioniz@ya.ru>

=head1 CONTRIBUTORS

=for stopwords Denis Ibaev Ivan Putintsev uid66

=over 4

=item *

Denis Ibaev <dionys@gmail.com>

=item *

Ivan Putintsev <uid@rydlab.ru>

=item *

uid66 <19481514+uid66@users.noreply.github.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Alexey Stavrov.

This is free software, licensed under:

  The MIT (X11) License

=cut

__DATA__
// from https://github.com/apache/calcite-avatica/tree/master/core/src/main/protobuf

syntax = "proto3";

package Avatica.Client.Protocol;

// Request for Meta#openConnection(Meta.ConnectionHandle, Map<String, String>)
message OpenConnectionRequest {
  string connection_id = 1;
  map<string, string> info = 2;
}

// Response to OpenConnectionRequest
message OpenConnectionResponse {
  RpcMetadata metadata = 1;
}

// Request for Meta#closeConnection(Meta.ConnectionHandle)
message CloseConnectionRequest {
  string connection_id = 1;
}

// Response to CloseConnectionRequest
message CloseConnectionResponse {
  RpcMetadata metadata = 1;
}

// Request for Meta#getCatalogs()
message CatalogsRequest {
  string connection_id = 1;
}

// Request for Meta#getColumns(String, org.apache.calcite.avatica.Meta.Pat,
//   org.apache.calcite.avatica.Meta.Pat, org.apache.calcite.avatica.Meta.Pat).
message ColumnsRequest {
  string catalog = 1;
  string schema_pattern = 2;
  string table_name_pattern = 3;
  string column_name_pattern = 4;
  string connection_id = 5;
  bool has_catalog = 6;
  bool has_schema_pattern = 7;
  bool has_table_name_pattern = 8;
  bool has_column_name_pattern = 9;
}

// Request for Meta#getTypeInfo()
message TypeInfoRequest {
  string connection_id = 1;
}

// Request for Meta#getSchemas(String, org.apache.calcite.avatica.Meta.Pat)}
message SchemasRequest {
  string catalog = 1;
  string schema_pattern = 2;
  string connection_id = 3;
  bool has_catalog = 4;
  bool has_schema_pattern = 5;
}

// Request for Meta#getTableTypes()
message TableTypesRequest {
  string connection_id = 1;
}

// Request for Request for Meta#getTables(String, org.apache.calcite.avatica.Meta.Pat,
//   org.apache.calcite.avatica.Meta.Pat, java.util.List)
message TablesRequest {
  string catalog = 1;
  string schema_pattern = 2;
  string table_name_pattern = 3;
  repeated string type_list = 4;
  bool has_type_list = 6; // Having an empty type_list is distinct from a null type_list
  string connection_id = 7;
  bool has_catalog = 8;
  bool has_schema_pattern = 9;
  bool has_table_name_pattern = 10;
}

message ConnectionSyncRequest {
  string connection_id = 1;
  ConnectionProperties conn_props = 2;
}

// Response to ConnectionSyncRequest
message ConnectionSyncResponse {
  ConnectionProperties conn_props = 1;
  RpcMetadata metadata = 2;
}

// Request for Meta#getDatabaseProperties()
message DatabasePropertyRequest {
  string connection_id = 1;
}

// Response for Meta#getDatabaseProperties()
message DatabasePropertyResponse {
  repeated DatabasePropertyElement props = 1;
  RpcMetadata metadata = 2;
}

// Request to invoke a commit on a Connection
message CommitRequest {
  string connection_id = 1;
}

// Response to a commit request
message CommitResponse {

}

// Request to invoke rollback on a Connection
message RollbackRequest {
  string connection_id = 1;
}

// Response to a rollback request
message RollbackResponse {

}

// Request for Meta#createStatement(Meta.ConnectionHandle)
message CreateStatementRequest {
  string connection_id = 1;
}

// Response to CreateStatementRequest
message CreateStatementResponse {
  string connection_id = 1;
  uint32 statement_id = 2;
  RpcMetadata metadata = 3;
}

// Request for Meta#closeStatement(Meta.StatementHandle)
message CloseStatementRequest {
  string connection_id = 1;
  uint32 statement_id = 2;
}

// Response to CloseStatementRequest
message CloseStatementResponse {
  RpcMetadata metadata = 1;
}

message PrepareAndExecuteRequest {
  string connection_id = 1;
  uint32 statement_id = 4;
  string sql = 2;
  uint64 max_row_count = 3; // Deprecated!
  int64 max_rows_total = 5;
  int32 first_frame_max_size = 6;
}

// Request to prepare and execute a collection of sql statements.
message PrepareAndExecuteBatchRequest {
  string connection_id = 1;
  uint32 statement_id = 2;
  repeated string sql_commands = 3;
}

// Request for Meta.prepare(Meta.ConnectionHandle, String, long)
message PrepareRequest {
  string connection_id = 1;
  string sql = 2;
  uint64 max_row_count = 3; // Deprecated
  int64 max_rows_total = 4; // The maximum number of rows that will be allowed for this query
}

// Response to PrepareRequest
message PrepareResponse {
  StatementHandle statement = 1;
  RpcMetadata metadata = 2;
}

// Request for Meta#execute(Meta.ConnectionHandle, list, long)
message ExecuteRequest {
  StatementHandle statementHandle = 1;
  repeated TypedValue parameter_values = 2;
  uint64 deprecated_first_frame_max_size = 3; // Deprecated, use the signed int instead.
  bool has_parameter_values = 4;
  int32 first_frame_max_size = 5; // The maximum number of rows to return in the first Frame
}

// Response to PrepareAndExecuteRequest
message ExecuteResponse {
  repeated ResultSetResponse results = 1;
  bool missing_statement = 2; // Did the request fail because of no-cached statement
  RpcMetadata metadata = 3;
}

message ExecuteBatchRequest {
  string connection_id = 1;
  uint32 statement_id = 2;
  repeated UpdateBatch updates = 3; // A batch of updates is a list<list<typevalue>>
}

// Response to a batch update request
message ExecuteBatchResponse {
  string connection_id = 1;
  uint32 statement_id = 2;
  repeated uint64 update_counts = 3;
  bool missing_statement = 4; // Did the request fail because of no-cached statement
  RpcMetadata metadata = 5;
}

// Response that contains a result set.
message ResultSetResponse {
  string connection_id = 1;
  uint32 statement_id = 2;
  bool own_statement = 3;
  Signature signature = 4;
  Frame first_frame = 5;
  uint64 update_count = 6; // -1 for normal result sets, else this response contains a dummy result set
                                    // with no signature nor other data.
  RpcMetadata metadata = 7;
}

// Request for Meta#fetch(Meta.StatementHandle, List, long, int)
message FetchRequest {
  string connection_id = 1;
  uint32 statement_id = 2;
  uint64 offset = 3;
  uint32 fetch_max_row_count = 4; // Maximum number of rows to be returned in the frame. Negative means no limit. Deprecated!
  int32 frame_max_size = 5;
}

// Response to FetchRequest
message FetchResponse {
  Frame frame = 1;
  bool missing_statement = 2; // Did the request fail because of no-cached statement
  bool missing_results = 3; // Did the request fail because of a cached-statement w/o ResultSet
  RpcMetadata metadata = 4;
}

message SyncResultsRequest {
  string connection_id = 1;
  uint32 statement_id = 2;
  QueryState state = 3;
  uint64 offset = 4;
}

message SyncResultsResponse {
  bool missing_statement = 1; // Server doesn't have the statement with the ID from the request
  bool more_results = 2; // Should the client fetch() to get more results
  RpcMetadata metadata = 3;
}

// Send contextual information about some error over the wire from the server.
message ErrorResponse {
  repeated string exceptions = 1; // exception stacktraces, many for linked exceptions.
  bool has_exceptions = 7; // are there stacktraces contained?
  string error_message = 2; // human readable description
  Severity severity = 3;
  uint32 error_code = 4; // numeric identifier for error
  string sql_state = 5; // five-character standard-defined value
  RpcMetadata metadata = 6;
}

message QueryState {
  StateType type = 1;
  string sql = 2;
  MetaDataOperation op = 3;
  repeated MetaDataOperationArgument args = 4;
  bool has_args = 5;
  bool has_sql = 6;
  bool has_op = 7;
}

enum StateType {
  SQL = 0;
  METADATA = 1;
}

// Enumeration corresponding to DatabaseMetaData operations
enum MetaDataOperation {
  GET_ATTRIBUTES = 0;
  GET_BEST_ROW_IDENTIFIER = 1;
  GET_CATALOGS = 2;
  GET_CLIENT_INFO_PROPERTIES = 3;
  GET_COLUMN_PRIVILEGES = 4;
  GET_COLUMNS = 5;
  GET_CROSS_REFERENCE = 6;
  GET_EXPORTED_KEYS = 7;
  GET_FUNCTION_COLUMNS = 8;
  GET_FUNCTIONS = 9;
  GET_IMPORTED_KEYS = 10;
  GET_INDEX_INFO = 11;
  GET_PRIMARY_KEYS = 12;
  GET_PROCEDURE_COLUMNS = 13;
  GET_PROCEDURES = 14;
  GET_PSEUDO_COLUMNS = 15;
  GET_SCHEMAS = 16;
  GET_SCHEMAS_WITH_ARGS = 17;
  GET_SUPER_TABLES = 18;
  GET_SUPER_TYPES = 19;
  GET_TABLE_PRIVILEGES = 20;
  GET_TABLES = 21;
  GET_TABLE_TYPES = 22;
  GET_TYPE_INFO = 23;
  GET_UDTS = 24;
  GET_VERSION_COLUMNS = 25;
}

// Represents the breadth of arguments to DatabaseMetaData functions
message MetaDataOperationArgument {
  enum ArgumentType {
    STRING = 0;
    BOOL = 1;
    INT = 2;
    REPEATED_STRING = 3;
    REPEATED_INT = 4;
    NULL = 5;
  }

  string string_value = 1;
  bool bool_value = 2;
  sint32 int_value = 3;
  repeated string string_array_values = 4;
  repeated sint32 int_array_values = 5;
  ArgumentType type = 6;
}

// Each command is a list of TypedValues
message UpdateBatch {
  repeated TypedValue parameter_values = 1;
}

// Database property, list of functions the database provides for a certain operation
message DatabaseProperty {
  string name = 1;
  repeated string functions = 2;
}

message DatabasePropertyElement {
  DatabaseProperty key = 1;
  TypedValue value = 2;
  RpcMetadata metadata = 3;
}

// Details about a connection
message ConnectionProperties {
  bool is_dirty = 1;
  bool auto_commit = 2;
  bool has_auto_commit = 7; // field is a Boolean, need to discern null and default value
  bool read_only = 3;
  bool has_read_only = 8; // field is a Boolean, need to discern null and default value
  uint32 transaction_isolation = 4;
  string catalog = 5;
  string schema = 6;
}

// The severity of some unexpected outcome to an operation.
// Protobuf enum values must be unique across all other enums
enum Severity {
  UNKNOWN_SEVERITY = 0;
  FATAL_SEVERITY = 1;
  ERROR_SEVERITY = 2;
  WARNING_SEVERITY = 3;
}

// A collection of rows
message Frame {
  uint64 offset = 1;
  bool done = 2;
  repeated Row rows = 3;
}

// A row is a collection of values
message Row {
  repeated ColumnValue value = 1;
}

// A value might be a TypedValue or an Array of TypedValue's
message ColumnValue {
  repeated TypedValue value = 1; // deprecated, use array_value or scalar_value
  repeated TypedValue array_value = 2;
  bool has_array_value = 3; // Is an array value set?
  TypedValue scalar_value = 4;
}

// Statement handle
message StatementHandle {
  string connection_id = 1;
  uint32 id = 2;
  Signature signature = 3;
}

// Results of preparing a statement
message Signature {
  repeated ColumnMetaData columns = 1;
  string sql = 2;
  repeated AvaticaParameter parameters = 3;
  CursorFactory cursor_factory = 4;
  StatementType statementType = 5;
}

message ColumnMetaData {
  uint32 ordinal = 1;
  bool auto_increment = 2;
  bool case_sensitive = 3;
  bool searchable = 4;
  bool currency = 5;
  uint32 nullable = 6;
  bool signed = 7;
  uint32 display_size = 8;
  string label = 9;
  string column_name = 10;
  string schema_name = 11;
  uint32 precision = 12;
  uint32 scale = 13;
  string table_name = 14;
  string catalog_name = 15;
  bool read_only = 16;
  bool writable = 17;
  bool definitely_writable = 18;
  string column_class_name = 19;
  AvaticaType type = 20;
}

// Metadata for a parameter
message AvaticaParameter {
  bool signed = 1;
  uint32 precision = 2;
  uint32 scale = 3;
  uint32 parameter_type = 4;
  string type_name = 5;
  string class_name = 6;
  string name = 7;
}

// Information necessary to convert an Iterable into a Calcite Cursor
message CursorFactory {
  enum Style {
    OBJECT = 0;
    RECORD = 1;
    RECORD_PROJECTION = 2;
    ARRAY = 3;
    LIST = 4;
    MAP = 5;
  }

  Style style = 1;
  string class_name = 2;
  repeated string field_names = 3;
}

// Has to be consistent with Meta.StatementType
enum StatementType {
  SELECT = 0;
  INSERT = 1;
  UPDATE = 2;
  DELETE = 3;
  UPSERT = 4;
  MERGE = 5;
  OTHER_DML = 6;
  CREATE = 7;
  DROP = 8;
  ALTER = 9;
  OTHER_DDL = 10;
  CALL = 11;
}

// Base class for a column type
message AvaticaType {
  uint32 id = 1;
  string name = 2;
  Rep rep = 3;

  repeated ColumnMetaData columns = 4; // Only present when name = STRUCT
  AvaticaType component = 5; // Only present when name = ARRAY
}

// Generic wrapper to support any SQL type. Struct-like to work around no polymorphism construct.
message TypedValue {
  Rep type = 1; // The actual type that was serialized in the general attribute below

  bool bool_value = 2; // boolean
  string string_value = 3; // char/varchar
  sint64 number_value = 4; // var-len encoding lets us shove anything from byte to long
                           // includes numeric types and date/time types.
  bytes bytes_value = 5; // binary/varbinary
  double double_value = 6; // big numbers
  bool null = 7; // a null object

  repeated TypedValue array_value = 8; // The Array
  Rep component_type = 9; // If an Array, the representation for the array values

  bool implicitly_null = 10; // Differentiate between explicitly null (user-set) and implicitly null
                            // (un-set by the user)
}

enum Rep {
  PRIMITIVE_BOOLEAN = 0;
  PRIMITIVE_BYTE = 1;
  PRIMITIVE_CHAR = 2;
  PRIMITIVE_SHORT = 3;
  PRIMITIVE_INT = 4;
  PRIMITIVE_LONG = 5;
  PRIMITIVE_FLOAT = 6;
  PRIMITIVE_DOUBLE = 7;
  BOOLEAN = 8;
  BYTE = 9;
  CHARACTER = 10;
  SHORT = 11;
  INTEGER = 12;
  LONG = 13;
  FLOAT = 14;
  DOUBLE = 15;
  BIG_INTEGER = 25;
  BIG_DECIMAL = 26;
  JAVA_SQL_TIME = 16;
  JAVA_SQL_TIMESTAMP = 17;
  JAVA_SQL_DATE = 18;
  JAVA_UTIL_DATE = 19;
  BYTE_STRING = 20;
  STRING = 21;
  NUMBER = 22;
  OBJECT = 23;
  NULL = 24;
  ARRAY = 27;
  STRUCT = 28;
  MULTISET = 29;
}

// Generic metadata for the server to return with each response.
message RpcMetadata {
  string server_address = 1; // The host:port of the server
}

// Message which encapsulates another message to support a single RPC endpoint
message WireMessage {
  string name = 1;
  bytes wrapped_message = 2;
}

__END__

=head1 SYNOPSIS

  use Avatica::Client;
  my $connection_id = 'number-or-uuid-or-any-string';
  my $client = Avatica::Client->new(url => 'http://172.17.0.1:8765');
  my ($res, $connection) = $client->open_connection($connection_id);
  die "can't open connection: $connection->{message}" if !$res;
  ($res, my $prepare) = $client->prepare($connection_id, 'SELECT * FROM table WERE id = ? LIMIT 10');
  die "can't prepare query: $prepare->{message}" if !$res;
  my $statement = $prepare->get_statement;
  my $statement_id = $statement->get_id;
  my $signature = $statement->get_signature;
  my $tv = Avatica::Client::Protocol::TypedValue->new;
  $tv->set_number_value(1);
  $tv->set_type(Avatica::Client::Protocol::Rep::LONG());
  ($res, my $execute) = $client->execute($connection_id, $statement_id, $signature, [$tv], 2);
  die "can't execute: $execute->{message}" if !$res;
  ($res, my $fetch) = $client->fetch($connection_id, $statement_id, undef, 8);
  die "can't fetch: $fetch->{message}" if !$res;
  ($res, my $close_state) = $client->close_statement($connection_id, $statement_id);
  die "close statement error: $close_state->{message}" if !$res;
  ($res, $r) = $client->close_connection($connection_id);
  die "close connection error: $r->{message}" if !$res;

=head1 DESCRIPTION

Client for Apache Calcite Avatica which based on HTTP and Google Protobuf.


=head2 new

Creates object of the Avatica::Client.

  my $client = Avatica::Client->new(url => 'http://127.0.0.1:8765', max_retries => 10);

=head3 Parameters

=head4 url

URL to send request (required).

=head4 max_retries

Number of retires (default 3).

=head4 ua

HTTP::Tiny user agent.


=head2 open_connection

Open new connection.

  my ($res, $connection) = $client->open_connection($connection_id);

=head3 Parameters

=head4 connection_id

Any generated string.


=head2 close_connection

Close connection.

  my ($res, $data) = $client->close_connection($connection_id);

=head3 Parameters

=head4 connection_id

Connection id from open_connection call (required).


=head2 catalog

This request is used to fetch the available catalog names in the database.

  my ($res, $catalog) = $client->catalog($connection_id);

=head3 Parameters

=head4 connection_id

Connection id from open_connection call (required).


=head2 columns

This request is used to fetch columns in the database given some optional filtering criteria.

  my ($res, $columns) = $client->columns($connection_id, $catalog, $schema_pattern, $table_pattern, $column_pattern);

=head3 Parameters

=head4 connection_id

Connection id from open_connection call (required).

=head4 catalog

The name of a catalog to limit returned columns.

=head4 schema_pattern

A Java Pattern against schemas to limit returned columns.

=head4 table_pattern

A Java Pattern against table names to limit returned columns.

=head4 column_pattern

A Java Pattern against column names to limit returned columns.


=head2 database_property

This request is used to fetch all database properties.

  my ($res, $prop) = $client->database_property($connection_id);

=head3 Parameters

=head4 connection_id

Connection id from open_connection call (required).


=head2 schemas

This request is used to fetch the schemas matching the provided criteria in the database.

  my ($res, $schemas) = $client->schemas($connection_id, $catalog, $schema_pattern);

=head3 Parameters

=head4 connection_id

Connection id from open_connection call (required).

=head4 catalog

The name of the catalog to fetch the schema from.

=head4 schema_pattern

A Java pattern of schemas to fetch.


=head2 tables

This request is used to fetch the tables available in this database filtered by the provided criteria.

  my ($res, $tables) = $client->tables($connection_id, $catalog, $schema_pattern, $table_pattern, $type_list);

=head3 Parameters

=head4 connection_id

Connection id from open_connection call (required).

=head4 catalog

The name of a catalog to restrict fetched tables.

=head4 schema_pattern

A Java Pattern representing schemas to include in fetched tables.

=head4 table_pattern

A Java Pattern representing table names to include in fetched tables.

=head4 type_list

A list of table types used to restrict fetched tables.


=head2 type_info

This request is used to fetch the types available in this database.

  my ($res, $type_info) = $client->type_info($connection_id);

=head3 Parameters

=head4 connection_id

Connection id from open_connection call (required).


=head2 table_types

This request is used to fetch the table types available in this database.

  my ($res, $table_types) = $client->table_types($connection_id);

=head3 Parameters

=head4 connection_id

Connection id from open_connection call (required).


=head2 connection_sync

This request is used to ensure that the client and server have a consistent view of the database properties.
Returns the properties that were applied on the server.

  my ($res, $connection_sync) = $client->connection_sync($connection_id, {
    AutoCommit => 0,
    ReadOnly => 0,
    TransactionIsolation => 2,
    Catalog => '',
    Schema => ''
  });

=head3 Parameters

=head4 connection_id

Connection id from open_connection call (required).

=head4 prop

This hash represents the properties for a given JDBC Connection.
AutoCommit is a boolean denoting if AutoCommit is enabled for transactions.
ReadOnly is a boolean denoting if a JDBC connection is read-only.
TransactionIsolation is an integer which denotes the level of transactions isolation per the JDBC specification:
  0 = No transactions.
  1 = READ_UNCOMMITTED.
  2 = READ_COMMITTED.
  4 = REPEATABLE_READ.
  8 = SERIALIZABLE.
Catalog is the name of a catalog to use when fetching connection properties.
Schema is the name of the schema to use when fetching connection properties.


=head2 commit

This request is used to issue a commit on the Connection in the Avatica server identified by the given ID.

  my ($res, $commit) = $client->commit($connection_id);

=head3 Parameters

=head4 connection_id

Connection id from open_connection call (required).


=head2 rollback

This request is used to issue a rollback on the Connection in the Avatica server identified by the given ID.

  my ($res, $rollback) = $client->rollback($connection_id);

=head3 Parameters

=head4 connection_id

Connection id from open_connection call (required).


=head2 create_statement

This request is used to create a new Statement in the Avatica server.

  my ($res, $statement) = $client->create_statement($connection_id);

=head3 Parameters

=head4 connection_id

Connection id from open_connection call (required).


=head2 prepare_and_execute

This request is used as a short-hand for create a Statement and fetching the first batch of results in a single call without any parameter substitution.

  my ($res, $result) = $client->prepare_and_execute($connection_id, $statement_id, $sql, $max_rows_total, $first_frame_max_size);

  my ($res, $statement) = $client->create_statement($connection_id);
  ($res, my $result) = $client->prepare_and_execute($connection_id, $statement->get_statement_id, 'SELECT * FROM TABLE', undef, 100);

=head3 Parameters

=head4 connection_id

Connection id from open_connection call (required).

=head4 statement_id

The identifier of the created statement (required).

=head4 sql

A SQL statement (required).

=head4 max_rows_total

The maximum number of rows which this query should return.

=head4 first_frame_max_size

The maximum number of rows which should be included in the first Frame.


=head2 close_statement

This request is used to close the Statement object in the Avatica server identified by the given IDs.

  my ($res, $result) = $client->close_statement($connection_id, $statement_id);

=head3 Parameters

=head4 connection_id

Connection id from open_connection call (required).

=head4 statement_id

The identifier of the statement to close (required).


=head2 prepare

This request is used to create create a new Statement with the given query in the Avatica server.

  my ($res, $prepare) = $client->prepare($connection_id, $sql, $max_rows_total);
  my ($res, $prepare) = $client->prepare($connection_id, 'SELECT * FROM TABLE');

=head3 Parameters

=head4 connection_id

Connection id from open_connection call (required).

=head4 sql

A SQL statement (required).

=head4 max_rows_total

The maximum number of rows which this query should return.


=head2 execute

This request is used to execute a PreparedStatement, optionally with values to bind to the parameters in the Statement.

  my ($res, $execute) = $client->execute($connection_id, $statement_id, $signature, $param_values, $first_frame_max_size);

  my ($res, $prepare) = $client->prepare($connection_id, 'SELECT * FROM table WHERE f1 = ? AND f2 = ?');
  my $val1 = Avatica::Client::Protocol::TypedValue->new;
  $val1->set_number_value(2);
  $val1->set_type(Avatica::Client::Protocol::Rep::LONG());
  my $val2 = Avatica::Client::Protocol::TypedValue->new;
  $val2->set_number_value(2);
  $val2->set_type(Avatica::Client::Protocol::Rep::LONG());
  my ($res, $execute) = $client->execute($connection_id, $prepare->get_statement->get_id, $prepare->get_statement->get_signature, [$val1, $val2]);

=head3 Parameters

=head4 connection_id

Connection id from open_connection call (required).

=head4 statement_id

The identifier of the created statement (required).

=head4 signature

A Signature object for the statement (required).

=head4 param_values

The TypedValue for each parameter on the prepared statement.

=head4 first_frame_max_size

The maximum number of rows to return in the first Frame.


=head2 prepare_and_execute_batch

This request is used as short-hand to create a Statement and execute a B<batch of updates> against that Statement.

  my ($res, $result) = $client->prepare_and_execute_batch($connection_id, $statement_id, $sqls);

  my ($res, $statement) = $client->create_statement($connection_id);
  ($res, my $result) = $client->prepare_and_execute_batch($connection_id, $statement->get_statement_id, [
    'UPSERT INTO table(F1, F2) values (1, 2)',
    'UPSERT INTO table(F1, F2) values (2, 3)',
    'UPSERT INTO table(F1, F2) values (3, 4)'
  ]);

=head3 Parameters

=head4 connection_id

Connection id from open_connection call (required).

=head4 statement_id

The identifier of the created statement (required).

=head4 sqls

A list of SQL commands to execute a B<batch of updates> (required).


=head2 execute_batch

This request is used to execute a B<batch of updates> against a PreparedStatement.

  my ($res, $result) = $client->execute_batch($connection_id, $statement_id, $rows);

  my ($res, $prepare) = $client->prepare($connection_id, 'UPSERT INTO table(F1, F2) VALUES (1, ?)');
  my $val1 = Avatica::Client::Protocol::TypedValue->new;
  $val1->set_number_value(1);
  $val1->set_type(Avatica::Client::Protocol::Rep::LONG());
  my $val2 = Avatica::Client::Protocol::TypedValue->new;
  $val2->set_number_value(2);
  $val2->set_type(Avatica::Client::Protocol::Rep::LONG());
  my ($res, $result) = $client->execute_batch($connection_id, $prepare->get_statement->get_id, [[$val1], [$val2]]);

=head3 Parameters

=head4 connection_id

Connection id from open_connection call (required).

=head4 statement_id

The identifier of the created statement (required).

=head4 rows

The list of the list of TypedValue for each parameter on the prepared statement (required).


=head2 fetch

This request is used to fetch a batch of rows from a Statement previously created.

  my ($res, $result) = $client->fetch($connection_id, $statement_id, $offset, $frame_max_size);

=head3 Parameters

=head4 connection_id

Connection id from open_connection call.

=head4 statement_id

The identifier of the created statement.

=head4 offset

The positional offset into a result set to fetch.

=head4 frame_max_size

The maximum number of rows to return in the response. Negative means no limit.


=head2 sync_results

This request is used to reset a ResultSet's iterator to a specific offset in the Avatica server.

  my ($res, $result) = $client->sync_results($connection_id, $statement_id, $state, $offset);

  # fetch first 6 rows
  ($res, my $statement) = $client->create_statement($connection_id);
  ($res, my $execute) = $client->prepare_and_execute($connection_id, $statement->get_statement_id, 'SELECT * FROM table', undef, 2);
  ($res, my $fetch) = $client->fetch($connection_id, $statement_id, undef, 4);
  # fetch again first 6 rows
  my $state = Avatica::Client::Protocol::QueryState->new;
  $state->set_type(0);
  $state->set_sql('SELECT * FROM table');
  $state->set_has_sql(1);
  ($res, my $sync) = $client->sync_results($connection_id, $statement_id, $state);
  ($res, $fetch) = $client->fetch($connection_id, $statement_id, undef, 6);

=head3 Parameters

=head4 connection_id

Connection id from open_connection call.

=head4 statement_id

The identifier of the created statement.

=head4 state

The QueryState object.

=head4 offset

The offset into the ResultSet to seek to.

=cut
