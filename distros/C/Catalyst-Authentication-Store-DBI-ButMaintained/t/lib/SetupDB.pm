use DBI;

my $dbfile = $ENV{'TESTAPP_DB_FILE'};

if (-e $dbfile) {
	unlink($dbfile);
}

my $dbh = DBI->connect("dbi:SQLite:$dbfile") or die($DBI::errstr);

my $sql = <<'EOSQL';
CREATE TABLE user (
  id integer not null,
  name text not null,
  password text not null,
  active integer not null,
  CONSTRAINT pk_user PRIMARY KEY (id)
);
CREATE UNIQUE INDEX idx_user_name
  ON user (name);

CREATE TABLE role (
  id integer not null,
  name text not null,
  CONSTRAINT pk_role PRIMARY KEY (id)
);
CREATE UNIQUE INDEX idx_role_name
  ON role (name);

CREATE TABLE userrole (
  user integer not null,
  role integer not null,
  CONSTRAINT pk_userrole PRIMARY KEY (user, role)
);

INSERT INTO user VALUES (1, 'joe', 'x', 1);
INSERT INTO user VALUES (2, 'bob', 'y', 1);
INSERT INTO user VALUES (3, 'martin', 'z', 0);

INSERT INTO role VALUES (1, 'admin');
INSERT INTO role VALUES (2, 'user');

INSERT INTO userrole VALUES (1, 1);
INSERT INTO userrole VALUES (1, 2);
INSERT INTO userrole VALUES (2, 1);
INSERT INTO userrole VALUES (3, 2);
EOSQL

for (split(m/;\s*/, $sql)) {
	$dbh->do($_) or die($dbh->errstr);
}
$dbh->disconnect();

