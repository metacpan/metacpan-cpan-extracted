#!/usr/bin/perl -w

use strict;

use DBI::BabyConnect;

my $dbhandle = DBI::BabyConnect->new('OK');
$dbhandle-> HookTracing(">>/tmp/foo.log",3);


my $SQL=<<SQL;
drop trigger BIR_<<<TABLENAME>>>
~
drop table <<<TABLENAME>>>

~
drop sequence <<<TABLENAME>>>_SEQ

~
create table <<<TABLENAME>>> (
ID number(20) NOT NULL,
LOOKUP varchar2(14) DEFAULT NULL,
IMGNAME varchar2(28) DEFAULT NULL,
IMAGE blob,
CHANGEDATE_T timestamp NOT NULL,
RECORDDATE_T timestamp NOT NULL
)

~
-- create a sequence
create sequence <<<TABLENAME>>>_SEQ

~
-- do not forget the ; at the end of the trigger
create trigger BIR_<<<TABLENAME>>>
before insert on <<<TABLENAME>>>
for each row
begin
	select <<<TABLENAME>>>_SEQ.nextval into :new.ID from dual;
end;

~alter table <<<TABLENAME>>> add constraint <<<TABLENAME>>>_PK primary key(ID)

SQL

$dbhandle-> recreateTableFromString($SQL,'IMAGES_TABLE');

