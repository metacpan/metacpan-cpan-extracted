-- Convert schema '/Users/doug/perl/cpantesters/src/cpantesters-schema/share/CPAN-Testers-Schema-0.024-SQLite.sql' to '/Users/doug/perl/cpantesters/src/cpantesters-schema/share/CPAN-Testers-Schema-0.027-SQLite.sql':;

BEGIN;

CREATE UNIQUE INDEX "dist_version02" ON "uploads" ("dist", "version");


COMMIT;

