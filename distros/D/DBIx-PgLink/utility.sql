--utility functions

set search_path = 'dbix_pglink';

create or replace function version_integer() returns int language plperlu as $body$
  my $ver = spi_exec_query("SELECT version()")->{rows}->[0]->{version};
  my ($major, $minor, $release) = $ver =~ /^PostgreSQL (\d+)\.(\d+)\.(\d+)/;
  return $major*10000+$minor*100+$release;
$body$;
comment on function version_integer() is
$$Return PostgreSQL server verion as integer value. For example, version 8.1.5 will be returned as 80105.$$;

grant execute on function version_integer() to public;


--debug functions

create or replace function trace_level(_value int) returns int language plperlu as $body$
  use DBIx::PgLink::Logger;
  return trace_level(shift);
$body$;
revoke execute on function trace_level(_value int) from public;

create or replace function trace_level() returns int language plperlu as $body$
  use DBIx::PgLink::Logger;
  return trace_level();
$body$;
revoke execute on function trace_level() from public;


create or replace function trace_msg(_severity text, _message text) returns void language plperlu as $body$
  use DBIx::PgLink::Logger;
  my ($severity, $message) = @_;
  trace_msg($severity, $message);
$body$;
--trace_msg() is safe, no revoke from public

/*
  Connection setup helper functions
*/

----------user helpers

create or replace function get_user(_conn_name text, _local_user text)
returns text language plpgsql as $body$
begin
  return (
    select remote_user
    from dbix_pglink.users
    where conn_name = _conn_name and local_user = _local_user
  );
end;
$body$;
revoke execute on function get_user(_conn_name text, _local_user text) from public;
comment on function get_user(_conn_name text, _local_user text) is
$$Get remote user name mapped for local user$$;


create or replace function set_user(_conn_name text, _local_user text, _remote_user text, _remote_password text)
returns void language plpgsql as $body$
begin
  begin
    insert into dbix_pglink.users (conn_name, local_user, remote_user, remote_password)
    values (_conn_name, _local_user, _remote_user, _remote_password);
  exception
    when unique_violation then
      update dbix_pglink.users set
        remote_user = _remote_user,
        remote_password = _remote_password
      where conn_name = _conn_name and local_user = _local_user;
  end;
end;
$body$;
revoke execute on function set_user(_conn_name text, _local_user text, _remote_user text, _remote_password text) from public;
comment on function set_user(_conn_name text, _local_user text, _remote_user text, _remote_password text) is
$$Set mapping between local and remote user$$;


create or replace function delete_user(_conn_name text, _local_user text)
returns boolean language plpgsql as $body$
begin
  delete from dbix_pglink.users
  where conn_name = _conn_name and local_user = _local_user;
  return FOUND;
end;
$body$;
revoke execute on function delete_user(_conn_name text, _local_user text) from public;
comment on function delete_user(_conn_name text, _local_user text) is
$$Delete user mapping by local user name$$;


----------connection role helpers

create or replace function get_role(_conn_name text, _local_user text, _role_kind text, _role_seq int)
returns d_perl_class_name language plpgsql as $body$
begin
  return (
    select role_name
    from dbix_pglink.roles
    where conn_name = _conn_name
      and local_user = _local_user 
      and role_kind = _role_kind
      and role_seq = _role_seq
  );
end;
$body$;
revoke execute on function get_role(_conn_name text, _local_user text, _role_kind text, _role_seq int) from public;
comment on function get_role(_conn_name text, _local_user text, _role_kind text, _role_seq int) is
$$Get connection role by sequence number$$;


create or replace function set_role(
  _conn_name  text,
  _local_user text,
  _role_kind  text,
  _role_name  d_perl_class_name,
  _role_seq   int,
  _replace    boolean
) returns void language plpgsql as $body$
declare
  _max int;
