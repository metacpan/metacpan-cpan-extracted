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
my $array = $db->array("SELECT name FROM dbix_raw");

isa_ok( $array, 'ARRAY' );

my $people = people_hash();

for my $name (@$array) {
	#for(@$people) { $_->{name} }
	ok((grep { $_->{name} eq $name } @$people) > 0, "Testing $name is in \$people");
}

done_testing();
