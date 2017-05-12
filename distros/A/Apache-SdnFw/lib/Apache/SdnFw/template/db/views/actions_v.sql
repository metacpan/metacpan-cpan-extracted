CREATE VIEW actions_v (action_id, name, a_object, a_function) AS
SELECT action_id, name, a_object, a_function
FROM actions;
GRANT ALL ON actions_v TO sdnfw;
