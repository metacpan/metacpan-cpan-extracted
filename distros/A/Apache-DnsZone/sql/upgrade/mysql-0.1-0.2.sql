insert into languages (lang, language, abbrev) values ('pt','Portuguese Brazil','pt-BR');

alter table rec_count add PTR_count integer default 0 null;
alter table rec_count add AAAA_count integer default 0 null;

create table records_AAAA (
  id integer not null auto_increment,
  domain integer not null,
  name varchar(255) not null,
  address varchar(39) not null,
  ttl int(7) not null,
  rec_lock int(1) default 0 null,
  primary key (id),
  foreign key (domain) references domains (id)
);

create table records_PTR (
  id integer not null auto_increment,
  domain integer not null,
  name varchar(255) not null,
  ptrdname varchar(255) not null,
  ttl int(7) not null,
  rec_lock int(1) default 0 null,
  primary key (id),
  foreign key (domain) references domains (id)
);
