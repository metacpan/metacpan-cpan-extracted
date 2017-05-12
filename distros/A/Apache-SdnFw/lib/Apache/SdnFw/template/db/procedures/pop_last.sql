CREATE OR REPLACE FUNCTION pop_last(text) RETURNS text
AS ' SELECT x.str[array_upper(x.str,1)] FROM (SELECT string_to_array($1,'','') as str) x; '
LANGUAGE sql;
