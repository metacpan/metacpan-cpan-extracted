DROP TABLE IF EXISTS entries;
DROP TABLE IF EXISTS medias;
DROP TABLE IF EXISTS users;

CREATE TABLE entries (
  id		INTEGER	PRIMARY KEY,
  edited	INTEGER,

  uri		TEXT,
  etag		TEXT,
  body		TEXT,	-- XML

  UNIQUE(uri)
);

CREATE TABLE medias (
  id		INTEGER	PRIMARY KEY,
  edited	INTEGER,

  entry_uri	TEXT,
  entry_etag	TEXT,
  entry_body	TEXT,	-- XML

  media_uri	TEXT,
  media_etag	TEXT,
  media_body	TEXT,	-- Base64
  media_type	TEXT,

  UNIQUE(entry_uri)
);


CREATE TABLE users (
  id		INTEGER	PRIMARY KEY,
  created_on	INTEGER,

  username	TEXT,
  password	TEXT,

  UNIQUE(username)
);

INSERT INTO users (
  username,
  password
)
VALUES (
  'foo',
  'acbd18db4cc2f85cedef654fccc4a4d8'
);
