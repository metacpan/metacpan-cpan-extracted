
CREATE TABLE nodes (
    node_id INTEGER PRIMARY KEY AUTOINCREMENT,
    name STRING,
    parent_id INTEGER,
    position INTEGER,
    lft INTEGER,
    rgt INTEGER
);

