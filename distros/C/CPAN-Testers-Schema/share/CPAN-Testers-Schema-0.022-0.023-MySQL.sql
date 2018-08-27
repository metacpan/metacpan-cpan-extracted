-- Convert schema '/Users/doug/perl/cpantesters/schema/share/CPAN-Testers-Schema-0.022-MySQL.sql' to 'CPAN::Testers::Schema v0.023':;

BEGIN;

SET foreign_key_checks=0;

CREATE TABLE IF NOT EXISTS `perl_version` (
  `version` varchar(255) NOT NULL,
  `perl` varchar(32) NULL,
  `patch` tinyint(1) NOT NULL DEFAULT 0,
  `devel` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`version`)
);

SET foreign_key_checks=1;


COMMIT;

