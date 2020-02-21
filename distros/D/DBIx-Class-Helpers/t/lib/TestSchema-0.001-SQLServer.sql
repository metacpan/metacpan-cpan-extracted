-- 
-- Created by SQL::Translator::Generator::Role::DDL
-- Created on Fri Feb 21 08:38:44 2020
-- 

--
-- Turn off constraints
--

IF EXISTS (SELECT name FROM sysobjects WHERE name = 'Gnarly_Station' AND type = 'U') ALTER TABLE [Gnarly_Station] NOCHECK CONSTRAINT all;
IF EXISTS (SELECT name FROM sysobjects WHERE name = 'Foo_Bar' AND type = 'U') ALTER TABLE [Foo_Bar] NOCHECK CONSTRAINT all;
IF EXISTS (SELECT name FROM sysobjects WHERE name = 'Foo' AND type = 'U') ALTER TABLE [Foo] NOCHECK CONSTRAINT all;
IF EXISTS (SELECT name FROM sysobjects WHERE name = 'Bar' AND type = 'U') ALTER TABLE [Bar] NOCHECK CONSTRAINT all;
IF EXISTS (SELECT name FROM sysobjects WHERE name = 'Station' AND type = 'U') ALTER TABLE [Station] NOCHECK CONSTRAINT all;
IF EXISTS (SELECT name FROM sysobjects WHERE name = 'SerializeAll' AND type = 'U') ALTER TABLE [SerializeAll] NOCHECK CONSTRAINT all;
IF EXISTS (SELECT name FROM sysobjects WHERE name = 'Search' AND type = 'U') ALTER TABLE [Search] NOCHECK CONSTRAINT all;
IF EXISTS (SELECT name FROM sysobjects WHERE name = 'HasDateOps' AND type = 'U') ALTER TABLE [HasDateOps] NOCHECK CONSTRAINT all;
IF EXISTS (SELECT name FROM sysobjects WHERE name = 'HasAccessor' AND type = 'U') ALTER TABLE [HasAccessor] NOCHECK CONSTRAINT all;
IF EXISTS (SELECT name FROM sysobjects WHERE name = 'Gnarly' AND type = 'U') ALTER TABLE [Gnarly] NOCHECK CONSTRAINT all;
IF EXISTS (SELECT name FROM sysobjects WHERE name = 'Bloaty' AND type = 'U') ALTER TABLE [Bloaty] NOCHECK CONSTRAINT all;
--
-- Drop tables
--

IF EXISTS (SELECT name FROM sysobjects WHERE name = 'Gnarly_Station' AND type = 'U') DROP TABLE [Gnarly_Station];
IF EXISTS (SELECT name FROM sysobjects WHERE name = 'Foo_Bar' AND type = 'U') DROP TABLE [Foo_Bar];
IF EXISTS (SELECT name FROM sysobjects WHERE name = 'Foo' AND type = 'U') DROP TABLE [Foo];
IF EXISTS (SELECT name FROM sysobjects WHERE name = 'Bar' AND type = 'U') DROP TABLE [Bar];
IF EXISTS (SELECT name FROM sysobjects WHERE name = 'Station' AND type = 'U') DROP TABLE [Station];
IF EXISTS (SELECT name FROM sysobjects WHERE name = 'SerializeAll' AND type = 'U') DROP TABLE [SerializeAll];
IF EXISTS (SELECT name FROM sysobjects WHERE name = 'Search' AND type = 'U') DROP TABLE [Search];
IF EXISTS (SELECT name FROM sysobjects WHERE name = 'HasDateOps' AND type = 'U') DROP TABLE [HasDateOps];
IF EXISTS (SELECT name FROM sysobjects WHERE name = 'HasAccessor' AND type = 'U') DROP TABLE [HasAccessor];
IF EXISTS (SELECT name FROM sysobjects WHERE name = 'Gnarly' AND type = 'U') DROP TABLE [Gnarly];
IF EXISTS (SELECT name FROM sysobjects WHERE name = 'Bloaty' AND type = 'U') DROP TABLE [Bloaty];
--
-- Table: [Bloaty]
--
CREATE TABLE [Bloaty] (
  [id] int NOT NULL,
  [name] varchar NOT NULL,
  [literature] text NULL,
  [your_mom] blob NULL,
  CONSTRAINT [Bloaty_pk] PRIMARY KEY ([id])
);


