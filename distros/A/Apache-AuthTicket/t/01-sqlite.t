#!perl
# this test case sets up the SQLite database that will be used for testing

use strict;
use Test::More;
use File::Basename qw(dirname);
use File::Spec::Functions qw(catfile);
use File::Path qw(mkpath);
use DBI;
use Fatal qw(unlink mkpath);

unless (eval { require DBD::SQLite }) {
    plan skip_all => 'DBD::SQLite is not installed';
    exit 0;
}

plan tests => 1;

my $dbfile = catfile( dirname(__FILE__), qw(db test.db) );

if (-f $dbfile) {
    unlink $dbfile;
}

unless (-d dirname $dbfile) {
    mkpath dirname $dbfile;
}

my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile");

$/ = ";\n";
while (<DATA>) {
    chomp;
    next unless /\S/;
    unless ($dbh->do($_)) {
        diag $_;
        fail "sqlite command failure: $DBI::errstr";
        exit 1;
    }
}

pass "sqlite setup";

# vim: ft=perl

__DATA__
create table tickets (
    t_hash varchar(32) not null,
    update_ts integer not null,
    primary key (t_hash)
);

create table t_users (
    usrname varchar(8) not null,
    passwd varchar(8) not null,
    primary key (usrname)
);

create table t_secret (
    s_version int primary key,
    s_data text
);

insert into t_secret (s_version, s_data) values (1, 'mvkj39vek@#$R*njdea9@#');

insert into t_users (usrname, passwd) values ('programmer', 'secret');
