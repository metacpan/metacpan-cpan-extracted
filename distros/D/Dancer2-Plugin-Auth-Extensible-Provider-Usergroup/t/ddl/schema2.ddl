CREATE TABLE myusers (
    id INTEGER PRIMARY KEY,
    mylogin_name TEXT UNIQUE NOT NULL,
    mypassphrase TEXT NOT NULL,
    name TEXT,
    myactivated INTEGER
);
CREATE TABLE mygroups (
    id INTEGER PRIMARY KEY,
    mygroup_name TEXT UNIQUE NOT NULL
);
CREATE TABLE mymemberships (
    id INTEGER PRIMARY KEY,
    myuser_id INTEGER NOT NULL REFERENCES users (id),
    mygroup_id INTEGER NOT NULL REFERENCES groups (id)
  );
CREATE VIEW myroles AS
    SELECT mylogin_name, mygroup_name AS myrole
        FROM myusers
        LEFT JOIN mymemberships ON myusers.id = mymemberships.myuser_id
        LEFT JOIN mygroups ON mygroups.id = mymemberships.mygroup_id;
CREATE UNIQUE INDEX mylogin_name ON myusers (mylogin_name);
CREATE UNIQUE INDEX mygroup_name ON mygroups (mygroup_name);
CREATE UNIQUE INDEX myuser_group ON mymemberships (myuser_id, mygroup_id);
CREATE INDEX mymember_user ON mymemberships (myuser_id);
CREATE INDEX mymember_group ON mymemberships (mygroup_id);
INSERT INTO myusers VALUES (1, 'burt', 'bacharach', '', 1), (2, 'hashedpassword', '{SSHA}+2u1HpOU7ak6iBR6JlpICpAUvSpA/zBM', '', 1), (3, 'mark', '{CRYPT}$2a$04$F3AWSohClqZSRp77dMfTDOoeSkacdPoJLey.huRcJFlB0KNk8w2dO', '', 1);
INSERT INTO mygroups VALUES (1, 'BeerDrinker'), (2, 'Motorcyclist'), (3, 'CiderDrinker');
INSERT INTO mymemberships VALUES (1,1,1), (2,2,2), (3,3,3);