begin
  if _role_seq is null then --append mode, max+1 number generation
    --skip if already exists, position not important
    if exists(
      select*
      from dbix_pglink.roles
      where conn_name = _conn_name
        and local_user = _local_user
        and role_kind = _role_kind
        and role_name = _role_name
    ) then
      return;
    end if;
    insert into dbix_pglink.roles (conn_name, local_user, role_kind, role_seq, role_name)
    values (
      _conn_name,
      _local_user,
      _role_kind,
      coalesce((
        select max(role_seq)
        from dbix_pglink.roles
        where conn_name = _conn_name
          and local_user = _local_user
          and role_kind = _role_kind
      ), 0) + 1,
      _role_name
    );
    return;
  end if;

  --delete role by name, if exists
  delete from dbix_pglink.roles
  where conn_name = _conn_name
    and local_user = _local_user
    and role_kind = _role_kind
    and role_name = _role_name;

  if _replace then --replace role with specified number

    begin
      insert into dbix_pglink.roles (conn_name, local_user, role_kind, role_seq, role_name)
      values (_conn_name, _local_user, _role_kind, _role_seq, _role_name);
    exception
      when unique_violation then
        update dbix_pglink.roles set role_name = _role_name
        where conn_name = _conn_name
          and local_user = _local_user
          and role_kind = _role_kind
          and role_seq = _role_seq;
    end;

  else --insert role in specified position, shift existing roles down

    _max := coalesce((
      select max(role_seq)
      from dbix_pglink.roles
      where conn_name = _conn_name
        and local_user = _local_user
        and role_kind = _role_kind
    ), 0);

    update dbix_pglink.roles set role_seq = role_seq + _max
    where conn_name = _conn_name
      and local_user = _local_user
      and role_kind = _role_kind
      and role_seq >= _role_seq;

    insert into dbix_pglink.roles (conn_name, local_user, role_kind, role_seq, role_name)
    values (_conn_name, _local_user, _role_kind, _role_seq, _role_name);

    update dbix_pglink.roles set role_seq = role_seq - _max + 1
    where conn_name = _conn_name
      and local_user = _local_user
      and role_kind = _role_kind
      and role_seq > _role_seq;

  end if;
end;
$body$;
revoke execute on function set_role(
  _conn_name  text,
  _local_user text,
  _role_kind  text,
  _role_name  d_perl_class_name,
  _role_seq   int,
  _replace    boolean
) from public;
comment on function set_role(
  _conn_name  text,
  _local_user text,
  _role_kind  text,
  _role_name  d_perl_class_name,
  _role_seq   int,
  _replace    boolean
) is
$$Set connection role by sequence number.
Append role to end, if sequence number is NULL.
If fifth parameter (_replace) is false, then insert role with specified number and shift existing roles down.$$;


create or replace function set_role(
  _conn_name text,
  _role_kind text,
  _role_name d_perl_class_name
) returns void language plpgsql as $$
begin
  perform dbix_pglink.set_role($1,current_user,$2,$3,null,false);
  return;
end;
$$;

revoke execute on function set_role(
  _conn_name text,
  _role_kind text,
  _role_name d_perl_class_name
) from public;
comment on function set_role(
  _conn_name text,
  _role_kind text,
  _role_name d_perl_class_name
) is
$$Add role to connection$$;


create or replace function delete_role(_conn_name text, _local_user text, _role_kind text, _role_name d_perl_class_name)
returns boolean language plpgsql as $body$
begin
  delete from dbix_pglink.roles
  where conn_name = _conn_name
    and local_user = _local_user
    and role_kind = _role_kind
    and role_name = _role_name;
  return FOUND;
end;
$body$;
revoke execute on function delete_role(_conn_name text, _local_user text, _role_kind text, _role_name d_perl_class_name) from public;
comment on function delete_role(_conn_name text, _local_user text, _role_kind text, _role_name d_perl_class_name)
is $$Delete connection role by role name$$;



----------connection attribute helpers

