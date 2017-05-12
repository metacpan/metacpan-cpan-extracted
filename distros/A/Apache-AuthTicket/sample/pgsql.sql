-- sample database shema for PostgreSQL

CREATE TABLE tickets (
    ticket_hash VARCHAR(32) NOT NULL,
		ts INT NOT NULL,
		PRIMARY KEY (ticket_hash)
);

CREATE TABLE myusers (
    usename VARCHAR(8) NOT NULL,
		passwd  VARCHAR(8) NOT NULL,
		PRIMARY KEY (usename)
);

CREATE TABLE ticket_secrets (
    sec_version SERIAL,
		sec_data TEXT
);

INSERT INTO ticket_secrets (sec_data)
VALUES ('mvkj39vek@#$R*njdea9@#');

INSERT INTO myusers (usename, passwd)
VALUES ('testuser', 'testpass');

GRANT ALL ON tickets TO PUBLIC;
GRANT ALL ON myusers TO PUBLIC;
GRANT ALL ON ticket_secrets TO PUBLIC;
GRANT ALL ON ticket_secrets_sec_version_seq TO PUBLIC;
