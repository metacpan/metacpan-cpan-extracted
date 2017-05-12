CREATE AGGREGATE concat (
	BASETYPE = anyelement,
	SFUNC = array_append,
	STYPE = anyarray,
	FINALFUNC = join_array,
	INITCOND = '{}'
);
