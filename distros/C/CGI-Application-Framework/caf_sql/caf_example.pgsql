
--
-- Table structure for table "album"
--

 DROP TABLE "album";
 DROP SEQUENCE "album_album_id_seq";
 CREATE TABLE "album" (
   "album_id" SERIAL NOT NULL ,
   "artist_id" integer default '0',
   "album_name" varchar(100) default '',
   "album_year" integer default '0',
   PRIMARY KEY  ("album_id")
 ) ;

 CREATE INDEX "album_year" on album ("album_year");
 CREATE INDEX "artist_id"  on album ("artist_id");
 CREATE INDEX "album_name" on album ("album_name");

 --
 -- Table structure for table "album_song"
 --

 DROP TABLE "album_song";
 DROP SEQUENCE "album_song_id_seq";
 CREATE TABLE "album_song" (
   "id" SERIAL NOT NULL,
   "album_id" INTEGER NOT NULL ,
   "song_id" INTEGER   NOT NULL ,
   "track_num" integer default '0',
   PRIMARY KEY  ("id")
 ) ;
 CREATE INDEX "album_id" on album_song ("album_id");
 CREATE INDEX "song_id" on album_song ("song_id");
 CREATE UNIQUE INDEX "album_song_id" on album_song ("album_id", "song_id");

 --
 -- Table structure for table "artist"
 --

 DROP TABLE "artist";
 DROP SEQUENCE "artist_artist_id_seq";
 CREATE TABLE "artist" (
   "artist_id" SERIAL NOT NULL,
   "artist_name" varchar(100) default '',
   PRIMARY KEY  ("artist_id")
 ) ;
 CREATE INDEX "artist_name" on artist ("artist_name");

 --
 -- Table structure for table "song"
 --

 DROP TABLE "song";
 DROP SEQUENCE "song_song_id_seq";
 CREATE TABLE "song" (
   "song_id" SERIAL NOT NULL ,
   "artist_id" integer default '0',
   "song_name" varchar(100) default '',
   PRIMARY KEY  ("song_id")
 ) ;
 CREATE INDEX "song_name" on song ("song_name");
 CREATE INDEX "song_artist_id" on song ("artist_id");

 --
 -- Table structure for table "user_album"
 --

 DROP TABLE "user_album";
 DROP SEQUENCE "user_album_id_seq";
 CREATE TABLE "user_album" (
   "id" SERIAL NOT NULL ,
   "user_id" INTEGER NOT NULL ,
   "album_id" INTEGER NOT NULL,
   PRIMARY KEY  ("id")
 ) ;

 CREATE INDEX "user_id" on user_album ("user_id");
 CREATE INDEX "user_album_album_id" on user_album ("album_id");
 CREATE UNIQUE INDEX "user_album_user_album_id" on user_album ("user_id", "album_id");

 --
 -- Dumping data for table "user_album"
 --

 INSERT INTO "user_album" VALUES (NEXTVAL('user_album_id_seq'), 1,1);
 INSERT INTO "user_album" VALUES (NEXTVAL('user_album_id_seq'), 1,3);
 INSERT INTO "user_album" VALUES (NEXTVAL('user_album_id_seq'), 1,4);
 INSERT INTO "user_album" VALUES (NEXTVAL('user_album_id_seq'), 1,6);
 INSERT INTO "user_album" VALUES (NEXTVAL('user_album_id_seq'), 1,7);
 INSERT INTO "user_album" VALUES (NEXTVAL('user_album_id_seq'), 2,1);
 INSERT INTO "user_album" VALUES (NEXTVAL('user_album_id_seq'), 2,2);
 INSERT INTO "user_album" VALUES (NEXTVAL('user_album_id_seq'), 2,6);
 INSERT INTO "user_album" VALUES (NEXTVAL('user_album_id_seq'), 2,7);

 --
 -- Table structure for table "users"
 --

 DROP TABLE "users";
 DROP SEQUENCE "users_uid_seq";
 CREATE TABLE "users" (
   "uid" SERIAL NOT NULL,
   "username" varchar(50) NOT NULL default '',
   "fullname" varchar(100) NOT NULL default '',
   "password" varchar(50) NOT NULL default '',
   PRIMARY KEY  ("uid")
 ) ;
 CREATE UNIQUE INDEX "username" on users ("username");
 CREATE INDEX "fullname" on users ("fullname");

 --
 -- Dumping data for table "users"
 --

 INSERT INTO "users" VALUES (NEXTVAL('users_uid_seq'),'rdice','Richard Dice','foobar');
 INSERT INTO "users" VALUES (NEXTVAL('users_uid_seq'),'woody','Sheriff Woody','buckaroo');
 INSERT INTO "users" VALUES (NEXTVAL('users_uid_seq'),'pete','Prospector Pete','doggie');
 INSERT INTO "users" VALUES (NEXTVAL('users_uid_seq'),'buzz','Buzz Lightyear','infinity');



