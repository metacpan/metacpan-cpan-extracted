#!/usr/bin/perl -w

use Test::More tests => 4;

use Algorithm::Pair::Swiss;

my $pairer = Algorithm::Pair::Swiss->new;

$pairer->parties(1,2,3);

my @pairs = $pairer->pairs;
ok( @pairs == 2,				'two pairs for three parties');

$pairer->exclude(@pairs);
@pairs = $pairer->pairs;
ok( @pairs == 2,				'still two pairs after first exclusion');

$pairer->exclude(@pairs);
@pairs = $pairer->pairs;
ok( @pairs == 2,				'still two pairs after second exclusion');

$pairer->exclude(@pairs);
@pairs = $pairer->pairs;
ok( @pairs == 0,				'no more pairs after third exclusion');

