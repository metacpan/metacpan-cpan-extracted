CREATE VIEW group_actions_v_group (group_id, action_id, action_name, checked) AS
SELECT g.group_id, a.action_id, a.name as action_name,
	CASE WHEN ga.group_id IS NOT NULL THEN TRUE ELSE FALSE END AS checked
FROM groups g
	JOIN actions a ON a.action_id>0
	LEFT JOIN group_actions ga ON a.action_id=ga.action_id
		AND g.group_id=ga.group_id
ORDER BY a.name;
GRANT ALL ON group_actions_v_group TO sdnfw;