create or replace function get_attr(_conn_name text, _local_user text, _attr_name text)
returns text language plpgsql as $body$
begin
  return (
    select attr_value
    from dbix_pglink.attributes
    where conn_name = _conn_name 
      and local_user = _local_user
      and attr_name = _attr_name
  );
end;
$body$;
revoke execute on function get_attr(_conn_name text, _local_user text, _attr_name text) from public;
comment on function get_attr(_conn_name text, _local_user text, _attr_name text) is
$$Get connection attribute value by name$$;


create or replace function set_attr(_conn_name text, _local_user text, _attr_name text, _attr_value text)
returns void language plpgsql as $body$
begin
  begin
    insert into dbix_pglink.attributes (conn_name, local_user, attr_name, attr_value)
    values (_conn_name, _local_user, _attr_name, _attr_value);
  exception
    when unique_violation then
      update dbix_pglink.attributes set attr_value = _attr_value
      where conn_name = _conn_name
        and local_user = _local_user
        and attr_name = _attr_name;
  end;
end;
$body$;
revoke execute on function set_attr(_conn_name text, _local_user text, _attr_name text, _attr_value text) from public;
comment on function set_attr(_conn_name text, _local_user text, _attr_name text, _attr_value text) is
$$Set connection attribute value by name$$;


create or replace function delete_attr(_conn_name text, _local_user text, _attr_name text)
returns boolean language plpgsql as $body$
begin
  delete from dbix_pglink.attributes
  where conn_name = _conn_name
    and local_user = _local_user
    and attr_name = _attr_name;
  return FOUND;
end;
$body$;
revoke execute on function delete_attr(_conn_name text, _local_user text, _attr_name text) from public;
comment on function delete_attr(_conn_name text, _local_user text, _attr_name text) is
$$Delete connection attribute by name$$;


----------connection environment helpers

create or replace function get_env(_conn_name text, _local_user text, _env_name text)
returns text language plpgsql as $body$
begin
  return (
    select env_value
    from dbix_pglink.environment
    where conn_name = _conn_name 
      and local_user = _local_user
      and env_name = _env_name
  );
end;
$body$;
revoke execute on function get_env(_conn_name text, _local_user text, _env_name text) from public;
comment on function get_env(_conn_name text, _local_user text, _env_name text) is
$$Get connection environment variable by name$$;


create or replace function set_env(_conn_name text, _local_user text, _env_action text, _env_name text, _env_value text)
returns void language plpgsql as $body$
begin
  begin
    insert into dbix_pglink.environment (conn_name, local_user, env_action, env_name, env_value)
    values (_conn_name, _local_user, _env_action, _env_name, _env_value);
  exception
    when unique_violation then
      update dbix_pglink.environment set
        env_action = _env_action,
        env_value  = _env_value
      where conn_name = _conn_name
        and local_user = _local_user
        and env_name = _env_name;
  end;
end;
$body$;
revoke execute on function set_env(_conn_name text, _local_user text, _env_action text, _env_name text, _env_value text) from public;
comment on function set_env(_conn_name text, _local_user text, _env_action text, _env_name text, _env_value text) is
$$Set or append connection environment variable by name. Use NULL value to unset variable.$$;


create or replace function delete_env(_conn_name text, _local_user text, _env_name text)
returns boolean language plpgsql as $body$
begin
  delete from dbix_pglink.environment
  where conn_name = _conn_name
    and local_user = _local_user
    and env_name = _env_name;
  return FOUND;
end;
$body$;
revoke execute on function delete_env(_conn_name text, _local_user text, _env_name text) from public;
comment on function delete_env(_conn_name text, _local_user text, _env_name text) is
$$Delete connection environment variable by name.
Deletion of variable not unset value, set NULL as value instead.$$;


----------remote initialisation script helpers

create or replace function get_init_session(_conn_name text, _local_user text, _init_seq int)
returns text language plpgsql as $body$
begin
  return (
    select init_query
    from dbix_pglink.init_session
    where conn_name = _conn_name 
      and local_user = _local_user
      and init_seq = _init_seq
  );
