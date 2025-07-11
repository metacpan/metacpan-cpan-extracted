use strict;
use warnings;
use Test::Most;

BEGIN { use_ok('DB::Berkeley') }

my $file = 't/test-sync.db';
unlink $file if -e $file;

my $db = DB::Berkeley->new($file, 0, 0600);

ok($db->put('key', 'value'), 'Put key => value');
ok($db->sync, 'sync() returned true');

is($db->get('key'), 'value', 'get() after sync');

done_testing();

END { unlink $file if -e $file }
