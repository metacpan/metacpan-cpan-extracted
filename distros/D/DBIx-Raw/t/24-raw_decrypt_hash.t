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
$db->raw(query=>"UPDATE dbix_raw SET name=?,favorite_color=? WHERE id=?", vals=>[$people->[0]->[0], $people->[0]->[2], 1], encrypt=>[0,1]);

my $decrypted = $db->raw(query=>"SELECT name,favorite_color FROM dbix_raw WHERE id=?", vals=>[1], decrypt=>['name', 'favorite_color']);

is($decrypted->{name}, $people->[0]->[0], 'Decrypt Hash Name');
is($decrypted->{favorite_color}, $people->[0]->[2], 'Decrypt Hash Color');
