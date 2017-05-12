#Courtesy of Duncan Ferguson
#REF: http://search.cpan.org/dist/Test-NoPlan/lib/Test/NoPlan.pm
 
use strict;
use warnings;
use Test::More;

eval 'use Test::NoPlan qw/ all_plans_ok /';
plan skip_all => 'Test::NoPlan required for this test' if $@;

all_plans_ok();
