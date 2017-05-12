-- This DDL is used to create a database with the original schema
-- so we can test upgrading it to the latest version

PRAGMA foreign_keys=OFF;
BEGIN TRANSACTION;
CREATE TABLE folders (
  id INTEGER PRIMARY KEY NOT NULL,
  name text NOT NULL DEFAULT 'Unknown'
);
INSERT INTO "folders" VALUES(100,'Inbox');
INSERT INTO "folders" VALUES(101,'Archive');
CREATE TABLE articles (
  id INTEGER PRIMARY KEY NOT NULL,
  title text NOT NULL DEFAULT 'Unknown',
  folder integer NOT NULL,
  created datetime NOT NULL DEFAULT (datetime('now', 'localtime')),
  FOREIGN KEY (folder) REFERENCES folders(id) ON DELETE CASCADE ON UPDATE CASCADE
);
INSERT INTO "articles" VALUES(1,'Welcome to Zapzi',100,'2013-08-05 12:57:41');
CREATE TABLE article_text (
  id INTEGER PRIMARY KEY NOT NULL,
  text blob NOT NULL DEFAULT '',
  FOREIGN KEY (id) REFERENCES articles(id) ON DELETE CASCADE
);
INSERT INTO "article_text" VALUES(1,'<p>Welcome to Zapzi! Please run <pre>zapzi -h</pre> to see documentation.</p>');
CREATE UNIQUE INDEX name_unique ON folders (name);
CREATE INDEX articles_idx_folder ON articles (folder);
COMMIT;
PRAGMA foreign_keys=ON;
