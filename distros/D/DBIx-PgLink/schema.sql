CREATE SCHEMA dbix_pglink;
COMMENT ON SCHEMA dbix_pglink IS
$$TODO$$;

SET search_path TO dbix_pglink;

create or replace function schema_version() returns integer language sql as 'SELECT 1';

create domain d_perl_class_name as 
  text 
  check (value ~ $re$^(\w+)(::\w+)*$$re$)  -- not a real check for existsing Perl package
;

create domain d_logon_mode as 
  text
  check (value in ('empty', 'current', 'default', 'deny')) 
  default 'empty'
  not null;


--simple audit: who and when insert/update record last time (no delete)
create type t_mod_stamp as (
  created_at timestamp with time zone,
  created_by name,
  updated_at timestamp with time zone,
  updated_by name
);

create or replace function mod_stamp_trg() returns trigger language plpgsql as $body$
declare
  ns  dbix_pglink.t_mod_stamp;
  os  dbix_pglink.t_mod_stamp;
begin
  ns := NEW.mod_stamp;
  if TG_OP = 'INSERT' then
    ns.created_at := current_timestamp;
    ns.created_by := current_user;
    ns.updated_at := current_timestamp;
    ns.updated_by := current_user;
  else
    os := OLD.mod_stamp;
    if os.created_at is distinct from ns.created_at
    or os.created_by is distinct from ns.created_by
    then
      raise EXCEPTION 'Modification of stamp fields is not allowed';
    end if;
    ns.updated_at := current_timestamp;
    ns.updated_by := current_user;
  end if;
  NEW.mod_stamp := ns;
  return NEW;
end;
$body$;


create table adapters (
  adapter_class   d_perl_class_name not null,
  dbms_name       text not null, --canonic name
  constraint pk_adapters primary key (adapter_class)
);
comment on table adapters is
  $$Available adapters$$;

insert into adapters values ('DBIx::PgLink::Adapter', 'generic');
insert into adapters values ('DBIx::PgLink::Adapter::Pg', 'PostgreSQL');
insert into adapters values ('DBIx::PgLink::Adapter::SQLite', 'SQLite');
insert into adapters values ('DBIx::PgLink::Adapter::SybaseASE', 'Sybase');
insert into adapters values ('DBIx::PgLink::Adapter::MSSQL', 'MSSQL');
insert into adapters values ('DBIx::PgLink::Adapter::XBase', 'XBase');


create table dbms_adapters (
  adapter_class   d_perl_class_name not null,
  dbms_name       text not null,
  constraint pk_dbms_adapters primary key (dbms_name)
);
comment on table dbms_adapters is 
  $$Adapter lookup by name of DBMS.$$;

insert into dbms_adapters values ('DBIx::PgLink::Adapter::Pg', 'Pg');
insert into dbms_adapters values ('DBIx::PgLink::Adapter::Pg', 'PostgreSQL');
insert into dbms_adapters values ('DBIx::PgLink::Adapter::Pg', 'Postgres');
insert into dbms_adapters values ('DBIx::PgLink::Adapter::SQLite', 'SQLite');
insert into dbms_adapters values ('DBIx::PgLink::Adapter::SybaseASE', 'Sybase');
insert into dbms_adapters values ('DBIx::PgLink::Adapter::SybaseASE', 'Sybase ASE');
insert into dbms_adapters values ('DBIx::PgLink::Adapter::SybaseASE', 'Sybase Adaptive Server Enterprise');
insert into dbms_adapters values ('DBIx::PgLink::Adapter::MSSQL', 'MSSQL');
insert into dbms_adapters values ('DBIx::PgLink::Adapter::MSSQL', 'Miscrosoft SQL Server');
insert into dbms_adapters values ('DBIx::PgLink::Adapter::XBase', 'XBase');


create table connections (
  conn_name     text not null,
  data_source   text not null,
  adapter_class d_perl_class_name not null default 'DBIx::PgLink::Adapter',
  logon_mode    d_logon_mode,
  comment       text null,
  use_libs      text[],
  mod_stamp     t_mod_stamp,
  constraint pk_connections primary key (conn_name),
  constraint fk_connections_adapters foreign key (adapter_class) references adapters(adapter_class)
    on update restrict on delete restrict
);
comment on table connections is 
  $$Connection metadata and default login credentials$$;
