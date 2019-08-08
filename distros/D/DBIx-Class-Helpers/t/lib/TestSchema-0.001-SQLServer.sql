-- 
-- Created by SQL::Translator::Generator::Role::DDL
-- Created on Fri Aug  2 10:45:06 2019
-- 

--
-- Turn off constraints
--

IF EXISTS (SELECT name FROM sysobjects WHERE name = 'HasDateOps' AND type = 'U') ALTER TABLE [HasDateOps] NOCHECK CONSTRAINT all;
IF EXISTS (SELECT name FROM sysobjects WHERE name = 'Gnarly' AND type = 'U') ALTER TABLE [Gnarly] NOCHECK CONSTRAINT all;
--
-- Drop tables
--

IF EXISTS (SELECT name FROM sysobjects WHERE name = 'HasDateOps' AND type = 'U') DROP TABLE [HasDateOps];
IF EXISTS (SELECT name FROM sysobjects WHERE name = 'Gnarly' AND type = 'U') DROP TABLE [Gnarly];
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
-- Table: [HasDateOps]
--
CREATE TABLE [HasDateOps] (
  [id] int NOT NULL,
  [a_date] datetime NOT NULL,
  [b_date] datetime NULL,
  CONSTRAINT [HasDateOps_pk] PRIMARY KEY ([id])
);
