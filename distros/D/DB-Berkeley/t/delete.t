use strict;
use warnings;
use Test::Most;
use FindBin;
use lib "$FindBin::Bin/../lib";

use_ok('DB::Berkeley');

my $dbfile = "test6.db";
unlink $dbfile if -e $dbfile;

my $db = DB::Berkeley->new($dbfile, 0, 0666);
ok($db, 'Opened DB');

# Put three keys
$db->put('alpha', 'one');
$db->put('beta',  'two');
$db->put('gamma', 'three');

# Exists should return true for all three
ok($db->exists('alpha'), 'alpha exists');
ok($db->exists('beta'),  'beta exists');
ok($db->exists('gamma'), 'gamma exists');

# keys() should return all three
my @keys = sort @{$db->keys()};
cmp_deeply(\@keys, [qw(alpha beta gamma)], 'keys() returned all keys');

# Delete one
ok($db->delete('beta'), 'deleted beta');

# Exists should now be false
ok(!$db->exists('beta'), 'beta no longer exists');

# keys() should return remaining two
@keys = sort @{$db->keys()};
cmp_deeply(\@keys, [qw(alpha gamma)], 'keys() updated correctly after delete');

# Delete non-existing key returns 0
is($db->delete('doesnotexist'), 0, 'delete returns 0 for nonexistent key');

done_testing;

END { unlink $dbfile if -e $dbfile }
