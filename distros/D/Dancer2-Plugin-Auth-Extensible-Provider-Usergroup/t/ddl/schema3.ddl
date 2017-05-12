CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    login_name TEXT UNIQUE NOT NULL,
    passphrase TEXT NOT NULL,
    name TEXT,
    activated INTEGER
);
CREATE TABLE groups (
    id INTEGER PRIMARY KEY,
    group_name TEXT UNIQUE NOT NULL
);
CREATE TABLE memberships (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users (id),
    group_id INTEGER NOT NULL REFERENCES groups (id)
  );
CREATE VIEW roles AS
    SELECT login_name, group_name AS role
        FROM users
        LEFT JOIN memberships ON users.id = memberships.user_id
        LEFT JOIN groups ON groups.id = memberships.group_id;
CREATE UNIQUE INDEX login_name ON users (login_name);
CREATE UNIQUE INDEX group_name ON groups (group_name);
CREATE UNIQUE INDEX user_group ON memberships (user_id, group_id);
CREATE INDEX member_user ON memberships (user_id);
CREATE INDEX member_group ON memberships (group_id);
INSERT INTO users VALUES (1, 'bananarepublic', '{SSHA}5gKaJEMxoJZbevrKz452MN31zzLF04Ps', 'Bananas', 1);
