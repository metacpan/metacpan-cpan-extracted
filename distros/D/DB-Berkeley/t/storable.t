use strict;
use warnings;

use Test::Most;
use DB::Berkeley;
use Storable qw(nfreeze thaw);

my $file = "t/storable.db";
unlink $file if -e $file;

my $db = DB::Berkeley->new($file, 0, 0600);

# Simulated row of data (like a DB row)
my $row = {
    id     => 42,
    name   => "Alice",
    email  => 'alice@example.com',
    active => 1,
};

# Serialize and store the row
ok($db->put("user:42", nfreeze($row)), "Stored structured row data");

# Fetch and deserialize
my $frozen = $db->get("user:42");
ok(defined $frozen, "Fetched frozen data");

my $retrieved = thaw($frozen);
cmp_deeply($retrieved, $row, "Row structure matches after thaw");

done_testing();

END { unlink $file if -e $file }
