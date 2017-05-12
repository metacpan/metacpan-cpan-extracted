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
$db->raw(query=>"UPDATE dbix_raw SET name=? WHERE id=?", vals=>['Billy Boy', 1], encrypt=>'*');

my ($encrypted_name)= $db->raw("SELECT name FROM dbix_raw WHERE id=?", 1);

isnt($encrypted_name, $people->[0]->[0], 'Name where not encrypted');
