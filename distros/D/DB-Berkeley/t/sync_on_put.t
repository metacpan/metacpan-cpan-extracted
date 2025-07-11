use strict;
use warnings;
use Test::Most;
use DB::Berkeley;

my $file = 't/test-sync-on-put.db';
unlink $file if -e $file;

my $db = DB::Berkeley->new($file, 0, 0600, 1);	# sync_on_put enabled

ok($db->put('autoflush', 'yes'), 'put() with sync_on_put');
is($db->get('autoflush'), 'yes', 'value persists');

done_testing();

END { unlink $file if -e $file }
