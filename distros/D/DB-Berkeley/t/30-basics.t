use strict;
use warnings;
use Test::Most;

BEGIN { use_ok('DB::Berkeley') }

my $dbfile = 'test.db';

# Clean up any pre-existing file
unlink $dbfile if -e $dbfile;

ok(my $db = DB::Berkeley->new($dbfile, 0, 0666), 'Created DB::Berkeley object');

ok($db->put('foo', 'bar'), "Inserted key 'foo' with value 'bar'");

is($db->get('foo'), 'bar', "Retrieved correct value for key 'foo'");

is($db->get('missing'), undef, 'Missing key returns undef');

ok($db->store('k1', 'v1'), 'store works');
is($db->fetch('k1'), 'v1', 'fetch returns correct value');

ok($db->set('fred', 'wilma'), 'set works');
is($db->get('fred'), 'wilma', 'get returns correct value');

done_testing();

# Clean up
END {
	unlink $dbfile if -e $dbfile;
}
