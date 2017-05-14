begin work;

create table languages (
  id serial not null,
  lang char(2) not null,
  language varchar(255) not null,
  abbrev char(5) not null,
  primary key (id)
);

insert into languages (lang, language, abbrev) values ('en','English','en');
insert into languages (lang, language, abbrev) values ('de','Deutsch','de');
insert into languages (lang, language, abbrev) values ('dk','Dansk','da');
insert into languages (lang, language, abbrev) values ('it','Italiano','it');
insert into languages (lang, language, abbrev) values ('fr','Fran&ccedil;ais','fr');
insert into languages (lang, language, abbrev) values ('se','Svenska','sv');
insert into languages (lang, language, abbrev) values ('br','Portuguese Brazil','pt-BR');

create table users (
  id serial not null,
  username varchar(20) not null,
  password varchar(20) not null,
  email varchar(255) not null,
  lang int not null,
  primary key (id),
  foreign key (lang) references languages(id)
);

create table domains (
  id serial not null,
  domain varchar(255) not null,
  owner integer not null,
  primary key (id),
  foreign key (owner) references users (id)
);

create table soa (
  domain integer not null,
  auth_ns varchar(255) not null, -- also the nameserver where the updates should go to
  email varchar(255) not null,
  serial int not null,
  refresh int not null,
  retry int not null,
  expire int not null,
  default_ttl int not null,
  rec_lock int default '0' null,
  foreign key (domain) references domains (id)
);

-- rec_count is MAX count of each type
create table rec_count (
  domain integer not null,
  A_count integer not null,
  AAAA_count integer not null,
  CNAME_count integer not null,
  MX_count integer not null,
  NS_count integer not null,
  PTR_count integer not null,
  TXT_count integer not null,
  foreign key (domain) references domains (id)
);

create table records_A (
  id serial not null,
  domain integer not null,
  name varchar(255) not null,
  address varchar(16) not null,
  ttl int not null,
  rec_lock int default 0 null,
  primary key (id),
  foreign key (domain) references domains (id)
);

create table records_AAAA (
  id serial not null,
  domain integer not null,
  name varchar(255) not null,
  address varchar(39) not null,
  ttl int not null,
  rec_lock int default 0 null,
  primary key (id),
  foreign key (domain) references domains (id)
);

create table records_CNAME (
  id serial not null,
  domain integer not null,
  name varchar(255) not null,
  cname varchar(255) not null,
  ttl int not null,
  rec_lock int default 0 null,
  primary key (id),
  foreign key (domain) references domains (id)
);

create table records_MX (
  id serial not null,
  domain integer not null,
  name varchar(255) not null,
  exchanger varchar(255) not null,
  preference int not null,
  ttl int not null,
  rec_lock int default 0 null,
  primary key (id),
  foreign key (domain) references domains (id)
);

create table records_NS (
  id serial not null,
  domain integer not null,
  name varchar(255) not null,
  nsdname varchar(255) not null,
  ttl int not null,
  rec_lock int default 0 null,
  primary key (id),
  foreign key (domain) references domains (id)
);

create table records_PTR (
  id serial not null,
  domain integer not null,
  name varchar(255) not null,
  ptrdname varchar(255) not null,
  ttl int not null,
  rec_lock int default 0 null,
  primary key (id),
  foreign key (domain) references domains (id)
);

create table records_TXT (
  id serial not null,
  domain integer not null,
  name varchar(255) not null,
  txtdata varchar(255) not null,
  ttl int not null,
  rec_lock int default 0 null,
  primary key (id),
  foreign key (domain) references domains (id)
);

create table tickets (
  ticket_hash char(32) not null default '',
  ts int not null default '0',
  primary key (ticket_hash)
);

create table ticketsecrets (
  sec_version int default NULL,
  sec_data text NOT NULL
);

insert into ticketsecrets values (1,'dnszone');

commit work;

