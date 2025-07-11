use strict;
use warnings;

use Test::Most;
use FindBin;

BEGIN { use_ok('DB::Berkeley') }

my $dbfile = 'test4.db';
unlink $dbfile if -e $dbfile;

my $db = DB::Berkeley->new($dbfile, 0, 0666);
ok($db, 'Opened DB');

$db->put($_, "val$_") for qw(a b c);

$db->iterator_reset();

my @keys;
while (my $k = $db->next_key) {
	push @keys, $k;
}

cmp_deeply([sort @keys], [qw(a b c)], 'next_key returned all keys');

done_testing;

END { unlink $dbfile if -e $dbfile }
