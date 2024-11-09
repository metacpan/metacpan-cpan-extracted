--
-- Created by SQL::Translator::Producer::MySQL
-- Created on Fri Nov  8 09:31:51 2024
--
SET foreign_key_checks=0;

DROP TABLE IF EXISTS `Bloaty`;

--
-- Table: `Bloaty`
--
CREATE TABLE `Bloaty` (
  `id` integer NOT NULL,
  `name` varchar(255) NOT NULL,
  `literature` text NULL,
  `your_mom` blob NULL,
  PRIMARY KEY (`id`)
);

DROP TABLE IF EXISTS `Gnarly`;

--
-- Table: `Gnarly`
--
CREATE TABLE `Gnarly` (
  `id` integer NOT NULL,
  `name` varchar(255) NOT NULL,
  `literature` text NULL,
  `your_mom` blob NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `HasAccessor`;

--
-- Table: `HasAccessor`
--
CREATE TABLE `HasAccessor` (
  `id` integer NOT NULL,
  `usable_column` varchar(255) NOT NULL,
  `unusable_column` varchar(255) NOT NULL,
  PRIMARY KEY (`id`)
);

DROP TABLE IF EXISTS `HasDateOps`;

--
-- Table: `HasDateOps`
--
CREATE TABLE `HasDateOps` (
  `id` integer NOT NULL,
  `a_date` datetime NOT NULL,
  `b_date` datetime NULL,
  PRIMARY KEY (`id`)
);

DROP TABLE IF EXISTS `Search`;

--
-- Table: `Search`
--
CREATE TABLE `Search` (
  `id` integer NOT NULL,
  `name` varchar(255) NOT NULL,
  PRIMARY KEY (`id`)
);

DROP TABLE IF EXISTS `SerializeAll`;

--
-- Table: `SerializeAll`
--
CREATE TABLE `SerializeAll` (
  `id` integer NOT NULL,
  `text_column` text NOT NULL,
  PRIMARY KEY (`id`)
);

DROP TABLE IF EXISTS `Station`;

--
-- Table: `Station`
--
CREATE TABLE `Station` (
  `id` integer NOT NULL,
  `name` varchar(255) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `Bar`;

--
-- Table: `Bar`
--
CREATE TABLE `Bar` (
  `id` integer(12) NOT NULL,
  `foo_id` integer NOT NULL,
  `test_flag` integer NULL,
  INDEX `Bar_idx_foo_id` (`foo_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `Bar_fk_foo_id` FOREIGN KEY (`foo_id`) REFERENCES `Foo` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `Foo`;

--
-- Table: `Foo`
--
CREATE TABLE `Foo` (
  `id` integer NOT NULL,
  `bar_id` integer NOT NULL,
  INDEX `Foo_idx_bar_id` (`bar_id`),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `Foo_Bar`;

--
-- Table: `Foo_Bar`
--
CREATE TABLE `Foo_Bar` (
  `foo_id` integer NOT NULL,
  `bar_id` integer(12) NOT NULL,
  INDEX `Foo_Bar_idx_bar_id` (`bar_id`),
  INDEX `Foo_Bar_idx_foo_id` (`foo_id`),
  PRIMARY KEY (`foo_id`, `bar_id`),
  CONSTRAINT `Foo_Bar_fk_bar_id` FOREIGN KEY (`bar_id`) REFERENCES `Bar` (`id`),
  CONSTRAINT `Foo_Bar_fk_foo_id` FOREIGN KEY (`foo_id`) REFERENCES `Foo` (`id`)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `Gnarly_Station`;

--
-- Table: `Gnarly_Station`
--
CREATE TABLE `Gnarly_Station` (
  `gnarly_id` integer NOT NULL,
  `station_id` integer NOT NULL,
  INDEX `Gnarly_Station_idx_gnarly_id` (`gnarly_id`),
  INDEX `Gnarly_Station_idx_station_id` (`station_id`),
  PRIMARY KEY (`gnarly_id`, `station_id`),
  CONSTRAINT `Gnarly_Station_fk_gnarly_id` FOREIGN KEY (`gnarly_id`) REFERENCES `Gnarly` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `Gnarly_Station_fk_station_id` FOREIGN KEY (`station_id`) REFERENCES `Station` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

SET foreign_key_checks=1;

