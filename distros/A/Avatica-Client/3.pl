#!/usr/bin/perl

use strict;
use warnings;

use HTTP::Request;
use LWP::UserAgent;
use HTTP::Tiny;
use Google::ProtocolBuffers::Dynamic;
use Google::ProtocolBuffers::Dynamic ':values';
use JSON::PP qw/encode_json decode_json/;
use Data::Dumper;

my $dynamic = Google::ProtocolBuffers::Dynamic->new;
$dynamic->load_string("person.proto", <<'EOT');
syntax = "proto3";

package avatica;

message OpenConnectionRequest {
  string connection_id = 1;
  map<string, string> info = 2;
}

message OpenConnectionResponse {
  RpcMetadata metadata = 1;
}

message CreateStatementRequest {
  string connection_id = 1;
}

message CreateStatementResponse {
  string connection_id = 1;
  uint32 statement_id = 2;
  RpcMetadata metadata = 3;
}

message PrepareRequest {
  string connection_id = 1;
  string sql = 2;
  uint64 max_row_count = 3; // Deprecated!
  int64 max_rows_total = 4;
}

message PrepareResponse {
  StatementHandle statement = 1;
  RpcMetadata metadata = 2;
}

message ExecuteRequest {
  StatementHandle statementHandle = 1;
  repeated TypedValue parameter_values = 2;
  uint64 deprecated_first_frame_max_size = 3;
  bool has_parameter_values = 4;
  int32 first_frame_max_size = 5;
}

message ExecuteResponse {
  repeated ResultSetResponse results = 1;
  bool missing_statement = 2;
  RpcMetadata metadata = 3;
}

message ResultSetResponse {
  string connection_id = 1;
  uint32 statement_id = 2;
  bool own_statement = 3;
  Signature signature = 4;
  Frame first_frame = 5;
  uint64 update_count = 6;
  RpcMetadata metadata = 7;
}

message Frame {
  uint64 offset = 1;
  bool done = 2;
  repeated Row rows = 3;
}

message Row {
  repeated ColumnValue value = 1;
}

message ColumnValue {
  repeated TypedValue value = 1; // Deprecated!
  repeated ColumnValue array_value = 2;
  bool has_array_value = 3;
  TypedValue scalar_value = 4;
}

message StatementHandle {
  string connection_id = 1;
  uint32 id = 2;
  Signature signature = 3;
}

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

message AvaticaParameter {
  bool signed = 1;
  uint32 precision = 2;
  uint32 scale = 3;
  uint32 parameter_type = 4;
  string type_name = 5;
  string class_name = 6;
  string name = 7;
}

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

message AvaticaType {
  uint32 id = 1;
  string name = 2;
  Rep rep = 3;
  repeated ColumnMetaData columns = 4;
  AvaticaType component = 5;
}

