use strict;
use lib qw(t);
use Test::More;
use autoclass_103::Parent;
use autoclass_103::Child;
use autoclass_103::GrandChild;

# this is a regression test covering a bug where the DEFAULTS set in a child class
# do not get correctly applied to attributes in the parent class

my $parent=new autoclass_103::Parent;
my $child=new autoclass_103::Child;
my $grandchild=new autoclass_103::GrandChild;

is($parent->a, 'parent', 'parent has correct default setting');
is($child->a, 'child', 'child has correct default setting');
is($grandchild->a, 'grandchild', 'grandchild has correct default setting');

# NG 05-12-07: regression test for incorrect handling of defaults for 'virtual' attributes.
#              a virtual attribute is one that is implemented as a method and not
#              directly stored in the object

is($parent->b, 'virtual parent', 'parent has correct default setting for virtual attribute');
is($child->b, 'virtual child', 'child has correct default setting for virtual attribute');
is($grandchild->b, 'virtual grandchild', 'grandchild has correct default setting for virtual attribute');
my $c='default set in parent, used in kids';
is($child->c, $c, 'default set in parent, used in child');
is($grandchild->c, $c, 'default set in parent, used in grandchild');

my $d='default set in grandchild for attribute defined in parent';
ok(!$parent->d, 'default set in grandchild not seen in parent');
ok(!$child->d, 'default set in grandchild not seen in child');
is($grandchild->d, $d, 'default set in grandchild for attribute defined in parent');

$d='actual value set in new for attribute defined in parent';
$grandchild=new autoclass_103::GrandChild(d=>$d);
is($grandchild->d,$d, "$d not overwritten by default defined in grandchild");

# NG 05-12-09: regression test for error in which defaults are stored directly
#              in object HASH, rather than being fed through methods
ok(!defined $parent->{'b'},'parent: virtual default  not stored in object HASH');
# NG 09-04-22: test below is just wrong. 'c' is instance attribute so default
#              should be stored in HASH
# ok(!defined $parent->{'c'},'parent: default used in kids not stored in object HASH');
# ok(!defined $parent->{'z'},'parent: unused default not stored in object HASH');
ok(!defined $child->{'b'},'child: virtual default  not stored in object HASH');
# NG 09-04-22: test below is just wrong. 'z' is instance attribute so default
#              should be stored in HASH
# ok(!defined $child->{'z'},'child: unused default not stored in object HASH');
ok(!defined $grandchild->{'b'},'grandchild: virtual default  not stored in object HASH');
# ok(!defined $grandchild->{'z'},'grandchild: unused default not stored in object HASH');

done_testing();
