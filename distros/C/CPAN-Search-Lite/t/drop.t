#!/usr/bin/perl
use strict;
use warnings;
use Test;
use DBI;
BEGIN {plan tests => 7};
my ($db, $user, $passwd) = ('test', 'test', '');

my $dbh = DBI->connect("DBI:mysql:$db", $user, $passwd,
                       {RaiseError => 1, AutoCommit => 0})
  or die "Cannot connect to $db";
ok($dbh);
my @tables = qw(mods auths chaps dists ppms reqs);
for my $table(@tables) {
  $dbh->do(qq{drop table if exists $table});
  ok(1);
}
$dbh->disconnect;
