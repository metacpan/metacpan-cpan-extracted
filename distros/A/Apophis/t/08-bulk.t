use strict;
use warnings;
use Test::More tests => 6;
use File::Temp qw(tempdir);
use Apophis;

my $dir = tempdir(CLEANUP => 1);
my $ca = Apophis->new(namespace => 'test-bulk', store_dir => $dir);

# store_many
my @contents = ('alpha', 'beta', 'gamma');
my @refs = map { \$_ } @contents;
my @ids = $ca->store_many(\@refs);

is(scalar @ids, 3, 'store_many returns correct number of IDs');
like($ids[0], qr/^[0-9a-f]{8}-/, 'first ID is valid UUID');

# All stored
ok($ca->exists($ids[0]), 'first item exists after store_many');
ok($ca->exists($ids[2]), 'third item exists after store_many');

# find_missing
my @check = ($ids[0], '00000000-0000-5000-8000-000000000000', $ids[1]);
my @missing = $ca->find_missing(\@check);
is(scalar @missing, 1, 'find_missing returns correct count');
is($missing[0], '00000000-0000-5000-8000-000000000000',
   'find_missing returns the nonexistent ID');
