--Install all database objects

\set ON_ERROR_STOP
set client_min_messages=WARNING;

\i schema.sql
\i data_type_map.sql
\i utility.sql
\i functions.sql
\i statistics.sql
