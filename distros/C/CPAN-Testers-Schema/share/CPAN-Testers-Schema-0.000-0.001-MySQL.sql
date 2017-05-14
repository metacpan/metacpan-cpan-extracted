-- 
-- Created by SQL::Translator::Producer::MySQL
-- Created on Thu May 11 15:06:58 2017
-- 
SET foreign_key_checks=0;

--
-- Table: `uploads`
--
CREATE TABLE IF NOT EXISTS `uploads` (
  `uploadid` integer unsigned NOT NULL auto_increment,
  `type` varchar(255) NOT NULL,
  `author` varchar(255) NOT NULL,
  `dist` varchar(255) NOT NULL,
  `version` varchar(255) NOT NULL,
  `filename` varchar(255) NOT NULL,
  `released` bigint NOT NULL,
  PRIMARY KEY (`uploadid`)
) ENGINE=InnoDB;

--
-- Table: `cpanstats`
--
CREATE TABLE IF NOT EXISTS `cpanstats` (
  `id` integer unsigned NOT NULL auto_increment,
  `guid` char(36) NOT NULL,
  `state` enum('pass', 'fail', 'unknown', 'na') NOT NULL,
  `postdate` mediumint unsigned NOT NULL,
  `tester` varchar(100) NOT NULL,
  `dist` varchar(100) NOT NULL,
  `version` varchar(20) NOT NULL,
  `platform` varchar(20) NOT NULL,
  `perl` varchar(10) NOT NULL,
  `osname` varchar(20) NOT NULL,
  `osvers` varchar(20) NOT NULL,
  `fulldate` char(8) NOT NULL,
  `type` tinyint unsigned NOT NULL,
  `uploadid` integer unsigned NOT NULL,
  INDEX `cpanstats_idx_uploadid` (`uploadid`),
  PRIMARY KEY (`id`),
  UNIQUE KEY (`guid`),
  CONSTRAINT `cpanstats_fk_uploadid` FOREIGN KEY (`uploadid`) REFERENCES `uploads` (`uploadid`)
) ENGINE=InnoDB;

--
-- Table: `ixlatest`
--
CREATE TABLE IF NOT EXISTS `ixlatest` (
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

--
-- Table: `release_data`
--
CREATE TABLE IF NOT EXISTS `release_data` (
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

--
-- Table: `release_summary`
--
CREATE TABLE IF NOT EXISTS `release_summary` (
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