--
-- Table: [Gnarly]
--
CREATE TABLE [Gnarly] (
  [id] int NOT NULL,
  [name] varchar NOT NULL,
  [literature] text NULL,
  [your_mom] blob NULL,
  CONSTRAINT [Gnarly_pk] PRIMARY KEY ([id])
);


--
-- Table: [HasAccessor]
--
CREATE TABLE [HasAccessor] (
  [id] int NOT NULL,
  [usable_column] varchar NOT NULL,
  [unusable_column] varchar NOT NULL,
  CONSTRAINT [HasAccessor_pk] PRIMARY KEY ([id])
);


--
-- Table: [HasDateOps]
--
CREATE TABLE [HasDateOps] (
  [id] int NOT NULL,
  [a_date] datetime NOT NULL,
  [b_date] datetime NULL,
  CONSTRAINT [HasDateOps_pk] PRIMARY KEY ([id])
);


--
-- Table: [Search]
--
CREATE TABLE [Search] (
  [id] int NOT NULL,
  [name] varchar NOT NULL,
  CONSTRAINT [Search_pk] PRIMARY KEY ([id])
);


--
-- Table: [SerializeAll]
--
CREATE TABLE [SerializeAll] (
  [id] int NOT NULL,
  [text_column] text NOT NULL,
  CONSTRAINT [SerializeAll_pk] PRIMARY KEY ([id])
);


--
-- Table: [Station]
--
CREATE TABLE [Station] (
  [id] int NOT NULL,
  [name] varchar NOT NULL,
  CONSTRAINT [Station_pk] PRIMARY KEY ([id])
);


--
-- Table: [Bar]
--
CREATE TABLE [Bar] (
  [id] integer NOT NULL,
  [foo_id] integer NOT NULL,
  [test_flag] integer NULL,
  CONSTRAINT [Bar_pk] PRIMARY KEY ([id])
);

CREATE INDEX [Bar_idx_foo_id] ON [Bar] ([foo_id]);


--
-- Table: [Foo]
--
CREATE TABLE [Foo] (
  [id] integer NOT NULL,
  [bar_id] integer NOT NULL,
  CONSTRAINT [Foo_pk] PRIMARY KEY ([id])
);

CREATE INDEX [Foo_idx_bar_id] ON [Foo] ([bar_id]);


--
-- Table: [Foo_Bar]
--
CREATE TABLE [Foo_Bar] (
  [foo_id] integer NOT NULL,
  [bar_id] integer NOT NULL,
  CONSTRAINT [Foo_Bar_pk] PRIMARY KEY ([foo_id], [bar_id])
);

CREATE INDEX [Foo_Bar_idx_bar_id] ON [Foo_Bar] ([bar_id]);

CREATE INDEX [Foo_Bar_idx_foo_id] ON [Foo_Bar] ([foo_id]);


--
-- Table: [Gnarly_Station]
--
CREATE TABLE [Gnarly_Station] (
  [gnarly_id] int NOT NULL,
  [station_id] int NOT NULL,
  CONSTRAINT [Gnarly_Station_pk] PRIMARY KEY ([gnarly_id], [station_id])
);

CREATE INDEX [Gnarly_Station_idx_gnarly_id] ON [Gnarly_Station] ([gnarly_id]);

CREATE INDEX [Gnarly_Station_idx_station_id] ON [Gnarly_Station] ([station_id]);
ALTER TABLE [Bar] ADD CONSTRAINT [Bar_fk_foo_id] FOREIGN KEY ([foo_id]) REFERENCES [Foo] ([id]) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE [Foo_Bar] ADD CONSTRAINT [Foo_Bar_fk_bar_id] FOREIGN KEY ([bar_id]) REFERENCES [Bar] ([id]);
ALTER TABLE [Foo_Bar] ADD CONSTRAINT [Foo_Bar_fk_foo_id] FOREIGN KEY ([foo_id]) REFERENCES [Foo] ([id]);
ALTER TABLE [Gnarly_Station] ADD CONSTRAINT [Gnarly_Station_fk_gnarly_id] FOREIGN KEY ([gnarly_id]) REFERENCES [Gnarly] ([id]) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE [Gnarly_Station] ADD CONSTRAINT [Gnarly_Station_fk_station_id] FOREIGN KEY ([station_id]) REFERENCES [Station] ([id]) ON DELETE CASCADE ON UPDATE CASCADE;