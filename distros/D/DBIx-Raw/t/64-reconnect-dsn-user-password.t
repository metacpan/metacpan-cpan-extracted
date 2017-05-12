#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use lib './t';
use dbixtest;

plan tests => 2;

use_ok( 'DBIx::Raw' ) || print "Bail out!\n";

my $db = prepare();
my $dbh = $db->dbh;

$db->conf(undef);

$db->dsn(dsn());
$db->user(user());
$db->password(password());

$db->connect;

isnt($db->dbh, $dbh, "New dbh shouldn't equal old dbh");
