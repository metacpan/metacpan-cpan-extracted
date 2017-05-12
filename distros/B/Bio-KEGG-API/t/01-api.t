#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use lib 'lib';
use Bio::KEGG::API;

plan tests => 1;

my $k = Bio::KEGG::API->new();

my $result = $k->database_info(database => 'hsa');
my $got = 0;

if ( $result =~ m/^T01001/ ) {
	
	$got = 1;

}

ok($got == 1, "api test");
