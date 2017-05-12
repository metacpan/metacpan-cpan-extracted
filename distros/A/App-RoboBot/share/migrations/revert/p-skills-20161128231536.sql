-- Revert robobot:p-skills-20161128231536 from pg

BEGIN;

DELETE FROM robobot.skills_levels
      WHERE name IN ('Plebe','Novice','Intermediate','Advanced','Expert','Creator','Thoughtlord');

COMMIT;
