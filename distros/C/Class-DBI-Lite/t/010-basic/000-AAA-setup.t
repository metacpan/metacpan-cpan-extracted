#!/usr/bin/perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';
use DBI;

my $dbh = DBI->connect('DBI:SQLite:dbname=t/testdb', '', '', {
  RaiseError => 1,
  ChopBlanks => 1,
});

$dbh->do('DROP TABLE IF EXISTS users');
$dbh->do('DROP TABLE IF EXISTS zipcodes');
$dbh->do('DROP TABLE IF EXISTS cities');
$dbh->do('DROP TABLE IF EXISTS states');

$dbh->do(<<'SQL');
create table users (
  user_id   integer not null primary key,
  user_first_name   varchar(50),
  user_last_name    varchar(50),
  user_email        varchar(100)
);
SQL

$dbh->do(<<'SQL');
create table states (
  state_id    integer not null primary key,
  state_name  varchar(50) not null,
  state_abbr  char(2) not null
);
SQL

$dbh->do(<<'SQL');
create table cities (
  city_id   integer not null primary key,
  state_id  integer not null,
  city_name varchar(100) not null,
  foreign key (state_id) references states (state_id) on delete restrict
);
SQL

$dbh->do(<<'SQL');
create table zipcodes (
  zipcode_id  integer not null primary key,
  city_id     integer not null,
  zipcode     char(5) not null,
  foreign key (city_id) references cities (city_id) on delete restrict
);
SQL

ok(1, 'created all the tables');

