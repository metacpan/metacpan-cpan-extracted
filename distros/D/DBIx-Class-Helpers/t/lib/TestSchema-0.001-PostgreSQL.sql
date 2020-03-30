-- 
-- Created by SQL::Translator::Producer::PostgreSQL
-- Created on Sat Mar 28 14:16:41 2020
-- 
--
-- Table: Bloaty
--
DROP TABLE "Bloaty" CASCADE;
CREATE TABLE "Bloaty" (
  "id" integer NOT NULL,
  "name" character varying NOT NULL,
  "literature" text,
  "your_mom" bytea,
  PRIMARY KEY ("id")
);

--
-- Table: Gnarly
--
DROP TABLE "Gnarly" CASCADE;
CREATE TABLE "Gnarly" (
  "id" integer NOT NULL,
  "name" character varying NOT NULL,
  "literature" text,
  "your_mom" bytea,
  PRIMARY KEY ("id")
);

--
-- Table: HasAccessor
--
DROP TABLE "HasAccessor" CASCADE;
CREATE TABLE "HasAccessor" (
  "id" integer NOT NULL,
  "usable_column" character varying NOT NULL,
  "unusable_column" character varying NOT NULL,
  PRIMARY KEY ("id")
);

--
-- Table: HasDateOps
--
DROP TABLE "HasDateOps" CASCADE;
CREATE TABLE "HasDateOps" (
  "id" integer NOT NULL,
  "a_date" timestamp NOT NULL,
  "b_date" timestamp,
  PRIMARY KEY ("id")
);

--
-- Table: Search
--
DROP TABLE "Search" CASCADE;
CREATE TABLE "Search" (
  "id" integer NOT NULL,
  "name" character varying NOT NULL,
  PRIMARY KEY ("id")
);

--
-- Table: SerializeAll
--
DROP TABLE "SerializeAll" CASCADE;
CREATE TABLE "SerializeAll" (
  "id" integer NOT NULL,
  "text_column" text NOT NULL,
  PRIMARY KEY ("id")
);

--
-- Table: Station
--
DROP TABLE "Station" CASCADE;
CREATE TABLE "Station" (
  "id" integer NOT NULL,
  "name" character varying NOT NULL,
  PRIMARY KEY ("id")
);

--
-- Table: Bar
--
DROP TABLE "Bar" CASCADE;
CREATE TABLE "Bar" (
  "id" bigint NOT NULL,
  "foo_id" integer NOT NULL,
  "test_flag" integer,
  PRIMARY KEY ("id")
);
CREATE INDEX "Bar_idx_foo_id" on "Bar" ("foo_id");

--
-- Table: Foo
--
DROP TABLE "Foo" CASCADE;
CREATE TABLE "Foo" (
  "id" integer NOT NULL,
  "bar_id" integer NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "Foo_idx_bar_id" on "Foo" ("bar_id");

--
-- Table: Foo_Bar
--
DROP TABLE "Foo_Bar" CASCADE;
CREATE TABLE "Foo_Bar" (
  "foo_id" integer NOT NULL,
  "bar_id" bigint NOT NULL,
  PRIMARY KEY ("foo_id", "bar_id")
);
CREATE INDEX "Foo_Bar_idx_bar_id" on "Foo_Bar" ("bar_id");
CREATE INDEX "Foo_Bar_idx_foo_id" on "Foo_Bar" ("foo_id");

--
-- Table: Gnarly_Station
--
DROP TABLE "Gnarly_Station" CASCADE;
CREATE TABLE "Gnarly_Station" (
  "gnarly_id" integer NOT NULL,
  "station_id" integer NOT NULL,
  PRIMARY KEY ("gnarly_id", "station_id")
);
CREATE INDEX "Gnarly_Station_idx_gnarly_id" on "Gnarly_Station" ("gnarly_id");
CREATE INDEX "Gnarly_Station_idx_station_id" on "Gnarly_Station" ("station_id");

--
-- Foreign Key Definitions
--

ALTER TABLE "Bar" ADD CONSTRAINT "Bar_fk_foo_id" FOREIGN KEY ("foo_id")
  REFERENCES "Foo" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "Foo_Bar" ADD CONSTRAINT "Foo_Bar_fk_bar_id" FOREIGN KEY ("bar_id")
  REFERENCES "Bar" ("id") DEFERRABLE;

ALTER TABLE "Foo_Bar" ADD CONSTRAINT "Foo_Bar_fk_foo_id" FOREIGN KEY ("foo_id")
  REFERENCES "Foo" ("id") DEFERRABLE;

ALTER TABLE "Gnarly_Station" ADD CONSTRAINT "Gnarly_Station_fk_gnarly_id" FOREIGN KEY ("gnarly_id")
  REFERENCES "Gnarly" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "Gnarly_Station" ADD CONSTRAINT "Gnarly_Station_fk_station_id" FOREIGN KEY ("station_id")
  REFERENCES "Station" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

