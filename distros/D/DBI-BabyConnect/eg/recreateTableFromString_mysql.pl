#!/usr/bin/perl -w

use strict;

use DBI::BabyConnect;

my $dbhandle = DBI::BabyConnect->new('BABYDB_001');
$dbhandle-> HookTracing(">>/tmp/foo.log",3);


my $SQL=<<SQL;
drop table <<<TABLENAME>>>

~
create table <<<TABLENAME>>> (
ID bigint(20) unsigned NOT NULL AUTO_INCREMENT,
LOOKUP varchar(14) default NULL,
IMGNAME varchar(28) NOT NULL default '',
IMGAGE blob,
CHANGEDATE_T TIMESTAMP NOT NULL,
RECORDDATE_T TIMESTAMP NOT NULL,
PRIMARY KEY (ID), UNIQUE KEY ID (ID) ) ENGINE=MyISAM

SQL

$dbhandle-> recreateTableFromString($SQL,'IMAGES_TABLE');


