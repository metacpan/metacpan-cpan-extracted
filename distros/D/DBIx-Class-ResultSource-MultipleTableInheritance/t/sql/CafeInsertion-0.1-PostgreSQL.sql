-- 
-- Created by SQL::Translator::Producer::PostgreSQL
-- Created on Mon Jul  8 18:59:40 2013
-- 
--
-- Table: _coffee.
--
DROP TABLE "_coffee" CASCADE;
CREATE TABLE "_coffee" (
  "id" serial NOT NULL,
  "flavor" text DEFAULT 'good' NOT NULL,
  PRIMARY KEY ("id")
);

--
-- Table: _sumatra.
--
DROP TABLE "_sumatra" CASCADE;
CREATE TABLE "_sumatra" (
  "id" integer NOT NULL,
  "aroma" text NOT NULL,
  PRIMARY KEY ("id")
);

--
-- Table: chair.
--
DROP TABLE "chair" CASCADE;
CREATE TABLE "chair" (
  "id" serial NOT NULL,
  "name" character varying(255) NOT NULL,
  PRIMARY KEY ("id")
);

--
-- Table: cream.
--
DROP TABLE "cream" CASCADE;
CREATE TABLE "cream" (
  "id" serial NOT NULL,
  "fat_free" boolean NOT NULL,
  PRIMARY KEY ("id")
);

--
-- Table: sugar.
--
DROP TABLE "sugar" CASCADE;
CREATE TABLE "sugar" (
  "id" serial NOT NULL,
  "sweetness" integer NOT NULL,
  PRIMARY KEY ("id")
);

--
-- View: "coffee"
--
DROP VIEW "coffee";
CREATE VIEW "coffee" ( "id", "flavor" ) AS
    SELECT _coffee.id, flavor FROM _coffee;

CREATE OR REPLACE FUNCTION coffee_insert
  (_flavor TEXT)
  RETURNS VOID AS $function$
  BEGIN
    INSERT INTO _coffee ( flavor) VALUES ( _flavor );
  END;
$function$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION coffee_update
  (_id INTEGER, _flavor TEXT)
  RETURNS VOID AS $function$
  BEGIN
    UPDATE _coffee SET flavor = _flavor WHERE ( id = _id );
  END;
$function$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION coffee_delete
  (_id INTEGER)
  RETURNS VOID AS $function$
  BEGIN
    DELETE FROM _coffee WHERE ( id = _id );
  END;
$function$ LANGUAGE plpgsql;


CREATE RULE _coffee_insert_rule AS
  ON INSERT TO coffee
  DO INSTEAD (
    SELECT coffee_insert(NEW.flavor)
  );


CREATE RULE _coffee_update_rule AS
  ON UPDATE TO coffee
  DO INSTEAD (
    SELECT coffee_update(OLD.id, NEW.flavor)
  );


CREATE RULE _coffee_delete_rule AS
  ON DELETE TO coffee
  DO INSTEAD (
    SELECT coffee_delete(OLD.id)
  );

;

--
-- View: "sumatra"
--
DROP VIEW "sumatra";
CREATE VIEW "sumatra" ( "id", "flavor", "sweetness", "fat_free", "aroma" ) AS
    SELECT _sumatra.id, flavor, sweetness, fat_free, aroma FROM _sumatra _sumatra  JOIN sugar sugar ON sugar.id = _sumatra.id  JOIN cream cream ON cream.id = _sumatra.id  JOIN coffee coffee ON coffee.id = _sumatra.id;

CREATE OR REPLACE FUNCTION sumatra_insert
  (_flavor TEXT, _sweetness INTEGER, _fat_free BOOLEAN, _aroma TEXT)
  RETURNS VOID AS $function$
  BEGIN
    INSERT INTO coffee ( flavor) VALUES ( _flavor );
    INSERT INTO _sumatra ( aroma, id) VALUES ( _aroma, currval('_coffee_id_seq') );
    INSERT INTO sugar ( id, sweetness) VALUES ( currval('_coffee_id_seq'), _sweetness );
    INSERT INTO cream ( fat_free, id) VALUES ( _fat_free, currval('_coffee_id_seq') );
  END;
$function$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION sumatra_update
  (_id INTEGER, _flavor TEXT, _sweetness INTEGER, _fat_free BOOLEAN, _aroma TEXT)
  RETURNS VOID AS $function$
  BEGIN
    UPDATE _sumatra SET aroma = _aroma WHERE ( id = _id );
    UPDATE sugar SET sweetness = _sweetness WHERE ( id = _id );
    UPDATE cream SET fat_free = _fat_free WHERE ( id = _id );
    UPDATE coffee SET flavor = _flavor WHERE ( id = _id );
  END;
$function$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION sumatra_delete
  (_id INTEGER)
  RETURNS VOID AS $function$
  BEGIN
    DELETE FROM _sumatra WHERE ( id = _id );
    DELETE FROM sugar WHERE ( id = _id );
    DELETE FROM cream WHERE ( id = _id );
    DELETE FROM coffee WHERE ( id = _id );
  END;
$function$ LANGUAGE plpgsql;


CREATE RULE _sumatra_insert_rule AS
  ON INSERT TO sumatra
  DO INSTEAD (
    SELECT sumatra_insert(NEW.flavor, NEW.sweetness, NEW.fat_free, NEW.aroma)
  );


CREATE RULE _sumatra_update_rule AS
  ON UPDATE TO sumatra
  DO INSTEAD (
    SELECT sumatra_update(OLD.id, NEW.flavor, NEW.sweetness, NEW.fat_free, NEW.aroma)
  );


CREATE RULE _sumatra_delete_rule AS
  ON DELETE TO sumatra
  DO INSTEAD (
    SELECT sumatra_delete(OLD.id)
  );

;

