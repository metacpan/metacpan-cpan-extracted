CREATE TABLE publication (
    publication_id      integer(11) not null AUTO_INCREMENT PRIMARY KEY,
    publication_name    varchar(128) not null
);

CREATE TABLE author (
);

CREATE TABLE journal (
);

CREATE TABLE evidence (
   evidence_id          integer(11) not null AUTO_INCREMENT PRIMARY KEY,
   protocol_id		integer(11) not null,
   publication_id       integer(11),
   type
   score
   date_run
);

CREATE TABLE protocol (
   protocol_id		integer(11) not null AUTO_INCREMENT PRIMARY KEY,
   description          text not null,
);
