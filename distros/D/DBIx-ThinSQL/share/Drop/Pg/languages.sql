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

DROP FUNCTION IF EXISTS drop_languages();

CREATE FUNCTION drop_languages() RETURNS void AS $$
DECLARE
    rec RECORD;
    cmd text;
BEGIN
    cmd := '';

    FOR rec IN SELECT
            'DROP LANGUAGE ' || lanname || ';' AS name
        FROM
            pg_catalog.pg_language
        WHERE
            lanispl
    LOOP
        cmd := cmd || rec.name;
    END LOOP;

    EXECUTE cmd;
    RETURN;
END;
$$ LANGUAGE plpgsql;

SELECT drop_languages();
DROP FUNCTION drop_languages();
