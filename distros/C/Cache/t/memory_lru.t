use strict;
use warnings;
use Test::More;
use Carp;

$SIG{__DIE__} = sub { confess @_; };

BEGIN { plan tests => 22 }

use_ok('Cache::Memory');

my $cache = Cache::Memory->new(size_limit => 10);

is(ref($cache->removal_strategy()), 'Cache::RemovalStrategy::LRU',
	'Default removal strategy set to LRU');

my $entry1 = $cache->entry('testkey');
my $entry2 = $cache->entry('testkey2');
my $entry3 = $cache->entry('testkey3');

# Test that entry1 is removed when entry2 overfills cache
$entry1->set('012345678');  # 9 bytes
ok($entry1->exists(), 'Entry added');
is($cache->size(), 9, 'Cache size correct');
$entry2->set('0123456'); # 7 bytes
ok($entry2->exists(), 'Second entry added');
ok(!$entry1->exists(), 'First entry removed');
is($cache->size(), 7, 'Cache size correct');

# Test that readding entry1 overfills cache and removes entry2
$entry1->set('012345678'); # 9 bytes
ok($entry1->exists(), 'First entry added');
ok(!$entry2->exists(), 'Second entry removed');
is($cache->size(), 9, 'Cache size correct');

# Test that entry1 is removed after entry2 & entry3 are added and overfill cache
$entry1->remove();
is($cache->size(), 0, 'Cache size correct');

$entry1->set('0123'); # 4 bytes
ok($entry1->exists(), 'First entry added');
$entry2->set('0123'); # 4 bytes
ok($entry1->exists(), 'Second entry added');
is($cache->size(), 8, 'Cache size correct');
$entry3->set('01234'); # 5 bytes
ok($entry3->exists(), 'Third entry added');
ok(!$entry1->exists(), 'First entry removed');
ok($entry2->exists(), 'Second entry remains');
is($cache->size(), 9, 'Cache size correct');

# Test that entry2 is removed after entry1 is used (LRU)
$entry1->remove();
$entry2->remove();
$entry3->remove();

$entry1->set('0123'); # 4 bytes
$entry2->set('0123'); # 4 bytes
$entry1->get();

$entry3->set('0123'); # 4 bytes
ok($entry3->exists(), 'Third entry added');
ok($entry1->exists(), 'First entry remains');
ok(!$entry2->exists(), 'Second entry removed');
is($cache->size(), 8, 'Cache size correct');
