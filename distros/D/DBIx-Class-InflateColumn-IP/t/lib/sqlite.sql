CREATE TABLE host (
	hostname TEXT NOT NULL PRIMARY KEY,
	address INTEGER NOT NULL UNIQUE
);

CREATE TABLE network (
        netname TEXT NOT NULL PRIMARY KEY,
        address VARCHAR(18) NOT NULL UNIQUE
);
