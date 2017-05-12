CREATE VIEW employees_v_keyval (id, name) AS
SELECT employee_id, name
FROM employees
ORDER BY name;
GRANT ALL ON employees_v_keyval TO sdnfw;
