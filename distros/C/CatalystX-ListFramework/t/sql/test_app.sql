CREATE TABLE artists (
  id int PRIMARY KEY,
  artist_fname varchar(255),
  artist_sname varchar(255),
  artist_pseudonym varchar(255),
  born varchar(255)
)

INSERT INTO artists (id,artist_fname,artist_sname,artist_pseudonym,born) VALUES (1, 'Mike', 'Smith', 'Alpha Artist', '1970-02-28')

INSERT INTO artists (id,artist_fname,artist_sname,artist_pseudonym,born) VALUES (2, 'David', 'Brown', 'Band Beta', '1992-05-30')

INSERT INTO artists (id,artist_fname,artist_sname,artist_pseudonym,born) VALUES (3, 'Adam', 'Smith', 'Gamma Group', '1981-05-10')

CREATE TABLE albums (
  id int PRIMARY KEY,
  title varchar(255),
  recorded varchar(255),
  artist int
)

INSERT INTO albums (id,title,recorded, artist) VALUES (1, 'DJ Mix 1', '1989-01-02', 1)

INSERT INTO albums (id,title,recorded, artist) VALUES (2, 'DJ Mix 2', '1989-02-02', 1)

INSERT INTO albums (id,title,recorded, artist) VALUES (3, 'DJ Mix 3', '1989-03-02', 1)

INSERT INTO albums (id,title,recorded, artist) VALUES (4, 'Pop Songs', '2007-05-30', 2)

INSERT INTO albums (id,title,recorded, artist) VALUES (5, 'Greatest Hits', '2002-05-21', 3)

CREATE TABLE copyright (
  id int PRIMARY KEY,
  rights_owner varchar(255),
  copyright_year varchar(255)
)

INSERT INTO copyright (id, rights_owner, copyright_year) VALUES (1, 'Label A', '1987')

INSERT INTO copyright (id, rights_owner, copyright_year) VALUES (2, 'Label B', '1991')

INSERT INTO copyright (id, rights_owner, copyright_year) VALUES (3, 'Label C', '2001')

CREATE TABLE tracks (
  id INTEGER PRIMARY KEY,
  tracktitle varchar(255),
  tracklength varchar(255),
  fromalbum int,
  trackcopyright int,
  tracksales int,
  trackreleasedate varchar(255)
)

INSERT INTO tracks (id,tracktitle,tracklength,fromalbum,trackcopyright,tracksales,trackreleasedate) VALUES (1, 'Track 1.1', '1:30', 1, 1, 5460000, '1994-04-05')

INSERT INTO tracks (id,tracktitle,tracklength,fromalbum,trackcopyright,tracksales,trackreleasedate) VALUES (2, 'Track 1.2', '1:40', 1, 2, 1775000, '1995-01-15')

INSERT INTO tracks (id,tracktitle,tracklength,fromalbum,trackcopyright,tracksales,trackreleasedate) VALUES (3, 'Track 1.3', '1:50', 1, 1, 2100000, '1989-08-18')

INSERT INTO tracks (id,tracktitle,tracklength,fromalbum,trackcopyright,tracksales,trackreleasedate) VALUES (4, 'Track 2.1', '2:30', 2, 2, 153000, '1990-01-04')

INSERT INTO tracks (id,tracktitle,tracklength,fromalbum,trackcopyright,tracksales,trackreleasedate) VALUES (5, 'Track 2.2', '2:40', 2, 1, 1020480, '1991-11-11')

INSERT INTO tracks (id,tracktitle,tracklength,fromalbum,trackcopyright,tracksales,trackreleasedate) VALUES (6, 'Track 2.3', '2:50', 2, 2, 9625543, '1980-07-21')

INSERT INTO tracks (id,tracktitle,tracklength,fromalbum,trackcopyright,tracksales,trackreleasedate) VALUES (7, 'Track 3.1', '3:30', 3, 1, 1953540, '1998-06-12')

INSERT INTO tracks (id,tracktitle,tracklength,fromalbum,trackcopyright,tracksales,trackreleasedate) VALUES (8, 'Track 3.2', '3:40', 3, 2, 2668000, '1998-01-04')

INSERT INTO tracks (id,tracktitle,tracklength,fromalbum,trackcopyright,tracksales,trackreleasedate) VALUES (9, 'Track 3.3', '3:50', 3, 1, 20000, '1999-11-14')

INSERT INTO tracks (id,tracktitle,tracklength,fromalbum,trackcopyright,tracksales,trackreleasedate) VALUES (10, 'Pop Song One', '1:01', 4, 2, 2685000, '1995-01-04')

INSERT INTO tracks (id,tracktitle,tracklength,fromalbum,trackcopyright,tracksales,trackreleasedate) VALUES (11, 'Hit Tune', '2:02', 5, 2, 1536000, '1990-11-06')

INSERT INTO tracks (id,tracktitle,tracklength,fromalbum,trackcopyright,tracksales,trackreleasedate) VALUES (12, 'Hit Tune II', '3:03', 5, 2, 195300, '1990-11-06')

INSERT INTO tracks (id,tracktitle,tracklength,fromalbum,trackcopyright,tracksales,trackreleasedate) VALUES (13, 'Hit Tune 3', '4:04', 5, 2, 1623000, '1990-11-06')

