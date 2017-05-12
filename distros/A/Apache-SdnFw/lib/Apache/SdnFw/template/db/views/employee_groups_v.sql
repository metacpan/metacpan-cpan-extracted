CREATE VIEW employee_groups_v (employee_id, group_id,
	employee_name, group_name) AS
SELECT eg.employee_id, eg.group_id,
	e.name as employee_name, g.name as group_name
FROM employee_groups eg
	JOIN employees e ON eg.employee_id=e.employee_id
	JOIN groups g ON eg.group_id=g.group_id
ORDER BY employee_name, group_name;
GRANT ALL ON employee_groups_v TO sdnfw;
