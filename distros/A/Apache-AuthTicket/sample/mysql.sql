-- example schema and sample data for a mysql database backend
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
    sec_version INT AUTO_INCREMENT PRIMARY KEY,
		sec_data TEXT
);

INSERT INTO ticket_secrets (sec_data)
VALUES ('mvkj39vek@#$R*njdea9@#');

INSERT INTO myusers (usename, passwd)
VALUES ('testuser', 'testpass');
