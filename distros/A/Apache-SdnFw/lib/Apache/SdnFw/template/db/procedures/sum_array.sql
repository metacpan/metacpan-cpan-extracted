CREATE OR REPLACE FUNCTION sum_array(anyarray,anyelement) RETURNS anyarray
AS ' SELECT array_append($1,COALESCE($1[array_upper($1,1)],0)+$2); '
LANGUAGE sql;
