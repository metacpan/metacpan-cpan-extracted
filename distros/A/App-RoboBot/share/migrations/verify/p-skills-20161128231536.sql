-- Verify robobot:p-skills-20161128231536 on pg

BEGIN;

SELECT 1/COUNT(*)
  FROM robobot.skills_levels;

ROLLBACK;
