#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use lib './t';
use dbixtest;

use_ok( 'DBIx::Raw' ) || print "Bail out!\n";

my $db = prepare(1);
my $aoa = $db->aoa(query => "SELECT name,age,favorite_color FROM dbix_raw", decrypt => [0,2]);

isa_ok( $aoa, 'ARRAY' );

my $people = people();
for my $person_num (0..$#$aoa) { 
	my $person = $aoa->[$person_num];
	isa_ok($person, 'ARRAY');
	my $array = $people->[$person_num];

	for my $count (0..$#$person) { 
		is($person->[$count], $array->[$count], "Testing index $count is " . $array->[$count]);
	}
}

done_testing();
