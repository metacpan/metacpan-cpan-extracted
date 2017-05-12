CREATE TABLE artist (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  forename varchar(255) NOT NULL,
  surname varchar(255) NOT NULL,
  pseudonym varchar(255),
  born date
);

INSERT INTO artist (forename,surname,pseudonym,born) VALUES ('Mike', 'Smith', 'Alpha Artist', '1970-02-28');

INSERT INTO artist (forename,surname,pseudonym,born) VALUES ('David', 'Brown', 'Band Beta', '1992-05-30');

INSERT INTO artist (forename,surname,pseudonym,born) VALUES ('Adam', 'Smith', 'Gamma Group', '1981-05-10');

-- album should get a column copyrights as many_to_many via the
-- tracks table. it should also have artists as many_to_many and
-- tracks as has_many.

CREATE TABLE album (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title varchar(255) NOT NULL,
  recorded date,
  deleted boolean DEFAULT 'false'
);

INSERT INTO album (title,recorded,deleted) VALUES ('DJ Mix 1', '1989-01-02', 'true');

INSERT INTO album (title,recorded,deleted) VALUES ('DJ Mix 2', '1989-02-02', 'true');

INSERT INTO album (title,recorded,deleted) VALUES ('DJ Mix 3', '1989-03-02', 'true');

INSERT INTO album (title,recorded,deleted) VALUES ('Pop Songs', '2007-05-30', 'false');

INSERT INTO album (title,recorded,deleted) VALUES ('Greatest Hits', '2002-05-21', 'false');

-- the link table album_artist should not appear as a column
-- in either of the refrenced tables (being detected as is_data)

CREATE TABLE album_artist (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  album_id int REFERENCES album(id) NOT NULL,
  artist_id int REFERENCES artist(id) NOT NULL
);

INSERT INTO album_artist (album_id,artist_id) VALUES (1,1);

INSERT INTO album_artist (album_id,artist_id) VALUES (2,1);

INSERT INTO album_artist (album_id,artist_id) VALUES (3,1);

INSERT INTO album_artist (album_id,artist_id) VALUES (2,3);

INSERT INTO album_artist (album_id,artist_id) VALUES (4,2);

INSERT INTO album_artist (album_id,artist_id) VALUES (5,1);

INSERT INTO album_artist (album_id,artist_id) VALUES (5,2);

INSERT INTO album_artist (album_id,artist_id) VALUES (5,3);

CREATE TABLE sleeve_notes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  text varchar(255) NOT NULL,
  album_id int REFERENCES album(id) UNIQUE NOT NULL
);

INSERT INTO sleeve_notes (text,album_id) VALUES ('This is a groovy album.', 1); 

CREATE TABLE copyright (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  rights_owner varchar(255) NOT NULL,
  copyright_year integer
);

INSERT INTO copyright (rights_owner, copyright_year) VALUES ('Label A', '1987');

INSERT INTO copyright (rights_owner, copyright_year) VALUES ('Label B', '1991');

INSERT INTO copyright (rights_owner, copyright_year) VALUES ('Label C', '2001');

CREATE TABLE track (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title varchar(255) NOT NULL,
  length varchar(255),
  album_id int REFERENCES album (id) NOT NULL,
  copyright_id int REFERENCES copyright (id),
  sales int,
  releasedate date
);

INSERT INTO track (title,length,album_id,copyright_id,sales,releasedate) VALUES ('Track 1.1', '1:30', 1, 1, 5460000, '1994-04-05');

INSERT INTO track (title,length,album_id,copyright_id,sales,releasedate) VALUES ('Track 1.2', '1:40', 1, 2, 1775000, '1995-01-15');

INSERT INTO track (title,length,album_id,copyright_id,sales,releasedate) VALUES ('Track 1.3', '1:50', 1, 1, 2100000, '1989-08-18');

INSERT INTO track (title,length,album_id,copyright_id,sales,releasedate) VALUES ('Track 2.1', '2:30', 2, 2, 153000, '1990-01-04');

INSERT INTO track (title,length,album_id,copyright_id,sales,releasedate) VALUES ('Track 2.2', '2:40', 2, 1, 1020480, '1991-11-11');

INSERT INTO track (title,length,album_id,copyright_id,sales,releasedate) VALUES ('Track 2.3', '2:50', 2, 2, 9625543, '1980-07-21');

INSERT INTO track (title,length,album_id,copyright_id,sales,releasedate) VALUES ('Track 3.1', '3:30', 3, 1, 1953540, '1998-06-12');

INSERT INTO track (title,length,album_id,copyright_id,sales,releasedate) VALUES ('Track 3.2', '3:40', 3, 2, 2668000, '1998-01-04');

INSERT INTO track (title,length,album_id,copyright_id,sales,releasedate) VALUES ('Track 3.3', '3:50', 3, 1, 20000, '1999-11-14');

INSERT INTO track (title,length,album_id,copyright_id,sales,releasedate) VALUES ('Pop Song One', '1:01', 4, 2, 2685000, '1995-01-04');

INSERT INTO track (title,length,album_id,copyright_id,sales,releasedate) VALUES ('Hit Tune', '2:02', 5, 2, 1536000, '1990-11-06');

INSERT INTO track (title,length,album_id,copyright_id,sales,releasedate) VALUES ('Hit Tune II', '3:03', 5, 2, 195300, '1990-11-06');

INSERT INTO track (title,length,album_id,copyright_id,sales,releasedate) VALUES ('Hit Tune 3', '4:04', 5, 2, 1623000, '1990-11-06');

