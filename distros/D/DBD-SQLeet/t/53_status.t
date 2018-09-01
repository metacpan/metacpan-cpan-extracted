#!/usr/bin/perl

use strict;

BEGIN {
  $|  = 1;
  $^W = 1;
}

use lib "t/lib";
use SQLeetTest qw/connect_ok @CALL_FUNCS/;
use Test::More;
use Test::NoWarnings;

my $tests = 3;

plan tests => 4 + $tests * @CALL_FUNCS + 1;

my $dbh = connect_ok();
{
  $dbh->do('create table foo (id integer primary key, text)');
  my $sth = $dbh->prepare('insert into foo values(?, ?)');
  $sth->execute($_, "text$_") for 1..100;
}

{
  my $status = DBD::SQLeet::sqlite_status();
  ok $status && ref $status eq ref {}, "status is a hashref";
  my $num_of_keys = scalar keys %$status;
  ok $num_of_keys, "status: $num_of_keys indicators";
  my $used_mem = $status->{memory_used}{current};
  ok defined $used_mem && $used_mem, "current used memory: $used_mem";
}

for my $func (@CALL_FUNCS) {
  {
    my $db_status = $dbh->$func('db_status');
    ok $db_status && ref $db_status eq ref {}, "db status is a hashref";
    my $num_of_keys = scalar keys %$db_status;
    ok $num_of_keys, "db status: $num_of_keys indicators";
  }

  {
    my $sth = $dbh->prepare('select * from foo where text = ? order by text desc');
    $sth->execute("text1");
    my $st_status = $sth->$func('st_status');
    ok $st_status && ref $st_status eq ref {}, "st status is a hashref";
  }
}
