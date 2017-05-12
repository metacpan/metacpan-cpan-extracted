-- Create table bb

create table bb (
    id      integer primary key,
    code    varchar not null
);

insert into bb values ( 1, 'bb1' );
insert into bb values ( 2, 'bb2''bb2' );
--insert into bb values ( 3, 'bb3' );
insert into bb values ( 4, 'bb4;bb4' );
insert into bb values ( 5, 'bb5' );
grant all select, insert, update on aa to test@localhost;

-- table: bb
-- delta-tag: aa6f727f-0731-421d-82cd-5d35839c5877

