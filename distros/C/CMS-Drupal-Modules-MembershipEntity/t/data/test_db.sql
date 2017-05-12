CREATE TABLE "membership_entity" (
  "mid" integer primary key autoincrement,
  "member_id" varchar(255) NOT NULL DEFAULT '',
  "type" varchar(32) NOT NULL DEFAULT 'membership',
  "uid" int(10) NOT NULL DEFAULT '0',
  "status" int(11) NOT NULL DEFAULT '1',
  "created" int(11) NOT NULL DEFAULT '0',
  "changed" int(11) NOT NULL DEFAULT '0'
);

CREATE TABLE "membership_entity_term" (
  "id" integer primary key autoincrement,
  "mid" int(10) NOT NULL,
  "status" int(11) NOT NULL DEFAULT '1',
  "term" varchar(32) NOT NULL DEFAULT '1 year',
  "modifiers" longtext DEFAULT 'a:0:{}',
  "start" datetime NOT NULL,
  "end" datetime DEFAULT NULL
);

CREATE TABLE "membership_entity_type" (
  "id" integer primary key autoincrement,
  "type" varchar(32) NOT NULL,
  "label" varchar(255) NOT NULL DEFAULT '',
  "weight" int(11) NOT NULL DEFAULT '0',
  "description" mediumtext,
  "data" longtext,
  "status" tinyint(4) NOT NULL DEFAULT '1',
  "module" varchar(255) DEFAULT NULL
);

CREATE TABLE "membership_entity_secondary_member" (
  "mid" int(10) NOT NULL,
  "uid" int(10) NOT NULL DEFAULT '0',
  "weight" int(11) NOT NULL DEFAULT '1',
  PRIMARY KEY ("mid","uid")
);

