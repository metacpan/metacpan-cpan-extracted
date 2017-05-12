drop database if exists act_dict_test;
create database act_dict_test;
grant all on act_dict_test.* 
   to 'act_dict_user'@'localhost' identified by 'act_dict_pass';

use act_dict_test;

CREATE TABLE t1 (
   t1_id serial,
   lang          enum('en','de','es') default 'en',
   realm         varchar(64)  NOT NULL,
   key_prefix    varchar(128) NOT NULL,
   last_modified datetime NOT NULL,
   c1 varchar(256) NOT NULL,
   c2 varchar(256) not null,
   UNIQUE KEY IDX_db_dictionary_1 (realm,key_prefix,lang)
);


CREATE TABLE t2 (
   t2_id serial,
   lang          enum('en','de','es') default 'en',
   realm         varchar(64)  NOT NULL,
   key_prefix    varchar(128) NOT NULL,
   last_modified datetime NOT NULL,
   c1 varchar(256) NOT NULL,
   c2 varchar(256) not null,
   UNIQUE KEY IDX_db_dictionary_1 (realm,key_prefix,lang)
);

insert into t1 values ( default, 'en', 'realmdb1', 'k1', now(), 'en_t1_c1', 'en_t1_c2' );
insert into t1 values ( default, 'en', 'realmdb1', 'k2', now(), 'en_t1_c1', 'en_t1_c2' );
insert into t1 values ( default, 'en', 'realmdb2', 'k2', now(), 'en_t1_c1', 'en_t1_c2' );
insert into t2 values ( default, 'de', 'realmdb1', 'k1', now(), 'de_t2_c1', 'de_t2_c2' );
insert into t2 values ( default, 'de', 'realmdb2', 'k1', now(), 'de_t2_c1', 'de_t2_c2' );
insert into t2 values ( default, 'en', 'realmdb2', 'k2', now(), 'en_t2_c1', 'en_t2_c2' );

/* CREATES:
               'en' => {
                           'realmdb1' => {
                                           'k1.c1' => 'en_t1_c1',
                                           'k2.c1' => 'en_t1_c1',
                                           'k2.c2' => 'en_t1_c2',
                                           'k1.c2' => 'en_t1_c2'
                                         },
                           'realmdb2' => {
                                           'k2.c1' => 'en_t2_c1',
                                           'k2.c2' => 'en_t2_c2'
                                         },
                         },
                 'de' => {
                           'realmdb1' => {
                                           'k1.c1' => 'de_t2_c1',
                                           'k1.c2' => 'de_t2_c2'
                                         },
                           'realmdb2' => {
                                           'k1.c1' => 'de_t2_c1',
                                           'k1.c2' => 'de_t2_c2'
                                         }
                         },
*/