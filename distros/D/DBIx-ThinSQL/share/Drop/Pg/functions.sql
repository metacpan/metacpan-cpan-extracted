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

DROP FUNCTION IF EXISTS drop_functions();

CREATE FUNCTION drop_functions() RETURNS void AS $$
DECLARE
    rec RECORD;
    cmd text;
BEGIN
    cmd := '';

    FOR rec IN SELECT
            'DROP FUNCTION ' || quote_ident(ns.nspname) || '.'
                || quote_ident(proname) || '(' || oidvectortypes(proargtypes)
                || ') CASCADE;' AS name
        FROM
            pg_proc
        INNER JOIN
            pg_namespace ns
        ON
            (pg_proc.pronamespace = ns.oid)
        WHERE
            ns.nspname =
            'public'
        ORDER BY
            proname
    LOOP
        cmd := cmd || rec.name;
    END LOOP;

    EXECUTE cmd;
    RETURN;
END;
$$ LANGUAGE plpgsql;

SELECT drop_functions();
