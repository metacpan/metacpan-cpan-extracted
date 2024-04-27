-- Convert schema '/Users/doug/perl/cpantesters/src/cpantesters-schema/share/CPAN-Testers-Schema-0.024-MySQL.sql' to 'CPAN::Testers::Schema v0.027':;

BEGIN;

ALTER TABLE uploads ADD UNIQUE dist_version (dist, version);


COMMIT;

