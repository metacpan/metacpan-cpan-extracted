use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Carp;

$SIG{__DIE__} = sub { confess @_; };

# This test suite requires total accuracy in ordering of removals over a short
# time period, so a higher resolution timer is required.
eval { require Time::HiRes }
	or plan skip_all => 'Time::HiRes is required for this test.';
Time::HiRes->export('Cache::File', 'time');
Time::HiRes->export('Cache::File::Entry', 'time');

plan tests => 22;

require_ok('Cache::File');

my $tempdir = tempdir(CLEANUP => 1);
my $cache = Cache::File->new(
		cache_root => $tempdir,
		size_limit => 10,
		removal_strategy => 'Cache::RemovalStrategy::FIFO',
	);

is(ref($cache->removal_strategy()), 'Cache::RemovalStrategy::FIFO',
	'Removal strategy set to FIFO');

my $entry1 = $cache->entry('testkey');
my $entry2 = $cache->entry('testkey2');
my $entry3 = $cache->entry('testkey3');

# Test that entry1 is removed when entry2 overfills cache
$entry1->set('012345678');  # 9 bytes
ok($entry1->exists(), 'Entry added');
is($cache->size(), 9, 'Cache size correct');
sleep(1);
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

# Test that entry1 is removed even after entry1 is used (FIFO)
$entry1->remove();
$entry2->remove();
$entry3->remove();

$entry1->set('0123'); # 4 bytes
sleep(2);
$entry2->set('0123'); # 4 bytes
sleep(2);
$entry1->get();
sleep(2);

$entry3->set('0123'); # 4 bytes
ok($entry3->exists(), 'Third entry added');
ok(!$entry1->exists(), 'First entry removed');
ok($entry2->exists(), 'Second entry remains');
is($cache->size(), 8, 'Cache size correct');
