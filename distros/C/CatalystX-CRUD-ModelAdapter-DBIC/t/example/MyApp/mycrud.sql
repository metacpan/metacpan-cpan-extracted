/* example SQL file to init db */

 create table albums
 (
    id      INTEGER primary key,
    title   varchar(128),
    artist  varchar(128)
 );

 create table songs
 (
    id      INTEGER primary key,
    title   varchar(128),
    artist  varchar(128),
    length  varchar(16)
 );

 create table album_songs
 (
    id          INTEGER primary key,
    album_id    int not null references albums(id),
    song_id     int not null references songs(id) 
 );

 insert into albums (title, artist) values ('Blonde on Blonde', 'Bob Dylan');
 insert into songs  (title, length) values ('Visions of Johanna', '8:00');
 insert into album_songs (album_id, song_id) values (1, 1);

