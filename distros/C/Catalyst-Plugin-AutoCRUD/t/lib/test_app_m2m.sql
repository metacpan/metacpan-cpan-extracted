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
  deleted boolean DEFAULT 'false'
);

INSERT INTO album (id,title,recorded,deleted) VALUES (1, 'DJ Mix 1', '1989-01-02', 'true');

INSERT INTO album (id,title,recorded,deleted) VALUES (2, 'DJ Mix 2', '1989-02-02', 'true');

INSERT INTO album (id,title,recorded,deleted) VALUES (3, 'DJ Mix 3', '1989-03-02', 'true');

INSERT INTO album (id,title,recorded,deleted) VALUES (4, 'Pop Songs', '2007-05-30', 'false');

INSERT INTO album (id,title,recorded,deleted) VALUES (5, 'Greatest Hits', '2002-05-21', 'false');

CREATE TABLE artist_album (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    artist_id int REFERENCES artist(id) NOT NULL,
    album_id int REFERENCES album(id) NOT NULL
);

INSERT INTO artist_album (id,artist_id,album_id) VALUES (1, 1, 1);

INSERT INTO artist_album (id,artist_id,album_id) VALUES (2, 1, 2);

INSERT INTO artist_album (id,artist_id,album_id) VALUES (3, 2, 3);

INSERT INTO artist_album (id,artist_id,album_id) VALUES (4, 3, 5);

