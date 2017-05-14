-- Convert schema '/Users/doug/perl/cpantesters/schema/share/CPAN-Testers-Schema-0.007-MySQL.sql' to 'CPAN::Testers::Schema v0.008':;

BEGIN;

ALTER TABLE metabase_user DROP INDEX ix_resource,
                          ADD UNIQUE metabase_user_resource (resource);


COMMIT;

