CREATE VIEW employees_v (employee_id, login, passwd, name, email) AS
SELECT employee_id, login, passwd, name, email
FROM employees
ORDER BY name;
GRANT ALL ON employees_v TO sdnfw;
