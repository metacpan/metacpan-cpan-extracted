use strict;
use warnings;
use Test::More;
use Carp;

$SIG{__DIE__} = sub { confess @_; };

BEGIN { plan tests => 21 }

use_ok('Cache::Null');

# Test basic get/set and remove

my $cache = Cache::Null->new();
ok($cache, 'Cache returned');

my $entry = $cache->entry('testkey');
ok($entry, 'Entry returned');
is($entry->key(), 'testkey', 'Entry key correct');
ok(!$entry->exists(), 'Entry doesnt exist initally');
is($entry->get(), undef, '$entry->get() returns undef');

$entry->set('test data');
ok(!$entry->exists(), 'Entry still doesnt exist after set');
is($entry->size(), undef, 'Data size is undef');
is($cache->size(), 0, 'Cache size is zero');

$entry->remove();
ok(!$entry->exists(), 'Entry doesnt exist after remove');


# Test handle write
my $handle = $entry->handle();
ok($handle, 'Handle created');
print $handle 'more test data';
close $handle;
ok(!$entry->exists(), 'Entry doesnt exist after handle write');
is($entry->get(), undef, '$entry->get() returns undef');

# Test handle read
$handle = $entry->handle('<');
is($handle, undef, 'Read handle not created');

# Test handle write only
$handle = $entry->handle('>');
ok($handle, 'Write handle created');
is(<$handle>, undef, 'Read from write only handle fails');
print $handle 'this should work';
undef $handle;
is($entry->get(), undef, 'Entry doesnt exist after handle write');

# Test append handle
$handle = $entry->handle('>>');
ok($handle, 'Append handle created');
$handle->print(' and it does');
$handle->close();
is($entry->get(), undef, 'Entry doesnt exist after handle append');
is($entry->size(), undef, 'Data size is correct');
is($cache->size(), 0, 'Cache size is correct');
