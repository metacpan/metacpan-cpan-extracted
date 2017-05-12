SET search_path TO dbix_pglink;

--Note: some functions has name reserved in SQL standard

--no explicit connect()

create or replace function disconnect(_conn_name text) 
returns void language plperlu security definer as $body$
#line 9
  use DBIx::PgLink;
  DBIx::PgLink->disconnect(shift);
$body$;

revoke execute on function disconnect(_conn_name text) from public;

comment on function disconnect(_conn_name text) is 
$$Close connection to remote database$$;


create or replace function begin(_conn_name text) 
returns void language plperlu security definer as $body$
#line 22
  use DBIx::PgLink;
  DBIx::PgLink->connect(shift)->adapter->begin_work;
$body$;

revoke execute on function begin(_conn_name text) from public;

comment on function begin(_conn_name text) is 
$$Start transaction in remote database$$;


create or replace function rollback(_conn_name text) 
returns void language plperlu security definer as $body$
#line 35
  use DBIx::PgLink;
  DBIx::PgLink->connect(shift)->adapter->rollback;
$body$;

revoke execute on function rollback(_conn_name text) from public;

comment on function rollback(_conn_name text) is 
$$Rollback transaction in remote database$$;


create or replace function commit(_conn_name text) 
returns void language plperlu security definer as $body$
#line 48
  use DBIx::PgLink;
  DBIx::PgLink->connect(shift)->adapter->commit;
$body$;

revoke execute on function commit(_conn_name text) from public;

comment on function commit(_conn_name text) is 
$$Commit transaction in remote database$$;



create or replace function set_adapter_attr(
  conn_name  text,
  attr_name  text,
  attr_value text
) returns text
security definer
language plperlu as $body$
#line 67
  use DBIx::PgLink;
  my ($conn_name, $attr_name, $attr_value) = @_;
  my $conn = DBIx::PgLink->connect($conn_name);
  $conn->adapter->$attr_name($attr_value);
$body$;

revoke execute on function set_adapter_attr(
  conn_name  text,
  attr_name  text,
  attr_value text
) from public;

comment on function set_adapter_attr(
  conn_name  text,
  attr_name  text,
  attr_value text
) is 
$$Set adapter attribute (or call any subroutine) for current session. Very unsafe function$$;



--SELECT without params
create or replace function query(
  conn_name text,
  query     text
) returns setof record
security definer
language plperlu as $body$
#line 96
  use DBIx::PgLink;
  my $conn = DBIx::PgLink->connect(shift);
  $conn->remote_query(named_params(\@_,
    qw/query_text/
  ));
$body$;

revoke execute on function query (
  conn_name text,
  query     text
) from public;

comment on function query (
  conn_name text,
  query     text
) is $$Execute resultset-returning operation (SELECT) on a remote data source$$;



--SELECT with parameter values and types
create or replace function query(
  conn_name    text,
  query_text   text,
  param_values text[],
  param_types  text[]
) returns setof record
security definer
language plperlu as $body$
#line 125
  use DBIx::PgLink;
  my $conn = DBIx::PgLink->connect(shift);
  $conn->remote_query(named_params(\@_,
    qw/query_text param_values param_types/
  ));
$body$;

revoke execute on function query (
  conn_name    text,
  query_text   text,
  param_values text[],
  param_types  text[]
) from public;

comment on function query (
  conn_name    text,
  query_text   text,
  param_values text[],
  param_types  text[]
) is $$Execute resultset-returning operation (SELECT) on a remote data source, with parameters$$;


--SELECT with parameter values (shortcut)
create or replace function query(
  conn_name    text,
  query_text   text,
  param_values text[]
) returns setof record
security definer
language plperlu as $body$
#line 156
  use DBIx::PgLink;
  my $conn = DBIx::PgLink->connect(shift);
  $conn->remote_query(named_params(\@_,
    qw/query_text param_values/
  ));
$body$;

revoke execute on function query (
  conn_name    text,
  query_text   text,
  param_values text[]
) from public;

comment on function query (
  conn_name    text,
  query_text   text,
  param_values text[]
) is $$Execute resultset-returning operation (SELECT) on a remote data source, with parameters$$;



--DO without params
create or replace function exec(
  conn_name    text,
  query_text   text
) returns bigint
security definer
language plperlu as $body$
#line 185
  use DBIx::PgLink;
  my $conn = DBIx::PgLink->connect(shift);
  $conn->remote_exec(named_params(\@_,
    qw/query_text/
  ));
