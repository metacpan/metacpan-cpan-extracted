CREATE VIEW employee_groups_v_employee (employee_id, group_id, group_name, checked) AS
SELECT e.employee_id, g.group_id, g.name as group_name,
	CASE WHEN eg.employee_id IS NOT NULL THEN TRUE ELSE FALSE END as checked
FROM employees e
	JOIN groups g ON g.group_id>0
	LEFT JOIN employee_groups eg ON e.employee_id=eg.employee_id
		AND eg.group_id=g.group_id
ORDER BY g.name;
GRANT ALL ON employee_groups_v_employee TO sdnfw;
