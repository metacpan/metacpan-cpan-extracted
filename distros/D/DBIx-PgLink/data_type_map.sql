SET search_path TO dbix_pglink;

--Standard SQL types for default connection

\copy dbix_pglink.data_type_map (remote_type, standard_type, local_type, quote_literal) from stdin csv
SQL_GUID,SQL_GUID,text,t
SQL_WLONGVARCHAR,SQL_WLONGVARCHAR,text,t
SQL_WVARCHAR,SQL_WVARCHAR,text,t
SQL_WCHAR,SQL_WCHAR,text,t
SQL_BIT,SQL_BIT,boolean,f
SQL_TINYINT,SQL_TINYINT,smallint,f
SQL_LONGVARCHAR,SQL_LONGVARCHAR,text,t
SQL_UNKNOWN_TYPE,SQL_UNKNOWN_TYPE,text,t
SQL_ALL_TYPES,SQL_ALL_TYPES,text,t
SQL_CHAR,SQL_CHAR,char,t
SQL_NUMERIC,SQL_NUMERIC,numeric,f
SQL_DECIMAL,SQL_DECIMAL,decimal,f
SQL_INTEGER,SQL_INTEGER,integer,f
SQL_SMALLINT,SQL_SMALLINT,smallint,f
SQL_BIGINT,SQL_BIGINT,bigint,f
SQL_FLOAT,SQL_FLOAT,float8,f
SQL_REAL,SQL_REAL,real,f
SQL_DOUBLE,SQL_DOUBLE,double precision,f
SQL_DATE,SQL_DATE,date,t
SQL_INTERVAL,SQL_INTERVAL,interval,t
SQL_TIME,SQL_TIME,time,t
SQL_TIMESTAMP,SQL_TIMESTAMP,timestamp,t
SQL_TYPE_TIME,SQL_TYPE_TIME,time,t
SQL_TYPE_DATE,SQL_TYPE_DATE,date,t
SQL_TYPE_TIMESTAMP,SQL_TYPE_TIMESTAMP,timestamp,t
SQL_TYPE_TIMESTAMP_WITH_TIMEZONE,SQL_TYPE_TIMESTAMP_WITH_TIMEZONE,timestamp with time zone,t
SQL_TYPE_TIME_WITH_TIMEZONE,SQL_TYPE_TIME_WITH_TIMEZONE,time with time zone,t
SQL_VARCHAR,SQL_VARCHAR,varchar,t
SQL_BOOLEAN,SQL_BOOLEAN,boolean,t
SQL_CLOB,SQL_CLOB,text,t
INT,SQL_INTEGER,int4,f
INTEGER,SQL_INTEGER,int4,f
SMALLINT,SQL_SMALLINT,smallint,f
BIGINT,SQL_BIGINT,bigint,f
NUMERIC,SQL_NUMERIC,numeric,f
DECIMAL,SQL_DECIMAL,decimal,f
REAL,SQL_REAL,real,f
FLOAT,SQL_FLOAT,float8,f
DOUBLE PRECISION,SQL_DOUBLE,double precision,f
CHAR,SQL_CHAR,char,t
CHARACTER,SQL_CHAR,char,t
VARCHAR,SQL_VARCHAR,varchar,t
CHARACTER VARYING,SQL_VARCHAR,varchar,t
TEXT,SQL_VARCHAR,text,t
DATE,SQL_DATE,date,t
TIME,SQL_TIME,time,t
BOOLEAN,SQL_BOOLEAN,boolean,t
INTERVAL,SQL_INTERVAL,interval,t
\.

\copy dbix_pglink.data_type_map (remote_type, standard_type, local_type, conv_to_local, conv_to_remote, quote_literal) from stdin csv
SQL_LONGVARBINARY,SQL_LONGVARBINARY,bytea,to_pg_bytea,,t
SQL_VARBINARY,SQL_VARBINARY,bytea,to_pg_bytea,,t
SQL_BINARY,SQL_BINARY,bytea,to_pg_bytea,,t
SQL_BLOB,SQL_BLOB,bytea,to_pg_bytea,,t
\.

--Vendor types for default connection

--SQLite
\copy dbix_pglink.data_type_map (adapter_class, remote_type, standard_type, local_type, quote_literal) from stdin csv
DBIx::PgLink::Adapter::SQLite,REAL,SQL_FLOAT,float8,f
\.


