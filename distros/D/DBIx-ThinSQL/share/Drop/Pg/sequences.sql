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

DROP FUNCTION IF EXISTS drop_sequences();

CREATE FUNCTION drop_sequences() RETURNS void AS $$
DECLARE
    rec RECORD;
    cmd text;
BEGIN
    cmd := '';

    FOR rec IN SELECT
            'DROP SEQUENCE ' || quote_ident(n.nspname) || '.'
                || quote_ident(c.relname) || ' CASCADE;' AS name
        FROM
            pg_catalog.pg_class AS c
        LEFT JOIN
            pg_catalog.pg_namespace AS n
        ON
            n.oid = c.relnamespace
        WHERE
            relkind = 'S' AND
            n.nspname NOT IN ('pg_catalog', 'pg_toast') AND
            pg_catalog.pg_table_is_visible(c.oid)
    LOOP
        cmd := cmd || rec.name;
    END LOOP;

    EXECUTE cmd;
    RETURN;
END;
$$ LANGUAGE plpgsql;

SELECT drop_sequences();
DROP FUNCTION drop_sequences();
