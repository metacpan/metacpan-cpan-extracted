#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use lib './t';
use dbixtest;

use_ok( 'DBIx::Raw' ) || print "Bail out!\n";

my $db = get_db();
create_table($db);

my $rows = [
	[
		1,
		'Adam',
		22,
	],
	[
		2,
		'Dan',
		55,
	],
];

$db->insert_multiple(table => 'dbix_raw', columns => [qw/id name age/], rows => $rows);

my $aoa = $db->aoa("SELECT id, name, age FROM dbix_raw");

for my $count (0..$#$rows) { 
	for my $second_count (0..$#{$rows->[$count]}) {
		is($aoa->[$count]->[$second_count], $rows->[$count]->[$second_count], "Testing $aoa->[$count]->[$second_count] equals $rows->[$count]->[$second_count]");	
	}
}

done_testing();
