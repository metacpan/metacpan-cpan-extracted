-- Convert schema '/Users/doug/perl/cpantesters/schema/share/CPAN-Testers-Schema-0.006-MySQL.sql' to 'CPAN::Testers::Schema v0.007':;

BEGIN;

SET foreign_key_checks=0;

CREATE TABLE `metabase_user` (
  `id` integer NOT NULL auto_increment,
  `resource` CHAR(50) NOT NULL,
  `fullname` varchar(255) NOT NULL,
  `email` varchar(255) NULL,
  INDEX `ix_resource` (`resource`),
  PRIMARY KEY (`id`)
);

SET foreign_key_checks=1;

ALTER TABLE test_report ADD COLUMN created datetime NOT NULL;


COMMIT;

