#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use lib './t';
use dbixtest;

use_ok( 'DBIx::Raw' ) || print "Bail out!\n";

my $db = prepare();

my $hoh = { 0 => { name => 'Billy', age => 23, favorite_color => 'brown' } };

$db->hoh(query=>"SELECT * FROM dbix_raw", key => 'id', href => $hoh);

isa_ok( $hoh, 'HASH' );

is($hoh->{0}->{name}, 'Billy', 'Testing href passed in name');
is($hoh->{0}->{age}, 23, 'Testing href passed in age');
is($hoh->{0}->{favorite_color}, 'brown', 'Testing href passed in favorite_color');

delete $hoh->{0};

my $people = people_hash();
while(my ($key, $hash) = each %$hoh) {
	isa_ok($hash, 'HASH');
	my $person = $people->[$hash->{id} - 1];

	while( my ($key2, $val2) = each %$hash) { 
		is($val2, $person->{$key2}, "Testing key $key2 is correct");
	}
}

done_testing();
