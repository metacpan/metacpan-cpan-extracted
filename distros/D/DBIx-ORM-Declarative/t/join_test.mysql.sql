-- Test SQL script; run this in your database to test DBIx::ORM::Declarative
-- This one is MySQL specific; will need a bit of tweakage for Oracle

drop table if exists person;
drop table if exists address;

create table address
(
    recid int(10) unsigned primary key auto_increment,
    addr1 varchar(250) not null default '',
    addr2 varchar(250),
    city varchar(250) not null default '',
    state char(2) not null default 'NC',
    zip char(9) not null default '',
    unique key (addr1, city, state),
    unique key (addr1, zip)
) ;

create table person
(
    recid int(10) unsigned primary key auto_increment,
    name varchar(250) default '' not null,
    home_addr_id int(10) unsigned not null default 0
        references address(recid),
    work_addr_id int(10) unsigned not null default 0
        references address(recid),
    email varchar(250) not null default '',
    phone varchar(30),
    unique key (name, home_addr_id),
    unique key (email)
) ;
