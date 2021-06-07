CREATE TABLE "artist" (
  "artistid" INTEGER PRIMARY KEY NOT NULL,
  "name" varchar(100),
  "rank" integer NOT NULL DEFAULT 13,
  "charfield" char(10)
);

CREATE INDEX "artist_name_hookidx" ON "artist" ("name");

CREATE UNIQUE INDEX "artist_name" ON "artist" ("name");

CREATE UNIQUE INDEX "u_nullable" ON "artist" ("charfield", "rank");

CREATE TABLE "genre" (
  "genreid" INTEGER PRIMARY KEY NOT NULL,
  "name" varchar(100) NOT NULL
);

CREATE UNIQUE INDEX "genre_name" ON "genre" ("name");

CREATE TABLE "producer" (
  "producerid" INTEGER PRIMARY KEY NOT NULL,
  "name" varchar(100) NOT NULL
);

CREATE UNIQUE INDEX "prod_name" ON "producer" ("name");

CREATE TABLE "cd" (
  "cdid" INTEGER PRIMARY KEY NOT NULL,
  "artist" integer NOT NULL,
  "title" varchar(100) NOT NULL,
  "year" varchar(100) NOT NULL,
  "genreid" integer,
  "prev_cdid" integer,
  FOREIGN KEY ("artist") REFERENCES "artist"("artistid") ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY ("genreid") REFERENCES "genre"("genreid") ON DELETE SET NULL ON UPDATE CASCADE,
  FOREIGN KEY ("prev_cdid") REFERENCES "cd"("cdid") ON DELETE SET NULL ON UPDATE CASCADE
);

CREATE INDEX "cd_idx_artist" ON "cd" ("artist");

CREATE INDEX "cd_idx_genreid" ON "cd" ("genreid");

CREATE UNIQUE INDEX "cd_artist_title" ON "cd" ("artist", "title");

CREATE TABLE "track" (
  "trackid" INTEGER PRIMARY KEY NOT NULL,
  "cd" integer NOT NULL,
  "position" int NOT NULL,
  "title" varchar(100) NOT NULL,
  "last_updated_on" datetime,
  "last_updated_at" datetime,
  FOREIGN KEY ("cd") REFERENCES "cd"("cdid") ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX "track_idx_cd" ON "track" ("cd");

CREATE UNIQUE INDEX "track_cd_position" ON "track" ("cd", "position");

CREATE UNIQUE INDEX "track_cd_title" ON "track" ("cd", "title");

CREATE TABLE "lyrics" (
  "lyric_id" INTEGER PRIMARY KEY NOT NULL,
  "track_id" integer NOT NULL,
  FOREIGN KEY ("track_id") REFERENCES "track"("trackid") ON DELETE CASCADE
);

CREATE INDEX "lyrics_idx_track_id" ON "lyrics" ("track_id");

CREATE TABLE "cd_artwork" (
  "cd_id" INTEGER PRIMARY KEY NOT NULL,
  FOREIGN KEY ("cd_id") REFERENCES "cd"("cdid") ON DELETE CASCADE
);

CREATE TABLE "lyric_versions" (
  "id" INTEGER PRIMARY KEY NOT NULL,
  "lyric_id" integer NOT NULL,
  "text" varchar(100) NOT NULL,
  FOREIGN KEY ("lyric_id") REFERENCES "lyrics"("lyric_id") ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX "lyric_versions_idx_lyric_id" ON "lyric_versions" ("lyric_id");

CREATE UNIQUE INDEX "lyric_versions_lyric_id_text" ON "lyric_versions" ("lyric_id", "text");

CREATE TABLE "tags" (
  "tagid" INTEGER PRIMARY KEY NOT NULL,
  "cd" integer NOT NULL,
  "tag" varchar(100) NOT NULL,
  FOREIGN KEY ("cd") REFERENCES "cd"("cdid") ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX "tags_idx_cd" ON "tags" ("cd");

CREATE UNIQUE INDEX "tagid_cd" ON "tags" ("tagid", "cd");

CREATE UNIQUE INDEX "tagid_cd_tag" ON "tags" ("tagid", "cd", "tag");

CREATE UNIQUE INDEX "tags_tagid_tag" ON "tags" ("tagid", "tag");

CREATE UNIQUE INDEX "tags_tagid_tag_cd" ON "tags" ("tagid", "tag", "cd");

CREATE TABLE "cd_to_producer" (
  "cd" integer NOT NULL,
  "producer" integer NOT NULL,
  "attribute" integer,
  PRIMARY KEY ("cd", "producer"),
  FOREIGN KEY ("cd") REFERENCES "cd"("cdid") ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY ("producer") REFERENCES "producer"("producerid")
);

CREATE INDEX "cd_to_producer_idx_cd" ON "cd_to_producer" ("cd");

CREATE INDEX "cd_to_producer_idx_producer" ON "cd_to_producer" ("producer");

CREATE TABLE "images" (
  "id" INTEGER PRIMARY KEY NOT NULL,
  "artwork_id" integer NOT NULL,
  "name" varchar(100) NOT NULL,
  "data" blob,
  FOREIGN KEY ("artwork_id") REFERENCES "cd_artwork"("cd_id") ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX "images_idx_artwork_id" ON "images" ("artwork_id");

CREATE TABLE "artwork_to_artist" (
  "artwork_cd_id" integer NOT NULL,
  "artist_id" integer NOT NULL,
  PRIMARY KEY ("artwork_cd_id", "artist_id"),
  FOREIGN KEY ("artist_id") REFERENCES "artist"("artistid") ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY ("artwork_cd_id") REFERENCES "cd_artwork"("cd_id") ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX "artwork_to_artist_idx_artist_id" ON "artwork_to_artist" ("artist_id");

CREATE INDEX "artwork_to_artist_idx_artwork_cd_id" ON "artwork_to_artist" ("artwork_cd_id");

CREATE VIEW "year2000cds" AS
    SELECT cdid, artist, title, year, genreid FROM cd WHERE year = '2000';
