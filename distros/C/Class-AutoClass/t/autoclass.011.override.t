use strict;
use lib qw(t);
use autoclass_011::Override;
use Child;
use Test::More;

# this tests the ability to override the AutoClass object with another object (using the '_OVERRIDE__' flag)
my $over1 = new autoclass_011::Override;
is(ref $over1, 'autoclass_011::Override','override not set');
my $over2 = new autoclass_011::Override(override=>1); # causes Override to set __OVERRIDE__ to true
is(ref $over2, 'Child','override set');

done_testing();
