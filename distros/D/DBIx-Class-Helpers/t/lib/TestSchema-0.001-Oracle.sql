-- 
-- Created by SQL::Translator::Producer::Oracle
-- Created on Sun Dec 29 06:57:57 2019
-- 
--
-- Table: Bloaty
--;

DROP TABLE "Bloaty" CASCADE CONSTRAINTS;

CREATE TABLE "Bloaty" (
  "id" number NOT NULL,
  "name" varchar2(4000) NOT NULL,
  "literature" clob,
  "your_mom" blob,
  PRIMARY KEY ("id")
);

--
-- Table: Gnarly
--;

DROP TABLE "Gnarly" CASCADE CONSTRAINTS;

CREATE TABLE "Gnarly" (
  "id" number NOT NULL,
  "name" varchar2(4000) NOT NULL,
  "literature" clob,
  "your_mom" blob,
  PRIMARY KEY ("id")
);

--
-- Table: HasAccessor
--;

DROP TABLE "HasAccessor" CASCADE CONSTRAINTS;

CREATE TABLE "HasAccessor" (
  "id" number NOT NULL,
  "usable_column" varchar2(4000) NOT NULL,
  "unusable_column" varchar2(4000) NOT NULL,
  PRIMARY KEY ("id")
);

--
-- Table: HasDateOps
--;

DROP TABLE "HasDateOps" CASCADE CONSTRAINTS;

CREATE TABLE "HasDateOps" (
  "id" number NOT NULL,
  "a_date" date NOT NULL,
  "b_date" date,
  PRIMARY KEY ("id")
);

--
-- Table: Search
--;

DROP TABLE "Search" CASCADE CONSTRAINTS;

CREATE TABLE "Search" (
  "id" number NOT NULL,
  "name" varchar2(4000) NOT NULL,
  PRIMARY KEY ("id")
);

--
-- Table: SerializeAll
--;

DROP TABLE "SerializeAll" CASCADE CONSTRAINTS;

CREATE TABLE "SerializeAll" (
  "id" number NOT NULL,
  "text_column" clob NOT NULL,
  PRIMARY KEY ("id")
);

--
-- Table: Station
--;

DROP TABLE "Station" CASCADE CONSTRAINTS;

CREATE TABLE "Station" (
  "id" number NOT NULL,
  "name" varchar2(4000) NOT NULL,
  PRIMARY KEY ("id")
);

--
-- Table: Bar
--;

DROP TABLE "Bar" CASCADE CONSTRAINTS;

CREATE TABLE "Bar" (
  "id" number(12) NOT NULL,
  "foo_id" number NOT NULL,
  "test_flag" number,
  PRIMARY KEY ("id")
);

--
-- Table: Foo
--;

DROP TABLE "Foo" CASCADE CONSTRAINTS;

CREATE TABLE "Foo" (
  "id" number NOT NULL,
  "bar_id" number NOT NULL,
  PRIMARY KEY ("id")
);

--
-- Table: Foo_Bar
--;

DROP TABLE "Foo_Bar" CASCADE CONSTRAINTS;

CREATE TABLE "Foo_Bar" (
  "foo_id" number NOT NULL,
  "bar_id" number(12) NOT NULL,
  PRIMARY KEY ("foo_id", "bar_id")
);

--
-- Table: Gnarly_Station
--;

DROP TABLE "Gnarly_Station" CASCADE CONSTRAINTS;

CREATE TABLE "Gnarly_Station" (
  "gnarly_id" number NOT NULL,
  "station_id" number NOT NULL,
  PRIMARY KEY ("gnarly_id", "station_id")
);

ALTER TABLE "Bar" ADD CONSTRAINT "Bar_foo_id_fk" FOREIGN KEY ("foo_id") REFERENCES "Foo" ("id") ON DELETE CASCADE;

ALTER TABLE "Foo_Bar" ADD CONSTRAINT "Foo_Bar_bar_id_fk" FOREIGN KEY ("bar_id") REFERENCES "Bar" ("id");

ALTER TABLE "Foo_Bar" ADD CONSTRAINT "Foo_Bar_foo_id_fk" FOREIGN KEY ("foo_id") REFERENCES "Foo" ("id");

ALTER TABLE "Gnarly_Station" ADD CONSTRAINT "Gnarly_Station_gnarly_id_fk" FOREIGN KEY ("gnarly_id") REFERENCES "Gnarly" ("id") ON DELETE CASCADE;

ALTER TABLE "Gnarly_Station" ADD CONSTRAINT "Gnarly_Station_station_id_fk" FOREIGN KEY ("station_id") REFERENCES "Station" ("id") ON DELETE CASCADE;

CREATE INDEX "Bar_idx_foo_id" on "Bar" ("foo_id");

CREATE INDEX "Foo_idx_bar_id" on "Foo" ("bar_id");

CREATE INDEX "Foo_Bar_idx_bar_id" on "Foo_Bar" ("bar_id");

CREATE INDEX "Foo_Bar_idx_foo_id" on "Foo_Bar" ("foo_id");

CREATE INDEX "Gnarly_Station_idx_gnarly_id" on "Gnarly_Station" ("gnarly_id");

CREATE INDEX "Gnarly_Station_idx_station_id" on "Gnarly_Station" ("station_id");

