use strict;
use warnings;
use Test::More tests => 9;
use File::Temp qw(tempdir);
use Apophis;

my $dir = tempdir(CLEANUP => 1);
my $ca = Apophis->new(namespace => 'test-store', store_dir => $dir);

# Store returns UUID
my $content = 'store me please';
my $id = $ca->store(\$content);
like($id, qr/^[0-9a-f]{8}-[0-9a-f]{4}-5[0-9a-f]{3}-/,
     'store returns valid UUID v5');

# Store returns same UUID as identify
my $expected = $ca->identify(\$content);
is($id, $expected, 'store returns same UUID as identify');

# Fetch round-trip
my $fetched = $ca->fetch($id);
ok(ref $fetched eq 'SCALAR', 'fetch returns scalar ref');
is($$fetched, $content, 'fetched content matches original');

# CAS dedup: storing same content again returns same ID
my $id2 = $ca->store(\$content);
is($id2, $id, 'storing same content returns same UUID (dedup)');

# Different content
my $other = 'different content';
my $id3 = $ca->store(\$other);
isnt($id3, $id, 'different content gets different UUID');

my $fetched3 = $ca->fetch($id3);
is($$fetched3, $other, 'fetch of second item returns correct content');

# Fetch nonexistent returns undef
my $missing = $ca->fetch('00000000-0000-5000-8000-000000000000');
ok(!defined $missing, 'fetch of nonexistent ID returns undef');

# store_dir override
my $dir2 = tempdir(CLEANUP => 1);
my $id4 = $ca->store(\$content, store_dir => $dir2);
my $fetched4 = $ca->fetch($id4, store_dir => $dir2);
is($$fetched4, $content, 'store_dir override works');
