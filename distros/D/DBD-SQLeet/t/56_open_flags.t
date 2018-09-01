#!/usr/bin/perl

use strict;

BEGIN {
  $|  = 1;
  $^W = 1;
}

use lib "t/lib";
use SQLeetTest;
use Test::More;

my $tests = 7;
plan tests => $tests;

use DBI;
use DBD::SQLeet;

my $dbfile = dbfile('foo');
unlink $dbfile if -f $dbfile;

{
  my $dbh = eval {
    DBI->connect("dbi:SQLeet:$dbfile", undef, undef, {
      PrintError => 0,
      RaiseError => 1,
      sqlite_open_flags => DBD::SQLeet::OPEN_READONLY,
    });
  };
  ok $@ && !$dbh && !-f $dbfile, "failed to open a nonexistent dbfile for readonly";
  unlink $dbfile if -f $dbfile;
}

{
  my $dbh = eval {
    DBI->connect("dbi:SQLeet:$dbfile", undef, undef, {
      PrintError => 0,
      RaiseError => 1,
      sqlite_open_flags => DBD::SQLeet::OPEN_READWRITE,
    });
  };
  ok $@ && !$dbh && !-f $dbfile, "failed to open a nonexistent dbfile for readwrite (without create)";
  unlink $dbfile if -f $dbfile;
}

{
  my $dbh = eval {
    DBI->connect("dbi:SQLeet:$dbfile", undef, undef, {
      PrintError => 0,
      RaiseError => 1,
      sqlite_open_flags => DBD::SQLeet::OPEN_READWRITE|DBD::SQLeet::OPEN_CREATE,
    });
  };
  ok !$@ && $dbh && -f $dbfile, "created a dbfile for readwrite";
  $dbh->disconnect;
  unlink $dbfile if -f $dbfile;
}

{
  eval {
    DBI->connect("dbi:SQLeet:$dbfile", undef, undef, {
      PrintError => 0,
      RaiseError => 1,
    });
  };
  ok !$@ && -f $dbfile, "created a dbfile";

  my $dbh = eval {
    DBI->connect("dbi:SQLeet:$dbfile", undef, undef, {
      PrintError => 0,
      RaiseError => 1,
      sqlite_open_flags => DBD::SQLeet::OPEN_READONLY,
    });
  };
  ok !$@ && $dbh, "opened an existing dbfile for readonly";
  $dbh->disconnect;
  unlink $dbfile if -f $dbfile;
}

{
  eval {
    DBI->connect("dbi:SQLeet:$dbfile", undef, undef, {
      PrintError => 0,
      RaiseError => 1,
    });
  };
  ok !$@ && -f $dbfile, "created a dbfile";

  my $dbh = eval {
    DBI->connect("dbi:SQLeet:$dbfile", undef, undef, {
      PrintError => 0,
      RaiseError => 1,
      sqlite_open_flags => DBD::SQLeet::OPEN_READWRITE,
    });
  };
  ok !$@ && $dbh, "opened an existing dbfile for readwrite";
  $dbh->disconnect;
  unlink $dbfile if -f $dbfile;
}