message TypedValue {
  Rep type = 1;
  bool bool_value = 2;
  string string_value = 3;
  sint64 number_value = 4;
  bytes bytes_value = 5;
  double double_value = 6;
  bool null = 7;
  repeated TypedValue array_value = 8;
  Rep component_type = 9;
  bool implicitly_null = 10;
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

message RpcMetadata {
  string server_address = 1;
}

message WireMessage {
  string name = 1;
  bytes wrapped_message = 2;
}

EOT

$dynamic->map({ package => 'avatica', prefix => 'Avatica' });

# ------------------
# json example

# my $ua = HTTP::Tiny->new;

# my $res = $ua->post('http://172.17.0.1:8765', {
#   headers => {
#     'Content-Type' => 'application/json'
#   },
#   content => encode_json({
#     "request" => "openConnection",
#     "connectionId" => "000000-0000-0000-00000001"
#   })
# });

# print encode_json({
#     "request" => "openConnection",
#     "connectionId" => "000000-0000-0000-00000001"
#   }), $/;

# if ($res->{success}) {
#   print "send open connection request success", $/;
# } else {
#   print "send open connection request failed: " . $res->{status}, $/;
#   print Dumper $res;
# }
# my $content = decode_json $res->{content};
# print $content;
# print Dumper $content;

# ------------------
# openConnection

my $connection_id = int(rand(111)) . $$;

my $open_req = Avatica::OpenConnectionRequest->new;
$open_req->set_connection_id($connection_id);

my $wrapped_open_req = Avatica::WireMessage->new;
$wrapped_open_req->set_name('org.apache.calcite.avatica.proto.Requests$OpenConnectionRequest');
$wrapped_open_req->set_wrapped_message(Avatica::OpenConnectionRequest->encode($open_req));

my $msg = Avatica::WireMessage->encode($wrapped_open_req);

my $ua = HTTP::Tiny->new;

my $res = $ua->post('http://172.17.0.1:8765', {
  headers => {
    'Content-Type' => 'application/x-google-protobuf'
  },
  content => $msg
});

if ($res->{success}) {
  print "send open connection request success", $/;
} else {
  print "send open connection request failed: " . $res->{status}, $/;
}
my $content = $res->{content};

my $wrapped_open_res = Avatica::WireMessage->decode($content);
print $wrapped_open_res->get_name, $/;
my $open_res = Avatica::OpenConnectionResponse->decode($wrapped_open_res->get_wrapped_message);
print $open_res->get_metadata->get_server_address, $/;


# --------------
# createStatment

# my $create_stmt = Avatica::CreateStatementRequest->new;
# $create_stmt->set_connection_id($connection_id);

# my $wrapped_create_stmt = Avatica::WireMessage->new;
# $wrapped_create_stmt->set_name('org.apache.calcite.avatica.proto.Requests$CreateStatementRequest');
# $wrapped_create_stmt->set_wrapped_message(Avatica::CreateStatementRequest->encode($create_stmt));

# $msg = Avatica::WireMessage->encode($wrapped_create_stmt);

# $res = $ua->post('http://172.17.0.1:8765', {
#   headers => {
#     'Content-Type' => 'application/x-google-protobuf'
#   },
#   content => $msg
# });

# if ($res->{success}) {
#   print "send create statement request success", $/;
# } else {
#   print "send create statement request failed: " . $res->{status}, $/;
# }
# $content = $res->{content};

# my $wrapped_create_stmt_resp = Avatica::WireMessage->decode($content);
# print $wrapped_create_stmt_resp->get_name, $/;
# my $create_stmt_resp = Avatica::CreateStatementResponse->decode($wrapped_create_stmt_resp->get_wrapped_message);
# print $create_stmt_resp->get_statement_id, $/;

# ---------------
# prepare

my $prepare_req = Avatica::PrepareRequest->new;
$prepare_req->set_connection_id($connection_id);
$prepare_req->set_sql('select * from Z where A = ? and B = ?');

my $wrapped_prepare_req = Avatica::WireMessage->new;
$wrapped_prepare_req->set_name('org.apache.calcite.avatica.proto.Requests$PrepareRequest');
$wrapped_prepare_req->set_wrapped_message(Avatica::PrepareRequest->encode($prepare_req));

$msg = Avatica::WireMessage->encode($wrapped_prepare_req);

$res = $ua->post('http://172.17.0.1:8765', {
  headers => {
    'Content-Type' => 'application/x-google-protobuf'
  },
  content => $msg
});

if ($res->{success}) {
  print "send prepare request success", $/;
} else {
  print "send prepare request failed: " . $res->{status}, $/;
}
$content = $res->{content};

my $wrapped_prepare_res = Avatica::WireMessage->decode($content);
print $wrapped_prepare_res->get_name, $/;
my $prepare_resp = Avatica::PrepareResponse->decode($wrapped_prepare_res->get_wrapped_message);
# print $prepare_resp->get_statement_id, $/;
print Dumper $prepare_resp;
print $prepare_resp->get_statement->get_id, $/;

my $statement = $prepare_resp->get_statement;

# --------------
# execute

my $tv1 = Avatica::TypedValue->new;
$tv1->set_number_value(1);
$tv1->set_type(Avatica::Rep::LONG());

my $tv2 = Avatica::TypedValue->new;
$tv2->set_number_value(2);
$tv2->set_type(Avatica::Rep::INTEGER());

my $execute_req = Avatica::ExecuteRequest->new;
$execute_req->set_statementHandle($statement);
$execute_req->set_first_frame_max_size(2);
$execute_req->set_deprecated_first_frame_max_size(2);
$execute_req->set_has_parameter_values(1);
$execute_req->add_parameter_values($tv1);
$execute_req->add_parameter_values($tv2);

my $wrapped_execute_req = Avatica::WireMessage->new;
$wrapped_execute_req->set_name('org.apache.calcite.avatica.proto.Requests$ExecuteRequest');
$wrapped_execute_req->set_wrapped_message(Avatica::ExecuteRequest->encode($execute_req));

$msg = Avatica::WireMessage->encode($wrapped_execute_req);

$res = $ua->post('http://172.17.0.1:8765', {
  headers => {
    'Content-Type' => 'application/x-google-protobuf'
  },
  content => $msg
});

if ($res->{success}) {
  print "send execute request success", $/;
} else {
  print "send execute request failed: " . $res->{status}, $/;
}
$content = $res->{content};

my $wrapped_execute_res = Avatica::WireMessage->decode($content);
# print $wrapped_execute_res->get_name, $/;
my $execute_resp = Avatica::ExecuteResponse->decode($wrapped_execute_res->get_wrapped_message);
# print $execute_resp->get_statement_id, $/;
print Dumper $execute_resp;
# print $execute_resp->get_statement->get_id, $/;
