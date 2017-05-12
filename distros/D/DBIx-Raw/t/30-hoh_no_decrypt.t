#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use lib './t';
use dbixtest;

use_ok( 'DBIx::Raw' ) || print "Bail out!\n";

my $db = prepare();
my $hoh = $db->hoh(query=>"SELECT * FROM dbix_raw", key => 'id');

isa_ok( $hoh, 'HASH' );

my $people = people_hash();
while(my ($key, $hash) = each %$hoh) {
	isa_ok($hash, 'HASH');
	my $person = $people->[$hash->{id} - 1];

	while( my ($key2, $val2) = each %$hash) { 
		is($val2, $person->{$key2}, "Testing key $key2 is correct");
	}
}

done_testing();
