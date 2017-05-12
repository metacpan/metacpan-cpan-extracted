#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use lib './t';
use dbixtest;

plan tests => 3;

use_ok( 'DBIx::Raw' ) || print "Bail out!\n";

my $people = people();
my $db = prepare();
$db->raw(query=>"INSERT INTO dbix_raw (name,favorite_color) VALUES('$people->[0]->[0]',?)", vals=>[$people->[0]->[2]], encrypt=>[0]);

my $id = $db->dbh->sqlite_last_insert_rowid();

my ($name, $encrypted_color)= $db->raw("SELECT name FROM dbix_raw WHERE id=?", $id);

is($name, $people->[0]->[0], 'Name insert multiple value');
isnt($encrypted_color, $people->[0]->[2], 'Encrypt color insert value');
