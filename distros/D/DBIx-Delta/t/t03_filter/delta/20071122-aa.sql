-- Create table aa

create table aa (
    id      integer primary key,
    name    varchar not null
);
insert into aa values ( 1, 'aa1' );
grant all on aa to test@localhost;

-- table: aa
-- tag: d5ae8840-2848-4382-88e8-61bf65e8e9ec

