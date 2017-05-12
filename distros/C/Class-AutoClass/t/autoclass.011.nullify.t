use strict;
use lib qw(t);
use autoclass_011::Nullable;
use Test::More;

# this tests the ability to nullify (using the '_NULLIFY_' flag) an AutoClass object so as to 
# return undef to the caller

my $n1=new autoclass_011::Nullable(a => 'hello');
is($n1->a, 'hello', 'returns a Nullable object with param set');
my $n2=new autoclass_011::Nullable();
is($n2, undef,'nullify set: result undef');
isnt(ref $n2, 'Nullable','nullify set: result not blessed');

done_testing();
