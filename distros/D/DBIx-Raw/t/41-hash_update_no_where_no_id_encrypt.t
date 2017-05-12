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

$db->update(href=>\%update, table => 'dbix_raw', encrypt => '*');

my $aoh = $db->aoh(query => "SELECT name, age, favorite_color FROM dbix_raw", decrypt => ['name', 'age', 'favorite_color']);

for(@$aoh) {
	while(my ($key, $val) = each %$_) {
		is($val, $update{$key}, "Testing $key contains $val");
	}
}

done_testing();
