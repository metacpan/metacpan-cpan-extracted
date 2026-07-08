CREATE TYPE color AS ENUM(
    'red',
    'green',
    'blue'
);

CREATE TABLE lights(
    light_id    SERIAL          NOT NULL PRIMARY KEY,
    light_uuid  UUID            NOT NULL,
    stamp       TIMESTAMPTZ(6),
    color       color           NOT NULL DEFAULT 'red'
);

CREATE TABLE aliases(
    alias_id    INTEGER      NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    light_id    INTEGER      NOT NULL REFERENCES lights(light_id),
    name        VARCHAR(128) NOT NULL,

    UNIQUE(name)
);

CREATE VIEW light_by_name AS
    SELECT a.name       AS name,
           a.alias_id   AS alias_id,
           l.light_id   AS light_id,
           l.light_uuid AS light_uuid,
           l.stamp      AS stamp,
           l.color      AS color
      FROM aliases AS a
      JOIN lights  AS l USING(light_id);

CREATE TABLE complex_keys(
    name_a      CHAR(128) NOT NULL,
    name_b      CHAR(128) NOT NULL,

    name_c      CHAR(128),

    UNIQUE(name_a, name_b, name_c),
    PRIMARY KEY(name_a, name_b)
);

CREATE TABLE complex_ref(
    name_a      CHAR(128) NOT NULL,
    name_b      CHAR(128) NOT NULL,

    extras      CHAR(128),

    PRIMARY KEY(name_a, name_b),
    FOREIGN KEY(name_a, name_b) REFERENCES complex_keys(name_a, name_b)
);
