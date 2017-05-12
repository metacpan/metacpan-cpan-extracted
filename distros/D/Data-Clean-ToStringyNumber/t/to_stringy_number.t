#!perl

use 5.010;
use strict;
use warnings;

use Data::Clean::ToStringyNumber;
use JSON::XS;
use Test::More 0.98;

my $c = Data::Clean::ToStringyNumber->get_cleanser;

is(JSON::XS->new->encode($c->clean_in_place([1, -1, 1.1, -1.1, "a", "1", undef, []])),
   q(["1","-1","1.1","-1.1","a","1",null,[]]));

DONE_TESTING:
done_testing();
