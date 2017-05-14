-- Convert schema '/Users/doug/perl/cpantesters/schema/share/CPAN-Testers-Schema-0.001-MySQL.sql' to 'CPAN::Testers::Schema v0.006':;

BEGIN;

SET foreign_key_checks=0;

CREATE TABLE `test_report` (
  `id` char(36) NOT NULL,
  `report` JSON NOT NULL,
  PRIMARY KEY (`id`)
);

SET foreign_key_checks=1;


COMMIT;

