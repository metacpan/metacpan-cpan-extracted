#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use lib './t';
use dbixtest;

use_ok( 'DBIx::Raw' ) || print "Bail out!\n";

my $db = prepare(1);
my $aoh = $db->aoh(query=>"SELECT * FROM dbix_raw", decrypt => decrypt_arr());

isa_ok( $aoh, 'ARRAY' );

my $people = people_hash();
for(@$aoh) { 
	isa_ok($_, 'HASH');
	my $hash = $people->[$_->{id} - 1];

	while( my ($key, $val) = each %$_) { 
		is($val, $hash->{$key}, "Testing key $key is correct");
	}
}

done_testing();
