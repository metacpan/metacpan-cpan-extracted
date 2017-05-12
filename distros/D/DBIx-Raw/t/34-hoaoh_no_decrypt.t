#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use lib './t';
use dbixtest;

use_ok( 'DBIx::Raw' ) || print "Bail out!\n";

my $db = prepare();
load_db($db);
my $hoaoh = $db->hoaoh(query=>"SELECT id,name FROM dbix_raw", key => 'name');

isa_ok( $hoaoh, 'HASH' );

my $people = people_hash();

my $local_hoaoh;

for(@$people) { 
	push @{
		$local_hoaoh->{$_->{name}}
	}, $_;

	my %new_hash = %$_;
	$new_hash{id} += 2;

	push @{
		$local_hoaoh->{$_->{name}}
	}, \%new_hash;
}

while(my ($key, $array) = each %$hoaoh) {
	isa_ok($array, 'ARRAY');

	is(scalar(@$array), scalar(@{$local_hoaoh->{$key}}), "Testing same array length for key $key");

	for my $i (0..$#{$array}) { 
		my $hash = $array->[$i];
		isa_ok( $hash, 'HASH' );
			
		while( my ($key2, $val) = each %$hash) { 
			is($val, $local_hoaoh->{$key}->[$i]->{$key2});
		}
	}
}

done_testing();
