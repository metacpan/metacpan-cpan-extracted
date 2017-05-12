#drop table languages;
#drop table users;
#drop table domains;
#drop table soa;
#drop table rec_count;
#drop table records_A;
#drop table records_CNAME;
#drop table records_MX;
#drop table records_NS;
#drop table records_TXT;
#drop table tickets;
#drop table ticketsecrets;

create table languages (
  id integer not null auto_increment,
  lang varchar(2) not null,
  language varchar(255) not null,
  abbrev varchar(2) not null,
  primary key (id)
);

insert into languages (lang, language, abbrev) values ('en','English','en');
insert into languages (lang, language, abbrev) values ('de','Deutsch','de');
insert into languages (lang, language, abbrev) values ('dk','Dansk','da');
insert into languages (lang, language, abbrev) values ('it','Italiano','it');
insert into languages (lang, language, abbrev) values ('fr','Fran&ccedil;ais','fr');
insert into languages (lang, language, abbrev) values ('se','Svenska','sv');

create table users (
  id integer not null auto_increment,
  username varchar(20) not null,
  password varchar(20) not null,
  email varchar(255) not null,
  lang int(2) not null,
  primary key (id),
  foreign key (lang) references languages (id)
);

create table domains (
  id integer not null auto_increment,
  domain varchar(255) not null,
  owner integer not null,
  primary key (id),
  foreign key (owner) references users (id)
);

create table soa (
  domain integer not null,
  auth_ns varchar(255) not null, # also the nameserver where the updates should go to
  email varchar(255) not null,
  serial int(7) not null,
  refresh int(7) not null,
  retry int(7) not null,
  expire int(7) not null,
  default_ttl int(7) not null,
  rec_lock int(1) default '0' null,
  foreign key (domain) references domains (id)
);

# rec_count is MAX count of each type
create table rec_count (
  domain integer not null,
  A_count integer not null,
  CNAME_count integer not null,
  MX_count integer not null,
  NS_count integer not null,
  TXT_count integer not null,
  foreign key (domain) references domains (id)
);

create table records_A (
  id integer not null auto_increment,
  domain integer not null,
  name varchar(255) not null,
  address varchar(16) not null,
  ttl int(7) not null,
  rec_lock int(1) default 0 null,
  primary key (id),
  foreign key (domain) references domains (id)
);

create table records_CNAME (
  id integer not null auto_increment,
  domain integer not null,
  name varchar(255) not null,
  cname varchar(255) not null,
  ttl int(7) not null,
  rec_lock int(1) default 0 null,
  primary key (id),
  foreign key (domain) references domains (id)
);

create table records_MX (
  id integer not null auto_increment,
  domain integer not null,
  name varchar(255) not null,
  exchanger varchar(255) not null,
  preference int(3) not null,
  ttl int(7) not null,
  rec_lock int(1) default 0 null,
  primary key (id),
  foreign key (domain) references domains (id)
);

create table records_NS (
  id integer not null auto_increment,
  domain integer not null,
  name varchar(255) not null,
  nsdname varchar(255) not null,
  ttl int(7) not null,
  rec_lock int(1) default 0 null,
  primary key (id),
  foreign key (domain) references domains (id)
);

create table records_TXT (
  id integer not null auto_increment,
  domain integer not null,
  name varchar(255) not null,
  txtdata varchar(255) not null,
  ttl int(7) not null,
  rec_lock int(1) default 0 null,
  primary key (id),
  foreign key (domain) references domains (id)
);

create table tickets (
  ticket_hash char(32) not null default '',
  ts int(11) not null default '0',
  primary key (ticket_hash)
);

create table ticketsecrets (
  sec_version int(11) default NULL,
  sec_data text NOT NULL
);

insert into ticketsecrets values (1,'dnszone');
  