comment on column connections.conn_name is 
  $$Connection name. Any string.$$;
comment on column connections.data_source is 
  $$Data source name for DBI. Example: 'dbi:Pg:host=127.0.0.1;port=5432;db=postgres'$$;
comment on column connections.adapter_class is 
  $$Subclass of DBIx::PgLink::Adapter that handles connection. Perl class name.$$;
comment on column connections.logon_mode is 
  $$Used when not exist mapping between local and remote login
    'empty' - Connect with empty user name and empty password
    'current' - Connect as current user without password
    'default' - Connect as default user (users.local_user='') with default password
    'deny' - Connection refused$$;
comment on column connections.use_libs is 
  $$Text array of directories, append to Perl @INC$$;

create trigger connections_mod_stamp before insert or update
  on connections
  for each row execute procedure mod_stamp_trg();

insert into connections (conn_name, data_source, comment) values ('', '', 'Default connection');

create function connections_trg_protect_default() returns trigger language plpgsql as $body$
begin
  if NEW.conn_name = '' then
    raise EXCEPTION 'Default connection can not be changed or deleted';
  end if;
  return NEW;
end;
$body$;

create trigger connections_trg_protect_default before insert or update on connections
  for each row execute procedure connections_trg_protect_default();


create table attributes (
  conn_name       text not null,
  local_user      text not null default '', --'' for all users
  attr_name       text not null,
  attr_value      text null, --scalar value
  mod_stamp       t_mod_stamp,
  constraint pk_attributes primary key (conn_name, local_user, attr_name),
  constraint fk_attributes_connections foreign key (conn_name) references connections(conn_name)
    on update cascade  on delete cascade
);
comment on table attributes is $$Connection attributes passed to Adapter and DBI objects$$;

create trigger attributes_mod_stamp before insert or update
  on attributes
  for each row execute procedure mod_stamp_trg();

create table roles (
  conn_name       text not null,
  local_user      text not null default '', --'' for all users
  role_kind       text check (role_kind in ('Adapter', 'Connector')) default 'Adapter', 
  role_seq        int4 not null,
  role_name       d_perl_class_name not null,
  mod_stamp       t_mod_stamp,
  constraint pk_roles primary key (conn_name, local_user, role_kind, role_seq),
  constraint ak_roles unique (conn_name, local_user, role_name),
  constraint fk_roles_connections foreign key (conn_name) references connections(conn_name)
    on update cascade  on delete cascade
);
comment on table roles is $$Roles applied to Adapter or Connector objects and affected its behaviour.
'role_name' must be a name of Perl module.$$;

create trigger roles_mod_stamp before insert or update
  on roles
  for each row execute procedure mod_stamp_trg();


create table environment (
  conn_name       text not null,
  local_user      text not null default '', --'' for all users
  env_action      text check (env_action in ('set','append')) default 'set',
  env_name        text not null,
  env_value       text null, --null = unset
  mod_stamp       t_mod_stamp,
  constraint pk_environment primary key (conn_name, local_user, env_name),
  constraint fk_environment_connections foreign key (conn_name) references connections(conn_name)
    on update cascade  on delete cascade
);
comment on table environment is 
  $$Operating system environment variables set before connection$$;

create trigger environment_mod_stamp before insert or update
  on environment
  for each row execute procedure mod_stamp_trg();


create table users (
  conn_name       text not null,
  local_user      text not null, -- = session_user | '' for default
  remote_user     text null,
  remote_password text null,
  mod_stamp       t_mod_stamp,
  constraint pk_users primary key (conn_name, local_user),
  constraint fk_users_connections foreign key (conn_name) references connections(conn_name)
    on update cascade  on delete cascade
);
comment on table users is
  $$Mapping between local and remote logins. Default credentials can be added as local_user = '' (empty string).
See comment for connection.logon_mode column$$;

