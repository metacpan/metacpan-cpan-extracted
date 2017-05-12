#drop table languages;
#drop table users;
#drop table soa;
#drop table rec_count;
#drop table records_A;
#drop table records_CNAME;
#drop table records_MX;
#drop table records_NS;
#drop table records_TXT;
#drop table domains;
#drop table tickets;
#drop table ticketsecrets;
#drop sequence languages_id
#drop sequence users_id
#drop sequence domains_id
#drop sequence records_A_id
#drop sequence records_CNAME_id
#drop sequence records_MX_id
#drop sequence records_NS_id
#drop sequence records_TXT_id

create table languages (
  id integer not null,
  lang varchar(2) not null,
  language varchar(255) not null,
  abbrev varchar(2) not null,
  primary key (id)
);

create sequence languages_id increment by 1 start with 1;

insert into languages (id, lang, language, abbrev) values (languages_id.nextval,'en','English','en');
insert into languages (id, lang, language, abbrev) values (languages_id.nextval,'de','Deutsch','de');
insert into languages (id, lang, language, abbrev) values (languages_id.nextval,'dk','Dansk','da');
insert into languages (id, lang, language, abbrev) values (languages_id.nextval,'it','Italiano','it');
insert into languages (id, lang, language, abbrev) values (languages_id.nextval,'fr','Fran&ccedil;ais','fr');
insert into languages (id, lang, language, abbrev) values (languages_id.nextval,'se','Svenska','sv');

create table users (
  id integer not null,
  username varchar(20) not null,
  password varchar(20) not null,
  email varchar(255) not null,
  lang int(2) not null,
  primary key (id),
  foreign key (lang) references languages (id)
);

create sequence users_id increment by 1 start with 1;

create table domains (
  id integer not null,
  domain varchar(255) not null,
  owner integer not null,
  primary key (id),
  foreign key (owner) references users (id)
);

create sequence domains_id increment by 1 start with 1;

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
  id integer not null,
  domain integer not null,
  name varchar(255) not null,
  address varchar(16) not null,
  ttl int(7) not null,
  rec_lock int(1) default 0 null,
  primary key (id),
  foreign key (domain) references domains (id)
);

create sequence records_A_id increment by 1 start with 1;

create table records_CNAME (
  id integer not null,
  domain integer not null,
  name varchar(255) not null,
  cname varchar(255) not null,
  ttl int(7) not null,
  rec_lock int(1) default 0 null,
  primary key (id),
  foreign key (domain) references domains (id)
);

create sequence records_CNAME_id increment by 1 start with 1;

create table records_MX (
  id integer not null,
  domain integer not null,
  name varchar(255) not null,
  exchanger varchar(255) not null,
  preference int(3) not null,
  ttl int(7) not null,
  rec_lock int(1) default 0 null,
  primary key (id),
  foreign key (domain) references domains (id)
);

create sequence records_MX_id increment by 1 start with 1;

create table records_NS (
  id integer not null,
  domain integer not null,
  name varchar(255) not null,
  nsdname varchar(255) not null,
  ttl int(7) not null,
  rec_lock int(1) default 0 null,
  primary key (id),
  foreign key (domain) references domains (id)
);

create sequence records_NS_id increment by 1 start with 1;

create table records_TXT (
  id integer not null,
  domain integer not null,
  name varchar(255) not null,
  txtdata varchar(255) not null,
  ttl int(7) not null,
  rec_lock int(1) default 0 null,
  primary key (id),
  foreign key (domain) references domains (id)
);

create sequence records_TXT_id increment by 1 start with 1;

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
  
