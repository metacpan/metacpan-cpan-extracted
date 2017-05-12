#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use lib './t';
use dbixtest;

plan tests => 2;

use_ok( 'DBIx::Raw' ) || print "Bail out!\n";

my $people = people();
my $db = prepare();
$db->raw(query=>"INSERT INTO dbix_raw (name) VALUES(?)", vals=>[$people->[0]->[0]], encrypt=>[0]);

my $id = $db->dbh->sqlite_last_insert_rowid();

my $encrypted_name = $db->raw("SELECT name FROM dbix_raw WHERE id=?", $id);

isnt($encrypted_name, $people->[0]->[0], 'Encrypt Name insert value');
