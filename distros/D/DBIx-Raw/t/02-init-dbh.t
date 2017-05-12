#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use lib './t';
use dbixtest;
use DBI;

plan tests => 2;

use_ok( 'DBIx::Raw' ) || print "Bail out!\n";

my $db;

my $dbh = DBI->connect(dsn(), user(), password());

isa_ok($db = DBIx::Raw->new(dbh => $dbh), 'DBIx::Raw');
