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
INSERT INTO users VALUES (1, 'dave', '{CRYPT}$2a$04$CKlFfyIIKBuRUedsSjTLp.lA//xWk2ra7XRykYIe3/qSCLZ/rg3Ji', 'David Precious', 1), (2, 'bob', '{CRYPT}$2a$04$ytNLO7CspMrUZENMTjpytueT4R2IrUudiTyWZ8vxhGtAJShKJsXGC', 'Bob Smith', 1), (3, 'mark', '{CRYPT}$2a$04$F3AWSohClqZSRp77dMfTDOoeSkacdPoJLey.huRcJFlB0KNk8w2dO', 'Update here', 1);
INSERT INTO groups VALUES (1, 'BeerDrinker'), (2, 'Motorcyclist'), (3, 'CiderDrinker');
INSERT INTO memberships VALUES (1,1,1), (2,1,2), (3,2,3);
