-- Convert schema '/Users/doug/perl/cpantesters/schema/share/CPAN-Testers-Schema-0.022-SQLite.sql' to '/Users/doug/perl/cpantesters/schema/share/CPAN-Testers-Schema-0.023-SQLite.sql':;

BEGIN;

CREATE TABLE "perl_version" (
  "version" varchar(255) NOT NULL,
  "perl" varchar(32),
  "patch" tinyint(1) NOT NULL DEFAULT 0,
  "devel" tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY ("version")
);


COMMIT;

