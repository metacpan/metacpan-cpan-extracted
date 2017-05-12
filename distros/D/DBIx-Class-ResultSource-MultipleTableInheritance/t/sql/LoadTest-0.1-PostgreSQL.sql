-- 
-- Created by SQL::Translator::Producer::PostgreSQL
-- Created on Mon Jul  8 19:18:41 2013
-- 
--
-- Table: just_a_table.
--
DROP TABLE "just_a_table" CASCADE;
CREATE TABLE "just_a_table" (
  "id" serial NOT NULL,
  "name" character varying(255) NOT NULL,
  PRIMARY KEY ("id")
);

--
-- Table: mixin.
--
DROP TABLE "mixin" CASCADE;
CREATE TABLE "mixin" (
  "id" serial NOT NULL,
  "words" text NOT NULL,
  PRIMARY KEY ("id")
);

--
-- Table: _bar.
--
DROP TABLE "_bar" CASCADE;
CREATE TABLE "_bar" (
  "id" integer NOT NULL,
  "b" integer NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "_bar_idx_b" on "_bar" ("b");

--
-- Table: _foo.
--
DROP TABLE "_foo" CASCADE;
CREATE TABLE "_foo" (
  "id" serial NOT NULL,
  "a" integer,
  PRIMARY KEY ("id")
);
CREATE INDEX "_foo_idx_a" on "_foo" ("a");

--
-- View: "foo"
--
DROP VIEW "foo";
CREATE VIEW "foo" ( "id", "a" ) AS
    SELECT _foo.id, a FROM _foo;

CREATE OR REPLACE FUNCTION foo_insert
  (_a INTEGER)
  RETURNS VOID AS $function$
  BEGIN
    INSERT INTO _foo ( a) VALUES ( _a );
  END;
$function$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION foo_update
  (_id INTEGER, _a INTEGER)
  RETURNS VOID AS $function$
  BEGIN
    UPDATE _foo SET a = _a WHERE ( id = _id );
  END;
$function$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION foo_delete
  (_id INTEGER)
  RETURNS VOID AS $function$
  BEGIN
    DELETE FROM _foo WHERE ( id = _id );
  END;
$function$ LANGUAGE plpgsql;


CREATE RULE _foo_insert_rule AS
  ON INSERT TO foo
  DO INSTEAD (
    SELECT foo_insert(NEW.a)
  );


CREATE RULE _foo_update_rule AS
  ON UPDATE TO foo
  DO INSTEAD (
    SELECT foo_update(OLD.id, NEW.a)
  );


CREATE RULE _foo_delete_rule AS
  ON DELETE TO foo
  DO INSTEAD (
    SELECT foo_delete(OLD.id)
  );

;

--
-- View: "bar"
--
DROP VIEW "bar";
CREATE VIEW "bar" ( "id", "a", "words", "b" ) AS
    SELECT _bar.id, a, words, b FROM _bar _bar  JOIN mixin mixin ON mixin.id = _bar.id  JOIN foo foo ON foo.id = _bar.id;

CREATE OR REPLACE FUNCTION bar_insert
  (_a INTEGER, _words TEXT, _b INTEGER)
  RETURNS VOID AS $function$
  BEGIN
    INSERT INTO foo ( a) VALUES ( _a );
    INSERT INTO _bar ( b, id) VALUES ( _b, currval('_foo_id_seq') );
    INSERT INTO mixin ( id, words) VALUES ( currval('_foo_id_seq'), _words );
  END;
$function$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION bar_update
  (_id INTEGER, _a INTEGER, _words TEXT, _b INTEGER)
  RETURNS VOID AS $function$
  BEGIN
    UPDATE _bar SET b = _b WHERE ( id = _id );
    UPDATE mixin SET words = _words WHERE ( id = _id );
    UPDATE foo SET a = _a WHERE ( id = _id );
  END;
$function$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION bar_delete
  (_id INTEGER)
  RETURNS VOID AS $function$
  BEGIN
    DELETE FROM _bar WHERE ( id = _id );
    DELETE FROM mixin WHERE ( id = _id );
    DELETE FROM foo WHERE ( id = _id );
  END;
$function$ LANGUAGE plpgsql;


CREATE RULE _bar_insert_rule AS
  ON INSERT TO bar
  DO INSTEAD (
    SELECT bar_insert(NEW.a, NEW.words, NEW.b)
  );


CREATE RULE _bar_update_rule AS
  ON UPDATE TO bar
  DO INSTEAD (
    SELECT bar_update(OLD.id, NEW.a, NEW.words, NEW.b)
  );


CREATE RULE _bar_delete_rule AS
  ON DELETE TO bar
  DO INSTEAD (
    SELECT bar_delete(OLD.id)
  );

;

--
-- Foreign Key Definitions
--

ALTER TABLE "_bar" ADD CONSTRAINT "_bar_fk_b" FOREIGN KEY ("b")
  REFERENCES "just_a_table" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "_foo" ADD CONSTRAINT "_foo_fk_a" FOREIGN KEY ("a")
  REFERENCES "_bar" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

