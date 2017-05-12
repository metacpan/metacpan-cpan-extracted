use strict;
use lib qw(t);
use Parent;
use Child;
use GrandChild;
use Test::More;

my $p = Parent->population;
is ($p, 42, 'class variable init\'d at declare time, also answer to life, universe, etc');
my $parent1=new Parent();
$parent1->population(10);
is ($parent1->population, 10, 'set via setter');
is($Parent::species, 'Dipodomys gravipes', 'test default value'); # set through Parent %DEFAULTS hash
my $parent2=new Parent(species=>'human'); # set through constructor args
#is ($parent2->a, 'parent', 'set via DEFAULT');
is($Parent::species, 'human', 'test value through normal class call');
is($parent1->species, 'human', 'same - but calling through object');
is($parent2->species, 'human');
$parent1->species('canine');
is($parent1->species, 'canine', 'value is reset for all referants');
is($parent2->species, 'canine');
# Child does not set its own default - should inherit from Parent 
my $child1=new Child();
is($Parent::species, 'canine','test Parent default value ok (class call)');
is($parent1->species, 'canine','test Parent default value ok (obj call)');
is($parent2->species, 'canine','test Parent default value ok (obj call)');
is($child1->species,  'Dipodomys gravipes','Child declares but does not set species');
is($parent1->population, 10, 'Parent class variable not reset to default by Child');
is($child1->population, 10, 'Child inherits class variable');
$child1->species('Thamnophis sirtalis');
is($Child::species, 'Thamnophis sirtalis','test setting class var');
is($child1->species, 'Thamnophis sirtalis');
is($parent1->species, 'canine');
is($parent2->species, 'canine');
my $child2=new Child();
is($child2->species, 'Thamnophis sirtalis', 'test default value');
# GrandChild has its own default value for class var "species"
my $gchild1 = new GrandChild;
is($Parent::species, 'canine', 'testing Parent class vars');
is($parent1->species, 'canine');
is($parent2->species, 'canine');
is($Child::species, 'Thamnophis sirtalis','testing Child class vars');
is($child1->species, 'Thamnophis sirtalis');
is($child2->species, 'Thamnophis sirtalis');
is($GrandChild::species, 'schmoo', 'testing GrandChild default vars');
is($gchild1->species, 'schmoo');
my $gchild2 = new GrandChild();
$gchild2->species('fudd');
is($gchild2->species, 'fudd');
is($Child::species, 'Thamnophis sirtalis','test that Child not affected by GrandChild changing its class variable');
is($Parent::species, 'canine', 'test that Parent not affected by GrandChild changing its class variable');
my $gchild3 = new GrandChild(species=>'unknown');
is($gchild2->species, 'unknown');
is($Child::species, 'Thamnophis sirtalis','test that Child not affected by GrandChild instance created by passing constructor parameters');
is($Parent::species, 'canine', 'test that Parent not affected by GrandChild instance created by passing constructor parameters');
is (Parent->species, 'canine', 'Parent invokation by classname');
is (Child->species, 'Thamnophis sirtalis', 'Child invokation by classname');
is (GrandChild->species, 'unknown', 'GrandChild invokation by classname');
is (GrandChild->population, 10, 'invokation by classname with inheritance');
is (Parent->class_hash->{these}, 'those', 'invokation by classname to get a hash value');
is (GrandChild->class_hash->{these}, 'them', 'invokation by classname to get a hash value w/inheritance');

done_testing();
