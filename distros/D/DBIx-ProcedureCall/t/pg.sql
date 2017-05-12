-- You can run the SQL below to enable additional tests for DBIx::ProcedureCall.
--
-- After testing you can drop the created objects again (they are only used in the test)
--


CREATE FUNCTION dbixproccall0() RETURNS SETOF pg_user AS $$
    SELECT * FROM pg_user;
$$ LANGUAGE SQL;

CREATE FUNCTION dbixproccall1(int) RETURNS SETOF pg_user AS $$
    SELECT * FROM pg_user;
$$ LANGUAGE SQL;



