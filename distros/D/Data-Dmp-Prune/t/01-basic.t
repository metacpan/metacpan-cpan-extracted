#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Data::Dmp::Prune qw(dmp);

{
    local $Data::Dmp::Prune::OPT_PRUNE = ["/3", "/b", "/c/foo"];
    is(dmp([1,2,3]), "[1,2,3]");
    is(dmp([1,2,3,4,5]), "[1,2,3,'PRUNED',5]");
    is(dmp({a=>1,b=>2,c=>{foo=>1,bar=>2}}), "{a=>1,c=>{bar=>2}}");
}

done_testing;
