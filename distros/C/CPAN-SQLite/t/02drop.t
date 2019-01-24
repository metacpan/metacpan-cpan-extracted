# $Id: 02drop.t 71 2019-01-15 01:46:34Z stro $

use strict;
use warnings;
use Test::More;
use DBD::SQLite;

plan tests => 6;

my $db_name = 't/dot-cpan/cpandb.sql';

my $dbh = DBI->connect("DBI:SQLite:$db_name", { RaiseError => 1, AutoCommit => 0 }) or die "Cannot connect to $db_name";
ok $dbh ;
isa_ok($dbh, 'DBI::db');

my @tables = qw(mods auths dists info);
my $sql    = 'SELECT name FROM sqlite_master WHERE type="table" AND name=?';
my $sth    = $dbh->prepare($sql);

foreach my $table (@tables) {
  $sth->execute($table);
  my $results = $sth->fetchrow_array;

  if ($results) {
    $dbh->do(qq{drop table $table});
    pass('Drop ' . $table);
  } else {
    pass('Skip ' . $table);
  }
}

$sth->finish;
$dbh->disconnect;
