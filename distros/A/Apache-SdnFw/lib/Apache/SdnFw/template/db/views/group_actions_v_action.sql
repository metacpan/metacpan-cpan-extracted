CREATE VIEW group_actions_v_action (action_id, group_id, group_name, checked) AS
SELECT a.action_id, g.group_id, g.name as group_name,
	CASE WHEN ga.action_id IS NOT NULL THEN TRUE ELSE FALSE END AS checked
FROM actions a
	JOIN groups g ON g.group_id>0
	LEFT JOIN group_actions ga ON a.action_id=ga.action_id
		AND g.group_id=ga.group_id
ORDER BY g.name;
GRANT ALL ON group_actions_v_action TO sdnfw;
