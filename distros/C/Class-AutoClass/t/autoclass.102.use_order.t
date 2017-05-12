use strict;
use lib qw(t);
use Test::More;
use Test::Deep;

# this is a regression test covering classes that are 'used' out of order
# due to the Parent class using the Child

BEGIN {	
  use_ok('autoclass_102::Parent'); # MUST use Parent before Child -- whole point of test!
  use_ok('autoclass_102::Child'); # MUST use Child before GrandChild -- whole point of test!
  use_ok('autoclass_102::GrandChild');
  use_ok('autoclass_102::StepParent'); # MUST use last
}
# test compile time declaration -- non-documented interface
*declared=\&Class::AutoClass::DECLARED;
is(declared('autoclass_102::Parent'),1,'Parent declared at compile-time');
is(declared('autoclass_102::StepParent'),1,'StepParent declared at compile-time');
is(declared('autoclass_102::Child'),1,'Child declared at compile-time');
is(declared('autoclass_102::GrandChild'),1,'Grandchild declared at compile-time');

my $child=new autoclass_102::Child
  (child_attribute=>'child',parent_attribute=>'parent',stepparent_attribute=>'stepparent');
isa_ok($child,'autoclass_102::Child','new');

# test instance attributes
is($child->child_attribute, 'child', 'child attribute set in child');
is($child->parent_attribute, 'parent', 'parent attribute set in child');
is($child->stepparent_attribute, 'stepparent', 'stepparent attribute set in child');
is($child->child_default, 'child', 'child default set in child');
is($child->parent_default, 'parent', 'parent default set in child');
is($child->stepparent_default, 'stepparent', 'stepparent default set in child');

# test class attributes
is($child->child_class_default,'child','child class default set in child');
is($child->parent_class_default,'parent','parent class default set in child');
is($child->stepparent_class_default,'stepparent','stepparent class default set in child');

my $grandchild=new autoclass_102::GrandChild
  (grandchild_attribute=>'grandchild',child_attribute=>'child',
   parent_attribute=>'parent',stepparent_attribute=>'stepparent');
isa_ok($grandchild,'autoclass_102::GrandChild','new');

# test instance attributes
is($grandchild->grandchild_attribute, 'grandchild', 'grandchild attribute set in grandchild');
is($grandchild->child_attribute, 'child', 'child attribute set in grandchild');
is($grandchild->parent_attribute, 'parent', 'parent attribute set in grandchild');
is($grandchild->stepparent_attribute, 'stepparent', 'stepparent attribute set in grandchild');
is($grandchild->grandchild_default, 'grandchild', 'grandchild default set in grandchild');
is($grandchild->child_default, 'child', 'child default set in grandchild');
is($grandchild->parent_default, 'parent', 'parent default set in grandchild');
is($grandchild->stepparent_default, 'stepparent', 'stepparent default set in grandchild');

# test class attributes
is($grandchild->grandchild_class_default,'grandchild',
   'grandchild class default set in grandchild');
is($grandchild->child_class_default,'child','child class default set in grandchild');
is($grandchild->parent_class_default,'parent','parent class default set in grandchild');
is($grandchild->stepparent_class_default,'stepparent','stepparent class default set in grandchild');

done_testing();
