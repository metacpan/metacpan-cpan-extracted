--
-- Table: artist
--
CREATE TABLE artist_preview (
  artistid INTEGER PRIMARY KEY NOT NULL,
  name varchar(100),
  dirty INTEGER DEFAULT '0',
  deleted INTEGER DEFAULT '0'
);
insert into artist_preview select *, 0, 0 from artist;