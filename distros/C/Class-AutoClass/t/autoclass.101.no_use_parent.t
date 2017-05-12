use strict;
use lib qw(t);
use Test::More;
use Test::Deep;
use autoclass_101::Child;

# this is a regression test covering the use of a class that does not 'use' its
# parent class

my $child=new autoclass_101::Child;
isa_ok($child,'autoclass_101::Child','new');

note 'test child attributes';
# test defaults
is($child->auto_c,'child auto attribute','child auto attribute default');
is($child->other_c,'child other attribute','child other attribute default');
is($child->class_c,'child class attribute','child class attribute default');
# NG 12-11-25: as of perl 5.17.6, order of hash keys is randomized. we cannot predict
#              order in which defaults applied to synonyms amd thus the final value
#              of 'syn_c' and 'real_c' making these tests pointless
# is($child->syn_c,'child synonym','child synonym default');
# is($child->real_c,'child synonym','child target of synonym equals synonym default');

# test auto attributes
ok($child->can('auto_c'),'child auto attribute defined');
is($child->auto_c(12345),12345,'child auto attribute can be set');
is($child->auto_c,12345,'child auto attribute can be gotten');

# test other attributes
ok($child->can('other_c'),'child other attribute defined');
is($child->other_c(12345),12345,'child other attribute can be set');
is($child->other_c,12345,'child other attribute can be gotten');

# test class attributes
ok($child->can('class_c'),'child class attribute defined');
is($child->class_c(12345),12345,'child class attribute can be set');
is($child->class_c,12345,'child class attribute can be gotten');

# test synonym and its target
ok($child->can('syn_c'),'child synonym defined');
is($child->syn_c(12345),12345,'child synonym can be set');
is($child->syn_c,12345,'child synonym can be gotten');
is($child->real_c,12345,'child target of synonym equals synonym');

ok($child->can('real_c'),'child target of synonym defined');
is($child->real_c(6789),6789,'child target of synonym can be set');
is($child->real_c,6789,'child target of synonym can be gotten');
is($child->syn_c,6789,'child synonym equals target of synonym');

note 'test parent attributes';
# test defaults
is($child->auto_p,'parent auto attribute','parent auto attribute default');
is($child->other_p,'parent other attribute','parent other attribute default');
is($child->class_p,'parent class attribute','parent class attribute default');
# NG 12-11-25: these tests now pointless.  see comment about hash keys randomization
# is($child->syn_p,'parent synonym','parent synonym default');
# is($child->real_p,'parent synonym','parent target of synonym equals synonym default');

# test auto attributes
ok($child->can('auto_p'),'parent auto attribute defined');
is($child->auto_p(12345),12345,'parent auto attribute can be set');
is($child->auto_p,12345,'parent auto attribute can be gotten');

# test other attributes
ok($child->can('other_p'),'parent other attribute defined');
is($child->other_p(12345),12345,'parent other attribute can be set');
is($child->other_p,12345,'parent other attribute can be gotten');

# test class attributes
ok($child->can('class_p'),'parent class attribute defined');
is($child->class_p(12345),12345,'parent class attribute can be set');
is($child->class_p,12345,'parent class attribute can be gotten');

# test synonym and its target
ok($child->can('syn_p'),'parent synonym defined');
is($child->syn_p(12345),12345,'parent synonym can be set');
is($child->syn_p,12345,'parent synonym can be gotten');
is($child->real_p,12345,'parent target of synonym equals synonym');

ok($child->can('real_p'),'parent target of synonym defined');
is($child->real_p(6789),6789,'parent target of synonym can be set');
is($child->real_p,6789,'parent target of synonym can be gotten');
is($child->syn_p,6789,'parent synonym equals target of synonym');

# test defaults again. should be same as before except for class
note 'test child and parent defaults again. should be same as before except for class';
my $child =new autoclass_101::Child;

is($child->auto_c,'child auto attribute','child auto attribute default 2nd time');
is($child->other_c,'child other attribute','child other attribute default 2nd time');
is($child->class_c,12345,'child class attribute default 2nd time');
# NG 12-11-25: these tests now pointless.  see comment about hash keys randomization
# is($child->syn_c,'child synonym','child synonym default 2nd time');
# is($child->real_c,'child synonym','child target of synonym equals synonym default 2nd time');

is($child->auto_p,'parent auto attribute','parent auto attribute default 2nd time');
is($child->other_p,'parent other attribute','parent other attribute default 2nd time');
is($child->class_p,12345,'parent class attribute default 2nd time');
# NG 12-11-25: these tests now pointless.  see comment about hash keys randomization
# is($child->syn_p,'parent synonym','parent synonym default 2nd time');
# is($child->real_p,'parent synonym','parent target of synonym equals synonym default 2nd time');

done_testing();
