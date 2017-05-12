DROP TABLE IF EXISTS entries;

CREATE TABLE entries (
  id		INTEGER	PRIMARY KEY,
  edited	INTEGER,
  uri		TEXT,
  xml		TEXT,
  UNIQUE(uri)
);
