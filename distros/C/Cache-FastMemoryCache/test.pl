# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 6 };
#use Cache::MemoryCache;
use Cache::FastMemoryCache;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

# 2. Create a cache
my $c = new Cache::FastMemoryCache();
ok(1);

# 3. Create another one, but with options.
$c = new Cache::FastMemoryCache(+{namespace => 'Fast'});
ok(1);

# 4. Insert some data.
my $h = { 'name' => 'old' };
$c->set('h', $h);
ok(1);

# 5. Fetch it back.
$h = $c->get('h');
ok($h);

# 6. Verify that it hasn't been cloned.
$h->{'name'} = 'new';
$h = $c->get('h');
ok($h->{'name'},'new');

