-- Convert schema '/Users/doug/perl/cpantesters/schema/share/CPAN-Testers-Schema-0.023-MySQL.sql' to 'CPAN::Testers::Schema v0.024':;

BEGIN;

ALTER TABLE cpanstats ADD INDEX cpanstats_idx_perl (perl),
                      ADD CONSTRAINT cpanstats_fk_perl FOREIGN KEY (perl) REFERENCES perl_version (version);

ALTER TABLE perl_version ENGINE=InnoDB;


COMMIT;

