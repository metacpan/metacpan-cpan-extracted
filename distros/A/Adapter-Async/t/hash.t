use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Adapter::Async::UnorderedMap::Hash;

my $hash = new_ok('Adapter::Async::UnorderedMap::Hash');
is($hash->count->get, 0, 'starts empty');
ok(!$hash->exists(xyz =>)->get, 'key does not yet exist');
ok($hash->set_key(xyz => 1234)->get, 'can set a key');
ok($hash->exists(xyz =>)->get, 'key now exists');
is($hash->get_key(xyz =>)->get, '1234', 'read back key');
ok($hash->delete(xyz =>)->get, 'can delete a key');
ok(!$hash->exists(xyz =>)->get, 'key does not exist any more');

done_testing;
