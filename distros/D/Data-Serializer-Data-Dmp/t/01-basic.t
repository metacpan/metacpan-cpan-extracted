#!perl

use 5.010;
use strict;
use warnings;

use Data::Serializer;
use Test::More 0.98;

my $ds = Data::Serializer->new(serializer=>"Data::Dmp");
is_deeply($ds->deserialize($ds->serialize([1,2,3,undef])), [1,2,3,undef]);
done_testing;
