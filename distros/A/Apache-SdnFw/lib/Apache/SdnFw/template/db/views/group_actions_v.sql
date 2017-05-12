CREATE VIEW group_actions_v (group_id, action_id, group_name, action_name) AS
SELECT ga.group_id, ga.action_id, g.name as group_name, a.name as action_name
FROM group_actions ga
	JOIN groups g ON ga.group_id=g.group_id
	JOIN actions a ON a.action_id=ga.action_id
ORDER BY group_name, action_name;
GRANT ALL ON group_actions_v TO sdnfw;
