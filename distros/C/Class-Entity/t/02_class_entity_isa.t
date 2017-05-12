use strict;
use warnings;
use Test::More qw(no_plan);
BEGIN { use_ok("Class::Entity") }
isa_ok(Class::Entity->new, "Class::Entity");

