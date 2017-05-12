BEGIN;
DROP TYPE setting CASCADE;
CREATE TYPE setting AS (
  setting_key text,
  value text
);

CREATE OR REPLACE FUNCTION setting_get(in_setting_key text)
returns setting language sql as
$$
SELECT $1, '0.2.1'::text;
$$;

COMMIT;
