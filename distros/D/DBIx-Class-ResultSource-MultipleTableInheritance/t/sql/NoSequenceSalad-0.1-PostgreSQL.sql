-- 
-- Created by SQL::Translator::Producer::PostgreSQL
-- Created on Mon Jul  8 18:59:40 2013
-- 
--
-- Table: _mesclun.
--
DROP TABLE "_mesclun" CASCADE;
CREATE TABLE "_mesclun" (
  "id" integer NOT NULL,
  "spiciness" integer NOT NULL,
  PRIMARY KEY ("id")
);

--
-- Table: _salad.
--
DROP TABLE "_salad" CASCADE;
CREATE TABLE "_salad" (
  "id" serial NOT NULL,
  "fresh" boolean NOT NULL,
  PRIMARY KEY ("id")
);

--
-- Table: dressing.
--
DROP TABLE "dressing" CASCADE;
CREATE TABLE "dressing" (
  "id" serial NOT NULL,
  "acidity" integer NOT NULL,
  PRIMARY KEY ("id")
);

--
-- View: "salad"
--
DROP VIEW "salad";
CREATE VIEW "salad" ( "id", "fresh" ) AS
    SELECT _salad.id, fresh FROM _salad;

CREATE OR REPLACE FUNCTION salad_insert
  (_fresh BOOLEAN)
  RETURNS VOID AS $function$
  BEGIN
    INSERT INTO _salad ( fresh) VALUES ( _fresh );
  END;
$function$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION salad_update
  (_id INTEGER, _fresh BOOLEAN)
  RETURNS VOID AS $function$
  BEGIN
    UPDATE _salad SET fresh = _fresh WHERE ( id = _id );
  END;
$function$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION salad_delete
  (_id INTEGER)
  RETURNS VOID AS $function$
  BEGIN
    DELETE FROM _salad WHERE ( id = _id );
  END;
$function$ LANGUAGE plpgsql;


CREATE RULE _salad_insert_rule AS
  ON INSERT TO salad
  DO INSTEAD (
    SELECT salad_insert(NEW.fresh)
  );


CREATE RULE _salad_update_rule AS
  ON UPDATE TO salad
  DO INSTEAD (
    SELECT salad_update(OLD.id, NEW.fresh)
  );


CREATE RULE _salad_delete_rule AS
  ON DELETE TO salad
  DO INSTEAD (
    SELECT salad_delete(OLD.id)
  );

;

--
-- View: "mesclun"
--
DROP VIEW "mesclun";
CREATE VIEW "mesclun" ( "id", "fresh", "acidity", "spiciness" ) AS
    SELECT _mesclun.id, fresh, acidity, spiciness FROM _mesclun _mesclun  JOIN dressing dressing ON dressing.id = _mesclun.id  JOIN salad salad ON salad.id = _mesclun.id;

CREATE OR REPLACE FUNCTION mesclun_insert
  (_fresh BOOLEAN, _acidity INTEGER, _spiciness INTEGER)
  RETURNS VOID AS $function$
  BEGIN
    INSERT INTO salad ( fresh) VALUES ( _fresh );
    INSERT INTO _mesclun ( id, spiciness) VALUES ( currval('_salad_id_seq'), _spiciness );
    INSERT INTO dressing ( acidity, id) VALUES ( _acidity, currval('_salad_id_seq') );
  END;
$function$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION mesclun_update
  (_id INTEGER, _fresh BOOLEAN, _acidity INTEGER, _spiciness INTEGER)
  RETURNS VOID AS $function$
  BEGIN
    UPDATE _mesclun SET spiciness = _spiciness WHERE ( id = _id );
    UPDATE dressing SET acidity = _acidity WHERE ( id = _id );
    UPDATE salad SET fresh = _fresh WHERE ( id = _id );
  END;
$function$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION mesclun_delete
  (_id INTEGER)
  RETURNS VOID AS $function$
  BEGIN
    DELETE FROM _mesclun WHERE ( id = _id );
    DELETE FROM dressing WHERE ( id = _id );
    DELETE FROM salad WHERE ( id = _id );
  END;
$function$ LANGUAGE plpgsql;


CREATE RULE _mesclun_insert_rule AS
  ON INSERT TO mesclun
  DO INSTEAD (
    SELECT mesclun_insert(NEW.fresh, NEW.acidity, NEW.spiciness)
  );


CREATE RULE _mesclun_update_rule AS
  ON UPDATE TO mesclun
  DO INSTEAD (
    SELECT mesclun_update(OLD.id, NEW.fresh, NEW.acidity, NEW.spiciness)
  );


CREATE RULE _mesclun_delete_rule AS
  ON DELETE TO mesclun
  DO INSTEAD (
    SELECT mesclun_delete(OLD.id)
  );

;

