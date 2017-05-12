CREATE OR REPLACE FUNCTION join_array(anyarray) RETURNS text
AS ' SELECT array_to_string($1,'',''); '
LANGUAGE sql;