create trigger users_mod_stamp before insert or update
  on users
  for each row execute procedure mod_stamp_trg();


create table data_type_map (
  conn_name       text default '' not null,
  adapter_class   d_perl_class_name not null default 'DBIx::PgLink::Adapter',
  remote_type     text not null,
  local_type      text not null,
  standard_type   text not null,
  insertable      bool not null default true,
  updatable       bool not null default true,
  conv_to_local   text null,
  conv_to_remote  text null,
  quote_literal   bool not null,
  constraint pk_types primary key (conn_name, adapter_class, remote_type),
  constraint fk_types_connections foreign key (conn_name) references connections(conn_name)
    on update cascade  on delete cascade
);
comment on table data_type_map is
  $$Mapping of remote data type$$;
comment on column data_type_map.conv_to_local  is $$Adapter method name to convert value from remote db to PostgreSQL$$;
comment on column data_type_map.conv_to_remote is $$Adapter method name to convert value from PostgreSQL to remote db$$;


create table object_types (
  object_type  text not null,
  object_class text not null,
  constraint pk_object_types primary key (object_type)
);
comment on table object_types is
  $$Remote object can possibly change its type to another of the same class.
For example TABLE can be replace by VIEW or vice versa.
Local accessor for TABLE or VIEW is the same.$$;

insert into object_types values ('TABLE',     'TABLE');
insert into object_types values ('VIEW',      'TABLE');
insert into object_types values ('FUNCTION',  'ROUTINE');
insert into object_types values ('PROCEDURE', 'ROUTINE');

create or replace function object_type_class(_type text) returns text 
language sql immutable --actually it is very _stable_ function
as $body$
SELECT object_class FROM dbix_pglink.object_types WHERE object_type = $1
$body$;


create sequence object_id_sequence;
create table objects (
  object_id            int4 default nextval('object_id_sequence') not null,
  conn_name            text not null,
  remote_object_type   text not null, --remote object type (TABLE/VIEW/etc)
  remote_catalog       text null,     --remote catalog name, not quoted
  remote_schema        text null,     --remote schema name, not quoted
  remote_object        text not null, --remote object name, not quoted
    -- (for routine can be contain id or full function signature)
  local_schema         text not null, --local schema name, not quoted
  local_object         text not null, --local object name, not quoted
  mod_stamp            t_mod_stamp,
  constraint pk_objects primary key (object_id),
  constraint fk_objects_connections foreign key (conn_name) references connections(conn_name)
    on update cascade  on delete cascade
);
comment on table objects is $$Metadata for mapped objects$$;

/*
  one remote object can have many local links in different schemas
*/
create unique index objects_unique_name on objects(
  conn_name, 
  dbix_pglink.object_type_class(remote_object_type), --don't allow table and view with same name
  remote_catalog,
  remote_schema, 
  remote_object,
  local_schema,
  local_object
);

create trigger objects_mod_stamp before insert or update
  on objects
  for each row execute procedure mod_stamp_trg();


create table queries (
  object_id         int4 not null,
  action            text check (action in ('S','I','U','D')), --SELECT/INSERT/UPDATE/DELETE
  query_text        text not null,
  mod_stamp         t_mod_stamp,
  constraint pk_queries primary key (object_id, action),
  constraint fk_queries_objects
    foreign key       (object_id) 
    references objects(object_id)
    on update cascade  on delete cascade
);

comment on table queries is $$SQL queries for retrieving or modification of remote table.$$;

create trigger queries_mod_stamp before insert or update
  on queries
  for each row execute procedure mod_stamp_trg();

create table query_params (
  object_id         int4 not null,
  action            text not null,
  param_position    int4 not null,
  column_name       text not null, -- shadow table column
  local_type        text not null,
  remote_type       text not null,
  conv_to_remote    text null,
  constraint pk_query_params primary key (object_id, action, param_position),
  constraint fk_query_params_queries
    foreign key       (object_id, action) 
    references queries(object_id, action)
    on update cascade  on delete cascade
);

comment on table query_params is 
  $$List of query parameters passed to query. 
