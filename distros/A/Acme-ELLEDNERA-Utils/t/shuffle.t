#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

use Acme::ELLEDNERA::Utils qw( shuffle );

ok( defined &shuffle, "Acme::ELLEDNERA::Utils::shuffle export ok" );

{
	my @shuffled = shuffle();
	is( scalar @shuffled, 0, "no input == empty list");
}

{
	my @ori_nums = (1, 3, 5, 7, 9, 11, 13, 15);
	my @shuffled = shuffle(@ori_nums);
	
	is( scalar @ori_nums, scalar @shuffled, "Same-sized array returned" );
	
	isnt("@ori_nums", "@shuffled", "Shuffled the bunch of numbers");
}


done_testing();

# besiyata d'shmaya

