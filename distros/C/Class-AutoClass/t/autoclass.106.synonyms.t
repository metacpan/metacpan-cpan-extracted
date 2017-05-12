use strict;
use lib qw(t);
use autoclass_106::Parent;
use autoclass_106::Child;
use GrandChild;
use Test::More;

# this is a regression test covering a bug where 2 or more synonyms exist
# for the same attribute, one synonym is set in the args, and a default
# is set for the real attribute

my $child=new autoclass_106::Child;
is($child->real, 'default', 'attribute set from defaults');
is($child->syn1, $child->real, 'syn1 same as real');
is($child->syn2, $child->real, 'syn2 same as real');
is($child->syn3, $child->real, 'syn3 same as real');
is($child->syn3, $child->real, 'syn4 same as real');
undef $child;
$child=new autoclass_106::Child(-syn1=>'arg');
is($child->real, 'arg', 'attribute set from args');
is($child->syn1, $child->real, 'syn1 same as real');
is($child->syn2, $child->real, 'syn2 same as real');
is($child->syn3, $child->real, 'syn3 same as real');
is($child->syn3, $child->real, 'syn4 same as real');

done_testing();
