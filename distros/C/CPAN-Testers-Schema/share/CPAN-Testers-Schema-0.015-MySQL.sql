-- 
-- Created by SQL::Translator::Producer::MySQL
-- Created on Thu Jul  6 22:57:31 2017
-- 
SET foreign_key_checks=0;

DROP TABLE IF EXISTS `metabase_user`;

--
-- Table: `metabase_user`
--
CREATE TABLE `metabase_user` (
  `id` integer NOT NULL auto_increment,
  `resource` char(50) NOT NULL,
  `fullname` varchar(255) NOT NULL,
  `email` varchar(255) NULL,
  PRIMARY KEY (`id`),
  UNIQUE `metabase_user_resource` (`resource`)
);

DROP TABLE IF EXISTS `test_report`;

--
-- Table: `test_report`
--
CREATE TABLE `test_report` (
  `id` char(36) NOT NULL,
  `created` datetime NOT NULL,
  `report` JSON NOT NULL,
  PRIMARY KEY (`id`)
);

DROP TABLE IF EXISTS `uploads`;

--
-- Table: `uploads`
--
CREATE TABLE `uploads` (
  `uploadid` integer unsigned NOT NULL auto_increment,
  `type` varchar(255) NOT NULL,
  `author` varchar(255) NOT NULL,
  `dist` varchar(255) NOT NULL,
  `version` varchar(255) NOT NULL,
  `filename` varchar(255) NOT NULL,
  `released` bigint NOT NULL,
  PRIMARY KEY (`uploadid`)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `cpanstats`;

--
-- Table: `cpanstats`
--
CREATE TABLE `cpanstats` (
  `id` integer unsigned NOT NULL auto_increment,
  `guid` char(36) NOT NULL,
  `state` enum('pass', 'fail', 'unknown', 'na') NOT NULL,
  `postdate` mediumint unsigned NOT NULL,
  `tester` varchar(255) NOT NULL,
  `dist` varchar(255) NOT NULL,
  `version` varchar(255) NOT NULL,
  `platform` varchar(255) NOT NULL,
  `perl` varchar(255) NOT NULL,
  `osname` varchar(255) NOT NULL,
  `osvers` varchar(255) NOT NULL,
  `fulldate` varchar(32) NOT NULL,
  `type` tinyint unsigned NOT NULL,
  `uploadid` integer unsigned NOT NULL,
  INDEX `cpanstats_idx_uploadid` (`uploadid`),
  PRIMARY KEY (`id`),
  UNIQUE `cpanstats_guid` (`guid`),
  CONSTRAINT `cpanstats_fk_uploadid` FOREIGN KEY (`uploadid`) REFERENCES `uploads` (`uploadid`)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `ixlatest`;

--
-- Table: `ixlatest`
--
CREATE TABLE `ixlatest` (
  `dist` varchar(255) NOT NULL,
  `author` varchar(255) NOT NULL,
  `version` varchar(255) NOT NULL,
  `released` bigint NOT NULL,
  `oncpan` integer NOT NULL,
  `uploadid` integer unsigned NOT NULL,
  INDEX `ixlatest_idx_uploadid` (`uploadid`),
  PRIMARY KEY (`dist`, `author`),
  CONSTRAINT `ixlatest_fk_uploadid` FOREIGN KEY (`uploadid`) REFERENCES `uploads` (`uploadid`)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `release_data`;

--
-- Table: `release_data`
--
CREATE TABLE `release_data` (
  `dist` varchar(255) NOT NULL,
  `version` varchar(255) NOT NULL,
  `id` integer NOT NULL,
  `guid` char(36) NOT NULL,
  `oncpan` integer NOT NULL,
  `distmat` integer NOT NULL,
  `perlmat` integer NOT NULL,
  `patched` integer NOT NULL,
  `pass` integer NOT NULL,
  `fail` integer NOT NULL,
  `na` integer NOT NULL,
  `unknown` integer NOT NULL,
  `uploadid` integer unsigned NOT NULL,
  INDEX `release_data_idx_uploadid` (`uploadid`),
  PRIMARY KEY (`id`, `guid`),
  CONSTRAINT `release_data_fk_uploadid` FOREIGN KEY (`uploadid`) REFERENCES `uploads` (`uploadid`)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `release_summary`;

--
-- Table: `release_summary`
--
CREATE TABLE `release_summary` (
  `dist` varchar(255) NOT NULL,
  `version` varchar(255) NOT NULL,
  `id` integer NOT NULL,
  `guid` char(36) NOT NULL,
  `oncpan` integer NOT NULL,
  `distmat` integer NOT NULL,
  `perlmat` integer NOT NULL,
  `patched` integer NOT NULL,
  `pass` integer NOT NULL,
  `fail` integer NOT NULL,
  `na` integer NOT NULL,
  `unknown` integer NOT NULL,
  `uploadid` integer unsigned NOT NULL,
  INDEX `release_summary_idx_guid` (`guid`),
  INDEX `release_summary_idx_uploadid` (`uploadid`),
  CONSTRAINT `release_summary_fk_guid` FOREIGN KEY (`guid`) REFERENCES `cpanstats` (`guid`),
  CONSTRAINT `release_summary_fk_uploadid` FOREIGN KEY (`uploadid`) REFERENCES `uploads` (`uploadid`)
) ENGINE=InnoDB;

SET foreign_key_checks=1;

