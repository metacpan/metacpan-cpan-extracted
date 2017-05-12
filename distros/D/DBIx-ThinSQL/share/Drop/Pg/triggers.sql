DROP FUNCTION IF EXISTS make_plpgsql();

CREATE OR REPLACE FUNCTION make_plpgsql() RETURNS VOID AS $$
CREATE LANGUAGE plpgsql;
$$ LANGUAGE SQL;

SELECT
    CASE WHEN
        EXISTS(
            SELECT
                1
            FROM
                pg_catalog.pg_language
            WHERE
                lanname='plpgsql'
        )
    THEN
        NULL
    ELSE
        make_plpgsql()
    END;

DROP FUNCTION make_plpgsql();

DROP FUNCTION IF EXISTS drop_triggers();

CREATE FUNCTION drop_triggers() RETURNS void AS $$
DECLARE
    rec RECORD;
    cmd text;
BEGIN
    cmd := '';

    -- TODO

    EXECUTE cmd;
    RETURN;
END;
$$ LANGUAGE plpgsql;

SELECT drop_triggers();
DROP FUNCTION drop_triggers();