end;
$body$;
revoke execute on function get_init_session(_conn_name text, _local_user text, _init_seq int) from public;
comment on function get_init_session(_conn_name text, _local_user text, _init_seq int) is
$$Get remote initialisation script by sequence number$$;

 
create or replace function set_init_session(_conn_name text, _local_user text, _init_seq int, _init_query text, _replace boolean)
returns void language plpgsql as $body$
declare
  _max int;
begin
  if _init_seq is null then --append mode, max+1 number generation
    insert into dbix_pglink.init_session (conn_name, local_user, init_seq, init_query)
    values (
      _conn_name,
      _local_user,
      coalesce((select max(init_seq) from dbix_pglink.init_session where conn_name = _conn_name), 0) + 1,
      _init_query
    );
    return;
  end if;

  if _replace then

    begin
      insert into dbix_pglink.init_session (conn_name, local_user, init_seq, init_query)
      values (_conn_name, _local_user, _init_seq, _init_query);
    exception
      when unique_violation then
        update dbix_pglink.init_session set init_query = _init_query
        where conn_name = _conn_name
          and local_user = _local_user
          and init_seq = _init_seq;
    end;

  else --shift (N, max) to (N+1, max+1), insert N

    --PostgreSQL bug: update of multiple rows with unique key to overlapped key range must be done in backward order
    --use two step shifting: (N, max) to (N+max, max+max), then to (N+1, max+1)
    _max := coalesce((select max(init_seq) from dbix_pglink.init_session where conn_name = _conn_name), 0);

    update dbix_pglink.init_session set init_seq = init_seq + _max
    where conn_name = _conn_name
      and local_user = _local_user
      and init_seq >= _init_seq;

    insert into dbix_pglink.init_session (conn_name, local_user, init_seq, init_query)
    values (_conn_name, _local_user, _init_seq, _init_query);

    update dbix_pglink.init_session set init_seq = init_seq - _max + 1
    where conn_name = _conn_name
      and local_user = _local_user
      and init_seq > _init_seq;

  end if;
end;
$body$;
revoke execute on function set_init_session(_conn_name text, _local_user text, _init_seq int, _init_query text, _replace boolean) from public;
comment on function set_init_session(_conn_name text, _local_user text, _init_seq int, _init_query text, _replace boolean) is
$$Set remote initialisation script by sequence number.
Append query to end, if sequence number is NULL.
If fourth parameter (_replace) is false, then insert query with specified number and shift existing queries down.$$;


create or replace function delete_init_session(_conn_name text, _local_user text, _init_seq int)
returns boolean language plpgsql as $body$
begin
  delete from dbix_pglink.init_session
  where conn_name = _conn_name
    and local_user = _local_user
    and init_seq = _init_seq;
  return FOUND;
end;
$body$;
revoke execute on function delete_init_session(_conn_name text, _local_user text, _init_seq int) from public;
comment on function delete_init_session(_conn_name text, _local_user text, _init_seq int) is
$$Delete remote initialisation script by sequence number$$;


create or replace function get_dbms_name(_data_source text)
returns text language plperlu as $body$
#line 468
  use strict;
  use DBI;
  my ($data_source) = @_;
  return eval {
    my $dbh = DBI->connect($data_source); # without user name
    $dbh->get_info(17) #ODBC SQL_DBMS_NAME
       || $dbh->{Driver}->{Name};
  };
$body$;


----------------------------------------------------- connection setup with defaults

create or replace function create_connection(
  _conn_name         text,
  _data_source       text,
  _adapter_class     d_perl_class_name,
  _logon_mode        d_logon_mode,
  _use_libs          text[],
  _comment           text
) returns void
security definer
language plpgsql as $body$
declare
  v_adapter_class text;
