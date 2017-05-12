#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use lib './t';
use dbixtest;

use_ok( 'DBIx::Raw' ) || print "Bail out!\n";

my $db = prepare();

my %update = ( 
	name => 'Steve',
	age => 25,
	favorite_color => 'purple',
);

my $people = people_hash();
my $p2 = $people->[1];

$db->update(href=>\%update, table => 'dbix_raw', where => "id=1");

my $person = $db->raw("SELECT name, age, favorite_color FROM dbix_raw where id=1");
my $person2 = $db->raw("SELECT name, age, favorite_color FROM dbix_raw where id=2");

is($person->{name}, $update{name}, "Testing name is $update{name}");
is($person->{age}, $update{age}, "Testing age is $update{age}");
is($person->{favorite_color}, $update{favorite_color}, "Testing favorite_color is $update{favorite_color}");

is($person2->{name}, $p2->{name}, "Testing name is $p2->{name}");
is($person2->{age}, $p2->{age}, "Testing age is $p2->{age}");
is($person2->{favorite_color}, $p2->{favorite_color}, "Testing favorite_color is $p2->{favorite_color}");

done_testing();
