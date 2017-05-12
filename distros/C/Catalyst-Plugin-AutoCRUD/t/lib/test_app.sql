CREATE TABLE artist (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  forename varchar(255) NOT NULL,
  surname varchar(255) NOT NULL,
  pseudonym varchar(255),
  born date
);

INSERT INTO artist (id,forename,surname,pseudonym,born) VALUES (1, 'Mike', 'Smith', 'Alpha Artist', '1970-02-28');

INSERT INTO artist (id,forename,surname,pseudonym,born) VALUES (2, 'David', 'Brown', 'Band Beta', '1992-05-30');

INSERT INTO artist (id,forename,surname,pseudonym,born) VALUES (3, 'Adam', 'Smith', 'Gamma Group', '1981-05-10');

CREATE TABLE album (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title varchar(255) NOT NULL,
  recorded date,
  deleted boolean DEFAULT 'false',
  artist_id int REFERENCES artist(id) NOT NULL
);

INSERT INTO album (id,title,recorded,deleted,artist_id) VALUES (1, 'DJ Mix 1', '1989-01-02', 'true', 1);

INSERT INTO album (id,title,recorded,deleted,artist_id) VALUES (2, 'DJ Mix 2', '1989-02-02', 'true', 1);

INSERT INTO album (id,title,recorded,deleted,artist_id) VALUES (3, 'DJ Mix 3', '1989-03-02', 'true', 1);

INSERT INTO album (id,title,recorded,deleted,artist_id) VALUES (4, 'Pop Songs', '2007-05-30', 'false', 2);

INSERT INTO album (id,title,recorded,deleted,artist_id) VALUES (5, 'Greatest Hits', '2002-05-21', 'false', 3);

CREATE TABLE sleeve_notes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  text varchar(255) NOT NULL,
  album_id int REFERENCES album(id) UNIQUE NOT NULL
);

INSERT INTO sleeve_notes (id,text,album_id) VALUES (1, 'This is a groovy album.', 2);

CREATE TABLE copyright (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  'rights owner' varchar(255) NOT NULL,
  copyright_year integer
);

INSERT INTO copyright (id, 'rights owner', copyright_year) VALUES (1, 'Label A', '1987');

INSERT INTO copyright (id, 'rights owner', copyright_year) VALUES (2, 'Label B', '1991');

INSERT INTO copyright (id, 'rights owner', copyright_year) VALUES (3, 'Label C', '2001');

CREATE TABLE track (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title varchar(255) NOT NULL,
  length varchar(255),
  album_id int REFERENCES album (id) NOT NULL,
  copyright_id int REFERENCES copyright (id),
  sales int,
  releasedate date
);

INSERT INTO track (id,title,length,album_id,copyright_id,sales,releasedate) VALUES (1, 'Track 1.1', '1:30', 1, 1, 5460000, '1994-04-05');

INSERT INTO track (id,title,length,album_id,copyright_id,sales,releasedate) VALUES (2, 'Track 1.2', '1:40', 1, 2, 1775000, '1995-01-15');

INSERT INTO track (id,title,length,album_id,copyright_id,sales,releasedate) VALUES (3, 'Track 1.3', '1:50', 1, 1, 2100000, '1989-08-18');

INSERT INTO track (id,title,length,album_id,copyright_id,sales,releasedate) VALUES (4, 'Track 2.1', '2:30', 2, 2, 153000, '1990-01-04');

INSERT INTO track (id,title,length,album_id,copyright_id,sales,releasedate) VALUES (5, 'Track 2.2', '2:40', 2, 1, 1020480, '1991-11-11');

INSERT INTO track (id,title,length,album_id,copyright_id,sales,releasedate) VALUES (6, 'Track 2.3', '2:50', 2, 2, 9625543, '1980-07-21');

INSERT INTO track (id,title,length,album_id,copyright_id,sales,releasedate) VALUES (7, 'Track 3.1', '3:30', 3, 1, 1953540, '1998-06-12');

INSERT INTO track (id,title,length,album_id,copyright_id,sales,releasedate) VALUES (8, 'Track 3.2', '3:40', 3, 2, 2668000, '1998-01-04');

INSERT INTO track (id,title,length,album_id,copyright_id,sales,releasedate) VALUES (9, 'Track 3.3', '3:50', 3, 1, 20000, '1999-11-14');

INSERT INTO track (id,title,length,album_id,copyright_id,sales,releasedate) VALUES (10, 'Pop Song One', '1:01', 4, 2, 2685000, '1995-01-04');

INSERT INTO track (id,title,length,album_id,copyright_id,sales,releasedate) VALUES (11, 'Hit Tune', '2:02', 5, 2, 1536000, '1990-11-06');

INSERT INTO track (id,title,length,album_id,copyright_id,sales,releasedate) VALUES (12, 'Hit Tune II', '3:03', 5, 2, 195300, '1990-11-06');

INSERT INTO track (id,title,length,album_id,copyright_id,sales,releasedate) VALUES (13, 'Hit Tune 3', '4:04', 5, 2, 1623000, '1990-11-06');

