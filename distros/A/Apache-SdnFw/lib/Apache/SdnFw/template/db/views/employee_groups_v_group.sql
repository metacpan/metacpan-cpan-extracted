CREATE VIEW employee_groups_v_group (group_id, employee_id, employee_name, checked) AS
SELECT g.group_id, e.employee_id, e.name as employee_name,
	CASE WHEN eg.group_id IS NOT NULL THEN TRUE ELSE FALSE END as checked
FROM groups g
	JOIN employees e ON COALESCE(e.expired_ts,now()) >= now()
	LEFT JOIN employee_groups eg ON e.employee_id=eg.employee_id
		AND eg.group_id=g.group_id
ORDER BY e.name;
GRANT ALL ON employee_groups_v_group TO sdnfw;
