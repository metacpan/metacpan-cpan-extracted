#!/usr/bin/perl -w
use strict;
use DBI;

=head1 USAGE

This program creates the sample database
and sets up the tables.

=cut

my $dbh = DBI->connect('dbi:SQLite:dbname=db/seed.sqlite',undef,undef,{RaiseError => 1});
$/ = ";\n";
while (<DATA>) {
    chomp;
    next unless /\S/;
    #warn $_;
    $dbh->do($_);
}

__DATA__

create table code_live (
    name varchar(256) not null primary key,
    code varchar(65536) not null
);

create table code_history (
    version integer primary key not null,
    timestamp varchar(15) not null,
    name varchar(256) not null,
    action varchar(1) not null, -- IUD, redundant with old_* and new_*
    old_code varchar(65536) not null,
    new_code varchar(65536) not null
);
create index idx_history_version on code_history (version);