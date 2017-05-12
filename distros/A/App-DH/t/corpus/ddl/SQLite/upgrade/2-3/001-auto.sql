-- Convert schema 'ddl/_source/deploy/2/001-auto.yml' to 'ddl/_source/deploy/3/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE kitten ADD COLUMN fluffiness int NOT NULL DEFAULT 5;

;

COMMIT;