$body$;

revoke execute on function exec (
  conn_name    text,
  query_text   text
) from public;

comment on function exec (
  conn_name    text,
  query_text   text
) is $$Execute operation on a remote data source$$;



--DO with parameter values and types
create or replace function exec(
  conn_name    text,
  query_text   text,
  param_values text[],
  param_types  text[]
) returns bigint
security definer
language plperlu as $body$
#line 214
  use DBIx::PgLink;
  my $conn = DBIx::PgLink->connect(shift);
  $conn->remote_exec(named_params(\@_,
    qw/query_text param_values param_types/
  ));
$body$;

revoke execute on function exec (
  conn_name    text,
  query_text   text,
  param_values text[],
  param_types  text[]
) from public;

comment on function exec (
  conn_name    text,
  query_text   text,
  param_values text[],
  param_types  text[]
) is $$Execute operation on a remote data source, with parameters$$;


--DO with parameter values (shortcut)
create or replace function exec(
  conn_name    text,
  query_text   text,
  param_values text[]
) returns bigint
security definer
language plperlu as $body$
#line 245
  use DBIx::PgLink;
  my $conn = DBIx::PgLink->connect(shift);
  $conn->remote_exec(named_params(\@_,
    qw/query_text param_values/
  ));
$body$;

revoke execute on function exec (
  conn_name    text,
  query_text   text,
  param_values text[]
) from public;

comment on function exec (
  conn_name    text,
  query_text   text,
  param_values text[]
) is $$Execute operation on a remote data source, with parameters$$;



----------------------------------------------------accessors

create or replace function build_accessors(
  _conn_name           text,
  _local_schema        text,
  _remote_catalog      text,
  _remote_schema       text,
  _remote_object       text,
  _remote_object_types text[],
  _object_name_mapping text[]
) 
returns int language plperlu security definer as $body$
#line 279
  use strict;
  use DBIx::PgLink;
  my $conn = DBIx::PgLink->connect(shift);
  $conn->build_accessors(named_params(\@_,
    qw/local_schema remote_catalog remote_schema remote_object remote_object_types object_name_mapping/
  ));
$body$;

revoke execute on function build_accessors(
  _conn_name           text,
  _local_schema        text,
  _remote_catalog      text,
  _remote_schema       text,
  _remote_object       text,
  _remote_object_types text[],
  _object_name_mapping text[]
) from public;

comment on function build_accessors(
  _conn_name           text,
  _local_schema        text,
  _remote_catalog      text,
  _remote_schema       text,
  _remote_object       text,
  _remote_object_types text[],
  _object_name_mapping text[]
) is $$Create accessors for remote objects in local schema. 
Parameters:
  1 - Connection name (from dbix_pglink.connections). Mandatory.
  2 - Local schema. Created if not exists. Mandatory.
  3 - Remote catalog (name of database). Like-pattern.
  4 - Remote schema name. Like-pattern.
  5 - Remote object name. Like-pattern.
  6 - Array of remote object type. Default is {TABLE,VIEW}.
  7 - Name mapping array. Format: '{remote_name_1=>local_name_1,remote_name_2=>local_name_2, ...}'
Like-patterns can accept '%' or NULL value to match all objects.
Returns number of created accessors.$$;


--shortcut
create or replace function build_accessors(
  _conn_name      text,
  _local_schema   text,
  _remote_schema  text
) 
returns int language plperlu security definer as $body$
#line 326
  use strict;
  use DBIx::PgLink;
  my $conn = DBIx::PgLink->connect(shift);
  $conn->build_accessors(named_params(\@_,
    qw/local_schema remote_schema/
  ));
$body$;

revoke execute on function build_accessors(
  _conn_name      text,
  _local_schema   text,
  _remote_schema  text
) from public;

comment on function build_accessors(
  _conn_name      text,
  _local_schema   text,
  _remote_schema  text
) is $$Create accessors for remote objects in local schema. 
Parameters:
  1 - Connection name (from dbix_pglink.connections). Mandatory.
  2 - Local schema. Created if not exists. Mandatory.
  3 - Remote schema name. Like-pattern.$$;



create or replace function rebuild_accessors(
  _conn_name      text,
  _local_schema   text,
  _local_object   text,
  _remote_object_types text[]
) 
returns int language plperlu security definer as $body$
#line 360
  use strict;
  use DBIx::PgLink;
  my $conn = DBIx::PgLink->connect(shift);
  $conn->rebuild_accessors(named_params(\@_,
    qw/local_schema local_object remote_object_types/
  ));