begin

  v_adapter_class := coalesce(
    nullif(_adapter_class,''),
    (
      select adapter_class
      from dbix_pglink.adapters
      where dbms_name = substring(_data_source from $RE$dbi:(\w+)$RE$) --first
      limit 1
    ),
    (
      select adapter_class
      from dbix_pglink.adapters
      where dbms_name = substring(_data_source from $RE$.*dbi:(\w+)$RE$) --last
      limit 1
    ),
    (
      select adapter_class
      from dbix_pglink.adapters
      where dbms_name = dbix_pglink.get_dbms_name(_data_source) --try connect
      limit 1
    ),
    'DBIx::PgLink::Adapter' --default
  );

  insert into dbix_pglink.connections (
    conn_name,
    data_source,
    adapter_class,
    logon_mode,
    use_libs,
    comment
  ) values (
    _conn_name,
    _data_source,
    v_adapter_class,
    _logon_mode,
    _use_libs,
    _comment
  );

  ----default roles
  --perform dbix_pglink.set_role(_conn_name, '', 'Adapter', 'CheckWhereClause');
  perform dbix_pglink.set_role(_conn_name, '', 'Adapter', 'InitSession');
  --perform dbix_pglink.set_role(_conn_name, '', 'Adapter', 'NestedTransactions');
  --perform dbix_pglink.set_role(_conn_name, '', 'Adapter', 'StatementCache');
  --perform dbix_pglink.set_role(_conn_name, '', 'Adapter', 'Reconnect');

  ----default attributes (starting point for customization, defaults are dubbed in code)
  --DBI/DBD attribute (CamelCase)
  perform dbix_pglink.set_attr(_conn_name, '', 'RaiseError',  '1');
  perform dbix_pglink.set_attr(_conn_name, '', 'PrintError',  '0');
  perform dbix_pglink.set_attr(_conn_name, '', 'AutoCommit',  '1');
  --adapter' role attribute (lower_case)
  perform dbix_pglink.set_attr(_conn_name, '', 'reconnect_retries',    '3');
  perform dbix_pglink.set_attr(_conn_name, '', 'reconnect_interval',   '5');
  perform dbix_pglink.set_attr(_conn_name, '', 'reconnect_timeout',    '5');
  perform dbix_pglink.set_attr(_conn_name, '', 'statement_cache_size', '100');

end;
$body$;

revoke execute on function create_connection(
  _conn_name         text,
  _data_source       text,
  _adapter_class     d_perl_class_name,
  _logon_mode        d_logon_mode,
  _use_libs          text[],
  _comment           text
) from public;
comment on function create_connection(
  _conn_name         text,
  _data_source       text,
  _adapter_class     d_perl_class_name,
  _logon_mode        d_logon_mode,
  _use_libs          text[],
  _comment           text
) is
$$Create and setup connection with reasonable defaults for attributes and roles$$;



create or replace function create_connection(
  _conn_name     text,
  _data_source   text,
  _comment       text
) returns void
security definer
language plpgsql as $$
begin
  perform dbix_pglink.create_connection($1,$2,null,'empty',null,$3);
  return;
end;
$$;

revoke execute on function create_connection(
  _conn_name     text,
  _data_source   text,
  _comment       text
) from public;
comment on function create_connection(
  _conn_name     text,
  _data_source   text,
  _comment       text
) is
$$Create and setup connection with reasonable defaults$$;



create or replace function delete_connection(
  _conn_name     text
) returns void
security definer
language plperlu as $body$
#line 608

  use DBIx::PgLink;
  use DBIx::PgLink::Local;

  my $conn_name = shift;

  my $conn = DBIx::PgLink->connect(
    $conn_name,
    no_connect => 1, # remote site can be dead
  );

  $conn->for_all_accessors( sub { (shift)->drop_local_objects } );

  pg_dbh->do(q/DELETE FROM dbix_pglink.connections WHERE conn_name=$1/, {}, $conn_name);

$body$;

revoke execute on function delete_connection(
  _conn_name     text
) from public;
comment on function delete_connection(
  _conn_name     text
) is
$$Delete connection with all settings$$;
