-- Revert robobot:p-skills-20161128215019 from pg

BEGIN;

DROP TABLE robobot.skills_nicks;
DROP TABLE robobot.skills_related;
DROP TABLE robobot.skills_levels;
DROP TABLE robobot.skills_skills;

COMMIT;
