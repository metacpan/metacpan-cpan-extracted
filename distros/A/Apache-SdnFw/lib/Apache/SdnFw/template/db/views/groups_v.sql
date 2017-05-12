CREATE VIEW groups_v (group_id, name) AS
SELECT group_id, name
FROM groups;
GRANT ALL ON groups_v TO sdnfw;