--XBase
\copy dbix_pglink.data_type_map (adapter_class, remote_type, standard_type, local_type, conv_to_local, conv_to_remote, quote_literal) from stdin csv
DBIx::PgLink::Adapter::XBase,DATE,SQL_DATE,date,,to_xbase_date,t
DBIx::PgLink::Adapter::XBase,BLOB,SQL_BLOB,bytea,to_pg_bytea,,t
DBIx::PgLink::Adapter::XBase,CHAR,SQL_CHAR,varchar,,,t
\.

--Sybase
\copy dbix_pglink.data_type_map (adapter_class, remote_type, standard_type, local_type, insertable, updatable, conv_to_local, conv_to_remote, quote_literal) from stdin csv
DBIx::PgLink::Adapter::Sybase,TINYINT,SQL_SMALLINT,smallint,t,t,,,f
DBIx::PgLink::Adapter::Sybase,NUMERIC IDENTITY,SQL_NUMERIC,numeric,f,f,,,f
DBIx::PgLink::Adapter::Sybase,MONEY,SQL_NUMERIC,"numeric(19,4)",t,t,,,f
DBIx::PgLink::Adapter::Sybase,SMALLMONEY,SQL_NUMERIC,"numeric(19,4)",t,t,,,f
DBIx::PgLink::Adapter::Sybase,DATETIME,SQL_TYPE_TIMESTAMP_WITH_TIMEZONE,timestamp without time zone,t,t,,,t
DBIx::PgLink::Adapter::Sybase,TIMESTAMP,SQL_BINARY,bytea,f,f,syb_binary_to_pg_bytea,,f
DBIx::PgLink::Adapter::Sybase,IMAGE,SQL_BLOB,bytea,t,t,to_pg_bytea,,t
DBIx::PgLink::Adapter::Sybase,BIT,SQL_BOOLEAN,boolean,t,t,,pg_bool_to_syb_bit,f
DBIx::PgLink::Adapter::Sybase,UNICHAR,SQL_CHAR,char,t,t,,,t
DBIx::PgLink::Adapter::Sybase,UNIVARCHAR,SQL_VARCHAR,varchar,t,t,,,t
DBIx::PgLink::Adapter::Sybase,BINARY,SQL_BINARY,bytea,t,t,syb_binary_to_pg_bytea,,t
DBIx::PgLink::Adapter::Sybase,VARBINARY,SQL_VARBINARY,bytea,t,t,syb_binary_to_pg_bytea,,t
\.

--MSSQL
\copy dbix_pglink.data_type_map (adapter_class, remote_type, standard_type, local_type, insertable, updatable, conv_to_local, conv_to_remote, quote_literal) from stdin csv
DBIx::PgLink::Adapter::MSSQL,TINYINT,SQL_SMALLINT,smallint,t,t,,,f
DBIx::PgLink::Adapter::MSSQL,NUMERIC IDENTITY,SQL_NUMERIC,numeric,f,f,,,f
DBIx::PgLink::Adapter::MSSQL,INT IDENTITY,SQL_INTEGER,int4,f,f,,,f
DBIx::PgLink::Adapter::MSSQL,BIGINT IDENTITY,SQL_BIGINT,int8,f,f,,,f
DBIx::PgLink::Adapter::MSSQL,MONEY,SQL_NUMERIC,"numeric(19,4)",t,t,,,f
DBIx::PgLink::Adapter::MSSQL,SMALLMONEY,SQL_NUMERIC,"numeric(19,4)",t,t,,,f
DBIx::PgLink::Adapter::MSSQL,DATETIME,SQL_TYPE_TIMESTAMP_WITH_TIMEZONE,timestamp without time zone,t,t,,,t
DBIx::PgLink::Adapter::MSSQL,TIMESTAMP,SQL_BINARY,bytea,f,f,to_pg_bytea,,t
DBIx::PgLink::Adapter::MSSQL,ROWVERSION,SQL_BINARY,bytea,f,f,to_pg_bytea,,t
DBIx::PgLink::Adapter::MSSQL,IMAGE,SQL_BLOB,bytea,t,t,to_pg_bytea,,t
DBIx::PgLink::Adapter::MSSQL,BIT,SQL_BOOLEAN,boolean,t,t,,pg_bool_to_mssql_bit,f
DBIx::PgLink::Adapter::MSSQL,NCHAR,SQL_CHAR,char,t,t,,,t
DBIx::PgLink::Adapter::MSSQL,NVARCHAR,SQL_VARCHAR,varchar,t,t,,,t
\.
