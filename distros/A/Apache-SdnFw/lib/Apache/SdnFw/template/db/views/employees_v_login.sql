CREATE VIEW employees_v_login (employee_id, login, cookie, passwd, name, email,
	password_expired, account_expired, groups, admin) AS
SELECT e.employee_id, e.login, e.cookie, e.passwd, e.name, e.email,
	CASE WHEN passwd_expire < now() THEN TRUE ELSE NULL END as password_expired,
	CASE WHEN expired_ts < now() THEN TRUE ELSE NULL END as account_expired,
	concat(eg.group_id) as groups,
	CASE WHEN count(g.admin) > 0 THEN TRUE ELSE NULL END as admin
FROM employees e
	LEFT JOIN employee_groups eg ON e.employee_id=eg.employee_id
	LEFT JOIN groups g ON eg.group_id=g.group_id
GROUP BY 1,2,3,4,5,6,7,8;
GRANT ALL ON employees_v_login TO sdnfw;
