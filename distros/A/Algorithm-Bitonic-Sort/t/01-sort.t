#!perl

use 5.10.1;
use utf8;
use common::sense;
use Test::Simple tests => 2;

use Algorithm::Bitonic::Sort;
	
my @sample = (1,5,8,4,4365,2,67,33,345);
my @up = (1,2,4,5,8,33,67,345,4365);
my @down = (4365,345,67,33,8,5,4,2,1);

my @result = bitonic_sort( 1 ,@sample);
ok(@result ~~ @up, 'Ascending');

my @result = bitonic_sort( 0 ,@sample);
ok(@result ~~ @down, 'Decreasing');
