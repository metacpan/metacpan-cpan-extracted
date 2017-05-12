#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use lib './t';
use dbixtest;

use_ok( 'DBIx::Raw' ) || print "Bail out!\n";

my $db = prepare(1);
load_db($db, 1);
my $hoa = $db->hoa(query=>"SELECT id,name FROM dbix_raw", key => 'name', val => 'id', decrypt => ['name']);

isa_ok( $hoa, 'HASH' );

my $people = people_hash();

my $local_hoa;

for(@$people) { 
	push @{$local_hoa->{$_->{name}}}, $_->{id};
}
for(@$people) { 
	push @{$local_hoa->{$_->{name}}}, $_->{id};
}

while(my ($key, $array) = each %$hoa) {
	isa_ok($array, 'ARRAY');
	is(scalar(@$array), scalar(@{$local_hoa->{$key}}), "Testing same array length for key $key");

	for(@$array) { 
		ok(grep { $_ } @{$local_hoa->{$key}} > 0, "Testing $_ is in local_hoa");
	}
}

done_testing();
