require 'dbconn.pl';
use DBI;
use strict;


use vars qw(%sql);
$sql{authors} =<<EOSQL;
create table IF NOT EXISTS  authors	(
       au_id char(11) not null,
       au_lname varchar(40) not null,
       au_fname varchar(20) not null,
       phone char(12) null,
       address varchar(40) null,
       city varchar(20) null,
       state char(2) null,
       zip char(5) null);
EOSQL


$sql{publishers} =<<EOSQL;
create table IF NOT EXISTS  publishers	(
       pub_id char(4) not null,
       pub_name varchar(40) null,
       address varchar(40) null,
       city varchar(20) null,
       state char(2) null);
EOSQL


$sql{roysched} =<<EOSQL;
create table IF NOT EXISTS roysched (
       title_id char(6) not null,
       lorange int null,
       hirange int null,
       royalty decimal(5,2) null);
EOSQL


$sql{titleauthors} =<<EOSQL;
create table IF NOT EXISTS  titleauthors	(
       au_id char(11) not null,
       title_id char(6) not null,
       au_ord tinyint null,
       royaltyshare decimal(5,2) null);
EOSQL


$sql{titles} =<<EOSQL;
create table IF NOT EXISTS  titles	(
       title_id char(6) not null,
       title varchar(80) not null,
       type char(12) null,
       pub_id char(4) null,
       price numeric(8,2) null,
       advance numeric(10,2) null,
       ytd_sales int null,
       contract bit not null,
       notes varchar(200) null,
       pubdate date null);
EOSQL


$sql{editors} =<<EOSQL;
create table IF NOT EXISTS  editors	(
       ed_id char(11) not null,
       ed_lname varchar(40) not null,
       ed_fname varchar(20) not null,
       ed_pos varchar(12) null,
       phone char(12) null,
       address varchar(40) null,
       city varchar(20) null,
       state char(2) null,
       zip char(5) null,
       ed_boss char(11) null );
EOSQL

$sql{titleeditors} =<<EOSQL;
create table IF NOT EXISTS  titleditors	(
       ed_id char(11) not null,
       title_id char(6) not null,
       ed_ord tinyint null);
EOSQL

$sql{sales} =<<EOSQL;
create table IF NOT EXISTS  sales	(
       sonum int not null,
       stor_id char(4) not null,
       ponum varchar(20) not null,
       sdate date null);
EOSQL

$sql{salesdetails} =<<EOSQL;
create table IF NOT EXISTS  salesdetails	(
       sonum int not null,
       qty_ordered smallint not null,
       qty_shipped smallint null,
       title_id char(6) not null,
       date_shipped date null);
EOSQL

my %index;
my $index =<<EOSQL;
create unique index pubind on publishers (pub_id);
create unique index auidind on authors (au_id);
create index aunmind on authors (au_lname, au_fname);
create unique index titleidind on titles (title_id);
create index titleind on titles (title);
create unique index taind on titleauthors (au_id, title_id);
create unique index edind on editors (ed_id);
create index ednmind on editors (ed_lname, ed_fname);
create unique index teind on titleditors (ed_id, title_id);
create index rstidind on roysched (title_id);
create unique index sdind on salesdetails (sonum, title_id) ;
create unique index salesind on sales (sonum);
EOSQL

my @index = split ';', $index;
for (@index) {
    /create unique index (\w+)/ and $index{$1} = $_;
}


my $dbh = dbh();


#$dbh->do('use test');
$dbh->do($person_tbl);
$dbh->do($country_tbl);
for (keys %sql) {
    warn $_;
    $dbh->do($sql{$_});
}

for (keys %index) {
    warn "*$_*";
   $dbh->do($index{$_});
}
