CREATE TABLE "artist" (
  "artistid" INTEGER PRIMARY KEY NOT NULL,
  "name" text NOT NULL,
  "last_name_change_id" INTEGER NULL,
  "previousid" INTEGER NULL,
  FOREIGN KEY ("last_name_change_id") REFERENCES "artist_event"("artisteventid")
  FOREIGN KEY ("previousid") REFERENCES "artist"("artistid")
);

CREATE UNIQUE INDEX "artist_name" ON "artist" ("name");

CREATE TABLE "artist_event" (
    "artisteventid" INTEGER PRIMARY KEY NOT NULL,
    "artistid" INTEGER NOT NULL,
    "event" VARCHAR(32) NOT NULL,
    "triggered_on" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "details" LONGTEXT,
  FOREIGN KEY ("artistid") REFERENCES "artist"("artistid") ON UPDATE CASCADE
);

CREATE INDEX "artist_event_idx_artist" ON "artist_event" ("artistid", "event", "triggered_on");

CREATE TABLE "cd" (
  "cdid" INTEGER PRIMARY KEY NOT NULL,
  "artistid" integer NOT NULL,
  "title" text NOT NULL,
  "year" datetime,
  FOREIGN KEY ("artistid") REFERENCES "artist"("artistid") ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX "cd_idx_artistid" ON "cd" ("artistid");

CREATE UNIQUE INDEX "cd_title_artistid" ON "cd" ("title", "artistid");

CREATE TABLE "cd_event" (
    "cdeventid" INTEGER PRIMARY KEY NOT NULL,
    "cdid" INTEGER NOT NULL,
    "event" VARCHAR(32) NOT NULL,
    "triggered_on" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "details" LONGTEXT,
  FOREIGN KEY ("cdid") REFERENCES "cd"("cdid") ON UPDATE CASCADE
);

CREATE INDEX "cd_event_idx_cd" ON "cd_event" ("cdid", "event", "triggered_on");

CREATE TABLE "track" (
  "trackid" INTEGER PRIMARY KEY NOT NULL,
  "cdid" integer NOT NULL,
  "id" varchar(16),
  "title" text NOT NULL,
  FOREIGN KEY ("cdid") REFERENCES "cd"("cdid") ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX "track_idx_cdid" ON "track" ("cdid");

CREATE UNIQUE INDEX "track_title_cdid" ON "track" ("title", "cdid");

CREATE TABLE "track_event" (
    "id" INTEGER PRIMARY KEY NOT NULL,
    "trackid" INTEGER NOT NULL,
    "event" VARCHAR(32) NOT NULL,
    "triggered_on" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "details" LONGTEXT,
    "title" text NULL,
  FOREIGN KEY ("trackid") REFERENCES "track"("trackid") ON UPDATE CASCADE
);

CREATE INDEX "track_event_idx_track" ON "track_event" ("trackid", "event", "triggered_on");
