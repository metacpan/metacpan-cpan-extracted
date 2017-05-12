use strict;
use warnings;
use Test::More;
use Algorithm::SpatialIndex;

my $do_unlink = !$ENV{PERL_ASI_TESTING_PRESERVE};

my $tlibpath;
BEGIN {
  $tlibpath = -d "t" ? "t/lib" : "lib";
}
use lib $tlibpath;

if (not eval {require DBI; require DBD::SQLite; 1;}) {
  plan skip_all => 'These tests require DBI and DBD::SQLite';
}
plan tests => 64;

my $dbfile = '31strategy-mquadtree-dbi.test.sqlite';
unlink $dbfile if -f $dbfile;

my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile", "", "");
ok(defined($dbh), 'got dbh');

END {
  unlink $dbfile if $do_unlink;
}

use Algorithm::SpatialIndex::MQTreeTest;
Algorithm::SpatialIndex::MQTreeTest->run('DBI', dbh_rw => $dbh);

