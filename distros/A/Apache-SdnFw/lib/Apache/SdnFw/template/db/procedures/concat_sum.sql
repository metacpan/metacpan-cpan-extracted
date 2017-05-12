CREATE AGGREGATE concat_sum (
	BASETYPE = anyelement,
	SFUNC = sum_array,
	STYPE = anyarray,
	FINALFUNC = join_array,
INITCOND = '{}'
);
