#!/usr/bin/perl -w

use Test::Simple tests => 2;
use Test::Exception;

use Algorithm::Pair::Swiss;

my $pairer = Algorithm::Pair::Swiss;

dies_ok { $pairer->parties(1,2,3,undef) }	'croak on undef party';

dies_ok { $pairer->parties(1,2,3,1) }		'croak on duplicated party';

