--
-- Table: punctuated_column_name
--
CREATE TABLE punctuated_column_name (
    id INTEGER PRIMARY KEY NOT NULL,
    "foo ' bar" INTEGER,
    'bar/baz' INTEGER,
    'baz;quux' INTEGER
);

INSERT INTO punctuated_column_name ("foo ' bar", 'bar/baz', 'baz;quux') VALUES (1,2,3);

INSERT INTO punctuated_column_name ("foo ' bar", 'bar/baz', 'baz;quux') VALUES (4,5,6);

--
-- Table: fourkeys
--
CREATE TABLE fourkeys (
  foo INTEGER NOT NULL,
  bar INTEGER NOT NULL,
  hello INTEGER NOT NULL,
  goodbye INTEGER NOT NULL,
  sensors CHARACTER(10) NOT NULL,
  read_count int,
  PRIMARY KEY (foo, bar, hello, goodbye)
);

INSERT INTO fourkeys (foo, bar, hello, goodbye, sensors) VALUES (1, 2, 3, 4, 'xxx');

INSERT INTO fourkeys (foo, bar, hello, goodbye, sensors) VALUES (5, 4, 3, 6, 'yyy');

--
-- Table: twokeys
--
CREATE TABLE twokeys (
  artist INTEGER NOT NULL,
  cd INTEGER NOT NULL,
  PRIMARY KEY (artist, cd)
);

INSERT INTO twokeys (artist, cd) VALUES (1, 1);

INSERT INTO twokeys (artist, cd) VALUES (1, 2);

INSERT INTO twokeys (artist, cd) VALUES (2, 1);

--
-- Table: fourkeys_to_twokeys
--
CREATE TABLE fourkeys_to_twokeys (
  f_foo INTEGER NOT NULL REFERENCES fourkeys(foo),
  f_bar INTEGER NOT NULL REFERENCES fourkeys(bar),
  f_hello INTEGER NOT NULL REFERENCES fourkeys(hello),
  f_goodbye INTEGER NOT NULL REFERENCES fourkeys(goodbye),
  t_artist INTEGER NOT NULL REFERENCES twokeys(artist),
  t_cd INTEGER NOT NULL REFERENCES twokeys(cd),
  autopilot CHARACTER NOT NULL,
  pilot_sequence INTEGER,
  PRIMARY KEY (f_foo, f_bar, f_hello, f_goodbye, t_artist, t_cd)
);

INSERT INTO fourkeys_to_twokeys (f_foo, f_bar, f_hello, f_goodbye, t_artist, t_cd, autopilot) VALUES (1, 2, 3, 4, 1, 2, 'x');

INSERT INTO fourkeys_to_twokeys (f_foo, f_bar, f_hello, f_goodbye, t_artist, t_cd, autopilot) VALUES (5, 4, 3, 6, 2, 1, 'y');

--
-- Table: dynamic_default
--
CREATE TABLE dynamic_default (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name VARCHAR(100) NOT NULL,
  on_create VARCHAR(100),
  on_create_and_update VARCHAR(100)
);

INSERT INTO dynamic_default (name) VALUES ('Charlie');

INSERT INTO dynamic_default (name) VALUES ('Bobby');

--
-- Table: link
--
CREATE TABLE link (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  url VARCHAR(100),
  title VARCHAR(100)
);

INSERT INTO link (url,title) VALUES ('http://www.perl.org/','Perl');

INSERT INTO link (url,title) VALUES ('http://www.google.com/','The Chocolate Factory');

INSERT INTO link (url,title) VALUES ('http://www.amazon.com/','Amazon');

--
-- Table: bookmark
--
CREATE TABLE bookmark (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  link INTEGER REFERENCES link(id)
);

INSERT INTO bookmark (link) VALUES (1);

--
-- Table: bookmark_with_link_proxy
--
CREATE TABLE bookmark_with_link_proxy (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  link INTEGER REFERENCES link(id)
);

INSERT INTO bookmark_with_link_proxy (link) VALUES (1);

--
-- Table: unicode_test
--
CREATE TABLE unicode_test (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  text CHARACTER
);

INSERT INTO unicode_test (text) VALUES ('ééé');

INSERT INTO unicode_test (text) VALUES ('®ç');

--
-- Table: noprimarykey
--
CREATE TABLE noprimarykey (
  foo integer NOT NULL,
  bar integer NOT NULL,
  baz integer NOT NULL
);

INSERT INTO noprimarykey (foo,bar,baz) VALUES (1,2,3);

INSERT INTO noprimarykey (foo,bar,baz) VALUES (4,5,6);

INSERT INTO noprimarykey (foo,bar,baz) VALUES (2,3,4);

--
-- Table: self_ref
--
CREATE TABLE self_ref (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name VARCHAR(100) NOT NULL,
  self_ref_id INTEGER REFERENCES self_ref(id)
);

INSERT INTO self_ref (name) VALUES ('harry');

INSERT INTO self_ref (name, self_ref_id) VALUES ('bob', 2);

INSERT INTO self_ref (name, self_ref_id) VALUES ('jim', 1);

--
-- Table: self_ref_alias
--
CREATE TABLE self_ref_alias (
  self_ref INTEGER NOT NULL REFERENCES self_ref(id),
  alias INTEGER NOT NULL REFERENCES self_ref(id),
  PRIMARY KEY (self_ref, alias)
);

INSERT INTO self_ref_alias (self_ref,alias) VALUES (1,2);

INSERT INTO self_ref_alias (self_ref,alias) VALUES (2,1);

--
-- Table: artist
--
CREATE TABLE artist (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  forename VARCHAR(255) NOT NULL,
  surname VARCHAR(255) NOT NULL,
  pseudonym VARCHAR(255),
  born DATE
);

INSERT INTO artist (forename,surname,pseudonym,born) VALUES ('Mike', 'Smith', 'Alpha Artist', '1970-02-28');

INSERT INTO artist (forename,surname,pseudonym,born) VALUES ('David', 'Brown', 'Band Beta', '1992-05-30');

INSERT INTO artist (forename,surname,pseudonym,born) VALUES ('Adam', 'Smith', 'Gamma Group', '1981-05-10');

--
-- Table: artist_undirected_map
--
CREATE TABLE artist_undirected_map (
  id1 INTEGER NOT NULL REFERENCES artist(id),
  id2 INTEGER NOT NULL REFERENCES artist(id),
  PRIMARY KEY (id1, id2)
);

INSERT INTO artist_undirected_map (id1,id2) VALUES (1,2);

INSERT INTO artist_undirected_map (id1,id2) VALUES (2,3);

--
-- View: aritsts_called_mike
--
CREATE VIEW artists_called_mike AS
    SELECT * FROM artist WHERE forename = 'Mike';

--
-- Reference Tables test, from rt.cpan.org #64455
--
CREATE TABLE reference (
  id INTEGER PRIMARY KEY AUTOINCREMENT
);

INSERT INTO reference (id) VALUES (1);

INSERT INTO reference (id) VALUES (2);

CREATE TABLE ref_a (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  reference INTEGER REFERENCES reference(id)
);

INSERT INTO ref_a (reference) VALUES (2);

CREATE TABLE ref_b (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  ref_a INTEGER REFERENCES ref_a(id),
  reference INTEGER REFERENCES reference(id)
);

INSERT INTO ref_b (ref_a, reference) VALUES (1,1);

INSERT INTO ref_b (ref_a, reference) VALUES (1,2);

