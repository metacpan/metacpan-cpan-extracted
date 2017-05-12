-- 
-- Created by SQL::Translator::Producer::SQLite
-- Created on Tue Aug  8 01:53:20 2006
-- 
BEGIN TRANSACTION;

CREATE TABLE FactA 
(
    fact_id             INTEGER PRIMARY KEY NOT NULL,
    date_id             INTEGER NOT NULL,
    time_id             INTEGER NOT NULL,
    fact                TEXT NOT NULL
);

CREATE TABLE DimDate
(
    date_id             INTEGER PRIMARY KEY NOT NULL,
    day_of_week         INTEGER NOT NULL,
    day_of_month        INTEGER NOT NULL,
    day_of_year         INTEGER NOT NULL
);

CREATE TABLE DimTime
(
    time_id             INTEGER PRIMARY KEY NOT NULL,
    hour                INTEGER NOT NULL,
    minute              INTEGER NOT NULL
);

CREATE TABLE FactB
(
    fact_id             INTEGER PRIMARY KEY NOT NULL,
    city_id             INTEGER NOT NULL,
    date_id             INTEGER NOT NULL
);

CREATE TABLE DimCity
(
    city_id             INTEGER PRIMARY KEY NOT NULL,
    region_id           INTEGER NOT NULL,
    city                TEXT
);


CREATE TABLE DimRegion
(
    region_id           INTEGER PRIMARY KEY NOT NULL,
    country_id          INTEGER NOT NULL,
    region              TEXT
);

CREATE TABLE DimCountry
(
    country_id          INTEGER PRIMARY KEY NOT NULL,
    country             TEXT
);

COMMIT;
