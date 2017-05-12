use strict;
use lib qw(t);
use Test::More;
use autoclass_100::Parent;

# this is a regression test covering the use of a class that does not inherit from AutoClass
# we don't really care what happens, so long as it doesn't crash

my $object =new autoclass_100::Parent;
isa_ok($object,'autoclass_100::Parent','new');

# test auto attributes
ok($object->can('auto'),'auto attribute defined');
is($object->auto(12345),12345,'auto attribute can be set');
is($object->auto,12345,'auto attribute can be gotten');

# test other attributes
ok($object->can('other'),'other attribute defined');
is($object->other(12345),12345,'other attribute can be set');
is($object->other,12345,'other attribute can be gotten');

# test class attributes
ok($object->can('class'),'class attribute defined');
is($object->class(12345),12345,'class attribute can be set');
is($object->class,12345,'class attribute can be gotten');

# test synonym and its target
ok($object->can('syn'),'synonym defined');
is($object->syn(12345),12345,'synonym can be set');
is($object->syn,12345,'synonym can be gotten');
is($object->real,12345,'target of synonym equals synonym');

ok($object->can('real'),'target of synonym defined');
is($object->real(6789),6789,'target of synonym can be set');
is($object->real,6789,'target of synonym can be gotten');
is($object->syn,6789,'synonym equals target of synonym');

# test defaults
my $object =new autoclass_100::Parent;
is($object->auto,'auto attribute','auto attribute default');
is($object->other,'other attribute','other attribute default');
is($object->class,'class attribute','class attribute default');
is($object->syn,'synonym','synonym default');
is($object->real,'synonym','target of synonym equals synonym default');

done_testing();
