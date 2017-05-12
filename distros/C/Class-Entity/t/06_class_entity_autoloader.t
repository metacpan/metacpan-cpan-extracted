use strict;
use warnings;
use Test::More qw(no_plan);

BEGIN { use_ok("Class::Entity") }

my $entity = Class::Entity->new(data => { Test => "Test" } );
cmp_ok($entity->Test, "eq", "Test", "object autloader");

