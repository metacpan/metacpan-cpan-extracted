#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use lib './t';
use dbixtest;

plan tests => 5;

use_ok( 'DBIx::Raw' ) || print "Bail out!\n";

my $people = people();
my $db = prepare();
$db->raw(query=>"UPDATE dbix_raw SET name=?,favorite_color=? WHERE id=?", vals=>[$people->[0]->[0], $people->[0]->[2],1], encrypt=>'*');

my ($encrypted_name, $encrypted_color) = $db->raw("SELECT name,favorite_color FROM dbix_raw WHERE id=?", 1);

isnt($encrypted_name, $people->[0]->[0], 'Encrypt Star Name');
isnt($encrypted_color, $people->[0]->[2], 'Encrypt Star Color');

my ($decrypted_name, $decrypted_color) = $db->raw(query=>"SELECT name,favorite_color FROM dbix_raw WHERE id=?", vals=>[1], decrypt=>[0,1]);

is($decrypted_name, $people->[0]->[0], 'Decrypt Star Name');
is($decrypted_color, $people->[0]->[2], 'Decrypt Star Color');