column_name    is shadow table column name for modification query. 
conv_to_remote is a name of Perl method of Adapter class associated with connection.$$;


create table columns (
  object_id            int4 not null,
  column_name          text not null, --remote column name, not quoted
  column_position      int4 not null, --position in remote table
  remote_type          text not null, --remote data type name
  remote_size          int null,
  remote_prec          int null,
  local_type           text not null, --local data type name
  --
  primary_key          bool not null default false, -- primary key in remote table
  searchable           bool not null default true,  -- use in update/delete WHERE clause
  nullable             bool not null default true,
  insertable           bool not null default true,
  updatable            bool not null default true,
  --
  conv_to_local        text null,     --remote to PostgreSQL
  conv_to_remote       text null,     --PostgreSQL to remote
  --
  constraint pk_columns primary key (object_id, column_name),
  constraint ak_columns unique (object_id, column_position),
  constraint fk_columns_objects
    foreign key       (object_id) 
    references objects(object_id)
    on update cascade  on delete cascade
);

comment on table columns is $$Column metadata for mapped objects$$;


--1:1 extension of objects table
create table routines (
  object_id           int4 not null,
  local_sign_arg      text not null,    --part of local function signature (arg types in parenthesis)
  remote_routine_name text not null,    --without arguments, not quoted
  returns_set         boolean not null, --setof function (or else scalar)
  rowtype             text null,        --unique local rowtype name for setof-functions
  mod_stamp           t_mod_stamp,
  constraint pk_routines primary key (object_id),
  constraint fk_routines_objects
    foreign key       (object_id) 
    references objects(object_id)
    on update cascade  on delete cascade
);

comment on table routines is $$Metadata for mapped routines$$;

create trigger routines_mod_stamp before insert or update
  on routines
  for each row execute procedure mod_stamp_trg();


create view v_routines
as
select
  o.*,
  r.local_sign_arg,
  r.remote_routine_name,
  r.returns_set,
  r.rowtype
from dbix_pglink.objects o
  join dbix_pglink.routines r on r.object_id = o.object_id
;
comment on view v_routines is $$Metadata for mapped routines$$;


create table routine_arguments (
  object_id         int4 not null,
  arg_position      int4 not null,
  arg_name          text null,
  remote_type       text not null,
  local_type        text not null,
  conv_to_remote    text null,
  constraint pk_routine_arguments primary key (object_id, arg_position),
  constraint fk_routine_arguments_routines
    foreign key        (object_id) 
    references routines(object_id)
    on update cascade  on delete cascade
);

comment on table routine_arguments is $$Arguments of mapped routine$$;


----------------------------------------------role configuration

create table init_session (
  conn_name       text not null,
  local_user      text not null default '', --'' for all users
  init_seq        int4 not null,
  init_query      text not null,
  mod_stamp       t_mod_stamp,
  constraint pk_init_session primary key (conn_name, local_user, init_seq),
  constraint fk_init_session_connections foreign key (conn_name) references connections(conn_name)
    on update cascade  on delete cascade
);
comment on table init_session is 
  $$Initialization SQL scripts executed on remote database when connection established$$;

create trigger init_session_mod_stamp before insert or update
  on init_session
  for each row execute procedure mod_stamp_trg();


create table safe (
  conn_name       text   not null,
  local_user      text   not null, --'' for all users
  safe_kind       text   not null check (safe_kind in ('command', 'regex', 'attribute')),
  safe_text       text   not null,
  safe_perm       text   not null check (safe_perm in ('allow','unallow','deny','undeny')),
  mod_stamp       t_mod_stamp,
  constraint pk_safe primary key (conn_name, safe_kind, safe_text),
  constraint fk_safe_connections foreign key (conn_name) references connections(conn_name)
    on update cascade  on delete cascade,
  constraint ck_safe_perm check (safe_perm in ('allow','unallow') or safe_kind='regex')
);
comment on table safe is $$Configuration of Safe role (optional)$$;

create trigger safe_mod_stamp before insert or update
  on safe
  for each row execute procedure mod_stamp_trg();
