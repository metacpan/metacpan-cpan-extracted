use strict;
use warnings;
use Test::More;


my $class;
BEGIN { $class = 'Data::FR::Town'; use_ok $class; }

my $object =  Data::FR::Town->new() ;

isa_ok $object, $class;

# Non-inherited methods
can_ok $object, qw( find insee zip article name cname dep depname );

$object = $object->find({insee => '01001'});
isa_ok $object, $class;
is ($object->cname(), 'ABERGEMENT-CLEMENCIAT', 'Cname for INSEE code 01001');
is ($object->zip(), '01400', 'Zip for INSEE code 01001');
is ($object->article(), 'L\'', 'Article for INSEE code 01001');
is ($object->dep(), '01', 'Dep for INSEE code 01001');
is ($object->depname(), 'AIN', 'Depname for INSEE code 01001');


$object = $class->find({insee => '97404'});
isa_ok $object, $class;
is ($object->cname(), 'ETANG-SALE', 'Cname for INSEE code 01001');
is ($object->zip(), '97427', 'Zip for INSEE code 01001');
is ($object->article(), 'L\'', 'Article for INSEE code 01001');
is ($object->dep(), '974', 'Dep for INSEE code 01001');
is ($object->depname(), 'REUNION', 'Depname for INSEE code 01001');

my $object2 = $class->new({insee => '97404'});
is_deeply($object, $object2, "find() and new({insee=>...}) retrieve the same object");

my $object3 = $class->new({zip => '97427'});
is_deeply($object, $object2, "find() and new({zip=>...}) retrieve the same object");

eval { $object3 = $class->new({unkonwnparam => '01001'})};
ok($@, "Unknown param illegal in new()");
eval { $object3 = $class->find({unkonwnparam => '01001'})};
ok($@, "Unknown param illegal in find()");

done_testing();
