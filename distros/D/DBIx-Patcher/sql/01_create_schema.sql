BEGIN;

CREATE SCHEMA patcher;

CREATE TABLE patcher.run (
    id SERIAL PRIMARY KEY,
    start timestamp with time zone DEFAULT now() NOT NULL,
    finish timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE patcher.patch (
    id SERIAL PRIMARY KEY,
    run_id integer REFERENCES patcher.run(id) DEFERRABLE,
    created timestamp with time zone DEFAULT now() NOT NULL,
    filename text NOT NULL,
    success boolean DEFAULT false,
    b64digest TEXT,
    output text
);

COMMIT;
