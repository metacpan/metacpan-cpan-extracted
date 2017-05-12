-- Test SQL script; run this in your database to test DBIx::ORM::Declarative
-- This one is MySQL specific; will need a bit of tweakage for Oracle

drop table if exists dod_test2;
drop table if exists dod_test1;

create table dod_test1
(
    recid int(10) unsigned primary key auto_increment,
    name varchar(250) not null default ''
) ;

create table dod_test2
(
    recid int(10) unsigned primary key auto_increment,
    nameid int(100) unsigned not null default 0
        references dod_test1,
    value varchar(250) not null default ''
) ;
