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
$db->raw(query=>"UPDATE dbix_raw SET name=?,favorite_color=? WHERE id=?", vals=>[$people->[0]->[0], $people->[0]->[2], 1], encrypt=>'*');

my $decrypted_name = $db->raw(query=>"SELECT name FROM dbix_raw WHERE id=?", vals=>[1], decrypt=> '*');

is($decrypted_name, $people->[0]->[0], 'Decrypt Star Name Scalar');