$body$;

revoke execute on function rebuild_accessors(
  _conn_name      text,
  _local_schema   text,
  _local_object   text,
  _remote_object_types text[]
) from public;

comment on function rebuild_accessors(
  _conn_name      text,
  _local_schema   text,
  _local_object   text,
  _remote_object_types text[]
) is $$Rebuild existing accessors for remote object in local schema, using stored metadata.
Parameters:
  1 - Connection name (from dbix_pglink.connections). Mandatory.
  2 - Local schema. Mandatory.
  3 - Local object name. Like-pattern.
  4 - Array of remote object types.$$;


create or replace function rebuild_accessor(
  _conn_name      text,
  _object_id      int4
) 
returns int language plperlu security definer as $body$
#line 394
  use strict;
  use DBIx::PgLink;
  my $conn = DBIx::PgLink->connect(shift);
  my $accessor = $conn->load_accessor(shift);
  $accessor->build( use_local_metadata => 1);
$body$;

revoke execute on function rebuild_accessor(
  _conn_name      text,
  _object_id      int4
) from public;

comment on function rebuild_accessor(
  _conn_name      text,
  _object_id      int4
) is $$Rebuild accessor for one object
Parameters:
  1 - Connection name (dbix_pglink.connections.conn_name)
  2 - Object ID (dbix_pglink.objects.object_id)$$;


create or replace function drop_accessor(
  _conn_name      text,
  _object_id      int4
) 
returns void language plperlu security definer as $body$
#line 421
  use strict;
  use DBIx::PgLink;
  my $conn = DBIx::PgLink->connect(shift);
  my $accessor = $conn->load_accessor(shift);
  $accessor->drop;
$body$;

revoke execute on function drop_accessor(
  _conn_name      text,
  _object_id      int4
) from public;

comment on function drop_accessor(
  _conn_name      text,
  _object_id      int4
) is $$Drop accessor for one object with stored metadata
Parameters:
  1 - Connection name (dbix_pglink.connections.conn_name)
  2 - Object ID (dbix_pglink.objects.object_id)$$;


------------------------------------------------- trigger functions

create or replace function shadow_row_trigger_func() returns trigger
language plperlu as $body$
#line 447
  use DBIx::PgLink;
  my ($conn_name, $object_id) = @_; # trigger arguments, hardwired in CREATE TRIGGER
  return DBIx::PgLink->connect($conn_name)->shadow_row_trigger(
    object_id    => $object_id,
    trigger_data => $_TD,
  );
$body$;

revoke execute on function shadow_row_trigger_func() from public;

comment on function shadow_row_trigger_func()
is $$Trigger function for all shadow tables created by DBIx::PgLink.
Redirect data modification statements back to remote database.
$$;


create or replace function shadow_stmt_trigger_func() returns trigger
language plperlu as $body$
#line 466
  use DBIx::PgLink;
  my ($conn_name, $object_id) = @_; # trigger arguments, hardwired in CREATE TRIGGER
  return DBIx::PgLink->connect($conn_name)->shadow_statement_trigger(
    object_id    => $object_id,
    trigger_data => $_TD,
  );
$body$;

revoke execute on function shadow_stmt_trigger_func() from public;

comment on function shadow_stmt_trigger_func()
is $$Trigger function for all shadow tables created by DBIx::PgLink.
Start remote transaction before rows modification, commit remote transaction after.
$$;



create or replace function build_procedure(
  conn_name        text,
  local_schema     text,
  remote_catalog   text,
  remote_schema    text,
  remote_object    text,
  local_object     text,
  column_info      text[]
) returns void language plperlu as $body$
#line 493
  use strict;
  use DBIx::PgLink;
  my $conn = DBIx::PgLink->connect(shift);
  $conn->build_procedure(named_params(\@_,
    qw/  
  local_schema
  remote_catalog
  remote_schema
  remote_object
  local_object
  column_info
     /
  ));
$body$;

revoke execute on function build_procedure(
  conn_name        text,
  local_schema     text,
  remote_catalog   text,
  remote_schema    text,
  remote_object    text,
  local_object     text,
  column_info      text[]
) from public;

comment on function build_procedure(
  conn_name        text,
  local_schema     text,
  remote_catalog   text,
  remote_schema    text,
  remote_object    text,
  local_object     text,
  column_info      text[]
) is $$Helper function for building MicrosoftSQLServer/Sybase stored procedure accessor$$;
