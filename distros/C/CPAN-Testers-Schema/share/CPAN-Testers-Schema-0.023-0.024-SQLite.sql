-- Convert schema '/Users/doug/perl/cpantesters/schema/share/CPAN-Testers-Schema-0.023-SQLite.sql' to '/Users/doug/perl/cpantesters/schema/share/CPAN-Testers-Schema-0.024-SQLite.sql':;

BEGIN;

CREATE INDEX "cpanstats_idx_perl02" ON "cpanstats" ("perl");



COMMIT;

