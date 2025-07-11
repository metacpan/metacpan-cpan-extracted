use strict;
use warnings;
use Test::Most;
use DB::Berkeley;

my $file = 't/sync-flag.db';
unlink $file if -e $file;

my $db = DB::Berkeley->new($file, 0, 0600);

# Default is 0
is($db->sync_on_put(), 0, 'sync_on_put default is off');

# Enable it
$db->sync_on_put(1);
is($db->sync_on_put(), 1, 'sync_on_put enabled');

# Disable again
$db->sync_on_put(0);
is($db->sync_on_put(), 0, 'sync_on_put disabled');

done_testing();

END { unlink $file if -e $file }
