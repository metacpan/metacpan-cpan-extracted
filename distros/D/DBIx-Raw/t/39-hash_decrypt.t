#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use lib './t';
use dbixtest;

use_ok( 'DBIx::Raw' ) || print "Bail out!\n";

my $db = prepare(1);
my $hash = $db->hash(query => "SELECT id,name FROM dbix_raw", key => "id", val => "name", decrypt => ['name']);

isa_ok( $hash, 'HASH' );

my $people = people_hash();
my %people_h;

for(@$people) { $people_h{$_->{id}} = $_->{name} }

while(my ($key, $val) = each %$hash) {
	is($val, $people_h{$key}, "Testing $key contains $val");
}

done_testing();
