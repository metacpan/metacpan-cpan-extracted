use Test::More tests => 4;

use_ok('Criteria::Compile');

ok( Criteria::Compile->new()->exec({}),
    'basic instance compilable');
ok( Criteria::Compile::HASH->new()->exec({}),
    'basic HASH instance compilable');
ok( Criteria::Compile::OBJECT->new()->exec({}),
    'basic OBJECT instance compilable');
