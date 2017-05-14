-- drop table languages;
-- drop table users;
-- drop table soa;
-- drop table rec_count;
-- drop table records_A;
-- drop table records_AAAA;
-- drop table records_CNAME;
-- drop table records_MX;
-- drop table records_NS;
-- drop table records_PTR;
-- drop table records_TXT;
-- drop table domains;
-- drop table tickets;
-- drop table ticketsecrets;
-- drop sequence languages_id;
-- drop sequence users_id;
-- drop sequence domains_id;
-- drop sequence records_A_id;
-- drop sequence records_AAAA_id;
-- drop sequence records_CNAME_id;
-- drop sequence records_MX_id;
-- drop sequence records_NS_id;
-- drop sequence records_PTR_id;
-- drop sequence records_TXT_id;

set escape \

create table languages (
  id number not null,
  lang varchar2(5) not null,
  language varchar2(255) not null,
  abbrev varchar2(5) not null,
  constraint languages_pk PRIMARY KEY (id)
);

create sequence languages_id increment by 1 start with 1;

insert into languages (id, lang, language, abbrev) values (languages_id.nextval,'en','English','en');
insert into languages (id, lang, language, abbrev) values (languages_id.nextval,'de','Deutsch','de');
insert into languages (id, lang, language, abbrev) values (languages_id.nextval,'dk','Dansk','da');
insert into languages (id, lang, language, abbrev) values (languages_id.nextval,'it','Italiano','it');
insert into languages (id, lang, language, abbrev) values (languages_id.nextval,'fr','Fran\&ccedil;ais','fr');
insert into languages (id, lang, language, abbrev) values (languages_id.nextval,'se','Svenska','sv');
insert into languages (id, lang, language, abbrev) values (languages_id.nextval,'br','Portuguese Brazil','pt-BR');

create table users (
  id number not null,
  username varchar2(20) not null,
  password varchar2(20) not null,
  email varchar2(255) not null,
  lang number(2) not null
     constraint lang_fk references languages(id),
  constraint users_pk primary key (id)
);

create sequence users_id increment by 1 start with 1;

create table domains (
  id number not null,
  domain varchar2(255) not null,
  owner number not null
     constraint users_fk references users(id),
  constraint domains_pk primary key (id)
);

create sequence domains_id increment by 1 start with 1;

create table soa (
  domain number not null
     constraint domain_fk references domains(id),
  auth_ns varchar2(255) not null, --  also the nameserver where the updates should go to
  email varchar2(255) not null,
  serial number(7) not null,
  refresh number(7) not null,
  retry number(7) not null,
  expire number(7) not null,
  default_ttl number(7) not null,
  rec_lock number(1) default '0' null
);

--  rec_count is MAX count of each type
create table rec_count (
  domain number not null
     constraint rec_c_domain_fk references domains(id),
  A_count number not null,
  AAAA_count number not null,
  CNAME_count number not null,
  MX_count number not null,
  NS_count number not null,
  PTR_count number not null,
  TXT_count number not null
);

create table records_A (
  id number not null,
  domain number not null
     constraint a_records_domain_fk references domains(id),
  name varchar2(255) not null,
  address varchar2(16) not null,
  ttl number(7) not null,
  rec_lock number(1) default 0 null,
  constraint records_a_pk primary key(id)
);

create sequence records_A_id increment by 1 start with 1;

create table records_AAAA (
  id number not null,
  domain number not null
     constraint aaaa_records_domain_fk references domains(id),
  name varchar2(255) not null,
  address varchar2(39) not null,
  ttl number(7) not null,
  rec_lock number(1) default 0 null,
  constraint records_aaaa_pk primary key(id)
);

create sequence records_AAAA_id increment by 1 start with 1;

create table records_CNAME (
  id number not null,
  domain number not null
     constraint cnames_domain_fk references domains(id),
  name varchar2(255) not null,
  cname varchar2(255) not null,
  ttl number(7) not null,
  rec_lock number(1) default 0 null,
  constraint records_cname_pk primary key (id)
);

create sequence records_CNAME_id increment by 1 start with 1;

create table records_MX (
  id number not null,
  domain number not null
     constraint mxrecords_domain_fk references domains(id),
  name varchar2(255) not null,
  exchanger varchar2(255) not null,
  preference number(3) not null,
  ttl number(7) not null,
  rec_lock number(1) default 0 null,
  constraint mxrecords_pk primary key (id)
);

create sequence records_MX_id increment by 1 start with 1;

create table records_NS (
  id number not null,
  domain number not null
     constraint nsrecords_domain_fk references domains(id),
  name varchar2(255) not null,
  nsdname varchar2(255) not null,
  ttl number(7) not null,
  rec_lock number(1) default 0 null,
  constraint nsrecords_pk primary key (id)
);

create sequence records_NS_id increment by 1 start with 1;

create table records_PTR (
  id number not null,
  domain number not null
     constraint ptr_records_domain_fk references domains(id),
  name varchar2(255) not null,
  ptrdname varchar2(255) not null,
  ttl number(7) not null,
  rec_lock number(1) default 0 null,
  constraint records_ptr_pk primary key(id)
);

create sequence records_PTR_id increment by 1 start with 1;

create table records_TXT (
  id number not null,
  domain number not null
     constraint txtrecords_domain_fk references domains(id),
  name varchar2(255) not null,
  txtdata varchar2(255) not null,
  ttl number(7) not null,
  rec_lock number(1) default 0 null,
  constraint txtrecords_pk  primary key (id)
);

create sequence records_TXT_id increment by 1 start with 1;

create table tickets (
  ticket_hash varchar2(32) not null,
  ts number(11) not null,
  constraint tickets_pk primary key (ticket_hash)
);

create table ticketsecrets (
  sec_version number(11),
  sec_data varchar2(16) NOT NULL
);

insert into ticketsecrets values (1,'dnszone');
  
